--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:19 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: tickstream_TB
-- Project Name: 
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

library streamlib;
use streamlib.events.all;
use streamlib.stream.all;

library main;

entity tickstream_TB is
generic(
  CHANNEL_BITS:integer:=3;
  PERIOD_BITS:integer:=32;
  MINIMUM_PERIOD:integer:=4;
  TIMESTAMP_BITS:integer:=64
);
end entity tickstream_TB;

architecture testbench of tickstream_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal tick:boolean;
signal timestamp:unsigned(TIMESTAMP_BITS-1 downto 0);
signal tick_period:unsigned(PERIOD_BITS-1 downto 0);
signal overflow,overflow_out:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal tickstream:streambus;
signal valid:boolean;
signal ready:boolean;
begin
	
clk <= not clk after CLK_PERIOD/2;
overflow_out <= to_boolean(tickstream.data(7 downto 0));

UUT:entity main.tickstream
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  PERIOD_BITS => PERIOD_BITS,
  MINIMUM_PERIOD => MINIMUM_PERIOD,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset,
  tick => tick,
  timestamp => timestamp,
  tick_period => tick_period,
  overflow => overflow,
  tickstream => tickstream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
tick_period <= to_unsigned(8,PERIOD_BITS);
overflow <= (others => FALSE);
ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*2;
overflow<= (0 => TRUE, others =>FALSE);
wait for CLK_PERIOD;
overflow <= (others => FALSE);
wait until tick;
overflow<= (1 => TRUE, others =>FALSE);
wait for CLK_PERIOD;
overflow <= (others => FALSE);
wait;
end process stimulus;

end architecture testbench;
