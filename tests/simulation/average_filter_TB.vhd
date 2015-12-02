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
	MAX_ORDER:integer:=8;
	IN_BITS:integer:=16;
	OUT_BITS:integer:=16
);
end entity average_filter_TB;

architecture testbench of average_filter_TB is
constant CLK_PERIOD:time:=4 ns;

signal clk:std_logic:='1';
signal sample:signed(IN_BITS-1 downto 0);
signal order:integer range 0 to MAX_ORDER;
signal average:signed(OUT_BITS-1 downto 0);
signal integer_av:signed(IN_BITS-1 downto 0);
signal enable:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.average_filter
generic map(
  MAX_ORDER => MAX_ORDER,
  IN_BITS => IN_BITS,
  OUT_BITS => OUT_BITS
)
port map(
  clk => clk,
  enable => enable,
  sample => sample,
  order => order,
  average => average
);

integer_av <= resize(shift_right(average, OUT_BITS-IN_BITS),IN_BITS);
stimulus:process is
begin
order <= 3;
sample <= (others => '0');
enable <= TRUE;
wait for CLK_PERIOD*32;
sample <= to_signed(32,IN_BITS);
wait for CLK_PERIOD*1;
sample <= to_signed(0,IN_BITS);
wait;
end process stimulus;

end architecture testbench;
