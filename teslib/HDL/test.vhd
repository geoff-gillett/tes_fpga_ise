library ieee;
use ieee.numeric_std.all;

entity get_value_TB is
end entity get_value_TB;

architecture testbench of get_value_TB is
signal u:unsigned(15 downto 0);

type rec is record
	u:unsigned(15 downto 0);
end record;
signal r:rec;
begin 

stimulau:process is
begin
wait for 4 ns;
u <= "1010101010101010";
r.u <= "1010101010101010";
wait;
end process;
end architecture testbench;
