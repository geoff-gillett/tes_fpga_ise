--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:28 Dec 2015
--
-- Design Name: TES_digitiser
-- Module Name: signal_measurement_TB
-- Project Name: tests 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
--
library dsplib;

entity signal_measurement_TB is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3
);
end entity signal_measurement_TB;

architecture testbench of signal_measurement_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
--
signal signal_in:signed(WIDTH-1 downto 0);
signal area:signed(AREA_BITS-1 downto 0);
signal extrema:signed(WIDTH-1 downto 0);
signal valid:boolean;
signal signal_out:signed(WIDTH-1 downto 0);
signal pos_xing:boolean;
signal neg_xing:boolean;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  signal_out => signal_out,
  pos_xing => pos_xing,
  neg_xing => neg_xing,
  area => area,
  extrema => extrema,
  valid => valid
);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
signal_in <= (others => '0');
wait for CLK_PERIOD;
signal_in <= to_signed(128,WIDTH);
wait for CLK_PERIOD*2;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(128,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-128,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD*3;
signal_in <= to_signed(-128,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(128,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);
wait;
end process stimulus;

end architecture testbench;
