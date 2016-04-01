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


type baseline_registers_t is record
	offset:adc_sample_t;
	subtraction:boolean;
	timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
	threshold:unsigned(BASELINE_BITS-2 downto 0);
	count_threshold:unsigned(BASELINE_COUNTER_BITS-1 downto 0);
	average_order:natural range 0 to BASELINE_MAX_AV_ORDER;
end record;

type capture_registers_t is record
	-- max peaks in pulse event 
	-- a value of zero means only record the initial peak
	-- maximum value is 2**PEAK_COUNT_WIDTH-1
	-- if max_peaks(PEAK_COUNT_WIDTH)='1' generate variable length events
	max_peaks:unsigned(PEAK_COUNT_WIDTH downto 0);
	-- cfd calculation is relative to the minima befere the peak
	-- if false calculation is relative to baseline
	cfd_rel2min:boolean; 
	constant_fraction:unsigned(CFD_BITS-2 downto 0);
	pulse_threshold:unsigned(DSP_BITS-2 downto 0);
	slope_threshold:unsigned(DSP_BITS-2 downto 0);
	pulse_area_threshold:area_t;
	height_type:height_d;
	-- the pulse threshold is relative to the minima, baseline if FALSE
	threshold_rel2min:boolean;
	height_rel2min:boolean;
	-- timing point
	trigger_type:timing_d;
	detection_type:detection_type_d;
	trace0_type:trace_type_d;
	trace1_type:trace_type_d;
end record;

type measurement_registers_t is record
	baseline:baseline_registers_t;
	capture:capture_registers_t;
end record;

type measurement_register_array is array (natural range <>) 
		 of measurement_registers_t;

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
--constant MCA_VALUE_SELECT_BITS:integer:=mca_value_d'pos(mca_value_d'high)+1;

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
  FILTERED_XING_MCA_TRIGGER, --FIXME this usefull?
  FILTERED_0XING_MCA_TRIGGER,
  SLOPE_0XING_MCA_TRIGGER,
  SLOPE_XING_MCA_TRIGGER,
  CFD_HIGH_MCA_TRIGGER,
  CFD_LOW_MCA_TRIGGER,
  MAXIMA_MCA_TRIGGER, -- peak
  MINIMA_MCA_TRIGGER, --peak start minima
  RAW_0XING_MCA_TRIGGER
);

constant NUM_MCA_TRIGGERS:integer:=mca_trigger_d'pos(mca_trigger_d'high)+1;
--constant MCA_TRIGGER_SELECT_BITS:integer:=NUM_MCA_TRIGGERS-1; --exclude disabled

function to_onehot(t:mca_trigger_d) return std_logic_vector;
function to_mca_trigger_d(i:natural range 0 to NUM_MCA_TRIGGERS-1) 
				 return mca_trigger_d;
function to_mca_trigger_d(u:unsigned) return mca_trigger_d;
function to_unsigned(t:mca_trigger_d;w:natural) return unsigned;
function to_std_logic(t:mca_trigger_d;w:natural) return std_logic_vector;
	
type mca_registers_t is record
	bin_n:unsigned(MCA_BIN_N_WIDTH-1 downto 0);
	lowest_value:signed(MCA_VALUE_BITS-1 downto 0);
	-- NOTE must be multiple of 2 LSB ignored
	last_bin:unsigned(MCA_ADDRESS_BITS-1 downto 0);
	ticks:unsigned(MCA_TICKCOUNT_BITS-1 downto 0);
	--tick_period:unsigned(TICK_PERIOD_WIDTH-1 downto 0);
	channel:unsigned(MCA_CHANNEL_WIDTH-1 downto 0);
	value:mca_value_d;
	trigger:mca_trigger_d;
end record;

end package registers;

package body registers is

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
