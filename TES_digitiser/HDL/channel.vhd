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
--
library adclib;
use adclib.types.all;
--
library streamlib;
use streamlib.types.all;
--
library controllerlib;
--
library dsplib;
--
entity channel is
generic(
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
  ADC_sample:in adc_sample_t;
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
  sample:out sample_t;
  baseline:out sample_t;
  local_maxima:out boolean;
  local_minima:out boolean;
  --! sample areas and extrema relative to baseline
  sample_extrema:out sample_t;
  sample_area:out area_t;
  sample_valid:out boolean;
  --
  pulse_area:out area_t;
  pulse_length:out time_t;
  pulse_valid:out boolean;
  --
  slope_extrema:out sample_t;
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
end entity channel;
--
architecture wrapper of channel is
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
signal area_threshold:area_t;
signal slope_crossing_level:sample_t;
signal baseline_relative:boolean;
signal start_threshold:sample_t;
signal stop_threshold:sample_t;
signal slope_threshold:sample_t;
--------------------------------------------------------------------------------
-- Measurements
--------------------------------------------------------------------------------
signal slope,slope_out,dsp_sample,sample_out:sample_t;
signal slope_out_reg,sample_out_reg:sample_t;
signal baseline_int,baseline_out:sample_t;
signal baseline_out_reg:sample_t;
signal max_valid,min_valid,measure_valid:boolean;
signal max_valid_reg,min_valid_reg,measure_valid_reg:boolean;
signal commit,dump,pulse_valid_int:boolean;
signal pulse_valid_reg:boolean;
signal start:boolean;
signal start_reg:boolean;
signal pulse_area_int,pulse_area_reg:area_t;
signal pulse_length_int,pulse_length_reg:time_t;
signal baseline_threshold:unsigned(BASELINE_MCA_COUNTER_BITS-1 downto 0);
signal fixed_baseline:sample_t;
signal sample_extrema_int,sample_extrema_reg:sample_t;
signal sample_area_int,sample_area_reg:area_t;
signal sample_valid_int,sample_valid_reg:boolean;
signal slope_extrema_int,slope_extrema_reg:sample_t;
signal slope_valid_int,slope_valid_reg:boolean;
signal raw:sample_t;
--
begin
local_maxima <= max_valid_reg;
local_minima <= min_valid_reg;
sample <= sample_out_reg;
baseline <= baseline_out_reg;
dirty <= measure_valid_reg; --FIXME this is not connected
pulse_valid <= pulse_valid_reg;
--event_lost <= event_lost;
pulse_area <= pulse_area_reg;
pulse_length <= pulse_length_reg;
--start_mux <= pulse_start_int;
commit_pulse <= commit;
dump_pulse <= dump;
sample_extrema <= sample_extrema_reg;
sample_area <= sample_area_reg;
sample_valid <= sample_valid_reg;
slope_extrema <= slope_extrema_reg;
slope_valid <= slope_valid_reg;

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
--FIXME local extrema should be handled in this entity make delay separate

signalProccessing:entity dsplib.dsp
	generic map(
		THRESHOLD_BITS             => AXI_DATA_BITS,
		THRESHOLD_FRAC             => 17,
		STAGE1_IN_BITS             => 18,
		STAGE1_IN_FRAC             => 3,
		STAGE1_BITS                => 48,
		STAGE1_FRAC                => 28,
		STAGE1_OUT_BITS            => 16,
		STAGE1_OUT_FRAC            => 1,
		STAGE2_BITS                => 48,
		STAGE2_FRAC                => 28,
		STAGE2_OUT_BITS            => 16,
		STAGE2_OUT_FRAC            => 1,
		BASELINE_BITS              => 10,
		BASELINE_AV_FRAC           => 4,
		BASELINE_COUNTER_BITS      => 18,
		BASELINE_TIMECONSTANT_BITS => AXI_DATA_BITS,
		BASELINE_MAX_AVERAGE_ORDER => 6
	)
	port map(
		clk => pipeline_clk,
		reset => reset1,
		adc_sample => adc_sample,
		adc_baseline => to_std_logic(resize(fixed_baseline, ADC_BITS)),
		baseline_subtraction => baseline_relative,
		baseline_timeconstant => baseline_timeconstant,
		baseline_threshold => to_unsigned(2**(10-1)-1,10-1),
		baseline_count_threshold => baseline_threshold,
		baseline_average_order => 6,
		interstage_shift => to_unsigned(25,bits(48-SIGNAL_BITS)),
		filter_config_data => (others => '0'),
		filter_config_valid => FALSE,
		filter_config_ready => open,
		filter_reload_data => (others => '0'),
		filter_reload_valid => FALSE,
		filter_reload_ready => open,
		filter_reload_last => FALSE,
		pulse_threshold => shift_right(resize(start_threshold,AXI_DATA_BITS),17),
		differentiator_config_data => (others => '0'),
		differentiator_config_valid => FALSE,
		differentiator_config_ready => open,
		differentiator_reload_data => (others => '0'),
		differentiator_reload_valid => FALSE,
		differentiator_reload_ready => open,
		differentiator_reload_last => FALSE,
		slope_threshold => shift_right(resize(start_threshold,AXI_DATA_BITS),17),
		new_filtered_measurement => DSP_sample,
		stage1_pos_threshold_xing => pulse_start,
		stage1_neg_threshold_xing => pulse_stop,
		stage1_pos_0_xing => sample_pos_xing,
		stage1_neg_0_xing => sample_neg_xing,
		slope => slope,
		stage2_pos_threshold_xing => arm_slope,
		stage2_neg_threshold_xing => open,
		stage2_pos_0_xing => slope_pos_xing,
		pulse_threshold => slope_neg_xing,
		new_filtered_measurement => raw,
		slope => baseline
	);


--DSP:entity dsplib.dsp_unit
--generic map(
--	SIGNAL_DELAY_BITS => DELAY_BITS,
--  SIGNAL_AV_BITS => SIGNAL_AV_BITS,
--  SLOPE_ADDRESS_BITS => SLOPE_ADDRESS_BITS,
--  SYNC_ADDRESS_BITS => SYNC_ADDRESS_BITS,
--  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
--  BASELINE_AV_BITS => BASELINE_AV_BITS
--)
--port map(
--	clk => pipeline_clk,
--  reset => reset2,
--  adc_sample => adc_sample,
--  signal_delay => delay,
--  signal_avn => signal_avn,
--  signal_avn_updated => signal_avn_updated,
--  slope_n => slope_n,
--  sync_clks => sync_clks,
--  baseline_timeconstant => baseline_timeconstant,
--  fixed_baseline => fixed_baseline,
--  baseline_avn => baseline_avn,
--  baseline_avn_updated => baseline_avn_updated,
--  baseline_threshold => baseline_threshold,
--  baseline_relative => baseline_relative,
--  baseline => baseline_int,
--  sample => DSP_sample,
--  slope => slope
--);
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
  sample_extrema => sample_extrema_int,
  sample_area => sample_area_int,
  sample_zero_crossing => sample_valid_int,
  pulse_area => pulse_area_int,
  pulse_length => pulse_length_int,
  pulse_start => start,
  pulse_stop => pulse_valid_int,
  slope_extrema => slope_extrema_int,
  slope_zero_crossing => slope_valid_int
);

