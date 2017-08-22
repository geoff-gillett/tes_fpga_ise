--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:25Nov.,2016
--
-- Design Name: TES_digitiser
-- Module Name: area_acc_TB
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
entity area_acc_TB is
generic(
  WIDTH:integer:=16;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=7;
  AREA_FRAC:integer:=1;
  AREA_ABOVE:boolean:=TRUE;
  TOWARDS_INF:boolean:=TRUE
);
end entity area_acc_TB;

architecture testbench of area_acc_TB is

constant SIM_WIDTH:integer:=8;

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal xing:boolean;
signal sig,sum:signed(WIDTH-1 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal area:signed(AREA_WIDTH-1 downto 0);

signal sim_count:unsigned(SIM_WIDTH-1 downto 0):=(others => '0');
constant DEPTH:natural:=5;
type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);
signal sig_pipe,sum_pipe:pipe(1 to DEPTH);
signal xing_pipe:boolean_vector(1 to DEPTH);
signal area_threshold:signed(AREA_WIDTH-1 downto 0);
signal above_area_threshold:boolean;
signal sign:std_logic:='0';

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  AREA_ABOVE => AREA_ABOVE,
  TOWARDS_INF => TOWARDS_INF
)
port map(
  clk => clk,
  reset => reset,
  sig => sig,
  signal_threshold => threshold,
  xing => xing,
  area_threshold => area_threshold,
  above_area_threshold => above_area_threshold,
  area => area
);

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= (others => '0');
    else
      sim_count <= sim_count+1;
      sig_pipe <= sig & sig_pipe(1 to DEPTH-1);
      sum_pipe <= sum & sum_pipe(1 to DEPTH-1);
      xing_pipe <= xing & xing_pipe(1 to DEPTH-1);
      if sim_count(4 downto 0)="11111" then
        sign <= not sign;
      end if;
      if xing then
        sum <= sig;
      else
        sum <= sum+sig;
      end if;
    end if;
  end if;
end process sim;
xing <= sim_count(4 downto 0)="00000" and reset='0';
sig <= resize(signed(sign & sim_count(4 downto 0)),WIDTH) when sign='0' else
       resize(signed(sign & not (sim_count(4 downto 0))),WIDTH);


stimulus:process is
begin
threshold <= to_signed(0, WIDTH);
area_threshold <= to_signed(0, AREA_WIDTH);
--sig <= to_signed(0,WIDTH);
wait for CLK_PERIOD*4;
reset <= '0';
--wait for CLK_PERIOD;
--sig <= to_signed(1,WIDTH);
wait for CLK_PERIOD;
--sig <= to_signed(0,WIDTH);
wait;
end process stimulus;

end architecture testbench;
