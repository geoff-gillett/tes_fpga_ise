library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

use work.measurements.all;
use work.events.all;
use work.registers.all;

entity measurement_unit2 is
generic(
  CHANNEL:integer:=0;
  WIDTH:integer:=18;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1;
  CFD_DELAY:integer:=1027;
  FRAMER_ADDRESS_BITS:integer:=11;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  registers:capture_registers_t;
  
  raw:in signed(WIDTH-1 downto 0);
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  measurements:out measurements_t;
  
  start:out boolean;
  commit:out boolean;
  dump:out boolean;
  
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity measurement_unit2;

architecture RTL of measurement_unit2 is
  
signal m:measurements_t;
  
begin
measurements <= m;

meas:entity work.measure
generic map(
  CHANNEL => CHANNEL,
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CFD_DELAY => CFD_DELAY
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  registers => registers,
  raw => raw,
  slope => slope,
  filtered => filtered,
  measurements => m
);

framer:entity work.measurement_framer
generic map(
  WIDTH => WIDTH,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset => reset1,
  start => start,
  commit => commit,
  dump   => dump,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
