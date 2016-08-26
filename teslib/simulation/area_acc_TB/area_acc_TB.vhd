library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity area_acc_TB is
generic(
  WIDTH:integer:=18
);
end entity area_acc_TB;

architecture testbench of area_acc_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal sig:signed(WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
signal xing:boolean;
signal area:signed(31 downto 0);
  
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.area_acc
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  xing => xing,
  sig => sig,
  area => area
);  
  
--sim:process (clk) is
--begin
--  if rising_edge(clk) then
--    if reset = '1' then
--      sig <= to_signed(0,WIDTH);
--    else
--      sig <= sig + 1;
--    end if;
--  end if;
--end process sim;

stimulus:process is
begin
  wait for CLK_PERIOD;
  reset <= '0';
  sig <= (17 => '0', others => '1');
  wait for CLK_PERIOD*8;
  xing <= TRUE;
  wait for CLK_PERIOD;
  xing <= FALSE;
  wait for CLK_PERIOD*3;
  xing <= TRUE;
  wait for CLK_PERIOD;
  xing <= FALSE;
  wait for 16452 ns;
  xing <= TRUE;
  wait for CLK_PERIOD;
  xing <= FALSE;
  wait;
end process;

end architecture testbench;