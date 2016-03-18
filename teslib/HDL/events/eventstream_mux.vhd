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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--use work.types.all;
--use work.functions.all;
--
library streamlib;
use streamlib.types.all;

use work.events.all;


--TODO optimise to remove wait states
-- merges instreams keeping temporal order incorporates tickstream
entity eventstream_mux is
generic(
  CHANNEL_BITS:integer:=3;
  RELTIME_BITS:integer:=16;
  TIMESTAMP_BITS:integer:=64;
  TICKPERIOD_BITS:integer:=32;
  MIN_TICKPERIOD:integer:=2**16;
  TICKPIPE_DEPTH:integer:=2
);
port(
  clk:in std_logic;
  reset:in std_logic;
  -- from channel captures
  start:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  commit:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  dump:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  instreams:in streambus_array_t(2**CHANNEL_BITS-1 downto 0);
  --pulsestream_lasts:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  instream_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  instream_readys:out boolean_vector(2**CHANNEL_BITS-1 downto 0);
  full:out boolean;
  -- tick event
  tick_period:in unsigned(TICKPERIOD_BITS-1 downto 0);
  overflows:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --dirty:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  muxstream:out streambus_t;
  valid:out boolean;
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
signal sel,sel_int:std_logic_vector(CHANNELS downto 0);

signal ticked,tick,time_valid,read_next:boolean;
--type FSMstate is (IDLE,HEAD,TAIL,NEXT_TIME);
--signal state,nextstate:FSMstate;
type arbFSMstate is (IDLE,ARBITRATE,SEL_STREAM,SEL_TICK,NEXT_TIME);
signal arb_state,arb_nextstate:arbFSMstate;
signal tickstream:streambus_t;
signal muxstream_int_valid,muxstream_int_ready,muxstream_last:boolean;
signal tickstream_valid:boolean;
signal tickstream_ready:boolean;
--
signal streams:streambus_array_t(CHANNELS downto 0);
signal muxstream_int,stream_int:streambus_t;
signal valids,readys:boolean_vector(CHANNELS downto 0);
signal time_done:boolean;
signal muxstream_handshake:boolean;
signal pulses_done:boolean;
signal muxstream_last_handshake:boolean;
signal sel_valid:boolean;
signal sel_done:boolean;
type outFSMstate is (HEAD,TAIL);
signal out_state,out_nextstate:outFSMstate;
signal first_event:boolean;
--signal sel_int:boolean_vector(CHANNELS downto 0);
signal sel_pipe:boolean_vector(3 downto 0);
signal window:unsigned(RELTIME_BITS-1 downto 0);
signal new_window:boolean;
--
begin

tickstreamer:entity work.tickstream
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  PERIOD_BITS => TICKPERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  MINIMUM_PERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH
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
  window => window,
  timestamp => timestamp,
  eventtime => eventtime,
  reltime => reltime,
  new_window => new_window,
  started => started,
  ticked => ticked,
  commited => commited,
  dumped => dumped,
  valid => time_valid,
  read_next => read_next,
  full => full
);

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
  sel => to_boolean(sel),
  instreams => streams,
  valids => valids,
  stream => muxstream_int,
 	valid => muxstream_int_valid
);
--readys <= to_boolean(sel) when muxstream_ready else (others => FALSE);  
muxstream_last <= muxstream_int.last(0);
muxstream_handshake <= muxstream_int_valid and muxstream_int_ready;
muxstream_last_handshake <= muxstream_handshake and muxstream_last;

pulses_done <= started = handled(CHANNELS downto 1);-- and time_valid; 
time_done <= pulses_done and to_std_logic(ticked) = handled(0);
read_next <= arb_state=NEXT_TIME;

--sel_valid <= TRUE;

-- clk1 req
-- clk2 gnt onehot index 
-- clk3 sel

