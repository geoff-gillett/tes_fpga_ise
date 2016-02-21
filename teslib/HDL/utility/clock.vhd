--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:08/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: clock
-- Project Name: control_unit
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library teslib;

entity clock is
generic(TIME_BITS:integer:=32);
port (
  clk:in std_logic;
  reset:in std_logic;
  te:in boolean; -- time enable
  
  initialise_to_1:in boolean;
  rolling_over:out boolean;
  time_stamp:out unsigned(TIME_BITS-1 downto 0)
);
end entity clock;

architecture RTL of clock is

signal time_counter:unsigned(TIME_BITS-1 downto 0);

begin
time_stamp <= time_counter;
rolling_over <= to_integer(not time_counter)=0;

count:process (clk) is
begin
if rising_edge(clk) then
  if reset = '1' then
    if initialise_to_1 then
      time_counter <= to_unsigned(1, TIME_BITS);
    else
      time_counter <= to_unsigned(0, TIME_BITS);
    end if;
  elsif te then
    time_counter <= time_counter+1;
  end if;
end if;
end process count;
end architecture RTL;
