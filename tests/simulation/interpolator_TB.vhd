--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:29 Dec 2015
--
-- Design Name: TES_digitiser
-- Module Name: interpolator_TB
-- Project Name: tests 
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

library dsplib;

entity interpolator_TB is
generic(
	WIDTH:integer:=18;
	TIME_FRAC:integer:=8
);
end entity interpolator_TB;

architecture testbench of interpolator_TB is

signal clk:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal signal_in:signed(WIDTH-1 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal clk_frac:unsigned(TIME_FRAC-1 downto 0);
signal valid:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.interpolator
generic map(
  WIDTH => WIDTH,
  TIME_FRAC => TIME_FRAC
)
port map(
  clk => clk,
  signal_in => signal_in,
  threshold => threshold,
  clk_frac => clk_frac,
  valid => valid
);

stimulus:process is
begin
signal_in <= (others => '0');
threshold <= to_signed(128,WIDTH);
wait for CLK_PERIOD*4;
signal_in <= to_signed(256,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);

wait;
end process stimulus;

end architecture testbench;
