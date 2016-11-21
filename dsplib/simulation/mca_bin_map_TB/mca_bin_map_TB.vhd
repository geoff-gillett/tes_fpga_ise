library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library extensions;
--use extensions.logic.all;

entity mca_bin_map_TB is
generic(
  VALUE_BITS:natural:=32;
  ADDRESS_BITS:natural:=4
);
end entity mca_bin_map_TB;

architecture testbench of mca_bin_map_TB is  
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;

constant SIM_WIDTH:integer:=4;
signal sim_count,sim_out:signed(SIM_WIDTH-1 downto 0);

constant DEPTH:natural:=9;
type pipe is array (1 to DEPTH) of signed(SIM_WIDTH-1 downto 0);
signal sim_pipe:pipe;
signal hist_nm1:natural range 0 to ADDRESS_BITS; -- last bin
signal bin_n:natural range 0 to ADDRESS_BITS;
signal lowest_value:signed(VALUE_BITS-1 downto 0);
signal value:signed(VALUE_BITS-1 downto 0);
signal bin:unsigned(ADDRESS_BITS-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.mca_bin_map
generic map(
  VALUE_BITS => VALUE_BITS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  last_bin => hist_nm1, 
  bin_n => bin_n,
  lowest_value => lowest_value,
  value => value,
  bin => bin
);
  
sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= (others => '0');
      sim_pipe <= (others => (others => '0'));
    else
      sim_pipe <= sim_count & sim_pipe(1 to DEPTH-1);
      sim_count <= sim_count+1;
    end if;
  end if;
end process sim;
sim_out <= sim_pipe(DEPTH);
value <= resize(sim_count,VALUE_BITS);

stimulus:process is
begin
  bin_n <= 1;
  hist_nm1 <= 4;
  lowest_value <= to_signed(-7,VALUE_BITS);
  wait for CLK_PERIOD;
  reset <= '0';
  wait;
end process stimulus;

end architecture testbench;