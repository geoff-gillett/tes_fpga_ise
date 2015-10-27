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
signal ticked,tick,time_valid,read_next,pulses_done:boolean;
type FSMstate is (IDLE,HEAD,TAIL,TICKHEAD,TICKTAIL);
signal state,nextstate:FSMstate;
signal muxstream,tickstream:eventbus_t;
signal muxstream_valid,ready_for_muxstream,muxstream_last:boolean;
signal granted,muxstream_handshake:boolean;
signal tickstream_valid:boolean;
signal tickstream_last:boolean;
signal ready_for_tickstream:boolean;
signal tickstream_handshake:boolean;
signal tickstream_done:boolean;
signal muxstream_done:boolean;
begin

tickUnit:entity work.tick_unit
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  TICK_BITS => TICK_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  MINIMUM_TICK_PERIOD => 2**RELTIME_BITS,
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
tickstream_handshake <= tickstream_valid and ready_for_tickstream;
tickstream_done <= tickstream_handshake and tickstream_last;

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
pulses_done <= started=(handled or dumped);
arbiter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	req <= (others => '0');
  	gnt <= (others => '0');
  else
  	if time_valid then
  		req <= started and commited and not handled;
      gnt <= req and std_logic_vector(unsigned(not req)+1);
      if state=IDLE then 
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
    state <= IDLE;
  else
    state <= nextstate;
  end if;
end if;
end process fsmNextstate;

muxstream_handshake <= ready_for_muxstream and muxstream_valid;
muxstream_done <= muxstream_handshake and muxstream_last;
fsmTrasition:process(state, granted,muxstream_handshake,muxstream_done,
										 tickstream_done,tickstream_handshake,pulses_done,ticked)
begin
nextstate <= state;
read_next <= FALSE;
case state is 
when IDLE =>
	if granted then
		nextstate <= HEAD;
	end if;
when HEAD =>
	if muxstream_handshake then
		nextstate <= TAIL;
	end if;
when TAIL =>
	if muxstream_done then
		if pulses_done and ticked then
			nextstate <= TICKHEAD;
		else
			if pulses_done then
				read_next <= TRUE;
			end if;
			nextstate <= IDLE;
		end if;
	end if;
when TICKHEAD =>
	if tickstream_handshake then
		nextstate <= TICKTAIL;
	end if;
when TICKTAIL =>
	if tickstream_done then
		read_next <= TRUE;
		nextstate <= IDLE;
	end if;
end case;
end process fsmTrasition;
-- This may make it difficult to achieve timing closure
mux:process(pulsestreams,index,pulsestream_valids,granted,pulsestream_lasts,
						reltime,state,grant,ready_for_muxstream) 
begin
if granted then
  if state=HEAD then
    --insert reltime
    muxstream(71 downto 52) <= pulsestreams(index)(71 downto 52);
    muxstream(51 downto 36) <= SetEndianness(reltime, ENDIANNESS);
    muxstream(35 downto 0) <= pulsestreams(index)(35 downto 0);
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
else
  muxstream <= (others => '-');
  muxstream_valid <= FALSE;
  muxstream_last <= FALSE;
  ready_for_pulsestreams <= (others => FALSE);
end if;
end process mux;
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
