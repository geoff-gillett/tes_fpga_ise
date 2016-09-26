library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

entity area_acc_TB is
generic(
  WIDTH:integer:=18
);
end entity area_acc_TB;

architecture testbench of area_acc_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal signal_in:signed(WIDTH-1 downto 0);

constant DEPTH:integer:=4;
constant CLK_PERIOD:time:=4 ns;
signal xing:boolean;
signal area:signed(31 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal signal_xing:signed(WIDTH-1 downto 0);
signal pos:boolean;
signal neg:boolean;
signal pos_closest:boolean;
signal neg_closest:boolean;
signal pos_pipe,neg_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
type pipe_t is array (natural range <>) of signed(WIDTH-1 downto 0);
signal pipe:pipe_t(1 to DEPTH);

constant SIM_WIDTH:natural:=4;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal pos_out : boolean;
signal neg_out : boolean;
signal signal_out : signed(WIDTH-1 downto 0);

  
begin
clk <= not clk after CLK_PERIOD/2;


thresXing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  threshold => threshold,
  signal_out => signal_xing,
  pos => pos,
  neg => neg,
  pos_closest => pos_closest,
  neg_closest => neg_closest
);

xing <= pos or neg;

pipeline:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      pos_pipe <= (others => FALSE);
      neg_pipe <= (others => FALSE);
      pipe <= (others => (others => '0'));
    else
      pos_pipe <= pos & pos_pipe(1 to DEPTH-1);
      neg_pipe <= neg & neg_pipe(1 to DEPTH-1);
      pipe <= signal_xing & pipe(1 to DEPTH-1);
    end if;
  end if;
end process pipeline;
pos_out <= pos_pipe(DEPTH);
neg_out <= neg_pipe(DEPTH);
signal_out <= pipe(DEPTH);


UUT:entity work.area_acc3
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  xing => xing,
  sig => signal_xing,
  area => area
);  

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= (others => '0');
    else
      sim_count <= sim_count+1;
    end if;
  end if;
end process sim;
signal_in <= to_signed(-8,WIDTH) when sim_count(SIM_WIDTH-1)='1' else
             to_signed(8,WIDTH);

stimulus:process is
begin
  threshold <= (others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait;
end process;

end architecture testbench;