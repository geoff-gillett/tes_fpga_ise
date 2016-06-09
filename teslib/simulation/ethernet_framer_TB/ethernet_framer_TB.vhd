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

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal mtu:unsigned(MTU_BITS-1 downto 0);
signal tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal eventstream:streambus_t;
signal eventstream_valid:boolean;
signal eventstream_ready:boolean;
signal mcastream:streambus_t;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

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
  clk => clk,
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

stimulus:process is
begin
eventstream.last <= (0 => TRUE, others => FALSE);
eventstream.discard <= (others => FALSE);
eventstream.data <= (others => '0');
mcastream.data <= (others => '0');
mcastream.last <= (others => FALSE);
mcastream.discard <= (others => FALSE);
mtu <= to_unsigned(88,MTU_BITS);
tick_latency <= to_unsigned(800,TICK_LATENCY_BITS);
wait for CLK_PERIOD;
ethernetstream_ready <= TRUE;
reset <= '0';
wait for CLK_PERIOD;
wait;
end process stimulus;

end architecture testbench;
