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

library streamlib;
use streamlib.types.all;

use work.types.all;
use work.functions.all;
use work.events21.all;
use work.registers21.all;



package measurements21 is

--DEPTH of pipelines in the measurement record
constant MEASUREMENT_DEPTH:natural:=2;
constant NOW:natural:=2; --value now
constant PRE:natural:=1; --value 1 clk before
constant PRE2:natural:=0; --value 2 clks before
	
type size_pipe is array (natural range <>) of 
     unsigned(PEAK_COUNT_BITS downto 0);
type frame_length_pipe is array (natural range <>) of 
     unsigned(MEASUREMENT_FRAMER_ADDRESS_BITS downto 0);
type time_pipe is array (natural range <>) of 
     unsigned(CHUNK_DATABITS-1 downto 0);
type signal_pipe is array (natural range <>) of 
     signed(CHUNK_DATABITS-1 downto 0);
	
--type peak_state_t is (IDLE_S,ARMED_S);
--type pulse_state_t is (BELLOW_S,ABOVE_S);
type measurements_t is record
  --the filtered signal
	f:signed(CHUNK_DATABITS-1 downto 0);
	--filtered signal measurement
	f_extrema,f_area:signed(CHUNK_DATABITS-1 downto 0);	
	--filtered signal zero crossing
	f_0,f_0_p,f_0_n:boolean;
  --pulse threshold crossings PRE2 is 2 clks before crossing
  p_t_p,p_t_n:boolean_vector(0 to MEASUREMENT_DEPTH);
	
	--the slope signal
  s:signed(CHUNK_DATABITS-1 downto 0);
  --slope signal measurement
	s_extrema,s_area:signed(CHUNK_DATABITS-1 downto 0);	
	--slope signal zero crossing
	s_0:boolean;
  --slope	threshold rising PRE2 is 2 clks before crossing
  s_t_p:boolean_vector(0 to MEASUREMENT_DEPTH);
  
  --minima in f or s_0_p crossing, PRE is one clk before.
  min:boolean_vector(0 to MEASUREMENT_DEPTH);
  --max in f or s_0_n crossing, PRE is one clk before
  max:boolean_vector(0 to MEASUREMENT_DEPTH);
	
  --the raw baseline corrected signal
	raw:signed(CHUNK_DATABITS-1 downto 0);

		
	--reg_pipe(PRE) reg settings for the next pulse (valid 2 clks prior to pulse
	--start)
	--reg_pipe(NOW) valid pulse start till p_t_n inclusive.
	reg:cap_reg_pipe(1 to MEASUREMENT_DEPTH); 
  
  --size of event part size(PRE) is valid 1 clk before pulse start
  size:size_pipe(1 to MEASUREMENT_DEPTH);
  --size of full event + event part, used when commit and new event simultaneous
  --size2(PRE) is valid one clk before pulse start
  size2:size_pipe(1 to MEASUREMENT_DEPTH);
  --frame_length(PRE) is valid one clk before pulse start.
  frame_length:frame_length_pipe(1 to MEASUREMENT_DEPTH);
  
  dp_address:size_pipe(1 to MEASUREMENT_DEPTH);
  
	--valid @ pulse_start
  enabled:boolean_vector(1 to MEASUREMENT_DEPTH);
  
  --valid rise with minima below pulse threshold PRE2 is 2 clks before
  pulse_start:boolean_vector(0 to MEASUREMENT_DEPTH); --min of valid first rise
  has_rise:boolean; --rise_number > 0 for this pulse
  
  --minima at start of a valid rise.
  rise_start:boolean_vector(1 to MEASUREMENT_DEPTH); 
  valid_rise:boolean; --rise_start to max; 
  rise0:boolean; --(min and first_peak) to max
  rise1:boolean; --(min and rise_number=1) to max
  rise2:boolean; --(min and rise_number=2) to max
  
  last_rise:boolean; --this is the last rise that can be recorded
  rise_overflow:boolean; --more valid rises than could be counted
  rise_number:unsigned(PEAK_COUNT_BITS downto 0); --first rise is number 0
  
  --rise timing point PRE valid 1 clk before
	stamp_rise:boolean_vector(1 to MEASUREMENT_DEPTH); --rise timing point
	--this rise has been stamped PRE 
	rise_stamped:boolean_vector(1 to MEASUREMENT_DEPTH); 
  --pulse timing point
  stamp_pulse:boolean_vector(1 to MEASUREMENT_DEPTH); 
  pulse_stamped:boolean_vector(1 to MEASUREMENT_DEPTH); 
  
	rise_time:time_pipe(1 to MEASUREMENT_DEPTH); 	--0 at rise timing point
	pulse_time:time_pipe(1 to MEASUREMENT_DEPTH); --0 at peak_start
	pulse_length:time_pipe(1 to MEASUREMENT_DEPTH); 	--0 at p_t_p 
	
	
  minima:signal_pipe(0 to MEASUREMENT_DEPTH); --value of f at s_0_p
  height:signal_pipe(1 to MEASUREMENT_DEPTH); --height measurement
  height_valid:boolean_vector(1 to MEASUREMENT_DEPTH); --measurement point 
	--maxima of at end of a valid rise
  rise_stop:boolean_vector(1 to MEASUREMENT_DEPTH); 
  
