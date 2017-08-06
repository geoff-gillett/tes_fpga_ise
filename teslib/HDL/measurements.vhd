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
use work.events.all;
use work.registers.all;



package measurements is

--DEPTH of pipelines in the measurement record
constant MEASUREMENT_DEPTH:natural:=3;
constant NOW:natural:=MEASUREMENT_DEPTH; --value now
constant PRE:natural:=MEASUREMENT_DEPTH-1; --value 1 clk before
constant PRE2:natural:=MEASUREMENT_DEPTH-2; --value 2 clks before
constant PRE3:natural:=MEASUREMENT_DEPTH-3; --value 2 clks before

type creg_pipe is array (natural range <>) of capture_registers_t;
type u_chunk_pipe is array (natural range <>) of 
     unsigned(CHUNK_DATABITS-1 downto 0);
type s_chunk_pipe is array (natural range <>) of 
     signed(CHUNK_DATABITS-1 downto 0);
	
type measurements_t is record
	--register settings from CFD captured 4 clks prior to each pulse_start.
	--valid at pulse_start(PRE3)
	reg:creg_pipe(PRE to NOW); 
	--event_enabled captured 4 clks (PRE) and 1 clk (NOW) prior to pulse_start.
  enabled:boolean_vector(PRE to NOW);
  --the filtered signal
	f:signed(CHUNK_DATABITS-1 downto 0);
	--extreme value of f between zero crossings.
	f_extrema:signed(CHUNK_DATABITS-1 downto 0);	
	f_area:signed(2*CHUNK_DATABITS-1 downto 0);	
	--filtered signal zero crossing
	f_0,f_0_p,f_0_n:boolean;
  --pulse threshold crossings PRE2 is 2 clks before crossing
  p_t_p,p_t_n:boolean_vector(PRE2 to NOW);
	
	--the slope signal
  s:signed(CHUNK_DATABITS-1 downto 0);
	--extreme value of s between zero crossings.
	s_extrema:signed(CHUNK_DATABITS-1 downto 0);	
	--sum of s between zero crossings.
	s_area:signed(2*CHUNK_DATABITS-1 downto 0);	
	--slope signal zero crossing
	s_0:boolean;
  --slope	threshold rising PRE2 is 2 clks before crossing
  s_t_p:boolean_vector(PRE to NOW);
  
  --minima in f or s_0_p crossing, PRE is one clk before.
  min:boolean_vector(PRE to NOW);
  --max in f or s_0_n crossing, PRE is one clk before
  max:boolean_vector(PRE to NOW);
	
  --the raw baseline corrected signal
	raw:signed(CHUNK_DATABITS-1 downto 0);
		
  
  --size of event part size(PRE) is valid 1 clk before pulse start
--  size:size_pipe(2 to MEASUREMENT_DEPTH);
  --size of full event + event part, used when commit and new event simultaneous
  --size2(PRE) is valid one clk before pulse start
--  size2:size_pipe(2 to MEASUREMENT_DEPTH);
  --frame_length(PRE) is valid one clk before pulse start.
--  frame_length:frame_length_pipe(2 to MEASUREMENT_DEPTH);
  
--  dp_address:size_pipe(1 to MEASUREMENT_DEPTH);
  
  
  --valid rise with minima below pulse threshold PRE2 is 2 clks before
  pulse_start:boolean_vector(PRE2 to NOW); --min of valid first rise
  has_rise:boolean; --rise_number > 0 for this pulse
  
  --minima at start of a valid rise.
  rise_start:boolean_vector(PRE to NOW); 
  valid_rise:boolean; --rise_start to max; 
  rise0:boolean; --true (min and first_peak) to max
  rise1:boolean; --true (min and rise_number=1) to max
  rise2:boolean; --true (min and rise_number=2) to max
  --changes 1 clk after max
  rise_address:unsigned(PEAK_COUNT_BITS downto 0);
  last_peak_address:unsigned(PEAK_COUNT_BITS downto 0);
  
  last_rise:boolean; --this is the last rise that can be recorded
  rise_overflow:boolean; --more valid rises than could be counted
  --first rise is number 0 updates 1 clk after max
  rise_number:unsigned(PEAK_COUNT_BITS-1 downto 0); 
  
  --rise timing point PRE valid 1 clk before
	stamp_rise:boolean_vector(PRE to NOW); --rise timing point
	--this rise has been stamped PRE 
	rise_stamped:boolean_vector(PRE to NOW); 
  --pulse timing point
  stamp_pulse:boolean_vector(PRE to MEASUREMENT_DEPTH); 
  pulse_stamped:boolean_vector(PRE to NOW); 
  
	rise_time:u_chunk_pipe(PRE to NOW); 	--0 at rise timing point
	pulse_time:u_chunk_pipe(PRE to NOW); --0 at peak_start
	pulse_length:u_chunk_pipe(PRE to NOW); 	--0 at p_t_p 
	
	
  minima:s_chunk_pipe(PRE2 to NOW); --value of f at s_0_p
  height:s_chunk_pipe(PRE to NOW); --height measurement
  height_valid:boolean_vector(PRE to NOW); --measurement point 
  
	--maxima at end of a valid rise
  rise_stop:boolean_vector(PRE to NOW); 
  
	cfd_high:signed(CHUNK_DATABITS-1 downto 0); --threshold
	cfd_low:signed(CHUNK_DATABITS-1 downto 0); --threshold
	cfd_low_p:boolean; --crossing 
	cfd_high_p:boolean; --crossing
  max_slope_p:boolean; --crossing
  
	cfd_valid:boolean; --thresholds are valid
	cfd_error:boolean; --true @ min if not cfd_valid 
	cfd_overrun:boolean; --rise to long for correct CFD operation.
	
	--true from s_t_p to min inclusive
  armed:boolean;
  --true from min to max inclusive if s_t_p will occur in that interval 
  will_arm:boolean;
  --true when f is above pulse threshold
  above:boolean;
  --true min to max inclusive if f_t_p will occur during that interval
  will_cross:boolean;
	
	
	--baseline:signal_t;
  mux_wr_en:boolean;
	
  rise_timestamp:unsigned(15 downto 0);
	
  
  pulse_area:area_t;
  
  above_area:boolean;
  
  --slope_threshold_neg:boolean;
  
  
--  offset:unsigned(PEAK_COUNT_BITS-1 downto 0);
--  
--  time_offset:unsigned(15 downto 0); 
  
  
	
end record;

type measurements_array is array (natural range <>)
		 of measurements_t;

		 
	
function get_mca_values(m:measurements_t) return mca_value_array;
function get_mca_triggers(m:measurements_t) return std_logic_vector;
  
function get_mca_quals(m:measurements_t) return std_logic_vector;
end package measurements;

package body measurements is

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
  va(8) := resize(m.cfd_high,MCA_VALUE_BITS);
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

end package body measurements;
