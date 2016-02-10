--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: measurement
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

library eventlib;
use eventlib.events.all;

use work.registers.all;

package measurements is
	
type signal_measurements is record
	area:area_t;
	extrema:signal_t;
	valid:boolean;
end record;

type measurement_t is record
	filtered_signal:signal_t;
	slope_signal:signal_t;
	raw_signal:signal_t;
	raw:signal_measurements;
	filtered:signal_measurements;
	pulse:signal_measurements;
	slope:signal_measurements;
	height:signal_t; --currently valid when commit true
	height_valid:boolean; 	
	peak_start:boolean;
	peak_count:unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
	pulse_start:boolean;
	pulse_stop:boolean;
	peak:boolean;
	cfd_low:boolean;
	cfd_high:boolean;
	slope_xing:boolean;
	filtered_xing:boolean;
end record;

type measurement_array is array (natural range <>)
		 of measurement_t;
		 
function get_values(m:measurement_t) return mca_value_array;
function get_triggers(m:measurement_t) return std_logic_vector;
	
end package measurements;

package body measurements is

function get_values(m:measurement_t) return mca_value_array is
variable va:mca_value_array(MCA_VALUE_SELECT_BITS-1 downto 0);
begin
  va(0) := resize(m.filtered_signal,MCA_VALUE_BITS);
  va(1) := resize(m.filtered.area,MCA_VALUE_BITS);
  va(2) := resize(m.filtered.extrema,MCA_VALUE_BITS);
  va(3) := resize(m.slope_signal,MCA_VALUE_BITS);
  va(4) := resize(m.slope.area,MCA_VALUE_BITS);
  va(5) := resize(m.slope.extrema,MCA_VALUE_BITS);
  va(6) := resize(m.pulse.area,MCA_VALUE_BITS);
  va(7) := resize(m.pulse.extrema,MCA_VALUE_BITS);
  va(8) := resize(m.raw_signal,MCA_VALUE_BITS);
  va(9) := resize(m.raw.area,MCA_VALUE_BITS);
  va(10) := resize(m.raw.extrema,MCA_VALUE_BITS);
  return va;
end function;

function get_triggers(m:measurement_t) return std_logic_vector is
variable o:std_logic_vector(MCA_TRIGGER_SELECT_BITS-1 downto 0);
begin
						o(0):='1';
						o(1):=to_std_logic(m.filtered_xing);
						o(2):=to_std_logic(m.filtered.valid);
						o(2):=to_std_logic(m.slope.valid);
						o(2):=to_std_logic(m.slope_xing);
						o(2):=to_std_logic(m.cfd_high);
						o(2):=to_std_logic(m.cfd_low);
						o(2):=to_std_logic(m.peak);
						o(2):=to_std_logic(m.peak_start);
						o(2):=to_std_logic(m.raw.valid);
						return o;
end function;
end package body measurements;
