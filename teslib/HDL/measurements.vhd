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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;
use work.functions.all;
use work.events.all;
use work.registers.all;

package measurements is
	

type filtered_measurement_t is record
	sample:signal_t;
	area:area_t;
	extrema:signal_t;
	pos_0xing:boolean;
	neg_0xing:boolean;
	zero_xing:boolean;
	pos_threshxing:boolean;
	neg_threshxing:boolean;
	xing_time:time_t;
	zero_xing_time:time_t;
end record;

type slope_measurement_t is record
	sample:signal_t;
	area:area_t;
	extrema:signal_t;
	--FIXME remove 0xings
	pos_0xing:boolean;
	neg_0xing:boolean;
	zero_xing:boolean;
	pos_threshxing:boolean;
	neg_threshxing:boolean;
	xing_time:time_t;
	zero_xing_time:time_t;
end record;

type threshold_measurement_t is record
  pos_xing:boolean;
  neg_xing:boolean;
	xing_time:time_t;
end record;

type raw_measurement_t is record
	sample:signal_t;
	area:area_t;
	extrema:signal_t;
	zero_xing:boolean;
	baseline:signal_t;
end record;

type pulse_measurement_t is record
	area:area_t;
	area_above_threshold:boolean;
	extrema:signal_t;
	pos_threshxing:boolean;
	neg_threshxing:boolean;
	rise_time:unsigned(RELATIVETIME_BITS-1 downto 0);
end record;
	
type signal_measurement_t is record
	sample:signal_t;
	area:area_t;
	extrema:signal_t;
	pos_0xing:boolean;
	neg_0xing:boolean;
	zero_xing:boolean;
end record;

type measurement_t is record
	raw:raw_measurement_t;
	filtered:filtered_measurement_t;
	slope:slope_measurement_t;
	pulse:pulse_measurement_t;
	
	height:signal_t; 
	height_valid:boolean;
	
	--time from trigger to height_valid
	trigger_time:time_t;
	event_start:boolean;
	event_time:time_t;

	peak_start:boolean; -- event_start
	trigger:boolean;
	peak:boolean;
	
	cfd_low:boolean; 
	cfd_high:boolean;
	
	peak_count:unsigned(PEAK_COUNT_BITS downto 0);
	--pulse_time:unsigned(RELATIVETIME_BITS-1 downto 0);
end record;

--type peak_state_t is (IDLE_S,ARMED_S);
--type pulse_state_t is (BELLOW_S,ABOVE_S);
type measurements_t is record
	raw:signal_measurement_t;
	filtered:signal_measurement_t;
	slope:signal_measurement_t;
	
  pulse_area:area_t;
  pulse_length:time_t; --time since pulse_pos_Txing
  pulse_time:time_t;   --time since last pulse start
  
  pulse_start:boolean; --minima at start of pulse
  peak_start:boolean; --minima at start of pulse
  
  --pulse time of timestamp valid after event start
  time_offset:unsigned(15 downto 0); 
  
  valid_peak:boolean;
	stamp_peak:boolean; --peak timing point
  stamp_pulse:boolean; --peak_start and first peak in a pulse
  rise_time:unsigned(15 downto 0);
  max_slope:boolean;
  
  eflags:detection_flags_t;
  size:unsigned(15 downto 0);
  
  -- actually max peaks -1
  max_peaks:unsigned(PEAK_COUNT_BITS-1 downto 0);
  last_peak:boolean;
  peak_address:unsigned(MEASUREMENT_FRAMER_ADDRESS_BITS-1 downto 0);
  last_address:unsigned(MEASUREMENT_FRAMER_ADDRESS_BITS-1 downto 0);
  
  pulse_threshold_pos:boolean;
  pulse_threshold_neg:boolean;
  slope_threshold_pos:boolean;
  slope_threshold_neg:boolean;
  
  above_area_threshold:boolean;
  above_pulse_threshold:boolean;
  armed:boolean; 
  has_armed:boolean;
  
  height_valid:boolean;
  	
	cfd_low:boolean; 
	cfd_high:boolean;
	cfd_error:boolean;
	
end record;

type measurement_array is array (natural range <>)
		 of measurement_t;
		 
function get_mca_values(m:measurement_t) return mca_value_array;
function get_mca_triggers(m:measurement_t) return std_logic_vector;
	
end package measurements;

package body measurements is

--FIXME need to double the values
function get_mca_values(m:measurement_t) return mca_value_array is
variable va:mca_value_array(NUM_MCA_VALUE_D-1 downto 0);
begin
  va(0) := resize(m.filtered.sample,MCA_VALUE_BITS);
  va(1) := resize(m.filtered.area,MCA_VALUE_BITS);
  va(2) := resize(m.filtered.extrema,MCA_VALUE_BITS);
  va(3) := resize(m.slope.sample,MCA_VALUE_BITS);
  va(4) := resize(m.slope.area,MCA_VALUE_BITS);
  va(5) := resize(m.slope.extrema,MCA_VALUE_BITS);
  va(6) := resize(m.pulse.area,MCA_VALUE_BITS);
  va(7) := resize(m.pulse.extrema,MCA_VALUE_BITS);
  va(8) := resize(signed('0' & m.pulse.rise_time),MCA_VALUE_BITS);
  va(9) := resize(m.raw.sample,MCA_VALUE_BITS);
  va(10) := resize(m.raw.area,MCA_VALUE_BITS);
  va(11) := resize(m.raw.extrema,MCA_VALUE_BITS);
  return va;
end function;

function get_mca_triggers(m:measurement_t) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
begin
  o(0):='1';
  o(1):=to_std_logic(m.pulse.pos_threshxing);
  -- FIXME this needs to be changed need a zero_xing
  o(2):=to_std_logic(m.filtered.pos_0xing);
  o(3):=to_std_logic(m.slope.zero_xing);
  o(4):=to_std_logic(m.slope.pos_threshxing);
  o(5):=to_std_logic(m.cfd_high);
  o(6):=to_std_logic(m.cfd_low);
  o(7):=to_std_logic(m.peak);
  o(8):=to_std_logic(m.peak_start);
  o(9):=to_std_logic(m.raw.zero_xing);
  --o(11):=to_std_logic(m.height_valid);
  return o;
end function;
end package body measurements;
