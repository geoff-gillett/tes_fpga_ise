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
  EVENTSTREAM_CHUNKS:integer:=4;
  ENDIANNESS:string:="LITTLE";
  --
  TICK_PERIOD_BITS:integer:=32;
  MINIMUM_TICK_PERIOD:integer:=2**14;
  TIMESTAMP_BITS:integer:=64
);
port (
  clk : in std_logic;
  reset : in std_logic
);
end entity test_eventstream;

architecture RTL of test_eventstream is
constant ADDRESS_BITS:integer:=9; --framer address width

signal event_counter:unsigned(25 downto 0);
signal framer_free:unsigned(ADDRESS_BITS downto 0);
signal framer_full:boolean;
signal tickstream:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal tickstream_valid:boolean;
signal tickstream_last:boolean;
signal tickstream_ready:boolean;

signal event1:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal event2:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);

signal tick_addr,event_addr:unsigned(0 downto 0);

type fsm_state is (IDLE, TICK, EVENT);
signal state,nextstate:fsm_state;
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal data:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_DATABITS-1 downto 0);

begin
	
ticker:entity main.tick_unit
generic map(
  CHANNEL_BITS        => CHANNEL_BITS,
  STREAM_CHUNKS       => EVENTSTREAM_CHUNKS,
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
  tick_period => to_unsigned(25000000,TICK_PERIOD_BITS),
  events_lost => open,
  dirty       => open,
  tickstream  => tickstream,
  valid       => tickstream_valid,
  last        => tickstream_last,
  ready       => tickstream_ready
);


framer:entity streamlib.framer
generic map(
  BUS_CHUNKS   => EVENTSTREAM_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk      => clk,
  reset    => reset,
  data     => data,
  address  => address,
  lasts    => lasts,
  keeps    => keeps,
  chunk_we => chunk_we,
  wr_valid => wr_valid,
  length   => length,
  commit   => commit,
  free     => framer_free,
  stream   => stream,
  valid    => valid,
  ready    => ready
);

event1 <= "001100010" & std_logic_vector(event_counter(13 downto 0)) & 
						 SetEndianness(event_counter(13 downto 0) & 
						 							 event_counter(25 downto 0), ENDIANNESS
						 );
event2 <= SetEndianness(event_counter(13 downto 0), ENDIANNESS) & 
						SetEndianness(event_counter(13 downto 0), ENDIANNESS) &
						"00000000000000000000000000000000";

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

fsmTransition:process(state,tickstream_valid)
begin
	nextstate <= state;
	case state is 
		when IDLE =>
			if tickstream_valid then 
				nextstate <= TICK;
			else 
				nextstate <= EVENT;
			end if;
		when TICK =>
			data <= when tick address = "0"
			if not framer_full
				
			null;
		when EVENT =>
			
			null;
	end case;
end process fsmTransition;						 
-- this process fills the framer with events and ticks
framer_full <= framer_free /= 0;
eventGen:process(clk, reset)
begin
if reset='1' then
	tick_addr <= (others => '0');
	event_addr <= (others => '0');
	event_counter <= (others => '0');
else
  if rising_edge(clk) then
    if not framer_full then
      if not tickstream_valid then
        
      end if;
    end if;
  end if;
end if;
end process eventGen;


end architecture RTL;
