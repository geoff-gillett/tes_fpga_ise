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
use work.events.all;

--TODO move all registers here

package registers is
--------------------------------------------------------------------------------
-- NOTES
--------------------------------------------------------------------------------
-- _WIDTH is the width of the register in the IO protocol
-- _BITS is the internal implementation width

--------------------------------------------------------------------------------
-- Globals
--------------------------------------------------------------------------------

--constant CHANNEL_WIDTH:integer:=4;
--constant TICKPERIOD_BITS:integer:=32;
constant TICKPIPE_DEPTH:integer:=2;
constant RELATIVETIME_BITS:integer:=16;
constant MTU_BITS:integer:=16;
--constant MAX_TICKS_BITS:integer:=16;
constant TICK_LATENCY_BITS:integer:=32;
constant ETHERNET_FRAMER_ADDRESS_BITS:integer:=14;
constant DELAY_BITS:integer:=13;

--------------------------------------------------------------------------------
-- Default register values on reset
--------------------------------------------------------------------------------

constant DEFAULT_TICK_PERIOD:integer:=64;
constant DEFAULT_MCA_TICKS:integer:=1;
constant DEFAULT_MTU:integer:=1500;
constant DEFAULT_TICK_LATENCY:integer:=2*DEFAULT_TICK_PERIOD;

--------------------------------------------------------------------------------
-- Global registers
--------------------------------------------------------------------------------

type ethernet_registers_t is record
	-- MTU must be a multiple of 8
	mtu:unsigned(MTU_BITS-4 downto 0);
end record;

--------------------------------------------------------------------------------
-- Channel Registers
--------------------------------------------------------------------------------
constant BASELINE_BITS:integer:=10;
constant BASELINE_TIMECONSTANT_BITS:integer:=32;
constant BASELINE_COUNTER_BITS:integer:=18;
constant BASELINE_MAX_AV_ORDER:integer:=6;
constant MEASUREMENT_FRAMER_ADDRESS_BITS:integer:=10;


-- types
type baseline_registers_t is record
	offset:adc_sample_t;
	subtraction:boolean;
	timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
	threshold:unsigned(BASELINE_BITS-2 downto 0);
	count_threshold:unsigned(BASELINE_COUNTER_BITS-1 downto 0);
	average_order:natural range 0 to BASELINE_MAX_AV_ORDER;
end record;

type capture_registers_t is record
	-- max peaks in pulse event sets length of pulse event
	max_peaks:unsigned(PEAK_COUNT_WIDTH-1 downto 0);
	constant_fraction:unsigned(CFD_BITS-2 downto 0);
	pulse_threshold:unsigned(DSP_BITS-2 downto 0);
	slope_threshold:unsigned(DSP_BITS-2 downto 0);
	area_threshold:area_t;
	height:height_d;
	threshold_rel2min:boolean;
	cfd_rel2min:boolean; 
	height_rel2min:boolean;
	timing:timing_d;
	detection:detection_d;
	trace0:trace_d;
	trace1:trace_d;
	delay:unsigned(DELAY_BITS-1 downto 0);
end record;

type channel_registers_t is record
	baseline:baseline_registers_t;
	capture:capture_registers_t;
end record;

type channel_register_array is array (natural range <>) 
		 of channel_registers_t;
		 
-- ADDRESS MAP (one hot)
-- capture register 					address bit 0
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
-- baseline flags							address bit 10
-- reserved										address bit 11
--
-- 2  downto 0  baseline.average_order
-- 4 						baseline.subtraction 

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
constant RESERVED_ADDR_BIT:integer:=11;
-- FIR AXI streams
constant FILTER_CONFIG_ADDR_BIT:integer:=20;
constant FILTER_RELOAD_ADDR_BIT:integer:=21;
constant DIFFERENTIATOR_CONFIG_ADDR_BIT:integer:=22;
constant DIFFERENTIATOR_RELOAD_ADDR_BIT:integer:=23;

-- reset values
constant DEFAULT_DETECTION:detection_d:=PULSE_DETECTION_D;
constant DEFAULT_TIMING:timing_d:=CFD_LOW_TIMING_D;
constant DEFAULT_MAX_PEAKS:unsigned(PEAK_COUNT_WIDTH-1 downto 0)
				 :=(others => '0');
