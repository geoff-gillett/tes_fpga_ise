--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:4 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: closest_xing_TB
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;

library dsplib;

entity closest_xing_TB is
generic(
	WIDTH:integer:=18
);
end entity closest_xing_TB;

architecture testbench of closest_xing_TB is

signal clk:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal signal_in:signed(WIDTH-1 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH-1 downto 0);
signal pos:boolean;
signal neg:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.closest_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  signal_in => signal_in,
  threshold => threshold,
  signal_out => signal_out,
  pos => pos,
  neg => neg
);

stimulus:process is
begin
signal_in <= (others => '0');
threshold <= to_signed(32,WIDTH);
wait for CLK_PERIOD*4;
signal_in <= to_signed(32,WIDTH);
wait for CLK_PERIOD*2;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(33,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(30,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(131,WIDTH);
wait for CLK_PERIOD*3;
signal_in <= to_signed(-90,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(50,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(10,WIDTH);
wait;
end process stimulus;

end architecture testbench;