req <= started and commited and not handled(CHANNELS downto 1);
sel_int <= gnt & to_std_logic(ticked and pulses_done);
arbiter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then 
--  	sel_int <= (others => '0');
  	handled <= (others => '0');
  	gnt <= (others => '0');
  else
  	--gnt <= req and std_logic_vector(unsigned(not req)+1);
  	
    if arb_state=IDLE then
    	handled <= (others => '0');		
    elsif muxstream_last_handshake then
      handled(CHANNELS downto 1) <= handled(CHANNELS downto 1) or 
                                    gnt or dumped;
    end if;
    													
    --if arb_state=ARBITRATE then
	    gnt <= req and std_logic_vector(unsigned(not req)+1);
    --end if;		
    													  
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

arbFSMtransition:process(arb_state,time_valid,sel,muxstream_last_handshake,
												 muxstream_int_ready,pulses_done,ticked,gnt)
begin
	arb_nextstate <= arb_state;
	readys <= (others => FALSE);
	sel <= (others => '0');
	case arb_state is 
	when IDLE =>
		if time_valid then 
			arb_nextstate <= ARBITRATE;
		end if;
	when ARBITRATE =>
		if pulses_done then 
			if ticked then
				arb_nextstate <= SEL_TICK;
			else
				arb_nextstate <= NEXT_TIME;
			end if;
		elsif unaryOR(gnt) then
			arb_nextstate <= SEL_STREAM;
		end if;
	when SEL_STREAM =>
		if muxstream_int_ready then
			readys <= to_boolean(sel);
		end if;
		sel <= gnt & '0';
		if muxstream_last_handshake then
			if pulses_done then
				if ticked then
					arb_nextstate <= SEL_TICK;
				else
					arb_nextstate <= NEXT_TIME;
				end if;
			else
				arb_nextstate <= ARBITRATE;
			end if;
		end if;
	when SEL_TICK =>
		sel <= (0 => '1', others => '0');
		readys <= (0 => TRUE, others => FALSE);
		if muxstream_last_handshake then
			arb_nextstate <= next_time;
		end if;
	when NEXT_TIME =>
		arb_nextstate <= IDLE;
	end case;
end process arbFSMtransition;

outFSMtrasition:process(out_state,muxstream_handshake,muxstream_last_handshake,
												muxstream_last)
begin
	out_nextstate <= out_state;
	case out_state is 
	when HEAD =>
		if muxstream_handshake and not muxstream_last then
			out_nextstate <= TAIL;
		end if;
	when TAIL =>
		if muxstream_last_handshake then -- might be at wrong latency
			out_nextstate <= HEAD;
		end if;
	end case;
end process outFSMtrasition;

--FIXME reltime not working
firstEvent:process(clk)
begin
	if rising_edge(clk) then
		if reset='1' then
			first_event <= TRUE;
		else
      if arb_state=NEXT_TIME then
        first_event <= TRUE;
      elsif muxstream_last_handshake then
        first_event <= FALSE;
      end if;
    end if;
	end if;
end process firstEvent;

relativetimestamp:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			reltime_stamp <= (others => '1');
		else
			if first_event then
				reltime_stamp <= to_std_logic(reltime);
			else
				reltime_stamp <= (others => '0');
			end if;
		end if;
	end if;
end process relativetimestamp;

--insert the timestamp
reltime_chunk <= reltime_stamp when (out_state=HEAD)
															 else muxstream_int.data(47 downto 32); 

stream_int.data <= muxstream_int.data(63 downto 48) &
									 reltime_chunk &
									 muxstream_int.data(31 downto 0);

stream_int.last <= muxstream_int.last;
stream_int.keep_n <= muxstream_int.keep_n;

--FIXME is this right?							
--stream_valid_int <= muxstream_valid and arb_state/=IDLE;

outStreamReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_int,
  ready_out => muxstream_int_ready,
  valid_in => muxstream_int_valid,
  stream => muxstream,
  ready => ready,
  valid => valid
);
end architecture RTL;
