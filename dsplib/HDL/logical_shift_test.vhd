--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:8Oct.,2016
--
-- Design Name: TES_digitiser
-- Module Name: logical_shift_test
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity logical_shift_test is
generic(
  WIDTH:natural:=48
);
port(
  clk:in std_logic;
  -- reset:in std_logic;
  s:in natural range 0 to 48;
  input:in std_logic_vector(WIDTH-1 downto 0);
  output:out std_logic_vector(WIDTH-1 downto 0)
);
end entity logical_shift_test;

architecture RTL of logical_shift_test is
signal inreg:std_logic_vector(WIDTH-1 downto 0);
signal s_reg:natural range 0 to 17;
begin

reg:process(clk) is
begin
  if rising_edge(clk) then
    inreg <= (others => '1');
    s_reg <= s;
    output <= std_logic_vector(shift_right(unsigned(inreg),s_reg));
  end if;
end process reg;

end architecture RTL;
