library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity constant_fraction_TB is
generic(
  WIDTH:integer:=18
);
end entity constant_fraction_TB;

architecture testbench of constant_fraction_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal min:boolean:=FALSE;
signal sig:signed(WIDTH-1 downto 0);
signal sig_out:signed(WIDTH-1 downto 0);
signal cf:signed(WIDTH-1 downto 0);
signal cf_low,cf_high:signed(WIDTH-1 downto 0):=(others => '0');
signal min_out:boolean;

constant CLK_PERIOD:time:=4 ns;
  
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
  sig => sig,
  cf => cf,
  min_out => min_out,
  sig_out => sig_out,
  cf_low => cf_low,
  cf_high => cf_high
);

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sig <= (others => '0');
    else
      sig <= sig + 1;
    end if;
  end if;
end process sim;

stimulus:process is
begin
  wait for CLK_PERIOD;
  reset <= '0';
  cf  <= (16 => '1',others => '0');
  min <= TRUE;
  wait for CLK_PERIOD;
  min <= FALSE;
  wait for CLK_PERIOD*9;
  cf  <= (15 => '1',others => '0');
  min <= TRUE;
  wait for CLK_PERIOD;
  min <= FALSE;
  wait;
end process;

end architecture testbench;
