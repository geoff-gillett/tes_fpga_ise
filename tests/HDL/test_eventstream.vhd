--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Creation Date:20/10/2015 
--
-- Repository Name: tes_fpga_ise
-- Module Name: test_eventstream
-- Project Name: tests
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--
-- For testing the frame generation on the FPGA side and capture speed on the 
-- PC side.
-- Generates ticks with 100ms period and events as fast as possible.
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
use streamlib.types.all;
use streamlib.functions.all;
--
library main;
--
entity test_eventstream is
generic(
  CHANNEL_BITS:integer:=3;
  --
  BUS_CHUNKS:integer:=4;
  ENDIANNESS:string:="LITTLE";
  --
  TICK_PERIOD_BITS:integer:=32;
  MINIMUM_TICK_PERIOD:integer:=2**14;
  TIMESTAMP_BITS:integer:=64
);
port (
  clk:in std_logic;
  reset:in std_logic;
	eventstream:out std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
	eventstream_valid:out boolean;
	eventstream_ready:in boolean;
	eventstream_last:out boolean
);
end entity test_eventstream;

architecture RTL of test_eventstream is
constant ADDRESS_BITS:integer:=9; --framer address width
constant TICK_PERIOD:integer:=25000000;

signal tickstream:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal tickstream_valid:boolean;
signal tickstream_last:boolean;
signal tickstream_ready:boolean;

signal pulsestream:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal pulsestream_valid:boolean;
signal pulsestream_ready:boolean;
signal pulsestream_last:boolean;
signal stream_in:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal ready_out:boolean;
signal valid_in:boolean;
signal last_in:boolean;

type fsm_state is (IDLE, TICK, EVENT);
signal state,nextstate:fsm_state;
begin
	
ticker:entity main.tick_unit
generic map(
  CHANNEL_BITS        => CHANNEL_BITS,
  STREAM_CHUNKS       => BUS_CHUNKS,
  SIZE_BITS           => SIZE_BITS,
  TICK_BITS           => TICK_PERIOD_BITS,
  MINIMUM_TICK_PERIOD => MINIMUM_TICK_PERIOD,
  TIMESTAMP_BITS      => TIMESTAMP_BITS,
  ENDIANNESS          => ENDIANNESS
)
port map(
  clk         => clk,
  reset       => reset,
  tick        => open,
  timestamp   => open,
  tick_period => to_unsigned(TICK_PERIOD,TICK_PERIOD_BITS),
  events_lost => (others => FALSE),
  dirty       => (others => FALSE),
  tickstream  => tickstream,
  valid       => tickstream_valid,
  last        => tickstream_last,
  ready       => tickstream_ready
);

pulses:entity work.test_pulsestream
generic map(
  BUS_CHUNKS   => BUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS,
  ENDIANNESS   => ENDIANNESS
)
port map(
  clk               => clk,
  reset             => reset,
  pulsestream       => pulsestream,
  pulsestream_valid => pulsestream_valid,
  pulsestream_ready => pulsestream_ready
);

streamReg:entity streamlib.register_slice
	generic map(
		STREAM_BITS => BUS_CHUNKS*CHUNK_BITS
	)
	port map(
		clk       => clk,
		reset     => reset,
		stream_in => stream_in,
		ready_out => ready_out,
		valid_in  => valid_in,
		last_in   => last_in,
		stream    => eventstream,
		ready     => eventstream_ready,
		valid     => eventstream_valid,
		last      => eventstream_last
	);

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

-- mux pulsestream and tickstream
pulsestream_last <= busLast(pulsestream,BUS_CHUNKS);
fsmTransition:process(state,tickstream_valid,ready_out,tickstream_last)
begin
nextstate <= state;
case state is 
when IDLE =>
	stream_in <= (others => '-');
  valid_in <= FALSE;
  last_in <= FALSE;
	tickstream_ready <= FALSE;
	pulsestream_ready <= FALSE;
  if tickstream_valid then 
  	nextstate <= TICK;
  else 
  	nextstate <= EVENT;
  end if;
when TICK =>
	stream_in <= tickstream;
  valid_in <= tickstream_valid;
  last_in <= tickstream_last;
	tickstream_ready <= ready_out;
	pulsestream_ready <= FALSE;
  if not tickstream_last and tickstream_valid and tickstream_ready then 
  	nextstate <= IDLE;
  end if;
when EVENT =>
	stream_in <= pulsestream;
  valid_in <= pulsestream_valid;
  last_in <= pulsestream_last;
	tickstream_ready <= FALSE;
	pulsestream_ready <= ready_out;
  if not pulsestream_last and pulsestream_valid and pulsestream_ready then 
  	nextstate <= IDLE;
  end if;
end case;
end process fsmTransition;						 


end architecture RTL;
