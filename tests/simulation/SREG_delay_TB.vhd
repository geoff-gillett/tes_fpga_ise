--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:13 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: SREG_delay_TB
-- Project Name:dsplib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library dsplib;

entity SREG_delay_TB is
generic(
  DEPTH:integer:=32; 
  DATA_BITS:integer:=18
);
end entity SREG_delay_TB;

architecture testbench of SREG_delay_TB is

signal clk:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal data_in:std_logic_vector(DATA_BITS-1 downto 0);
signal delay:natural range 0 to DEPTH-1;
signal delayed_sreg,delayed_ram:std_logic_vector(DATA_BITS-1 downto 0);
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.SREG_delay
generic map(
  DEPTH     => DEPTH,
  DATA_BITS => DATA_BITS
)
port map(
  clk     => clk,
  data_in => data_in,
  delay   => delay,
  delayed => delayed_sreg
);

UUT2:entity dsplib.RAM_delay
	generic map(
		DEPTH     => DEPTH,
		DATA_BITS => DATA_BITS
	)
	port map(
		clk     => clk,
		data_in => data_in,
		delay   => delay,
		delayed => delayed_ram
	);

stimulus:process is
begin
delay <= 0;
data_in <= (others => '0');
wait for CLK_PERIOD*2;
data_in <= to_std_logic(1,DATA_BITS);
wait for CLK_PERIOD;
data_in <= to_std_logic(2,DATA_BITS);
wait for CLK_PERIOD;
data_in <= to_std_logic(0,DATA_BITS);
wait for CLK_PERIOD;
wait;
end process stimulus;

end architecture testbench;
