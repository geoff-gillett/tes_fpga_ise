--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:21 Jan 2016
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
--
library teslib;
use teslib.types.all;

library dsplib;
use dsplib.types.all;

library streamlib;
use streamlib.stream.all;

library eventlib;
use eventlib.events.all;

library adclib;
use adclib.types.all;

use work.registers.all;
use work.measurements.all;

entity measurement_unit is
generic(
	CHANNEL:integer:=0;
	FRAMER_ADDRESS_BITS:integer:=10
);
port (
  clk:in std_logic;
  reset:in std_logic;
  adc_sample:in adc_sample_t;
  
  registers:in measurement_registers;
  
  filter_config_data:in std_logic_vector(7 downto 0);
  filter_config_valid:in boolean;
  filter_config_ready:out boolean;
  filter_reload_data:in std_logic_vector(31 downto 0);
  filter_reload_valid:in boolean;
  filter_reload_ready:out boolean;
  filter_reload_last:in boolean;
  differentiator_config_data:in std_logic_vector(7 downto 0);
  differentiator_config_valid:in boolean;
  differentiator_config_ready:out boolean;
  differentiator_reload_data:in std_logic_vector(31 downto 0);
  differentiator_reload_valid:in boolean;
  differentiator_reload_ready:out boolean;
  differentiator_reload_last:in boolean;
  
  overflow:out boolean;
  time_overflow:out boolean;
  cfd_error:out boolean;
  
  measurements:out measurement_t;
  
  -- mux signals
  start:out boolean;
  commit:out boolean;
  dump:out boolean;
  
  eventstream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity measurement_unit;

architecture wrapper of measurement_unit is

signal filtered:signal_t;
signal peak:boolean;
signal peak_start:boolean;
signal pulse_pos_xing:boolean;
signal pulse_neg_xing:boolean;
signal cfd_low:boolean;
signal cfd_high:boolean;
signal cfd_error_int:boolean;
signal slope_area:area_t;
signal measurements_int:measurement_t;
signal commit_int:boolean;
	
begin

SignalProcessor:entity dsplib.dsp
generic map(
  WIDTH => DSP_BITS,
  FRAC => DSP_FRAC,
  TIME_BITS => TIME_BITS,
  TIME_FRAC => TIME_FRAC,
  BASELINE_BITS => BASELINE_BITS,
  BASELINE_COUNTER_BITS => BASELINE_COUNTER_BITS,
  BASELINE_TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  BASELINE_MAX_AVERAGE_ORDER => BASELINE_MAX_AV_ORDER,
  CFD_BITS => CFD_BITS,
  CFD_FRAC => CFD_FRAC
)
port map(
  clk => clk,
  reset => reset,
  adc_sample => adc_sample,
  adc_baseline => registers.dsp.baseline.offset,
  baseline_subtraction => registers.dsp.baseline.subtraction,
  baseline_timeconstant => registers.dsp.baseline.timeconstant,
  baseline_threshold => registers.dsp.baseline.threshold,
  baseline_count_threshold => registers.dsp.baseline.count_threshold,
  baseline_average_order => registers.dsp.baseline.average_order,
  filter_config_data => filter_config_data,
  filter_config_valid => filter_config_valid,
  filter_config_ready => filter_config_ready,
  filter_reload_data => filter_reload_data,
  filter_reload_valid => filter_reload_valid,
  filter_reload_ready=> filter_reload_ready,
  filter_reload_last => filter_reload_last,
  differentiator_config_data => differentiator_config_data,
  differentiator_config_valid => differentiator_config_valid,
  differentiator_config_ready => differentiator_config_ready,
  differentiator_reload_data => differentiator_reload_data,
  differentiator_reload_valid => differentiator_reload_valid,
  differentiator_reload_ready => differentiator_reload_ready,
  differentiator_reload_last => differentiator_reload_last,
  cfd_relative => registers.dsp.cfd_relative,
  constant_fraction => registers.dsp.constant_fraction,
  pulse_threshold => registers.dsp.pulse_threshold,
  slope_threshold => registers.dsp.slope_threshold,
  raw => measurements_int.raw_signal,
  raw_area => measurements_int.raw.area,
  raw_extrema => measurements_int.raw.extrema,
  raw_valid => measurements_int.raw.valid,
  filtered => filtered,
  filtered_area => measurements_int.filtered.area,
  filtered_extrema => measurements_int.filtered.extrema,
  filtered_valid => measurements_int.filtered.valid,
  slope => measurements_int.slope_signal,
  slope_area => slope_area,
  slope_extrema => measurements_int.slope.extrema,
  slope_valid => measurements_int.slope.valid,
  slope_threshold_xing => measurements_int.slope_xing,
  peak_start => peak_start,
  peak => peak,
  pulse_pos_xing => pulse_pos_xing,
  pulse_neg_xing => pulse_neg_xing,
  peak_minima => open,
  cfd_low => cfd_low,
  cfd_high => cfd_high,
  pulse_area => measurements_int.pulse.area,
  pulse_extrema => measurements_int.pulse.extrema,
  pulse_valid => measurements_int.pulse.valid,
  cfd_error => cfd_error_int,
  time_overflow => time_overflow
);

measurements <= measurements_int;
measurements_int.slope.area <= slope_area;
measurements_int.filtered_signal <= filtered;
measurements_int.filtered_xing <= pulse_pos_xing;
measurements_int.peak <= peak;
measurements_int.peak_start <= peak_start;
measurements_int.pulse_start <= pulse_pos_xing;
measurements_int.pulse_stop <= pulse_neg_xing;
measurements_int.height_valid <= commit_int;
measurements_int.cfd_high <= cfd_high;
measurements_int.cfd_low <= cfd_low;

commit <= commit_int;
cfd_error <= cfd_error_int;

framer:entity eventlib.event_framer
generic map(
  CHANNEL => CHANNEL,
  PEAK_COUNT_BITS => MAX_PEAK_COUNT_BITS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  BUS_CHUNKS => BUS_CHUNKS
)
port map(
  clk => clk,
  reset => reset,
  height_form => registers.capture.height_form,
  rel_to_min => registers.capture.rel_to_min,
  use_cfd_timing => registers.capture.use_cfd_timing,
  signal_in => filtered,
  peak => peak,
  peak_start => peak_start,
  overflow => overflow,
  pulse_pos_xing => pulse_pos_xing,
  pulse_neg_xing => pulse_neg_xing,
  cfd_low => cfd_low,
  cfd_high => cfd_high,
  cfd_error => cfd_error_int,
  slope_area => slope_area,
  enqueue => start,
  dump => dump,
  commit => commit_int,
  peak_count => measurements_int.peak_count, --valid when pulse_neg_xing
  height => measurements_int.height,
  eventstream => eventstream,
  valid => valid,
  ready => ready
);

end architecture wrapper;
