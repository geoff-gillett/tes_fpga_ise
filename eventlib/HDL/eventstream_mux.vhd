--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: eventstream_mux
-- Project Name: eventlib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.stream.all;

use work.events.all;
--TODO optimise to remove wait states
-- merges instreams keeping temporal order incorporates tickstream
entity eventstream_mux is
generic(
  CHANNEL_BITS:integer:=3;
  RELTIME_BITS:integer:=16;
  TIMESTAMP_BITS:integer:=64;
  TICKPERIOD_BITS:integer:=32;
  MIN_TICKPERIOD:integer:=2**16
);
port(
  clk:in std_logic;
  reset:in std_logic;
  -- from channel captures
  start:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  commit:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  dump:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  instreams:in streambus_array(2**CHANNEL_BITS-1 downto 0);
  --pulsestream_lasts:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  instream_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  instream_readys:out boolean_vector(2**CHANNEL_BITS-1 downto 0);
  full:out boolean;
  -- tick event
  tick_period:in unsigned(TICKPERIOD_BITS-1 downto 0);
  overflows:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --dirty:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  outstream:out streambus_t;
  valid:out boolean;
  --last:out boolean;
  ready:in boolean
);
end entity eventstream_mux;
--
architecture RTL of eventstream_mux is
	
constant CHANNELS:integer:=2**CHANNEL_BITS;

signal timestamp,eventtime:unsigned(TIMESTAMP_BITS-1 downto 0);
signal reltime:unsigned(CHUNK_DATABITS-1 downto 0);
signal reltime_stamp,reltime_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal started,commited,dumped:std_logic_vector(CHANNELS-1 downto 0);
signal req,gnt:std_logic_vector(CHANNELS-1 downto 0);
signal handled:std_logic_vector(CHANNELS downto 0);
signal sel:std_logic_vector(CHANNELS downto 0);

signal ticked,tick,time_valid,read_next:boolean;
--type FSMstate is (IDLE,HEAD,TAIL,NEXT_TIME);
--signal state,nextstate:FSMstate;
type arbFSMstate is (IDLE,ARBITRATE,SEL_STREAM,NEXT_TIME);
signal arb_state,arb_nextstate:arbFSMstate;
signal tickstream:streambus_t;
signal muxstream_valid,muxstream_ready,muxstream_last:boolean;
signal tickstream_valid:boolean;
signal tickstream_ready:boolean;
--
signal streams:streambus_array(CHANNELS downto 0);
signal muxstream,stream_int:streambus_t;
signal valids,readys:boolean_vector(CHANNELS downto 0);
signal time_done:boolean;
signal handshake:boolean;
signal pulses_done:boolean;
signal last_handshake:boolean;
signal sel_valid:boolean;
signal sel_done:boolean;
type outFSMstate is (HEAD,TAIL);
signal out_state,out_nextstate:outFSMstate;
signal event_head:boolean;
signal new_sel:boolean;
--signal sel_int:boolean_vector(CHANNELS downto 0);
signal sel_pipe:boolean_vector(3 downto 0);
--
begin

tickstreamer:entity work.tickstream
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  PERIOD_BITS => TICKPERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  MINIMUM_PERIOD => MIN_TICKPERIOD
)
port map(
  clk => clk,
  reset => reset,
  tick => tick,
  timestamp => timestamp,
  tick_period => tick_period,
  overflow => overflows,
  tickstream => tickstream,
  valid => tickstream_valid,
  ready => tickstream_ready
);

buffers:entity work.timing_buffer
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  RELTIME_BITS => RELTIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset,
  start => start,
  commit => commit,
  dump => dump,
  tick => tick,
  timestamp => timestamp,
  eventtime => eventtime,
  reltime => reltime,
  started => started,
  ticked => ticked,
  commited => commited,
  dumped => dumped,
  valid => time_valid,
  read_next => read_next,
  full => full
);

--

--readys <= (others => FALSE) when arb_state=IDLE or not muxstream_ready 
--														else to_boolean(sel);
	
--FIXME are these register slices needed?	
inputRegGen:for i in CHANNELS downto 1 generate
begin
	inputReg:entity streamlib.streambus_register_slice
  port map(
    clk => clk,
    reset => reset,
    stream_in => instreams(i-1),
    ready_out => instream_readys(i-1),
    valid_in => instream_valids(i-1),
    stream => streams(i),
    ready => readys(i),
    valid => valids(i)
  );
end generate;

tickInputReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => tickstream,
  ready_out => tickstream_ready,
  valid_in => tickstream_valid,
  stream => streams(0),
  ready => readys(0),
  valid => valids(0)
);

