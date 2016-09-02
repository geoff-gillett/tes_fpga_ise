library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity closest_xing_TB is
generic(WIDTH:integer:=18);
end entity closest_xing_TB;

architecture RTL of closest_xing_TB is
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal signal_in:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH-1 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal pos:boolean;
signal neg:boolean;

constant CLK_PERIOD:time:=4 ns;

begin
  
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.closest_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  threshold => threshold,
  signal_out => signal_out,
  pos => pos,
  neg => neg
);

stimulus:process is
begin
threshold <= to_signed(0,WIDTH);
signal_in <= to_signed(10,WIDTH);
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*8;
signal_in <= to_signed(-9,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-9,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(8,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(7,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-6,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(7,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-8,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(9,WIDTH);

wait;
  
end process stimulus;


end architecture RTL;
