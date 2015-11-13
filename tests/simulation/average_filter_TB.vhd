library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
--
library dsplib;

entity average_filter_TB is
generic(
	STAGES:integer:=8
);
end entity average_filter_TB;

architecture testbench of average_filter_TB is
constant CLK_PERIOD:time:=4 ns;

signal clk:std_logic:='1';
signal sample:sample_t;
signal n:integer range 0 to STAGES;
signal average:sample_t;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.averaging_filter
generic map(
  STAGES => STAGES
)
port map(
  clk     => clk,
  sample  => sample,
  n       => n,
  average => average
);

stimulus:process is
begin
n <= STAGES;
sample <= (others => '0');
wait for CLK_PERIOD*32;
sample <= to_signed(1024,SAMPLE_BITS);
wait for CLK_PERIOD*1;
sample <= to_signed(0,SAMPLE_BITS);
wait;
end process stimulus;

end architecture testbench;
