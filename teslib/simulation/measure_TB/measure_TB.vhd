library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity measure_TB is
generic(
  WIDTH:integer:=18
);
end entity measure_TB;

architecture testbench of measure_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal sig:signed(WIDTH-1 downto 0);
signal sim:signed(7 downto 0);
signal cf:unsigned(16 downto 0);

signal slope:signed(WIDTH-1 downto 0);
signal raw_out:signed(WIDTH-1 downto 0);
signal filtered_out:signed(WIDTH-1 downto 0);
signal slope_out:signed(WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
  
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.measure
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  constant_fraction => cf,
  raw => sig,
  slope => slope,
  filtered => sig,
  raw_out => raw_out,
  filtered_out => filtered_out,
  slope_out => slope_out
);  

simulate:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim <= to_signed(-16,8);
    else
      sim <= sim + 1;
    end if;
  end if;
end process simulate;

sig <= resize(sim,WIDTH);

stimulus:process is
begin
  slope <= to_signed(-8,WIDTH);
  wait for CLK_PERIOD;
  reset <= '0';
  cf  <= (16 => '1', others => '0');
  wait for CLK_PERIOD*6;
  slope <= to_signed(9,WIDTH);
  wait for CLK_PERIOD*16;
  slope <= to_signed(-9,WIDTH);
  wait;
end process;

end architecture testbench;