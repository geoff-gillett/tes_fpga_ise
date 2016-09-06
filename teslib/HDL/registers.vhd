--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: registers
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.adc.all;
use work.dsptypes.all;
use work.types.all;
use work.functions.all;
--use work.events.all;

--TODO move all registers here

package registers is

-- hardware parameters
--constant CHANNEL_BITS:integer:=3;

-- field sizes
constant BASELINE_BITS:integer:=10;
constant BASELINE_TIMECONSTANT_BITS:integer:=32;
constant BASELINE_COUNTER_BITS:integer:=18;
constant BASELINE_MAX_AV_ORDER:integer:=6;
constant MEASUREMENT_FRAMER_ADDRESS_BITS:integer:=10;
constant DELAY_BITS:integer:=13;
constant PEAK_COUNT_BITS:integer:=4;

constant MCA_BIN_N_BITS:integer:=5;
constant MCA_CHANNEL_WIDTH:integer:=3;
constant MCA_TICKCOUNT_BITS:integer:=32;
constant MCA_ADDRESS_BITS:integer:=14;
constant MCA_COUNTER_BITS:integer:=32;
constant MCA_VALUE_BITS:integer:=32;
constant MCA_TOTAL_BITS:integer:=64;

constant TICKPIPE_DEPTH:integer:=2;
constant RELATIVETIME_BITS:integer:=16;
constant MTU_BITS:integer:=16;
constant TICK_PERIOD_BITS:integer:=32;
constant MIN_TICK_PERIOD:integer:=2**16;
constant TICK_LATENCY_BITS:integer:=32;
constant ETHERNET_FRAMER_ADDRESS_BITS:integer:=12;
constant IODELAY_CONTROL_BITS:integer:=ADC_BITS+ADC_CHANNELS+2*ADC_CHIPS;

-- Discrete Types --------------------------------------------------------------

-- type of detection
type detection_d is (
	PEAK_DETECTION_D,
	AREA_DETECTION_D,
	PULSE_DETECTION_D, --use fixed flag to indicate fixed/variable length
	TRACE_DETECTION_D
);

constant NUM_DETECTION_D:integer:=detection_d'pos(detection_d'high)+1;
constant DETECTION_D_BITS:integer:=ceilLog2(NUM_DETECTION_D);
function to_std_logic(d:detection_d;w:integer) return std_logic_vector;
function to_detection_d(s:std_logic_vector) return detection_d;
function to_detection_d(i:natural range 0 to NUM_DETECTION_D-1) 
return detection_d;

-- the point the relative time-stamp is taken
-- FIXME would be nice to add slope extrema
type timing_d is (
	PULSE_THRESH_TIMING_D,
	SLOPE_THRESH_TIMING_D,
	CFD_LOW_TIMING_D,
	RISE_START_TIMING_D
);

constant NUM_TIMING_D:integer:=timing_d'pos(timing_d'high)+1;
constant TIMING_D_BITS:integer:=ceilLog2(NUM_TIMING_D);
function to_std_logic(t:timing_d;w:integer) return std_logic_vector;
function to_timing_d(i:natural range 0 to NUM_TIMING_D-1) return timing_d;
function to_timing_d(s:std_logic_vector) return timing_d;

--TODO add CFD_LOW?	or extrema?
type height_d is (
	PEAK_HEIGHT_D,
	CFD_HEIGHT_D,
	SLOPE_INTEGRAL_D
);

constant NUM_HEIGHT_D:integer:=height_d'pos(height_d'high)+1;
constant HEIGHT_D_BITS:integer:=ceilLog2(NUM_HEIGHT_D);
function to_std_logic(h:height_d;w:integer) return std_logic_vector;
function to_height_d(s:std_logic_vector) return height_d;
function to_height_d(i:natural range 0 to NUM_HEIGHT_D-1) return height_d;

type trace_d is(
	NO_TRACE_D,
	RAW_TRACE_D,
	FILTERED_TRACE_D,
	SLOPE_TRACE_D
);