selector:entity work.eventstream_selector
generic map(
  CHANNELS => CHANNELS+1
)
port map(
	clk => clk,
	reset => reset,
  sel => to_boolean(sel),
  go => new_sel,
  done => sel_done, -- last read into registers
  instreams => streams,
  valids => valids,
  readys => readys,
  mux_stream => muxstream,
  mux_valid => muxstream_valid,
  mux_ready => muxstream_ready 
);
muxstream_last <= muxstream.last(0);

pulses_done <= started = handled(CHANNELS downto 1);-- and time_valid; 
time_done <= pulses_done and to_std_logic(ticked) = handled(0);
read_next <= arb_state=NEXT_TIME;

sel_valid <= TRUE;

-- clk1 req
-- clk2 gnt onehot index 
-- clk3 sel


new_sel <= sel_pipe(0);
arbiter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' or arb_state=NEXT_TIME then
  	req <= (others => '0');
  	gnt <= (others => '0');
  	sel <= (others => '0');
  	handled <= (others => '0');
  else
    sel_pipe(2) <= (arb_state=IDLE and time_valid) or 
    							 (sel_done and arb_state=SEL_STREAM and not time_done);
    							 
    sel_pipe(1 downto 0) <= sel_pipe(2 downto 1);
  	if time_valid then
  		req <= started and commited and not handled(CHANNELS downto 1);
      gnt <= req and std_logic_vector(unsigned(not req)+1);
--      if state=IDLE then 
   		--sel_valid <= TRUE;
	    if arb_state=ARBITRATE then 
      	if pulses_done then 
	      	handled(0) <= to_std_logic(ticked);
--	      	if sel_done or arb_state=IDLE then
      		sel <= (0 => to_std_logic(ticked), others => '0');
--      		end if;
      	else
	      	handled <= handled or gnt & '0' or dumped & '0';
--	      	if sel_done or arb_state=IDLE then
      		sel <= gnt & '0';
--      		end if;
      	end if;
      end if;
  	else
    	--sel_valid <= FALSE;
  		sel <= (others => '0');
  		req <= (others => '0');
  		handled <= (others => '0');
  	end if;
	end if;
end if;
end process arbiter;

fsmNextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	--state <= IDLE;
  	arb_state <= IDLE;
  	out_state <= HEAD;
  else
  	arb_state <= arb_nextstate;
  	out_state <= out_nextstate; 
    --state <= nextstate;
  end if;
end if;
end process fsmNextstate;

arbFSMtransition:process(arb_state,time_done,sel_done,time_valid,sel_pipe(1))
begin
	arb_nextstate <= arb_state;
	case arb_state is 
	when IDLE =>
		if time_valid then 
			arb_nextstate <= ARBITRATE;
		end if;
	when ARBITRATE =>
		if sel_pipe(1) then
			arb_nextstate <= SEL_STREAM;
		end if;
	when SEL_STREAM =>
		if sel_done then
			if time_done then
				arb_nextstate <= NEXT_TIME;
			else
				arb_nextstate <= ARBITRATE;
			end if;
		end if;
	when NEXT_TIME =>
		arb_nextstate <= IDLE;
	end case;
end process arbFSMtransition;

handshake <= muxstream_valid and muxstream_ready;
last_handshake <= handshake and muxstream_last;

outFSMtrasition:process(out_state,handshake,time_done)
begin
	out_nextstate <= out_state;
	case out_state is 
	when HEAD =>
		if handshake then
			out_nextstate <= TAIL;
		end if;
	when TAIL =>
		if time_done then -- might be at wrong latency
			out_nextstate <= HEAD;
		end if;
	end case;
end process outFSMtrasition;

eventHead:process(clk)
begin
	if rising_edge(clk) then
		if reset='1' then
			event_head <= TRUE;
		elsif time_done then
			event_head <= TRUE;
		elsif handshake then
			event_head <= FALSE;
		end if;
	end if;
end process eventHead;

relativetimestamp : process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			reltime_stamp <= (others => '1');
		else
			if (time_valid and arb_state=IDLE) then
				reltime_stamp <= to_std_logic(reltime);
			elsif last_handshake then
				reltime_stamp <= (others => '0');
			end if;
		end if;
	end if;
end process relativetimestamp;

--insert the timestamp
reltime_chunk <= reltime_stamp when (out_state=HEAD and not time_done)
															 else muxstream.data(47 downto 32); 

stream_int.data <= muxstream.data(63 downto 48) &
									 reltime_chunk &
									 muxstream.data(31 downto 0);

stream_int.last <= muxstream.last;
stream_int.keep_n <= muxstream.keep_n;

--FIXME is this right?							
--stream_valid_int <= muxstream_valid and arb_state/=IDLE;

outStreamReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_int,
  ready_out => muxstream_ready,
  valid_in => muxstream_valid,
  stream => outstream,
  ready => ready,
  valid => valid
);
end architecture RTL;
