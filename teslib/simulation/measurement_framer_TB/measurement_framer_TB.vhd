--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:12Feb.,2017
--
-- Design Name: TES_digitiser
-- Module Name: measurement_framer_TB
-- Project Name:  teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.measurements.all;
use work.registers.all;

library streamlib;
use streamlib.types.all;


entity measurement_framer_TB is
end entity measurement_framer_TB;

architecture testbench of measurement_framer_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal measurements:measurements_t;
signal start:boolean;
signal commit:boolean;
signal dump:boolean;
signal overflow:boolean;
signal error:boolean;
signal stream:streambus_t;
signal valid:boolean;
signal ready:boolean;

begin

clk <= not clk after CLK_PERIOD/2;
UUT:entity work.measurement_framer4
generic map(
  FRAMER_ADDRESS_BITS => 8,
  ENDIAN => "LITTLE"
)
port map(
  clk => clk,
  reset => reset,
  measurements => measurements,
  start => start,
  commit => commit,
  dump => dump,
  overflow => overflow,
  error => error,
  stream => stream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
wait;
end process stimulus;

end architecture testbench;