constant NUM_TRACE_D:integer:=trace_d'pos(trace_d'high)+1;
constant TRACE_D_BITS:integer:=ceilLog2(NUM_TRACE_D);
function to_std_logic(t:trace_d;w:integer) return std_logic_vector;
function to_trace_d(s:std_logic_vector) return trace_d;
function to_trace_d(i:natural range 0 to NUM_TRACE_D-1) return trace_d;

-- the value sampled into the MCA
type mca_value_d is (
	MCA_FILTERED_SIGNAL_D, -- the output of the dsp filter
  MCA_FILTERED_AREA_D, -- the area between zero crossings
  MCA_FILTERED_EXTREMA_D, -- max or min between zero crossings
  MCA_SLOPE_SIGNAL_D, -- the output of the dsp differentiator
  MCA_SLOPE_AREA_D,
  MCA_SLOPE_EXTREMA_D,
  MCA_PULSE_AREA_D, -- the area between threshold crossings
  MCA_PULSE_EXTREMA_D, -- the maximum between threshold xings
  MCA_PULSE_TIME_D, -- make this start at minima
  MCA_RAW_SIGNAL_D,
  MCA_RAW_AREA_D,
  MCA_RAW_EXTREMA_D
);

constant NUM_MCA_VALUE_D:integer:=mca_value_d'pos(mca_value_d'high)+1;										
constant MCA_VALUE_D_BITS:integer:=ceilLog2(NUM_MCA_VALUE_D);
function to_onehot(v:mca_value_d) return std_logic_vector;
function to_mca_value_d(i:natural range 0 to NUM_MCA_VALUE_D-1) 
				 return mca_value_d;
function to_mca_value_d(s:std_logic_vector) return mca_value_d;
function to_std_logic(v:mca_value_d;w:natural) return std_logic_vector;

-- the trigger that samples a value into the MCA
type mca_trigger_d is (
	DISABLED_MCA_TRIGGER_D, -- no select bits set
	CLOCK_MCA_TRIGGER_D,
  FILTERED_XING_MCA_TRIGGER_D, --FIXME this usefull? change to height?
  FILTERED_0XING_MCA_TRIGGER_D,
  SLOPE_0XING_MCA_TRIGGER_D,
  SLOPE_XING_MCA_TRIGGER_D,
  CFD_HIGH_MCA_TRIGGER_D,
  CFD_LOW_MCA_TRIGGER_D,
  MAXIMA_MCA_TRIGGER_D, -- peak
  MINIMA_MCA_TRIGGER_D, --peak start minima
  RAW_0XING_MCA_TRIGGER_D 
  --TODO add minima or maxima
  -- there are two slots left
);
-- FIXME need trigger for pulse area FILTERED_NEG_XING
-- 

constant NUM_MCA_TRIGGER_D:integer:=mca_trigger_d'pos(mca_trigger_d'high)+1;
constant MCA_TRIGGER_D_BITS:integer:=ceilLog2(NUM_MCA_TRIGGER_D);
function to_onehot(t:mca_trigger_d) return std_logic_vector;
function to_mca_trigger_d(i:natural range 0 to NUM_MCA_TRIGGER_D-1) 
return mca_trigger_d;
function to_mca_trigger_d(s:std_logic_vector) return mca_trigger_d;
function to_std_logic(t:mca_trigger_d;w:natural) return std_logic_vector;
	
--------------------------------------------------------------------------------
-- Channel Registers
--------------------------------------------------------------------------------
type baseline_registers_t is record
	offset:adc_sample_t;
	subtraction:boolean;
	timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
	threshold:unsigned(BASELINE_BITS-2 downto 0);
	count_threshold:unsigned(BASELINE_COUNTER_BITS-1 downto 0);
	average_order:natural range 0 to BASELINE_MAX_AV_ORDER;
end record;

