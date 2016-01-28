--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: channel
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;

library eventlib;
use eventlib.events.all;

library adclib;
use adclib.types.all;

library dsplib;
use dsplib.types.all;

package channel is


type framer_registers is record
	height_form:height_form_t;
	rel_to_min:boolean;
	use_cfd_timing:boolean;
end record;	

constant BASELINE_BITS:integer:=10;
constant BASELINE_TIMECONSTANT_BITS:integer:=32;
constant BASELINE_COUNTER_BITS:integer:=18;
constant BASELINE_MAX_AV_ORDER:integer:=6;

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
	height_form:height_form_t;
	rel_to_min:boolean;
	use_cfd_timing:boolean;
end record;

type measurement_registers is record
	dsp:dsp_registers;
	capture:event_framer_registers;
end record;

type signal_measurements is record
	area:area_t;
	extrema:signal_t;
	valid:boolean;
end record;

type channel_measurements is record
	filtered_signal:signal_t;
	slope_signal:signal_t;
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
end record;

type measurement_register_array is array (natural range <>) 
		 of measurement_registers;
		 
type channel_measurement_array is array (natural range <>)
		 of channel_measurements;

end package channel;

package body channel is
	
end package body channel;
