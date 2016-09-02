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

constant DEPTH:integer:=5;
constant CLK_PERIOD:time:=4 ns;
signal xing:boolean;
signal area:signed(31 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH-1 downto 0);
signal pos:boolean;
signal neg:boolean;
signal pos_closest:boolean;
signal neg_closest:boolean;
signal pos_pipe,neg_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
type pipe_t is array (natural range <>) of signed(WIDTH-1 downto 0);
signal pipe:pipe_t(1 to DEPTH);
  
begin
clk <= not clk after CLK_PERIOD/2;

pipeline : process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      pos_pipe <= (others => FALSE);
      neg_pipe <= (others => FALSE);
      pipe <= (others => (others => '0'));
    else
      pos_pipe(1) <= pos;
      pos_pipe(2 to DEPTH) <= pos_pipe(1 to DEPTH-1);
      neg_pipe(1) <= neg;
      neg_pipe(2 to DEPTH) <= neg_pipe(1 to DEPTH-1);
      pipe(1) <= signal_out;
      pipe(2 to DEPTH) <= pipe(1 to DEPTH-1);
    end if;
  end if;
end process pipeline;


thresXing:entity work.threshold_xing
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
  neg => neg,
  pos_closest => pos_closest,
  neg_closest => neg_closest
);

xing <= pos or neg;

UUT:entity work.area_acc(DSPx2)
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  xing => xing,
  sig => signal_out,
  area => area
);  
  
--sim:process (clk) is
--begin
--  if rising_edge(clk) then
--    if reset = '1' then
--      sig <= to_signed(0,WIDTH);
--    else
--      sig <= sig + 1;
--    end if;
--  end if;
--end process sim;

stimulus:process is
begin
  threshold <= (others => '0');
  signal_in <= (others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*8;
  signal_in <= to_signed(-65,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(0,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(-70,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(60,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(0,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(50,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(-40,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(50,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(-60,WIDTH);
  wait for CLK_PERIOD;
  signal_in <= to_signed(65,WIDTH);
  
  wait;
end process;

end architecture testbench;