type capture_registers_t is record
	-- sets length of pulse event
	max_peaks:unsigned(PEAK_COUNT_BITS-1 downto 0);
	constant_fraction:unsigned(CFD_BITS-2 downto 0);
	pulse_threshold:unsigned(DSP_BITS-2 downto 0);
	slope_threshold:unsigned(DSP_BITS-2 downto 0);
	area_threshold:area_t;
	height:height_d;
	threshold_rel2min:boolean;
	rel2min:boolean; 
	timing:timing_d;
	detection:detection_d;
	full_trace:boolean;
	trace0:trace_d;
	trace1:trace_d;
	delay:unsigned(DELAY_BITS-1 downto 0);
	adc_select:std_logic_vector(CHANNELS-1 downto 0);
	invert:boolean;
end record;

type channel_registers_t is record
	baseline:baseline_registers_t;
	capture:capture_registers_t;
end record;

-- TODO implement
-- idea is to be able to filter output based on the upper and lower values
type event_filter is record
	area_u:area_t; 
	area_l:area_t;
	peak_count_u:unsigned(PEAK_COUNT_BITS-1 downto 0);
	peak_count_l:unsigned(PEAK_COUNT_BITS-1 downto 0);
	height_peak:unsigned(PEAK_COUNT_BITS-1 downto 0);
	use_height_peak:boolean;
	height_u:signal_t;
	height_l:signal_t;
end record;

type channel_register_array is array (natural range <>) 
		 of channel_registers_t;
		 
-- ADDRESS MAP (one hot)
-- cpu_version                address 0  READ ONLY (no bits set)
-- capture control register 	address bit 0
--
-- 1  downto 0  detection
-- 3  downto 2  timing
-- 7  downto 4  max_peaks
-- 9  downto 8  height
-- 11 downto 10 trace0
-- 13 downto 12 trace1
-- 14           cfd_rel2min
-- 15           height_rel2min
-- 16           threshold_rel2min
--
-- pulse_threshold 						address bit 1
-- slope_threshold 						address bit 2
-- constant_fraction 					address bit 3
-- pulse_area_threshold				address bit 4
-- delay											address bit 5
-- baseline.offset   					address bit 6				
-- baseline.timeconstant  		address bit 7				
-- baseline.threshold		  		address bit 8
-- baseline.count_threshold		address bit 9
-- baseline.flags							address bit 10
-- 2  downto 0  baseline.average_order
-- 4 						baseline.subtraction 
--
-- input select								address bit 11  

-- One-hot addresses
constant CAPTURE_ADDR_BIT:integer:=0;
constant PULSE_THRESHOLD_ADDR_BIT:integer:=1;
constant SLOPE_THRESHOLD_ADDR_BIT:integer:=2;
constant CONSTANT_FRACTION_ADDR_BIT:integer:=3;
constant AREA_THRESHOLD_ADDR_BIT:integer:=4;
constant DELAY_ADDR_BIT:integer:=5;
constant BL_OFFSET_ADDR_BIT:integer:=6;
constant BL_TIMECONSTANT_ADDR_BIT:integer:=7;
constant BL_THRESHOLD_ADDR_BIT:integer:=8;
constant BL_COUNT_THRESHOLD_ADDR_BIT:integer:=9;
constant BL_FLAGS_ADDR_BIT:integer:=10;
constant INPUT_SEL_ADDR_BIT:integer:=11;

-- FIR AXI streams
constant FILTER_CONFIG_ADDR_BIT:integer:=20;
constant FILTER_RELOAD_ADDR_BIT:integer:=21;
constant DIFFERENTIATOR_CONFIG_ADDR_BIT:integer:=22;
constant DIFFERENTIATOR_RELOAD_ADDR_BIT:integer:=23;

-- reset values
constant DEFAULT_DETECTION:detection_d:=PEAK_DETECTION_D;
constant DEFAULT_TIMING:timing_d:=CFD_LOW_TIMING_D;
constant DEFAULT_MAX_PEAKS:unsigned(PEAK_COUNT_BITS-1 downto 0)
				 :=(others => '0');
