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
generic(WIDTH:integer:=18);
end entity constant_fraction_TB;

architecture testbench of constant_fraction_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal min:signed(WIDTH-1 downto 0);
signal cf:signed(WIDTH-1 downto 0);
signal sig:signed(WIDTH-1 downto 0);
signal p:signed(WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.constant_fraction
generic map(
  WIDTH => WIDTH
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
cf <= (WIDTH-1 downto WIDTH-2 => '0', others => '1');
min <= (others => '0');
wait for CLK_PERIOD*10;
sig <= to_signed(512, WIDTH);
min <= to_signed(12, WIDTH);

wait;
end process stimulus;

end architecture testbench;
