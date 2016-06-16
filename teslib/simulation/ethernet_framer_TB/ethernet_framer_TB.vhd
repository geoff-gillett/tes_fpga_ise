--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:4 Jun 2016
--
-- Design Name: TES_digitiser
-- Module Name: ethernet_framer_TB
-- Project Name: teslib	
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

use work.types.all;

entity ethernet_framer_TB is
generic(
	MTU_BITS:integer:=16;
	TICK_LATENCY_BITS:integer:=16;
	FRAMER_ADDRESS_BITS:integer:=4;
	DEFAULT_MTU:unsigned:=to_unsigned(80,16);
	DEFAULT_TICK_LATENCY:unsigned:=to_unsigned(128,16);
	ENDIANNESS:string:="LITTLE"
);
end entity ethernet_framer_TB;

architecture testbench of ethernet_framer_TB is

signal signal_clk:std_logic:='1';	
signal io_clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant SIGNAL_PERIOD:time:=4 ns;
constant IO_PERIOD:time:=8 ns;

signal mtu:unsigned(MTU_BITS-1 downto 0);
signal tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal eventstream:streambus_t;
signal eventstream_valid:boolean;
signal eventstream_ready:boolean;
signal eventdata:std_logic_vector(63 downto 0);
signal eventlast:boolean;
signal mcastream:streambus_t;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal mcadata:std_logic_vector(63 downto 0);
signal mcalast:boolean;
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:boolean;
signal bytestream_last:boolean;

begin
signal_clk <= not signal_clk after SIGNAL_PERIOD/2;
io_clk <= not io_clk after IO_PERIOD/2;

eventstream.data <= eventdata;
eventstream.discard <= (others => FALSE);
eventstream.last <= (0 => eventlast, others => FALSE);

mcastream.data <= mcadata;
mcastream.discard <= (others => FALSE);
mcastream.last <= (0 => mcalast, others => FALSE);

UUT:entity work.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  TICK_LATENCY_BITS => TICK_LATENCY_BITS,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => signal_clk,
  reset => reset,
  mtu => mtu,
  tick_latency => tick_latency,
  eventstream => eventstream,
  eventstream_valid => eventstream_valid,
  eventstream_ready => eventstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

enetCdc:entity work.CDC_bytestream_adapter
port map(
  s_clk => signal_clk,
  s_reset => reset,
  streambus => ethernetstream,
  streambus_valid => ethernetstream_valid,
  streambus_ready => ethernetstream_ready,
  b_clk => io_clk,
  b_reset => reset,
  bytestream => bytestream,
  bytestream_valid => bytestream_valid,
  bytestream_ready => bytestream_ready,
  bytestream_last => bytestream_last
);

end architecture testbench;
