library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.types.all;
use streamlib.functions.all;
--
--FIXME: BUS_CHUNKS etc redundant due to eventbus_array
entity eventstream_mux is
generic(
  CHANNEL_BITS:integer:=3;
  RELTIME_BITS:integer:=16;
  TIMESTAMP_BITS:integer:=64;
  TICK_BITS:integer:=32;
  MIN_TICKPERIOD:integer:=2**16;
  ENDIANNESS:string:="LITTLE"
);
port(
  clk:in std_logic;
  reset:in std_logic;
  start:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  commit:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  dump:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  pulsestreams:in eventbus_array(2**CHANNEL_BITS-1 downto 0);
  pulsestream_lasts:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  pulsestream_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  ready_for_pulsestreams:out boolean_vector(2**CHANNEL_BITS-1 downto 0);
  full:out boolean;
  -- tick event
  tick_period:in unsigned(TICK_BITS-1 downto 0);
  events_lost:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  dirty:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  eventstream:out eventbus_t;
  valid:out boolean;
  last:out boolean;
  ready:in boolean
);
end entity eventstream_mux;
--
architecture RTL of eventstream_mux is
	
constant CHANNELS:integer:=2**CHANNEL_BITS;
signal timestamp,eventtime:unsigned(TIMESTAMP_BITS-1 downto 0);
signal reltime:unsigned(RELTIME_BITS-1 downto 0);
signal started,commited,dumped:std_logic_vector(CHANNELS-1 downto 0);
signal handled,req,gnt,grant:std_logic_vector(CHANNELS-1 downto 0);
signal index:integer range 0 to CHANNELS-1;
signal ticked,tick,time_valid,read_next,pulses_handled:boolean;
type muxstate is (IDLE,HANDLEPULSE,HANDLETICK);
signal mux_state,mux_nextstate:muxstate;
type streamstate is (HEAD,TAIL);
signal stream_state,stream_nextstate:streamstate;
signal muxstream,tickstream:eventbus_t;
signal muxstream_valid,ready_for_muxstream,muxstream_last:boolean;
signal granted,muxstream_handshake:boolean;
signal tickstream_valid:boolean;
signal tickstream_last:boolean;
signal ready_for_tickstream:boolean;
signal tickstream_handshake:boolean;
signal tickstream_done:boolean;
signal muxstream_done:boolean;
signal ready_for_pulsestream:boolean;
-- 
signal store:eventbus_t;
signal valid_int,store_valid,last_int,store_last,ready_int:boolean;
signal sel:boolean_vector(3 downto 0);
--
begin
tickUnit:entity work.tick_unit
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  TICK_BITS => TICK_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  MINIMUM_TICK_PERIOD => MIN_TICKPERIOD,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset,
  tick => tick,
  timestamp => timestamp,
  tick_period => tick_period,
  events_lost => events_lost,
  dirty => dirty,
  tickstream => tickstream,
  valid => tickstream_valid,
  last => tickstream_last,
  ready => ready_for_tickstream
);
--
buffers:entity work.event_buffers
generic map(
  CHANNEL_BITS   => CHANNEL_BITS,
  RELTIME_BITS   => RELTIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk       => clk,
  reset     => reset,
  start     => start,
  commit    => commit,
  dump      => dump,
  tick      => tick,
  timestamp => timestamp,
  eventtime => eventtime,
  reltime   => reltime,
  started   => started,
  ticked    => ticked,
  commited  => commited,
  dumped    => dumped,
  valid     => time_valid,
  read_next => read_next,
  full      => full
);
--
-- clk1 req
-- clk2 gnt onehot index 
-- clk3 mux
-- 
pulses_handled <= started = (started and (handled or dumped)) and time_valid;
arbiter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	req <= (others => '0');
  	gnt <= (others => '0');
  	grant <= (others => '0');
  else
  	if time_valid then
  		req <= started and commited and not handled;
      gnt <= req and std_logic_vector(unsigned(not req)+1);
      if mux_state=IDLE then 
        handled <= handled or gnt;
        grant <= gnt;
        if unsigned(gnt) = 0 then
        	index <= 0;
        	granted <= FALSE;
        else
          index <= onehotToInteger(gnt);
        	granted <= TRUE;
        end if;
      end if;
  	else
  		grant <= (others => '0');
  		granted <= FALSE;
  		req <= (others => '0');
  		handled <= (others => '0');
  	end if;
	end if;
end if;
end process arbiter;
--
fsmNextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	mux_state <= IDLE;
  	stream_state <= HEAD;
  else
    mux_state <= mux_nextstate;
    stream_state <=  stream_nextstate;
  end if;
