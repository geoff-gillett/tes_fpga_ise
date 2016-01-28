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
signal req,gnt:std_logic_vector(CHANNELS-1 downto 0);
signal handled:std_logic_vector(CHANNELS downto 0);
signal sel:std_logic_vector(CHANNELS downto 0);

signal ticked,tick,time_valid,read_next:boolean;
--type muxstate is (IDLE,HANDLEPULSE,HANDLETICK);
--signal mux_state,mux_nextstate:muxstate;
type FSMstate is (IDLE,HEAD,TAIL,NEXT_TIME);
signal state,nextstate:FSMstate;
signal tickstream:eventbus_t;
signal stream_valid,ready_for_stream,stream_last:boolean;
signal tickstream_valid:boolean;
signal tickstream_last:boolean;
signal ready_for_tickstream:boolean;

--
signal streams:eventbus_array(CHANNELS downto 0);
signal stream,stream_int:eventbus_t;
signal valids,lasts,readys:boolean_vector(CHANNELS downto 0);
signal done:boolean;
signal handshake:boolean;
signal pulses_done:boolean;
signal stream_valid_int:boolean;
signal last_handshake:boolean;

--
begin

tickUnit:entity work.tick_unit(aligned)
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

selector:entity work.eventstream_select
generic map(
  CHANNELS => CHANNELS+1
)
port map(
  sel     => sel,
  streams => streams,
  lasts   => lasts,
  valids  => valids,
  stream  => stream,
  valid   => stream_valid,
  last    => stream_last
);
--
-- clk1 req
-- clk2 gnt onehot index 
-- clk3 mux
-- 
--pulses_handled <= started = (started and (handled or dumped)) and time_valid;

readys <= (others => FALSE) when state=IDLE or not ready_for_stream 
													  else to_boolean(sel);
	
inputRegGen:for i in CHANNELS downto 1 generate
begin
	inputReg:entity streamlib.register_slice
		generic map(
			STREAM_BITS => CHUNK_BITS*BUS_CHUNKS
		)
		port map(
			clk       => clk,
			reset     => reset,
			stream_in => pulsestreams(i-1),
			ready_out => ready_for_pulsestreams(i-1),
			valid_in  => pulsestream_valids(i-1),
			last_in   => pulsestream_lasts(i-1),
			stream    => streams(i),
			ready     => readys(i),
			valid     => valids(i),
			last      => lasts(i)
		);
end generate;

tickInputReg:entity streamlib.register_slice
generic map(
  STREAM_BITS => CHUNK_BITS*BUS_CHUNKS
)
port map(
  clk       => clk,
  reset     => reset,
  stream_in => tickstream,
  ready_out => ready_for_tickstream,
  valid_in  => tickstream_valid,
  last_in   => tickstream_last,
  stream    => streams(0),
  ready     => readys(0),
  valid     => valids(0),
  last      => lasts(0)
);

pulses_done <= started = handled(CHANNELS downto 1);-- and time_valid; 
done <= pulses_done and to_std_logic(ticked) = handled(0);
read_next <= state=NEXT_TIME;
arbiter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' or state=NEXT_TIME then
  	req <= (others => '0');
  	gnt <= (others => '0');
  	sel <= (others => '0');
  	handled <= (others => '0');
  else
  	if time_valid then
  		req <= started and commited and not handled(CHANNELS downto 1);
      gnt <= req and std_logic_vector(unsigned(not req)+1);
--      if state=IDLE then 
      if last_handshake or state=IDLE then 
      	if pulses_done then 
	      	handled(0) <= to_std_logic(ticked);
      		sel <= (0 => to_std_logic(ticked), others => '0');
      	else
	      	handled <= handled or gnt & '0' or dumped & '0';
      		sel <= gnt & '0';
      	end if;
      end if;
  	else
  		sel <= (others => '0');
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
  	state <= IDLE;
  else
    state <= nextstate;
  end if;
end if;
end process fsmNextstate;
--
handshake <= stream_valid and ready_for_stream;
last_handshake <= handshake and stream_last;
fsmTransition:process(state,sel,handshake,done,last_handshake)
begin
nextstate <= state;  		
case state is 
when IDLE =>
	if unaryOr(sel) then
		nextstate <= HEAD;
	elsif done then
		nextstate <= NEXT_TIME;
	end if;
when HEAD =>
	if handshake then
		nextstate <= TAIL;
	end if;
when TAIL =>
	if last_handshake then
		if done then
			nextstate <= NEXT_TIME;
		else
			nextstate <= IDLE;
		end if;
	end if;
when NEXT_TIME =>
	nextstate <= IDLE;
end case;
end process fsmTransition;
--

stream_int <= stream(71 downto 52) & SetEndianness(reltime,ENDIANNESS) &
							stream(35 downto 0) when state=HEAD
							else stream;
stream_valid_int <= stream_valid and state/=IDLE;
--
outStreamReg:entity streamlib.register_slice
generic map(
  STREAM_BITS => EVENTBUS_BITS
)
port map(
  clk       => clk,
  reset     => reset,
  stream_in => stream_int,
  ready_out => ready_for_stream,
  valid_in  => stream_valid_int,
  last_in   => stream_last,
  stream    => eventstream,
  ready     => ready,
  valid     => valid,
  last      => last
);
end architecture RTL;
