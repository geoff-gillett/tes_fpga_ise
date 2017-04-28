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
	--baseline:signal_t;
	
  height:signal_t; 
  height_valid:boolean;
  
  rise_time:unsigned(15 downto 0);
	filtered_long:signed(DSP_BITS-1 downto 0);
	
  pulse_threshold_pos:boolean;
  pulse_threshold_neg:boolean;
  pre_pulse_threshold_neg:boolean;
  above_pulse_threshold:boolean;
  pulse_area:area_t;
  above_area_threshold:boolean;
  will_go_above:boolean;
  pulse_length:time_t; --time since pulse_pos_Txing
  pulse_time:time_t;   --time since last pulse start
  min_value:signal_t;
  
  slope_threshold_pos:boolean;
  --slope_threshold_neg:boolean;
  armed:boolean; 
  will_arm:boolean;
  
	cfd_low:boolean; 
	cfd_high:boolean;
  max_slope:boolean;
  pulse_start:boolean; --minima at start of pulse
  pre_pulse_start:boolean; -- clk before
  peak_start:boolean; --minima at start of pulse
  pre_peak_start:boolean; --minima at start of pulse
  peak_stop:boolean;
  offset:unsigned(PEAK_COUNT_BITS-1 downto 0);
  valid_peak:boolean;
  valid_peak0:boolean;
  valid_peak1:boolean;
  valid_peak2:boolean;
  
	peak_stamped:boolean; 
  pulse_stamped:boolean; 
	stamp_peak:boolean; --peak timing point
  stamp_pulse:boolean; --peak_start and first peak in a pulse
	pre_stamp_peak:boolean; --peak timing point
  pre_stamp_pulse:boolean; --peak_start and first peak in a pulse
  time_offset:unsigned(15 downto 0); 
  peak_time:unsigned(15 downto 0);
  
  eflags,pre_eflags:detection_flags_t;
  --pre_detection:detection_d;
  size:unsigned(15 downto 0);
  pre_size:unsigned(15 downto 0);
--  pre2_size:unsigned(15 downto 0);
  
  -- actually max peaks -1
  --max_peaks:unsigned(PEAK_COUNT_BITS-1 downto 0);
  last_peak:boolean;
  peak_overflow:boolean;
  peak_address:unsigned(PEAK_COUNT_BITS downto 0);
  last_peak_address:unsigned(PEAK_COUNT_BITS downto 0);
  
  timing_threshold:signed(15 downto 0);
	cfd_error:boolean;
	cfd_valid:boolean;
	
end record;

type measurements_array is array (natural range <>)
		 of measurements_t;

type measurement_array is array (natural range <>)
		 of measurement_t;
		 
function get_mca_values(m:measurement_t) return mca_value_array;
function get_mca_triggers(m:measurement_t) return std_logic_vector;
	
function get_mca_values(m:measurements_t) return mca_value_array;
function get_mca_triggers(m:measurements_t) return std_logic_vector;
  
function get_mca_quals(m:measurements_t) return std_logic_vector;
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
  va(9) := resize(m.raw.sample,MCA_VALUE_BITS);
  va(10) := resize(m.raw.area,MCA_VALUE_BITS);
  va(11) := resize(m.raw.extrema,MCA_VALUE_BITS);
  va(6) := resize(m.pulse.area,MCA_VALUE_BITS);
  va(7) := resize(m.pulse.extrema,MCA_VALUE_BITS);
  va(8) := resize(signed('0' & m.pulse.rise_time),MCA_VALUE_BITS);
  return va;
end function;

function get_mca_values(m:measurements_t) return mca_value_array is
variable va:mca_value_array(NUM_MCA_VALUE_D-2 downto 0);
begin
  va(0) := resize(m.filtered.sample,MCA_VALUE_BITS);
  va(1) := resize(m.filtered.area,MCA_VALUE_BITS);
  va(2) := resize(m.filtered.extrema,MCA_VALUE_BITS);
  va(3) := resize(m.slope.sample,MCA_VALUE_BITS);
  va(4) := resize(m.slope.area,MCA_VALUE_BITS);
  va(5) := resize(m.slope.extrema,MCA_VALUE_BITS);
  va(6) := resize(m.raw.sample,MCA_VALUE_BITS);
  va(7) := resize(m.raw.area,MCA_VALUE_BITS);
  va(8) := resize(m.raw.extrema,MCA_VALUE_BITS);
  va(9) := resize(m.pulse_area,MCA_VALUE_BITS);
  va(10) := resize(signed('0' & m.pulse_length),MCA_VALUE_BITS);
  va(11) := resize(signed('0' & m.rise_time),MCA_VALUE_BITS);
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

function get_mca_triggers(m:measurements_t) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
begin
  o(0):='1';
  o(1):=to_std_logic(m.pulse_threshold_pos);
  o(2):=to_std_logic(m.pulse_threshold_neg);
  o(3):=to_std_logic(m.filtered.zero_xing);
  o(4):=to_std_logic(m.slope.zero_xing);
  o(5):=to_std_logic(m.raw.zero_xing);
  o(6):=to_std_logic(m.slope_threshold_pos);
  o(7):=to_std_logic(m.cfd_high);
  o(8):=to_std_logic(m.cfd_low);
  o(9):=to_std_logic(m.max_slope);
  o(10):=to_std_logic(m.slope.pos_0xing);
  o(11):=to_std_logic(m.slope.neg_0xing);
  return o;
end function;

function get_mca_quals(m:measurements_t) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_QUAL_D-2 downto 0);
begin
  o(0):='1';
  o(1):=to_std_logic(m.valid_peak);
  o(2):=to_std_logic(m.above_area_threshold);
  o(3):=to_std_logic(m.above_pulse_threshold);
  o(4):=to_std_logic(m.will_go_above);
  o(5):=to_std_logic(m.armed);
  o(6):=to_std_logic(m.will_arm);
  o(7):=to_std_logic(m.valid_peak0);
  o(8):=to_std_logic(m.valid_peak1);
  o(9):=to_std_logic(m.valid_peak2);
  return o;
end function;

end package body measurements;