end if;
end process fsmNextstate;
--
muxstream_handshake <= muxstream_valid and ready_for_muxstream;
tickstream_handshake <= tickstream_valid and ready_for_muxstream;
muxTransition:process(granted,tickstream_handshake,pulses_handled,ticked,
										 mux_state,stream_state,tickstream_last,
										 grant,index,pulsestream_lasts,pulsestream_valids,
										 pulsestreams,tickstream,tickstream_valid, 
										 ready_for_muxstream,muxstream_handshake,muxstream_last, 
										 time_valid,reltime)
begin
mux_nextstate <= mux_state;
stream_nextstate <= stream_state;
case mux_state is 
when IDLE =>
	muxstream <= (others => '-');
	muxstream_valid <= FALSE;
	muxstream_last <= FALSE;
	ready_for_pulsestream <= FALSE;
	ready_for_tickstream <= FALSE;
	ready_for_pulsestreams <= (others => FALSE);
	read_next <= FALSE;
  if pulses_handled then
  	if ticked then
  		mux_nextstate <= HANDLETICK; 
  	else
  		mux_nextstate <= IDLE;
			read_next <= TRUE;
  	end if;
  elsif granted and time_valid then
  	mux_nextstate <= HANDLEPULSE;
  end if;
when HANDLETICK =>
	if stream_state = HEAD then 
		muxstream <= tickstream(71 downto 52) & 
								 SetEndianness(reltime,ENDIANNESS) &
								 tickstream(35 downto 0);
	else
		muxstream <= tickstream;
		end if;
	muxstream_valid <= tickstream_valid;
	muxstream_last <= tickstream_last;
	ready_for_pulsestream <= FALSE;
	ready_for_tickstream <= ready_for_muxstream;
	ready_for_pulsestreams <= (others => FALSE);
	read_next <= FALSE;
	if tickstream_handshake then
		if tickstream_last then
			stream_nextstate <= HEAD;
			mux_nextstate <= IDLE;
			read_next <= TRUE;
		else
			stream_nextstate <= TAIL;
		end if;
	end if; 
when HANDLEPULSE =>
	if stream_state=HEAD then
		muxstream <= pulsestreams(index)(71 downto 52) & 
								 SetEndianness(reltime,ENDIANNESS) &
								 pulsestreams(index)(35 downto 0);
	else
		muxstream <= pulsestreams(index);
	end if;
	muxstream_valid <= pulsestream_valids(index);
	muxstream_last <= pulsestream_lasts(index);
	if ready_for_muxstream then
		ready_for_pulsestreams <= to_boolean(grant);
	else
		ready_for_pulsestreams <= (others => FALSE);
	end if;
	ready_for_tickstream <= FALSE;
	read_next <= FALSE;
	if muxstream_handshake then
		if muxstream_last then
			stream_nextstate <= HEAD;
			mux_nextstate <= IDLE;
		else
			stream_nextstate <= TAIL;
		end if;
	end if; 
end case;
end process muxTransition;
-- This may make it difficult to achieve timing closure
-- this needs to be clocked
-- Problem when MUX switches? need to stop after last
-- remember to 
--mux:process(clk)
--begin
--if rising_edge(clk) then
--  if reset = '1' then
--    muxstream <= (others => '-');
--    muxstream_valid <= FALSE;
--    muxstream_last <= FALSE;
--  else 
--  	ready_for_tickstream <= FALSE;
-- 		ready_for_pulsestreams <= (others => FALSE);
--    muxstream <= (others => '-');
--    muxstream_valid <= FALSE;
--    muxstream_last <= FALSE;
-- 		if not muxstream_valid or (muxstream_valid and ready_for_muxstream) then
-- 			if pulses_handled and ticked and tickstream_valid 
-- 			   and ready_for_tickstream then
--        muxstream <= tickstream;
--        muxstream_valid <= tickstream_valid;
--        muxstream_last <= tickstream_last;
--        if tickstream_valid and not muxstream_last then
--          ready_for_tickstream <= TRUE;
--        end if;
--      elsif granted then
--        muxstream <= pulsestreams(index);
--        muxstream_valid <= pulsestream_valids(index);
--        muxstream_last <= pulsestream_lasts(index);
--        if pulsestream_valids(index) and not muxstream_last then
--        	ready_for_pulsestreams(index) <= TRUE;
--        end if;
--      end if;
--    end if;
--  end if;
--end if;  	
--end process mux;
--
outStreamReg:entity streamlib.register_slice
generic map(
  STREAM_BITS => EVENTBUS_BITS
)
port map(
  clk       => clk,
  reset     => reset,
  stream_in => muxstream,
  ready_out => ready_for_muxstream,
  valid_in  => muxstream_valid,
  last_in   => muxstream_last,
  stream    => eventstream,
  ready     => ready,
  valid     => valid,
  last      => last
);
end architecture RTL;