constant DEFAULT_HEIGHT:height_d:=PEAK_HEIGHT_D;
constant DEFAULT_TRACE0:trace_d:=NO_TRACE_D;
constant DEFAULT_TRACE1:trace_d:=NO_TRACE_D;
constant DEFAULT_CFD_REL2MIN:boolean:=TRUE;
constant DEFAULT_HEIGHT_REL2MIN:boolean:=TRUE;
constant DEFAULT_THRESHOLD_REL2MIN:boolean:=FALSE;
constant DEFAULT_PULSE_THRESHOLD:unsigned(DSP_BITS-2 downto 0)
				 :=to_unsigned(1000,DSP_BITS-DSP_FRAC-1) & to_unsigned(0,DSP_FRAC);
constant DEFAULT_SLOPE_THRESHOLD:unsigned(DSP_BITS-2 downto 0)
				 :=to_unsigned(1000,DSP_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
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
				 :=to_unsigned(150,BASELINE_COUNTER_BITS);
constant DEFAULT_BL_AVERAGE_ORDER:integer:=4;

function capture_register(r:channel_registers_t) return std_logic_vector;
function baseline_flags(r:channel_registers_t) return std_logic_vector;

--------------------------------------------------------------------------------
-- MCA Registers
--------------------------------------------------------------------------------

constant MCA_BIN_N_WIDTH:integer:=4;
constant MCA_CHANNEL_WIDTH:integer:=4;
constant MCA_TICKCOUNT_BITS:integer:=32;
constant MCA_ADDRESS_BITS:integer:=14;
constant MCA_COUNTER_BITS:integer:=32;
constant MCA_VALUE_BITS:integer:=32;
constant MCA_TOTAL_BITS:integer:=64;

type mca_value_array is array (natural range <>) 
												of signed(MCA_VALUE_BITS-1 downto 0);

-- NOTE selectors take a max of 12 inputs 
-- SEE teslib.select_1of12
type mca_value_d is (
	MCA_FILTERED_SIGNAL, -- the output of the dsp filter
  MCA_FILTERED_AREA, -- the area between zero crossings
  MCA_FILTERED_EXTREMA, -- max or min between zero crossings
  MCA_SLOPE_SIGNAL, -- the output of the dsp differentiator
  MCA_SLOPE_AREA,
  MCA_SLOPE_EXTREMA,
  MCA_PULSE_AREA, -- the area between threshold crossings
  MCA_PULSE_EXTREMA, -- the maximum between threshold xings
  MCA_PULSE_TIME,
  MCA_RAW_SIGNAL,
  MCA_RAW_AREA,
  MCA_RAW_EXTREMA
);

constant NUM_MCA_VALUES:integer:=mca_value_d'pos(mca_value_d'high)+1;										

function to_onehot(v:mca_value_d) return std_logic_vector;
function to_mca_value_d(i:natural range 0 to NUM_MCA_VALUES-1) 
				 return mca_value_d;
function to_mca_value_d(u:unsigned) return mca_value_d;
function to_unsigned(v:mca_value_d;w:natural) return unsigned;
function to_std_logic(v:mca_value_d;w:natural) return std_logic_vector;

--TODO check that 0xings are same as valids
type mca_trigger_d is (
	DISABLED_MCA_TRIGGER, -- no bits set
	CLOCK_MCA_TRIGGER,
  FILTERED_XING_MCA_TRIGGER, --FIXME this usefull? change to height?
  FILTERED_0XING_MCA_TRIGGER,
  SLOPE_0XING_MCA_TRIGGER,
  SLOPE_XING_MCA_TRIGGER,
  CFD_HIGH_MCA_TRIGGER,
  CFD_LOW_MCA_TRIGGER,
  MAXIMA_MCA_TRIGGER, -- peak
  MINIMA_MCA_TRIGGER, --peak start minima
  RAW_0XING_MCA_TRIGGER --TODO add minima or maxima
);

constant NUM_MCA_TRIGGERS:integer:=mca_trigger_d'pos(mca_trigger_d'high)+1;

function to_onehot(t:mca_trigger_d) return std_logic_vector;
function to_mca_trigger_d(i:natural range 0 to NUM_MCA_TRIGGERS-1) 
				 return mca_trigger_d;
