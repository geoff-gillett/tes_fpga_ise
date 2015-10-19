--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:13/05/2014 
--
-- Design Name: TES_digitiser
-- Module Name: signal_pipeline
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
use teslib.functions.all;

library streamlib;
use streamlib.types.all;

library controllerlib;
--
library dsplib;
--
entity channel_pipeline is
generic(
  ADC_BITS:integer:=14;
  AREA_BITS:integer:=26;
  TIME_BITS:integer:=14;
  ------------------------------------------------------------------------------
  -- Signal path parameters
  ------------------------------------------------------------------------------
  CHANNEL_NUMBER:integer:=1;
  DELAY_BITS:integer:=10;
  SLOPE_ADDRESS_BITS:integer:=6;
  SYNC_ADDRESS_BITS:integer:=6;
  SIGNAL_AV_BITS:integer:=6;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_AV_BITS:integer:=10;
  BASELINE_MCA_COUNTER_BITS:integer:=18;
  MAX_PEAKS:integer:=4;
  ENDIANNESS:string:="LITTLE";
  ------------------------------------------------------------------------------
  -- Register defaults
  ------------------------------------------------------------------------------
  DEFAULT_DELAY:integer:=0;
  DEFAULT_SIGNAL_AVN:integer:=5;
  DEFAULT_SLOPE_N:integer:=3;
  DEFAULT_SYNC_CLKS:integer:=4;
  DEFAULT_BASELINE_TIMECONSTANT:integer:=0;
  DEFAULT_FIXED_BASELINE:integer:=8192;
  DEFAULT_BASELINE_AVN:integer:=7;
  DEFAULT_START_THRESHOLD:integer:=1000;
  DEFAULT_STOP_THRESHOLD:integer:=1000;
  DEFAULT_SLOPE_THRESHOLD:integer:=25;
  DEFAULT_SLOPE_CROSSING:integer:=0;
  DEFAULT_AREA_THRESHOLD:integer:=300000
);
port(
  pipeline_clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  ADC_sample:in unsigned(ADC_BITS-1 downto 0);
  --
  eventstream_enabled:in boolean;
  mux_full:in boolean;
  event_lost:out boolean;
  dirty:out boolean; --!signals valid after startup or register change
  ------------------------------------------------------------------------------
  -- Channel CPUs register interface
  ------------------------------------------------------------------------------
  register_write_value:in registerdata;
  register_read_value:out registerdata;
  register_address:in registeraddress;
  register_write:in boolean;
  ------------------------------------------------------------------------------
  -- Measurements for MCA
  ------------------------------------------------------------------------------
  sample:out signed(ADC_BITS downto 0);
  baseline:out unsigned(ADC_BITS-1 downto 0);
  local_maxima:out boolean;
  local_minima:out boolean;
  --! sample areas and extrema relative to baseline
  sample_extrema:out signed(ADC_BITS downto 0);
  sample_area:out signed(AREA_BITS downto 0);
  sample_valid:out boolean;
  --
  pulse_area:out unsigned(AREA_BITS-1 downto 0);
  pulse_length:out unsigned(TIME_BITS-1 downto 0);
  pulse_valid:out boolean;
  --
  slope_extrema:out signed(ADC_BITS downto 0);
  slope_valid:out boolean;
  ------------------------------------------------------------------------------
  -- to MUX
  ------------------------------------------------------------------------------
  start_mux:out boolean;
  commit_pulse:out boolean;
  dump_pulse:out boolean;
  ------------------------------------------------------------------------------
  -- stream output
  ------------------------------------------------------------------------------
  eventstream:out eventbus_t;
  eventstream_valid:out boolean;
  eventstream_ready:in boolean;
  eventstream_last:out boolean
);
end entity channel_pipeline;
--
architecture wrapper of channel_pipeline is
--------------------------------------------------------------------------------
-- Channel registers
--------------------------------------------------------------------------------
signal baseline_timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
signal baseline_timeconstant_updated:boolean;
signal baseline_avn:unsigned(bits(BASELINE_AV_BITS) downto 0);
signal baseline_avn_updated:boolean;
signal delay:unsigned(DELAY_BITS-1 downto 0);
signal signal_avn:unsigned(bits(SIGNAL_AV_BITS) downto 0);
signal signal_avn_updated:boolean;
signal slope_n:unsigned(bits(SLOPE_ADDRESS_BITS) downto 0);
signal slope_n_updated:boolean;
signal sync_clks:unsigned(SYNC_ADDRESS_BITS downto 0);
signal sync_clks_updated:boolean;
signal area_threshold:unsigned(AREA_BITS-1 downto 0);
signal slope_crossing_level:unsigned(ADC_BITS-1 downto 0);
signal baseline_relative:boolean;
signal start_threshold:unsigned(ADC_BITS-1 downto 0);
signal stop_threshold:unsigned(ADC_BITS-1 downto 0);
signal slope_threshold:unsigned(ADC_BITS-1 downto 0);
--------------------------------------------------------------------------------
-- Measurements
--------------------------------------------------------------------------------
signal slope,slope_out,dsp_sample,sample_out:rel_sample_t;
signal baseline_int,baseline_out:unsigned(ADC_BITS-1 downto 0);
signal max_valid,min_valid,measure_valid:boolean;
signal commit,dump,pulse_valid_int:boolean;
signal start:boolean;
signal pulse_area_int:unsigned(AREA_BITS-1 downto 0);
signal pulse_length_int:unsigned(TIME_BITS-1 downto 0);
signal baseline_threshold : unsigned(BASELINE_MCA_COUNTER_BITS-1 downto 0);
signal fixed_baseline:unsigned(ADC_BITS-1 downto 0);
--
begin
local_maxima <= max_valid;
local_minima <= min_valid;
sample <= sample_out;
baseline <= baseline_out;
dirty <= measure_valid;
pulse_valid <= pulse_valid_int;
--event_lost <= event_lost;
pulse_area <= pulse_area_int;
pulse_length <= pulse_length_int;
--start_mux <= pulse_start_int;
commit_pulse <= commit;
dump_pulse <= dump;
--
channelRegisters:entity controllerlib.channel_registers
generic map(
  DELAY_BITS => DELAY_BITS,
  SIGNAL_AV_ADDRESS_BITS => SIGNAL_AV_BITS,
  SLOPE_ADDRESS_BITS => SLOPE_ADDRESS_BITS,
  SYNC_ADDRESS_BITS => SYNC_ADDRESS_BITS,
  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  BASELINE_AV_ADDRESS_BITS => BASELINE_AV_BITS,
  DEFAULT_DELAY => DEFAULT_DELAY,
  DEFAULT_SIGNAL_AVN => DEFAULT_SIGNAL_AVN,
  DEFAULT_SLOPE_N => DEFAULT_SLOPE_N,
  DEFAULT_SYNC_CLKS => DEFAULT_SYNC_CLKS,
  DEFAULT_BASELINE_TIMECONSTANT => DEFAULT_BASELINE_TIMECONSTANT,
  DEFAULT_FIXED_BASELINE => DEFAULT_FIXED_BASELINE,
  DEFAULT_BASELINE_AVN => DEFAULT_BASELINE_AVN,
  DEFAULT_START_THRESHOLD => DEFAULT_START_THRESHOLD,
  DEFAULT_STOP_THRESHOLD => DEFAULT_STOP_THRESHOLD,
  DEFAULT_SLOPE_THRESHOLD => DEFAULT_SLOPE_THRESHOLD,
  DEFAULT_SLOPE_CROSSING => DEFAULT_SLOPE_CROSSING,
  DEFAULT_AREA_THRESHOLD => DEFAULT_AREA_THRESHOLD
)
port map(
  clk => pipeline_clk,
  reset => reset1,
  data_in => register_write_value,
  address => register_address,
  write => register_write,
  data_out => register_read_value,
  delay => delay,
  signal_avn => signal_avn,
  signal_avn_updated => signal_avn_updated,
  slope_n => slope_n,
  slope_n_updated => slope_n_updated,
  sync_clks => sync_clks,
  sync_clks_updated => sync_clks_updated,
  baseline_timeconstant => baseline_timeconstant,
  fixed_baseline => fixed_baseline,
  baseline_timeconstant_updated => baseline_timeconstant_updated,
  baseline_avn => baseline_avn,
  baseline_avn_updated => baseline_avn_updated,
  start_threshold => start_threshold,
  stop_threshold => stop_threshold,
  baseline_relative => baseline_relative,
  slope_threshold => slope_threshold,
  slope_crossing_level => slope_crossing_level,
  area_threshold => area_threshold,
  baseline_threshold => baseline_threshold
);
--
--TODO local extrema should be handled in this entity make delay separate
DSP:entity dsplib.dsp_unit
generic map(
	SIGNAL_DELAY_BITS => DELAY_BITS,
  SIGNAL_AV_BITS => SIGNAL_AV_BITS,
  SLOPE_ADDRESS_BITS => SLOPE_ADDRESS_BITS,
  SYNC_ADDRESS_BITS => SYNC_ADDRESS_BITS,
  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  BASELINE_AV_BITS => BASELINE_AV_BITS
)
port map(
	clk => pipeline_clk,
  reset => reset2,
  adc_sample => adc_sample,
  signal_delay => delay,
  signal_avn => signal_avn,
  signal_avn_updated => signal_avn_updated,
  slope_n => slope_n,
  sync_clks => sync_clks,
  baseline_timeconstant => baseline_timeconstant,
  fixed_baseline => fixed_baseline,
  baseline_avn => baseline_avn,
  baseline_avn_updated => baseline_avn_updated,
  baseline_threshold => baseline_threshold,
  baseline_relative => baseline_relative,
  baseline => baseline_int,
  sample => DSP_sample,
  slope => slope
);
--
measurement:entity dsplib.measurement
port map(
  clk => pipeline_clk,
  reset => reset2,
  pulse_threshold => start_threshold,
  baseline_relative => baseline_relative,
  slope_threshold => slope_threshold,
  slope_crossing_level => slope_crossing_level,
  baseline_in => baseline_int,
  sample_in => DSP_sample,
  slope_in => slope,
  sample_out => sample_out,
  slope_out => slope_out,
  baseline_out => baseline_out,
  local_maxima => max_valid,
  local_minima => min_valid,
  sample_extrema => sample_extrema,
  sample_area => sample_area,
  sample_zero_crossing => sample_valid,
  pulse_area => pulse_area_int,
  pulse_length => pulse_length_int,
  pulse_start => start,
  pulse_stop => pulse_valid_int,
  slope_extrema => slope_extrema,
  slope_zero_crossing => slope_valid
);
--
streamer:entity work.event_framer
generic map(
  CHANNEL => CHANNEL_NUMBER,
  MAX_PEAKS => MAX_PEAKS,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => pipeline_clk,
  reset => reset2,
  sample => sample_out,
  area_threshold => area_threshold,
  enabled  => eventstream_enabled,
  event_lost => event_lost,
  mux_full => mux_full,
  start => start,
  pulse_valid => pulse_valid_int,
  peak => max_valid,
  pulse_area => pulse_area_int,
  pulse_length => pulse_length_int,
  start_mux => start_mux,
  dump => dump,
  commit => commit,
  eventstream => eventstream,
  valid => eventstream_valid,
  ready => eventstream_ready,
  last => eventstream_last
);
--
end architecture wrapper;