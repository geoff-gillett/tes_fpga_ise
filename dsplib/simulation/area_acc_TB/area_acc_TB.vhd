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

entity area_acc_TB is
generic(
  WIDTH:integer:=18;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=4;
  AREA_FRAC:integer:=1;
  TOWARDS_INF:boolean:=FALSE
);
end entity area_acc_TB;

architecture testbench of area_acc_TB is

constant SIM_WIDTH:integer:=8;

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal xing:boolean;
signal sig:signed(WIDTH-1 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal area:signed(AREA_WIDTH-1 downto 0);

signal sim_count:unsigned(SIM_WIDTH-1 downto 0):=(others => '0');

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.area_acc2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  TOWARDS_INF => TOWARDS_INF
)
port map(
  clk => clk,
  reset => reset,
  xing => xing,
  sig => sig,
  threshold => threshold,
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
--xing <= resize(signed(sim_count),WIDTH)=threshold;
xing <= TRUE;
sig <= resize(signed(sim_count),WIDTH);

stimulus:process is
begin
threshold <= (others => '0');
wait for CLK_PERIOD;
reset <= '0';
wait;
end process stimulus;

end architecture testbench;
