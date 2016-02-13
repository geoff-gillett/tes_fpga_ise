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

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;

library adclib;
use adclib.types.all;

library dsplib;
use dsplib.types.all;

library eventlib;
use eventlib.events.all;

--use work.mca.mca_registers;
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
constant TICKPERIOD_BITS:integer:=32;
constant TICKPIPE_DEPTH:integer:=2;
constant RELATIVETIME_BITS:integer:=16;
constant MTU_BITS:integer:=16;
--constant MAX_TICKS_BITS:integer:=16;
constant TICK_LATENCY_BITS:integer:=32;
constant ETHERNET_FRAMER_ADDRESS_BITS:integer:=10;


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


type baseline_registers is record
	offset:adc_sample_t;
	subtraction:boolean;
	timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
	threshold:unsigned(BASELINE_BITS-2 downto 0);
	count_threshold:unsigned(BASELINE_COUNTER_BITS-1 downto 0);
	average_order:natural range 0 to BASELINE_MAX_AV_ORDER;
end record;

type dsp_registers is record
	baseline:baseline_registers;
	cfd_relative:boolean; -- cfd height is calculated relative to min
	constant_fraction:unsigned(CFD_BITS-2 downto 0);
	pulse_threshold:unsigned(DSP_BITS-2 downto 0);
	slope_threshold:unsigned(DSP_BITS-2 downto 0);
end record;

type event_framer_registers is record
	height_form:height_t;
	rel_to_min:boolean;
	timing_trigger:trigger_t;
	area_threshold:area_t;
end record;

type measurement_registers is record
	dsp:dsp_registers;
	capture:event_framer_registers;
end record;



type measurement_register_array is array (natural range <>) 
		 of measurement_registers;
		 
		 

--------------------------------------------------------------------------------
-- MCA Registers
--------------------------------------------------------------------------------

constant MCA_BIN_N_WIDTH:integer:=5;
constant MCA_TICKCOUNT_BITS:integer:=32;
constant MCA_ADDRESS_BITS:integer:=10;
constant MCA_COUNTER_BITS:integer:=32;
constant MCA_VALUE_BITS:integer:=32;
constant MCA_TOTAL_BITS:integer:=64;

type mca_value_array is array (natural range <>) 
												of signed(MCA_VALUE_BITS-1 downto 0);

-- NOTE selectors take a max of 12 inputs 
-- SEE teslib.select_1of12
type mca_values_t is (FILTERED, -- the output of the dsp filter
											FILTERED_AREA, -- the area between zero crossings
											FILTERED_EXTREMA, -- max or min between zero crossings
											SLOPE, -- the output of the dsp differentiator
											SLOPE_AREA,
											SLOPE_EXTREMA,
											PULSE_AREA, -- the area between threshold crossings
											PULSE_EXTREMA, -- the maximum between threshold xings
											RAW,
											RAW_AREA,
											RAW_EXTREMA,
											RISE_TIME);
											
constant MCA_VALUE_SELECT_BITS:integer:=mca_values_t'pos(mca_values_t'high)+1;

function to_onehot(v:mca_values_t) return std_logic_vector;
function to_values_t(i:natural range 0 to MCA_VALUE_SELECT_BITS-1) 
				 return mca_values_t;
function to_values_t(u:unsigned) return mca_values_t;
function to_unsigned(v:mca_values_t;w:natural) return unsigned;

--TODO check that 0xings are same as valids
type mca_triggers_t is (DISABLED,
									  		CLOCK,
									  		FILTERED_XING,
									  		FILTERED_0XING,
									  		SLOPE_0XING,
									  		SLOPE_XING,
									  		CFD_HIGH,
									  		CFD_LOW,
									  		PEAK,
									  		PEAK_START,
									  		RAW);
									  
constant MCA_TRIGGER_SELECT_BITS:integer
				 :=mca_triggers_t'pos(mca_triggers_t'high); 

function to_onehot(t:mca_triggers_t) return std_logic_vector;
function to_trigger_t(i:natural range 0 to MCA_TRIGGER_SELECT_BITS-1) 
				 return mca_triggers_t;
function to_trigger_t(u:unsigned) return mca_triggers_t;
function to_unsigned(t:mca_triggers_t;w:natural) return unsigned;
	
type mca_registers_t is record
	bin_n:unsigned(MCA_BIN_N_WIDTH-1 downto 0);
	lowest_value:signed(MCA_VALUE_BITS-1 downto 0);
	-- NOTE must be multiple of 2 LSB ignored
	last_bin:unsigned(MCA_ADDRESS_BITS-1 downto 0);
	ticks:unsigned(MCA_TICKCOUNT_BITS-1 downto 0);
	--tick_period:unsigned(TICK_PERIOD_WIDTH-1 downto 0);
	channel:unsigned(CHANNEL_WIDTH-1 downto 0);
	value:mca_values_t;
	trigger:mca_triggers_t;
end record;

end package registers;

package body registers is

-- mca_values_t functions ------------------------------------------------------
	
function to_onehot(v:mca_values_t) return std_logic_vector is
variable o:std_logic_vector(MCA_VALUE_SELECT_BITS-1 downto 0):=(others => '0');
begin
		o:=to_onehot(mca_values_t'pos(v),MCA_VALUE_SELECT_BITS);
	return o;
end function;

function to_values_t(i:natural range 0 to MCA_VALUE_SELECT_BITS-1) 
				 return mca_values_t is
begin
	return mca_values_t'val(i);
end function;
	
function to_values_t(u:unsigned) return mca_values_t is
begin
	return to_values_t(to_integer(u));
end function;
	
function to_unsigned(v:mca_values_t;w:natural) return unsigned is
begin
	return to_unsigned(mca_values_t'pos(v),w);
end function;
	
-- mca_triggers_t functions ----------------------------------------------------

function to_onehot(t:mca_triggers_t) return std_logic_vector is
variable o:std_logic_vector(MCA_TRIGGER_SELECT_BITS-1 downto 0)
					:=(others => '0');
begin
	if t/=DISABLED then
		o:=to_onehot(mca_triggers_t'pos(t)-1,MCA_TRIGGER_SELECT_BITS);
	end if;
	return o;
end function;

function to_trigger_t(i:natural range 0 to MCA_TRIGGER_SELECT_BITS-1) 
return mca_triggers_t is
begin
	return mca_triggers_t'val(i);
end function;

function to_trigger_t(u:unsigned) return mca_triggers_t is 
begin
	return to_trigger_t(to_integer(u));
end function;
	
function to_unsigned(t:mca_triggers_t;w:natural) return unsigned is
begin
	return to_unsigned(mca_triggers_t'pos(t),w);
end function;

end package body registers;
