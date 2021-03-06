--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:21Nov.,2016
--
-- Design Name: TES_digitiser
-- Module Name: constant_fraction_TB
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--

entity constant_fraction_TB is
generic(
  WIDTH:integer:=16;
  CF_WIDTH:integer:=18;
  CF_FRAC:integer:=17
);
end entity constant_fraction_TB;

architecture testbench of constant_fraction_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal min:signed(WIDTH-1 downto 0);
signal cf:signed(CF_WIDTH-1 downto 0);
signal sig:signed(WIDTH-1 downto 0);
signal p:signed(WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.constant_fraction8
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC
  
)
port map(
  clk => clk,
  reset => reset,
  min => min,
  cf => cf,
  sig => sig,
  p => p
);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
sig <= to_signed(256, WIDTH);
cf <= (CF_WIDTH-3 => '1', others => '0');
min <= (others => '0');
wait for CLK_PERIOD*10;
sig <= to_signed(64, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(-512, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(-513, WIDTH);
min <= (others => '0');
--min <= to_signed(12, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(-514, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(-515, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(-516, WIDTH);
wait for CLK_PERIOD;
min <= to_signed(-4, WIDTH);
wait for CLK_PERIOD;
min <= to_signed(0, WIDTH);
sig <= to_signed(512, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(513, WIDTH);
min <= (others => '0');
--min <= to_signed(12, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(514, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(515, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(516, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(517, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(518, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(519, WIDTH);
wait for CLK_PERIOD;
sig <= to_signed(520, WIDTH);

wait;
end process stimulus;

end architecture testbench;