constant DEFAULT_HEIGHT:height_d:=PEAK_HEIGHT_D;
constant DEFAULT_TRACE0:trace_d:=NO_TRACE_D;
constant DEFAULT_TRACE1:trace_d:=NO_TRACE_D;
constant DEFAULT_CFD_REL2MIN:boolean:=TRUE;
constant DEFAULT_HEIGHT_REL2MIN:boolean:=TRUE;
constant DEFAULT_THRESHOLD_REL2MIN:boolean:=FALSE;
constant DEFAULT_PULSE_THRESHOLD:unsigned(DSP_BITS-2 downto 0)
				 :=to_unsigned(500,DSP_BITS-DSP_FRAC-1) & to_unsigned(0,DSP_FRAC);
constant DEFAULT_SLOPE_THRESHOLD:unsigned(DSP_BITS-2 downto 0)
				 :=to_unsigned(2,DSP_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
constant DEFAULT_CONSTANT_FRACTION:unsigned(CFD_BITS-2 downto 0)
				 :=to_unsigned((2**(CFD_BITS-1))/5,CFD_BITS-1); --20%
constant DEFAULT_AREA_THRESHOLD:area_t:=to_signed(10000,AREA_BITS);
constant DEFAULT_DELAY:unsigned(DELAY_BITS-1 downto 0)
         :=to_unsigned(2**(DELAY_BITS-1),DELAY_BITS);
constant DEFAULT_BL_OFFSET:adc_sample_t
         :=std_logic_vector(to_unsigned(260,ADC_BITS));
constant DEFAULT_BL_SUBTRACTION:boolean:=TRUE;
constant DEFAULT_BL_TIMECONSTANT:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0)
				 :=to_unsigned(2**16,BASELINE_TIMECONSTANT_BITS);
constant DEFAULT_BL_THRESHOLD:unsigned(BASELINE_BITS-2 downto 0)
				 :=to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
constant DEFAULT_BL_COUNT_THRESHOLD:unsigned(BASELINE_COUNTER_BITS-1 downto 0)
				 :=to_unsigned(40,BASELINE_COUNTER_BITS);
constant DEFAULT_BL_AVERAGE_ORDER:integer:=4;

function capture_register(r:capture_registers_t) return std_logic_vector;
function baseline_flags(r:baseline_registers_t) return std_logic_vector;

--------------------------------------------------------------------------------
-- Global registers
--------------------------------------------------------------------------------

-- MCA registers ---------------------------------------------------------------


type mca_value_array is array (natural range <>) 
												of signed(MCA_VALUE_BITS-1 downto 0);

-- NOTE selectors take a max of 12 inputs 
-- SEE teslib.select_1of12

--TODO check that 0xings are same as valids
	
type mca_registers_t is record
	bin_n:unsigned(MCA_BIN_N_BITS-1 downto 0); -- FIXME this should be 5 bits
	lowest_value:signed(MCA_VALUE_BITS-1 downto 0);
	-- NOTE must be odd LSB set to 1 so there are an even number of bins
	last_bin:unsigned(MCA_ADDRESS_BITS-1 downto 0);
	ticks:unsigned(MCA_TICKCOUNT_BITS-1 downto 0);
	channel:unsigned(MCA_CHANNEL_WIDTH-1 downto 0);
	value:mca_value_d;
	trigger:mca_trigger_d;
	update_asap:boolean;
	update_on_completion:boolean;
	--iodelay_control:std_logic_vector(IODELAY_CONTROL_BITS-1 downto 0);
end record;

-- Other global registers ------------------------------------------------------



-- Types -----------------------------------------------------------------------

