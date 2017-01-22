library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library extensions;
--use extensions.logic.all;

entity dynamic_round_TB is
generic(
  WIDTH_IN:natural:=48; -- max 48
  WIDTH_OUT:natural:=5;
  TOWARDS_INF:boolean:=FALSE
); 
end entity dynamic_round_TB;

architecture testbench of dynamic_round_TB is  
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;
signal input:std_logic_vector(WIDTH_IN-1 downto 0);
signal output:std_logic_vector(WIDTH_OUT-1 downto 0);

constant SIM_WIDTH:integer:=9;
signal sim_count,sim_out:signed(SIM_WIDTH-1 downto 0);

constant DEPTH:natural:=7;
type pipe is array (1 to DEPTH) of signed(SIM_WIDTH-1 downto 0);
signal sim_pipe:pipe;
signal point:integer range 0 to WIDTH_IN;
signal msb:integer range 0 to WIDTH_IN;
signal bin_n:integer range 0 to WIDTH_IN;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.dynamic_round
generic map(
  WIDTH_IN => WIDTH_IN,
  WIDTH_OUT => WIDTH_OUT,
  TOWARDS_INF => TOWARDS_INF
)
port map(
  clk => clk,
  reset => reset,
  msb => msb,
  point => point,
  input => input,
  output => output
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
input <= std_logic_vector(resize(sim_count,WIDTH_IN));

stimulus:process is
begin
  bin_n <= 3;
  wait for CLK_PERIOD;
  point <= bin_n;
  msb <= WIDTH_OUT-1+bin_n;
  reset <= '0';
  wait;
end process stimulus;

end architecture testbench;