--  max_peaks:unsigned(PEAK_COUNT_BITS downto 0);
  -- flags
  
	
	cfd_high_threshold:signal_t;
	
	--baseline:signal_t;
  mux_wr_en:boolean;
	
  rise_timestamp:unsigned(15 downto 0);
	
  above,will_cross:boolean;
  
  pulse_area:area_t;
  
  above_area:boolean;
  
  --slope_threshold_neg:boolean;
  armed:boolean; 
  will_arm:boolean;
  
	cfd_low_p:boolean; 
	cfd_high_p:boolean;
  max_slope_p:boolean;
  
  offset:unsigned(PEAK_COUNT_BITS-1 downto 0);
  
	pre_stamp_rise:boolean; --peak timing point
  pre_stamp_pulse:boolean; --peak_start and first peak in a pulse
  time_offset:unsigned(15 downto 0); 
  
  --pre_detection:detection_d;
--  pre_size2:unsigned(MEASUREMENT_FRAMER_ADDRESS_BITS downto 0);
  -- frame_length + size
--  pre2_size:unsigned(15 downto 0);
  
  -- actually max peaks -1
  --max_peaks:unsigned(PEAK_COUNT_BITS-1 downto 0);
  rise_address:unsigned(PEAK_COUNT_BITS downto 0);
  last_peak_address:unsigned(PEAK_COUNT_BITS downto 0);
  
	cfd_error:boolean;
	cfd_overrun:boolean;
  
--	trace_signal:trace_signal_d;
--	trace_type:trace_type_d;
	
end record;

type measurements_array is array (natural range <>)
		 of measurements_t;

		 
	
function get_mca_values(m:measurements_t) return mca_value_array;
function get_mca_triggers(m:measurements_t) return std_logic_vector;
  
function get_mca_quals(m:measurements_t) return std_logic_vector;
end package measurements21;

package body measurements21 is

--FIXME need to double the values

function get_mca_values(m:measurements_t) return mca_value_array is
variable va:mca_value_array(NUM_MCA_VALUE_D-2 downto 0);
begin
  va(0) := resize(m.f,MCA_VALUE_BITS);
  va(1) := resize(m.f_area,MCA_VALUE_BITS);
  va(2) := resize(m.f_extrema,MCA_VALUE_BITS);
  va(3) := resize(m.s,MCA_VALUE_BITS);
  va(4) := resize(m.s_area,MCA_VALUE_BITS);
  va(5) := resize(m.s_extrema,MCA_VALUE_BITS);
  va(6) := resize(m.pulse_area,MCA_VALUE_BITS);
  va(7) := resize(m.raw,MCA_VALUE_BITS);
  va(8) := resize(m.cfd_high_threshold,MCA_VALUE_BITS);
  va(9) := resize(signed('0' & m.pulse_time(NOW)),MCA_VALUE_BITS);
  va(10) := resize(signed('0' & m.rise_timestamp),MCA_VALUE_BITS);
--  va(11) := resize(m.dot_product,MCA_VALUE_BITS);
  return va;
end function;


function get_mca_triggers(m:measurements_t) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
begin
  o(0):='1';
  o(1):=to_std_logic(m.p_t_p(NOW));
  o(2):=to_std_logic(m.p_t_n(NOW));
  o(3):=to_std_logic(m.s_t_p(NOW));
  o(4):=to_std_logic(m.f_0);
  o(5):=to_std_logic(m.s_0);
  o(6):=to_std_logic(m.min(NOW));
  o(7):=to_std_logic(m.max(NOW));
  o(8):=to_std_logic(m.cfd_high_p);
  o(9):=to_std_logic(m.cfd_low_p);
  o(10):=to_std_logic(m.max_slope_p);
 -- o(11):=dot product valid
  return o;
end function;

function get_mca_quals(m:measurements_t) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_QUAL_D-2 downto 0);
begin
  o(0):='1';
  o(1):=to_std_logic(m.valid_rise);
  o(2):=to_std_logic(m.above_area);
  o(3):=to_std_logic(m.above);
  o(4):=to_std_logic(m.will_cross);
  o(5):=to_std_logic(m.armed);
  o(6):=to_std_logic(m.will_arm);
  o(7):=to_std_logic(m.rise0);
  o(8):=to_std_logic(m.rise1);
  o(9):=to_std_logic(m.rise2);
  return o;
end function;

end package body measurements21;
