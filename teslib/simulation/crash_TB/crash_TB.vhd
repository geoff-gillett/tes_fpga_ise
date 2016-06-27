library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crash_TB is
end entity crash_TB;

architecture testbench of crash_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';
--constant NUM_COUNTERS:integer:=16;
type countarray is array (natural range <>) of unsigned(15 downto 0);
signal counters:countarray(0 to 3);

	
constant CLK_PERIOD:time:=4 ns;

begin

clk <= not clk after CLK_PERIOD/2;
	
counter:process (clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			counters <= (others => (others => '0'));
		else
			for i in 0 to 4 loop
				counters(i) <= counters(i)+1;
			end loop;
		end if;
	end if;
end process counter;

stimulus:process
begin
  wait for CLK_PERIOD;
  reset <= '0';
  wait;
end process;

end architecture testbench;
