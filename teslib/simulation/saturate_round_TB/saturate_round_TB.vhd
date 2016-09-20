library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.registers.all;

entity saturate_round_TB is
generic(
  WIDTH_IN:integer:=48; -- max 48
  FRAC_IN:integer:=28;
  WIDTH_OUT:integer:=18;
  FRAC_OUT:integer:=3
); 
end entity saturate_round_TB;


architecture testbench of saturate_round_TB is  
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;
signal input:std_logic_vector(WIDTH_IN-1 downto 0);
signal output:std_logic_vector(WIDTH_OUT-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.saturate_round2
generic map(
  WIDTH_IN => WIDTH_IN,
  FRAC_IN => FRAC_IN,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT
)
port map(
  clk => clk,
  reset => reset,
  --gain => gain,
  input => input,
  output => output
);

stimulus:process is
begin
  input <= (others => '0'); 
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*8;
  input <= (46 downto 28 => '1', others => '0'); 
  wait for CLK_PERIOD;
  input <= (others => '0'); 
  wait for CLK_PERIOD;
  input <= (47 downto 29 => '1', 20 => '1',others => '0'); 
  wait for CLK_PERIOD;
  input <= (47 => '1', others => '0'); 
  wait for CLK_PERIOD;
  input <= (47 downto 30 => '1', 19 => '1',others => '0'); 
  wait for CLK_PERIOD;
  wait;
end process stimulus;


end architecture testbench;