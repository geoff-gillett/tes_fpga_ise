library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.logic.all;


entity round_TB is
generic(
  WIDTH_IN:natural:=48; -- max 48
  FRAC_IN:natural:=3;
  WIDTH_OUT:natural:=6;
  FRAC_OUT:natural:=0;
  TOWARDS_INF:boolean:=FALSE
); 
end entity round_TB;


architecture testbench of round_TB is  
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;
signal input:signed(WIDTH_IN-1 downto 0);
signal output:signed(WIDTH_OUT-1 downto 0);

constant SIM_WIDTH:integer:=7;
signal sim_count,sim_out:signed(SIM_WIDTH-1 downto 0);

constant DEPTH:natural:=3;
type pipe is array (1 to DEPTH) of signed(SIM_WIDTH-1 downto 0);
signal sim_pipe:pipe;
signal output_threshold:signed(WIDTH_OUT-1 downto 0);
signal above_threshold:boolean;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.round2
generic map(
  WIDTH_IN => WIDTH_IN,
  FRAC_IN => FRAC_IN,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  TOWARDS_INF => TOWARDS_INF
)
port map(
  clk => clk,
  reset => reset,
  input => input,
  output_threshold => output_threshold,
  output => output,
  above_threshold => above_threshold
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
input <= resize(sim_count,WIDTH_IN);

stimulus:process is
begin
  --input <= (others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*8;
  --input <= (0 => '1',others => '0');
  
  wait for CLK_PERIOD*32;
  --saturate <= '1';
  wait;
end process stimulus;


end architecture testbench;