type global_registers_t is record
	-- MTU must be a multiple of 8
	mtu:unsigned(MTU_BITS-1 downto 0);
	tick_period:unsigned(TICK_PERIOD_BITS-1 downto 0);
	tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
	adc_enable:std_logic_vector(ADC_CHANNELS-1 downto 0);
	channel_enable:std_logic_vector(CHANNELS-1 downto 0);
	mca:mca_registers_t;
	iodelay_control:std_logic_vector(IODELAY_CONTROL_BITS-1 downto 0);
	window:unsigned(TIME_BITS-1 downto 0);
	FMC108_internal_clk:boolean;
	VCO_power:boolean;
end record;

-- ADDRESS MAP (one hot)
-- IO_controler version							address 0      implemented in CPU READ ONLY
-- Features 											 	address bit 23 implemented in CPU READ ONLY
-- HDL version										 	address bit 0   READ ONLY
--
-- Readable registers use lowest 12 bits to simplify read mux (select1of12)
-- MCA control register            	address bit 1
-- 		3  downto 0  	value
-- 		7  downto 4  	trigger
-- 		10 downto 8  	channel	       
-- 		15 downto 11 	bin_n
-- 		31 downto 16 	last_bin
-- 
-- mca.lowest_value               	address bit 2
-- mca.ticks                        address bit 3
-- MTU															address bit 4
-- tick_period											address bit 5
-- tick_latency											address bit 6
-- adc_enable												address bit 7
-- channel_enable										address bit 8
--
-- flags     												address bit 9
--		0	fmc108 internal clk enable
--    1  VCO power enable
-- window														address bit 10
-- RESERVED													address bit 11 
--
-- write only strobe registers 
--
-- iodelay_control                  address bit 12 WRITE ONLY
--		16 downto 14		channel				TODO describe how iodelay works
--		13 downto 8			inc delay
--		7  downto 0			dec delay
--
-- MCA update flags register        address bit 13 WRITE ONLY
--    0	update_on_completion
-- 		1 update_asap

-- fir configuration
type fir_control_in_t is record
  config_data:std_logic_vector(7 downto 0);
  config_valid:std_logic;
  reload_data:std_logic_vector(31 downto 0);
  reload_valid:std_logic;
  reload_last:std_logic;
end record;

type fir_control_out_t is record
  config_ready:std_logic;
  reload_ready:std_logic;
	reload_last_missing:std_logic;
 	reload_last_unexpected:std_logic;
end record;

constant HDL_VERSION_ADDR_BIT:integer:=0;
constant MCA_CONTROL_REGISTER_ADDR_BIT:integer:=1;
constant MCA_LOWEST_VALUE_ADDR_BIT:integer:=2;
constant MCA_TICKS_ADDR_BIT:integer:=3;
constant MTU_ADDR_BIT:integer:=4;
constant TICK_PERIOD_ADDR_BIT:integer:=5;
constant TICK_LATENCY_ADDR_BIT:integer:=6;
constant ADC_ENABLE_ADDR_BIT:integer:=7;
constant CHANNEL_ENABLE_ADDR_BIT:integer:=8;
constant FLAGS_ADDR_BIT:integer:=9;
constant WINDOW_ADDR_BIT:integer:=10;

constant IODELAY_CONTROL_ADDR_BIT:integer:=12;
constant MCA_UPDATE_ADDR_BIT:integer:=13;
-- control flags
constant NUM_CTL_FLAGS:integer:=2; 
constant CTL_FMC108_INTERNAL_CLK_BIT:integer:=0;
constant CTL_VCO_POWER_BIT:integer:=1;
constant CTL_MMCM_LOCKED_BIT:integer:=2;
--MCA flags
constant MCA_UPDATE_ON_COMPLETION_BIT:integer:=0;
constant MCA_UPDATE_ASAP:integer:=1;

function mca_control_register(m:mca_registers_t) return register_data_t;

-- Default register values on reset --------------------------------------------
constant DEFAULT_TICK_PERIOD_INT:integer:=25000000;
constant DEFAULT_TICK_PERIOD:unsigned(TICK_PERIOD_BITS-1 downto 0)
				 :=to_unsigned(DEFAULT_TICK_PERIOD_INT,TICK_PERIOD_BITS);
