--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:23 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: area_time
-- Project Name: dsplib
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

entity area_time is
port(
  clk:in std_logic;
  --
  signal_in:signal_t;
  start:in boolean;
  stop:in boolean;
  --
  area:out area_t;
  length:out time_t;
  valid:out boolean
);
end entity area_time;

architecture RTL of area_time is

signal area_int:signed(AREA_BITS downto 0);
signal length_int:unsigned(TIME_BITS downto 0);
	
begin

--area can't overflow but length can 

measurement:process(clk)
begin
if rising_edge(clk) then
  if start then
    length_int <= to_unsigned(1,TIME_BITS);
    area_int <= resize(signal_in,AREA_BITS);
  else
    if length_int /= to_unsigned(2**TIME_BITS-1,TIME_BITS) then
      length_int <= length_int+1;
      area_int <= area_int+signal_in;
    end if;
  end if;
  if stop then
    area <= area_int;
    length <= length_int;
    valid <= TRUE;
  else
    valid <= FALSE;
  end if;
end if;
end process measurement;

end architecture RTL;
