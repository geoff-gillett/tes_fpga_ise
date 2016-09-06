library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.measurements.all;
use work.events.all;
use work.registers.all;

entity measurement_framer is
generic(
  CHANNEL:integer:=0;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  reg:capture_registers_t;
  
  m:in measurements_t
);
end entity measurement_framer;

architecture RTL of measurement_framer is
  
constant CHUNKS:integer:=4;
constant CHAN_BITS:integer:=3;
 
signal flags:detection_flags_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;

signal peak_we,area_we:boolean_vector(CHUNKS-1 downto 0);
  
begin
--FIXME this could be a function
flags.channel <= to_unsigned(CHANNEL,CHAN_BITS);
flags.event_type.detection <= capture_cfd.detection;
flags.event_type.tick <= FALSE;
flags.relative <= capture_cfd.height_rel2min;
flags.timing <= capture_cfd.timing;
flags.peak_count <= m.peak_count(PEAK_COUNT_BITS-1 downto 0)-1;
flags.height <= capture_cfd.height;


end architecture RTL;
