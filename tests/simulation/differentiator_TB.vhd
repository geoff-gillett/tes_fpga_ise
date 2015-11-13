--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:5 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: differentiator_TB
-- Project Name: dsplib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
--
library dsplib;

entity differentiator_TB is
end entity differentiator_TB;

architecture testbench of differentiator_TB is
constant CLK_PERIOD:time:=4 ns;
signal clk:std_logic:='1';	

signal sample:sample_t:=(others => '0');
signal derivitive:sample_t;
signal sample_out:sample_t;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.differentiator(robust_fabric)
	port map(
		clk        => clk,
		sample     => sample,
		derivitive => derivitive,
		sample_out => sample_out
	);

stimulus:process is
begin
--sample <= to_signed(0,SAMPLE_BITS);
--wait for CLK_PERIOD*30;
--sample <= to_signed(128,SAMPLE_BITS);
sample <= sample+1;
wait for CLK_PERIOD*1;
--wait for CLK_PERIOD*1;
--sample <= to_signed(0,SAMPLE_BITS);
--sample <= to_signed(16,SAMPLE_BITS);
--wait for CLK_PERIOD*1;
--sample <= to_signed(24,SAMPLE_BITS);
--wait for CLK_PERIOD*1;
--sample <= to_signed(32,SAMPLE_BITS);
--wait for CLK_PERIOD*1;
--sample <= to_signed(0,SAMPLE_BITS);
--wait;
end process stimulus;

end architecture testbench;