--to help close timing
measurementReg:process(pipeline_clk) is
begin
if rising_edge(pipeline_clk) then
	sample_out_reg <= sample_out;
	slope_out_reg <= slope_out;
	baseline_out_reg <= baseline_out;
	max_valid_reg <= max_valid;
	min_valid_reg <= min_valid;
	sample_extrema_reg <= sample_extrema_int;
	sample_area_reg <= sample_area_int;
	sample_valid_reg <= sample_valid_int;
	pulse_area_reg <= pulse_area_int;
	pulse_length_reg <= pulse_length_int;
	start_reg <= start;
	pulse_valid_reg <= pulse_valid_int;
	slope_extrema_reg <= slope_extrema_reg;
	slope_valid_reg <= slope_valid_int;
end if;
end process measurementReg;

streamer:entity work.event_framer(fixed_aligned)
generic map(
  CHANNEL => CHANNEL_NUMBER,
  MAX_PEAKS => MAX_PEAKS,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => pipeline_clk,
  reset => reset2,
  sample => sample_out_reg,
  area_threshold => area_threshold,
  enabled  => eventstream_enabled,
  event_lost => event_lost,
  mux_full => mux_full,
  start => start_reg,
  pulse_valid => pulse_valid_reg,
  peak => max_valid_reg,
  pulse_area => pulse_area_reg,
  pulse_length => pulse_length_reg,
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