constant DEFAULT_MTU:unsigned(MTU_BITS-1 downto 0):=to_unsigned(1496,MTU_BITS);
constant DEFAULT_TICK_LATENCY:unsigned(TICK_LATENCY_BITS-1 downto 0)
				 :=to_unsigned(2*DEFAULT_TICK_PERIOD_INT,TICK_LATENCY_BITS);
constant DEFAULT_MCA_TICKS:unsigned(MCA_TICKCOUNT_BITS-1 downto 0)
				 :=to_unsigned(1,MCA_TICKCOUNT_BITS);
constant DEFAULT_MCA_BIN_N:unsigned(MCA_BIN_N_BITS-1 downto 0)
				 :=to_unsigned(0,MCA_BIN_N_BITS);
constant DEFAULT_MCA_LAST_BIN:unsigned(MCA_ADDRESS_BITS-1 downto 0)
				 :=to_unsigned(2**MCA_ADDRESS_BITS-1,MCA_ADDRESS_BITS);
constant DEFAULT_MCA_TRIGGER:mca_trigger_d:=DISABLED_MCA_TRIGGER_D;
constant DEFAULT_MCA_VALUE:mca_value_d:=MCA_FILTERED_SIGNAL_D;
constant DEFAULT_MCA_LOWEST_VALUE:signed(MCA_VALUE_BITS-1 downto 0)
				 :=to_signed(-1000,MCA_VALUE_BITS);

end package registers;

--------------------------------------------------------------------------------

package body registers is

-- discrete type conversion functions ------------------------------------------

