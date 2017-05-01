library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.logic.all;


entity average_2n_TB is
generic(
  WIDTH:natural:=16;
  DIVIDE_N:natural:=4
); 
end entity average_2n_TB;


architecture testbench of average_2n_TB is  
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;

constant DIVIDE_BITS:integer:=ceillog2(48-WIDTH+1);
constant SIM_WIDTH:integer:=4;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0):=(others => '0');

constant DEPTH:natural:=3;
--type pipe is array (1 to DEPTH) of signed(SIM_WIDTH-1 downto 0);
--signal sim_pipe:pipe;
signal threshold:signed(WIDTH-1 downto 0);
signal sample:signed(WIDTH-1 downto 0);
signal average:signed(WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.average_fixed_n
generic map(
  WIDTH => WIDTH,
  DIVIDE_N => DIVIDE_N
)
port map(
  clk => clk,
  reset => reset,
  threshold => threshold,
  sample => sample,
  average => average
);
  
sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= (others => '0');
--      sim_pipe <= (others => (others => '0'));
    else
--      sim_pipe <= sim_count & sim_pipe(1 to DEPTH-1);
      sim_count <= sim_count+1;
    end if;
  end if;
end process sim;
--sim_out <= sim_pipe(DEPTH);
sample <= resize(-signed('0' & sim_count),WIDTH);
--sample <= to_signed(1,WIDTH);

stimulus:process is
begin
--  threshold <= to_signed(4,WIDTH);
  threshold <= (WIDTH-1 => '0', others => '1');
  --input <= (others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*8;
  
  wait for CLK_PERIOD*32;
  wait;
end process stimulus;


end architecture testbench;