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
  WIDTH:integer:=18;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
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
constant DEPTH:natural:=5;
type pipe is array (natural range <>) of unsigned(SIM_WIDTH-1 downto 0);
signal sim_pipe:pipe(1 to DEPTH);
signal xing_pipe:boolean_vector(1 to DEPTH);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.area_acc2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
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
      sim_pipe <= sim_count & sim_pipe(1 to DEPTH-1);
      xing_pipe <= xing & xing_pipe(1 to DEPTH-1);
    end if;
  end if;
end process sim;
xing <= sim_count(3 downto 0)=0000;
--xing <= TRUE;
sig <= resize(signed(sim_count),WIDTH);

stimulus:process is
begin
threshold <= to_signed(0, WIDTH);
wait for CLK_PERIOD;
reset <= '0';
wait;
end process stimulus;

end architecture testbench;