function to_mca_trigger_d(u:unsigned) return mca_trigger_d;
function to_unsigned(t:mca_trigger_d;w:natural) return unsigned;
function to_std_logic(t:mca_trigger_d;w:natural) return std_logic_vector;
	
type mca_registers_t is record
	bin_n:unsigned(MCA_BIN_N_WIDTH-1 downto 0);
	lowest_value:signed(MCA_VALUE_BITS-1 downto 0);
	-- NOTE must be odd LSB set to 1 so there are an even number of bins
	last_bin:unsigned(MCA_ADDRESS_BITS-1 downto 0);
	ticks:unsigned(MCA_TICKCOUNT_BITS-1 downto 0);
	--tick_period:unsigned(TICK_PERIOD_WIDTH-1 downto 0);
	channel:unsigned(MCA_CHANNEL_WIDTH-1 downto 0);
	value:mca_value_d;
	trigger:mca_trigger_d;
end record;

end package registers;

package body registers is
-- AXI data made up of multiple registers

function capture_register(r:channel_registers_t) return std_logic_vector is
	variable s:std_logic_vector(AXI_DATA_BITS-1 downto 0):=(others => '0');
begin
	s(1 downto 0):=to_std_logic(r.capture.detection,2);
	s(3 downto 2):=to_std_logic(r.capture.timing,2);
	s(7 downto 4):=to_std_logic(r.capture.max_peaks);
	s(9 downto 8):=to_std_logic(r.capture.height,2);
	s(11 downto 10):=to_std_logic(r.capture.trace0,2);
	s(13 downto 12):=to_std_logic(r.capture.trace1,2);
	s(14):=to_std_logic(r.capture.cfd_rel2min);
	s(15):=to_std_logic(r.capture.height_rel2min);
	s(16):=to_std_logic(r.capture.threshold_rel2min);
	return s;
end function; 

function baseline_flags(r:channel_registers_t) return std_logic_vector is
	variable s:std_logic_vector(AXI_DATA_BITS-1 downto 0):=(others => '0');
begin
	s(2 downto 0) := to_std_logic(r.baseline.average_order,3);
	s(4) := to_std_logic(r.baseline.subtraction);
	return s;
end function;
-- mca_values_t functions ------------------------------------------------------
	
function to_onehot(v:mca_value_d) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_VALUES-1 downto 0):=(others => '0');
begin
		o:=to_onehot(mca_value_d'pos(v),NUM_MCA_VALUES);
	return o;
end function;

function to_mca_value_d(i:natural range 0 to NUM_MCA_VALUES-1) 
				 return mca_value_d is
begin
	return mca_value_d'val(i);
end function;
	
function to_mca_value_d(u:unsigned) return mca_value_d is
begin
	return to_mca_value_d(to_integer(u));
end function;
	
function to_unsigned(v:mca_value_d;w:natural) return unsigned is
begin
	return to_unsigned(mca_value_d'pos(v),w);
end function;

function to_std_logic(v:mca_value_d;w:natural) return std_logic_vector is
begin
	return std_logic_vector(to_unsigned(mca_value_d'pos(v),w));
end function;
	
-- mca_triggers_t functions ----------------------------------------------------

function to_onehot(t:mca_trigger_d) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_TRIGGERS-2 downto 0):=(others => '0');
begin
	if t/=DISABLED_MCA_TRIGGER then
		o:=to_onehot(mca_trigger_d'pos(t)-1,NUM_MCA_TRIGGERS-1);
	end if;
	return o;
end function;

function to_mca_trigger_d(i:natural range 0 to NUM_MCA_TRIGGERS-1) 
return mca_trigger_d is
begin
	return mca_trigger_d'val(i);
end function;

function to_mca_trigger_d(u:unsigned) return mca_trigger_d is 
begin
	return to_mca_trigger_d(to_integer(u));
end function;
	
function to_unsigned(t:mca_trigger_d;w:natural) return unsigned is
begin
	return to_unsigned(mca_trigger_d'pos(t),w);
end function;

function to_std_logic(t:mca_trigger_d;w:natural) return std_logic_vector is
begin
	return std_logic_vector(to_unsigned(mca_trigger_d'pos(t),w));
end function;

end package body registers;