-- height_d
function to_std_logic(h:height_d;w:integer) return std_logic_vector is
begin
	if w < HEIGHT_D_BITS then
		assert FALSE report "w to small to represent height_d" severity ERROR;
	end if;
	return to_std_logic(height_d'pos(h),w);
end function;

function to_height_d(i:natural range 0 to NUM_HEIGHT_D-1) return height_d is
begin
	return height_d'val(i);
end function;

function to_height_d(s:std_logic_vector) return height_d is
begin
	return to_height_d(to_integer(unsigned(s)));
end function;

-- timing_d
function to_std_logic(t:timing_d;w:integer) return std_logic_vector is
begin
	if w < TIMING_D_BITS then
		assert FALSE report "w to small to represent timing_d" severity ERROR;
	end if;
	return to_std_logic(timing_d'pos(t),w);
end function;

function to_timing_d(i:natural range 0 to NUM_TIMING_D-1) 
return timing_d is
begin
	return timing_d'val(i);
end function;

function to_timing_d(s:std_logic_vector) return timing_d is
begin
	return to_timing_d(to_integer(unsigned(s)));
end function;

-- detection_d
function to_std_logic(d:detection_d;w:integer) return std_logic_vector is
begin
	if w < DETECTION_D_BITS then
		assert FALSE report "w to small to represent detection_d" severity ERROR;
	end if;
	return to_std_logic(detection_d'pos(d),w);
end function;

function to_detection_d(i:natural range 0 to NUM_DETECTION_D-1) 
return detection_d is
begin
	return detection_d'val(i);
end function;

function to_detection_d(s:std_logic_vector) return detection_d is
begin
	return to_detection_d(to_integer(unsigned(s)));
end function;

-- trace_d
function to_std_logic(t:trace_d;w:integer) return std_logic_vector is
begin
	if w < TRACE_D_BITS then
		assert FALSE report "w to small to represent trace_d" severity ERROR;
	end if;
	return to_std_logic(trace_d'pos(t),w);
end function;

function to_trace_d(i:natural range 0 to NUM_TRACE_D-1) return trace_d is
begin
	return trace_d'val(i);
end function;

function to_trace_d(s:std_logic_vector) return trace_d is
begin
	return to_trace_d(to_integer(unsigned(s)));
end function;

-- mca_triggers_d 
function to_std_logic(t:mca_trigger_d;w:natural) return std_logic_vector is
begin
	if w < MCA_TRIGGER_D_BITS then
		assert FALSE report "w to small to represent height_d" severity ERROR;
	end if;
	return to_std_logic(mca_trigger_d'pos(t),w);
end function;

function to_mca_trigger_d(i:natural range 0 to NUM_MCA_TRIGGER_D-1) 
return mca_trigger_d is
begin
	return mca_trigger_d'val(i);
end function;

function to_mca_trigger_d(s:std_logic_vector) return mca_trigger_d is
begin
	return to_mca_trigger_d(to_integer(unsigned(s)));
end function;
--FIXME check the one hot synthesises well
function to_onehot(t:mca_trigger_d) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0):=(others => '0');
begin
	if t/=DISABLED_MCA_TRIGGER_D then
		o(mca_trigger_d'pos(t)-1) := '1';
	end if;
	return o;
end function;

-- mca_values_d
function to_std_logic(v:mca_value_d;w:natural) return std_logic_vector is
begin
	if w < MCA_VALUE_D_BITS then
		assert FALSE report "w to small to represent mca_value_d" severity ERROR;
	end if;
	return to_std_logic(mca_value_d'pos(v),w);
end function;

function to_mca_value_d(i:natural range 0 to NUM_MCA_VALUE_D-1) 
				 return mca_value_d is
begin
	return mca_value_d'val(i);
end function;
	
function to_mca_value_d(s:std_logic_vector) return mca_value_d is
begin
	return to_mca_value_d(to_integer(unsigned(s)));
end function;

function to_onehot(v:mca_value_d) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0):=(others => '0');
begin
		o(mca_value_d'pos(v)) := '1';
	return o;
end function;

--------------------------------------------------------------------------------
-- MCA register functions 
--------------------------------------------------------------------------------

function capture_register(r:capture_registers_t) return std_logic_vector is
	variable s:std_logic_vector(AXI_DATA_BITS-1 downto 0):=(others => '0');
begin
	s(1 downto 0):=to_std_logic(r.detection,2);
	s(3 downto 2):=to_std_logic(r.timing,2);
	s(7 downto 4):=to_std_logic(r.max_peaks);
	s(9 downto 8):=to_std_logic(r.height,2);
	s(11 downto 10):=to_std_logic(r.trace0,2);
	s(13 downto 12):=to_std_logic(r.trace1,2);
	s(14):=to_std_logic(r.rel2min);
	s(15):=to_std_logic(r.rel2min);
	s(16):=to_std_logic(r.threshold_rel2min);
	return s;
end function; 

function baseline_flags(r:baseline_registers_t) return std_logic_vector is
	variable s:std_logic_vector(AXI_DATA_BITS-1 downto 0):=(others => '0');
begin
	s(2 downto 0) := to_std_logic(r.average_order,3);
	s(4) := to_std_logic(r.subtraction);
	return s;
end function;

function mca_control_register(m:mca_registers_t) return register_data_t is
	variable d:register_data_t;
begin
	d(3 downto 0) := to_std_logic(m.value,4);
	d(7 downto 4) := to_std_logic(m.trigger,4);
	d(10 downto 8) := to_std_logic(m.channel);
	d(15 downto 11) := to_std_logic(m.bin_n);
	d(29 downto 16) := to_std_logic(m.last_bin);
	return d;
end function;

-- mca_values_t functions ------------------------------------------------------
-- FIXME does this one hot function synthesise well

	
--function to_unsigned(v:mca_value_d;w:natural) return unsigned is
--begin
--	return to_unsigned(mca_value_d'pos(v),w);
--end function;
--
--function to_std_logic(v:mca_value_d;w:natural) return std_logic_vector is
--begin
--	return std_logic_vector(to_unsigned(mca_value_d'pos(v),w));
--end function;
	

end package body registers;
