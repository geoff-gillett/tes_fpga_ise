library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cfd_dsp48e_TB is
generic(
  WIDTH:integer:=18
);
end entity cfd_dsp48e_TB;

architecture testbench of cfd_dsp48e_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal min:signed(WIDTH-1 downto 0):=(others => '0');
signal sig:signed(WIDTH-1 downto 0);
signal sig_out:signed(WIDTH-1 downto 0);
signal cf:signed(WIDTH-1 downto 0);
signal cf_low,cf_high:signed(WIDTH-1 downto 0):=(others => '0');
signal min_out:boolean;
signal cfd:signed(WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
  
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.cfd_dsp48e1
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  min => min,
  cf => cf,
  sig => sig,
  cfd => cfd
);
  
sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sig <= to_signed(-8,WIDTH);
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
  wait;
end process;

end architecture testbench;