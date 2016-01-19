--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: dsp_capture_TB
-- Project Name: tests 
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

library dsplib;
library streamlib;
--use streamlib.types.all;
use streamlib.stream.all;
use streamlib.events.all;

library adclib;
use adclib.types.all;

entity capture_mux_TB is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3;
	TIME_BITS:integer:=16;
	TIME_FRAC:integer:=0;
  BASELINE_BITS:integer:=10;
  BASELINE_COUNTER_BITS:integer:=18;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_MAX_AVERAGE_ORDER:integer:=6;
  CFD_BITS:integer:=18;
  CFD_FRAC:integer:=17;
  CHANNEL:integer:=1;
  PEAK_COUNT_BITS:integer:=4;
  ADDRESS_BITS:integer:=9;
  BUS_CHUNKS:integer:=4
);
end entity capture_mux_TB;

architecture testbench of capture_mux_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal adc_sample:adc_sample_t;
signal adc_baseline:adc_sample_t;
signal baseline_subtraction:boolean;
signal baseline_timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
signal baseline_threshold:unsigned(BASELINE_BITS-2 downto 0);
signal baseline_count_threshold:unsigned(BASELINE_COUNTER_BITS-1 downto 0);
signal baseline_average_order:natural range 0 to BASELINE_MAX_AVERAGE_ORDER;
signal filter_config_data:std_logic_vector(7 downto 0);
signal filter_config_valid:boolean;
signal filter_config_ready:boolean;
signal filter_reload_data:std_logic_vector(31 downto 0);
signal filter_reload_valid:boolean;
signal filter_reload_ready:boolean;
signal filter_reload_last:boolean;
signal differentiator_config_data:std_logic_vector(7 downto 0);
signal differentiator_config_valid:boolean;
signal differentiator_config_ready:boolean;
signal differentiator_reload_data:std_logic_vector(31 downto 0);
signal differentiator_reload_valid:boolean;
signal differentiator_reload_ready:boolean;
signal differentiator_reload_last:boolean;
signal cfd_relative:boolean;
signal constant_fraction:unsigned(CFD_BITS-2 downto 0);
signal pulse_threshold:unsigned(WIDTH-2 downto 0);
signal slope_threshold:unsigned(WIDTH-2 downto 0);
signal raw_area:area_t;
signal raw_extrema:signal_t;
signal raw_valid:boolean;
signal filtered:signal_t;
signal filtered_area:area_t;
signal filtered_extrema:signal_t;
signal filtered_valid:boolean;
signal slope:signal_t;
signal slope_area:area_t;
signal slope_extrema:signal_t;
signal slope_valid:boolean;
signal slope_threshold_xing:boolean;
signal peak_start:boolean;
signal peak:boolean;
signal peak_minima:signal_t;
signal cfd_low:boolean;
signal cfd_high:boolean;
signal pulse_area:area_t;
signal pulse_extrema:signal_t;
signal pulse_valid:boolean;
signal cfd_error:boolean;
signal time_overflow:boolean;
signal height_format:heighttype;
signal rel_to_min:boolean;
signal use_cfd_timing:boolean;
signal overflow:boolean;
signal pulse_pos_xing:boolean;
signal pulse_neg_xing:boolean;
signal enqueue:boolean;
signal dump:boolean;
signal commit:boolean;
signal peak_count:unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
signal height:signal_t;
signal eventstream:streambus;
signal valid:boolean;
signal ready:boolean;
signal stream_bus:streambus;
signal event_LE:std_logic_vector(BUS_DATABITS-1 downto 0);
signal height_slv:std_logic_vector(1 downto 0);
begin
clk <= not clk after CLK_PERIOD/2;

dspProcessor:entity dsplib.dsp
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  TIME_BITS => TIME_BITS,
  TIME_FRAC => TIME_FRAC,
  BASELINE_BITS => BASELINE_BITS,
  BASELINE_COUNTER_BITS => BASELINE_COUNTER_BITS,
  BASELINE_TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  BASELINE_MAX_AVERAGE_ORDER => BASELINE_MAX_AVERAGE_ORDER,
  CFD_BITS => CFD_BITS,
  CFD_FRAC => CFD_FRAC
)
port map(
  clk => clk,
  reset => reset,
  adc_sample => adc_sample,
  adc_baseline => adc_baseline,
  baseline_subtraction => baseline_subtraction,
  baseline_timeconstant => baseline_timeconstant,
  baseline_threshold => baseline_threshold,
  baseline_count_threshold => baseline_count_threshold,
  baseline_average_order => baseline_average_order,
  filter_config_data => filter_config_data,
  filter_config_valid => filter_config_valid,
  filter_config_ready => filter_config_ready,
  filter_reload_data => filter_reload_data,
  filter_reload_valid => filter_reload_valid,
  filter_reload_ready => filter_reload_ready,
  filter_reload_last => filter_reload_last,
  differentiator_config_data => differentiator_config_data,
  differentiator_config_valid => differentiator_config_valid,
  differentiator_config_ready => differentiator_config_ready,
  differentiator_reload_data => differentiator_reload_data,
  differentiator_reload_valid => differentiator_reload_valid,
  differentiator_reload_ready => differentiator_reload_ready,
  differentiator_reload_last => differentiator_reload_last,
  cfd_relative => cfd_relative,
  constant_fraction => constant_fraction,
  pulse_threshold => pulse_threshold,
  slope_threshold => slope_threshold,
  raw_area => raw_area,
  raw_extrema => raw_extrema,
  raw_valid => raw_valid,
  filtered => filtered,
  filtered_area => filtered_area,
  filtered_extrema => filtered_extrema,
  filtered_valid => filtered_valid,
  slope => slope,
  slope_area => slope_area,
  slope_extrema => slope_extrema,
  slope_valid => slope_valid,
  slope_threshold_xing => slope_threshold_xing,
  peak_start => peak_start,
  peak => peak,
  pulse_pos_xing => pulse_pos_xing,
  pulse_neg_xing => pulse_neg_xing,
  peak_minima => peak_minima,
  cfd_low => cfd_low,
  cfd_high => cfd_high,
  pulse_area => pulse_area,
  pulse_extrema => pulse_extrema,
  pulse_valid => pulse_valid,
  cfd_error => cfd_error,
  time_overflow => time_overflow
);

eventCapture:entity streamlib.event_capture
generic map(
  CHANNEL => CHANNEL,
  PEAK_COUNT_BITS => PEAK_COUNT_BITS,
  ADDRESS_BITS => ADDRESS_BITS,
  BUS_CHUNKS => BUS_CHUNKS
)
port map(
  clk => clk,
  reset => reset,
  height_format => height_format,
  rel_to_min => rel_to_min,
  use_cfd_timing => use_cfd_timing,
  signal_in => filtered,
  peak => peak,
  peak_start => peak_start,
  overflow => overflow,
  pulse_pos_xing => pulse_pos_xing,
  pulse_neg_xing => pulse_neg_xing,
  cfd_low => cfd_low,
  cfd_high => cfd_high,
  cfd_error => cfd_error,
  slope_area => slope_area,
  enqueue => enqueue,
  dump => dump,
  commit => commit,
  peak_count => peak_count,
  height => height,
  eventstream => eventstream,
  valid => valid,
  ready => ready
);
event_LE <= SwapEndianness(stream_bus.data);
height_slv <= to_std_logic(height_format);
--eventstream_LE <= stream_bus.data;

stimulus:process is
begin
filter_config_data <= (others => '0');
filter_config_valid <= FALSE;
filter_reload_data <= (others => '0');
filter_reload_valid <= FALSE;
filter_reload_last <= FALSE;
differentiator_config_data <= (others => '0');
differentiator_config_valid <= FALSE;
differentiator_reload_data <= (others => '0');
differentiator_reload_valid <= FALSE;
differentiator_reload_last <= FALSE;
pulse_threshold <= to_unsigned(300,WIDTH-FRAC-1) & 
										to_unsigned(0,FRAC);
slope_threshold <= to_unsigned(10,WIDTH-SLOPE_FRAC-1) & 
										to_unsigned(0,SLOPE_FRAC);
baseline_timeconstant <= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);
baseline_threshold <= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
baseline_count_threshold <= to_unsigned(150,BASELINE_COUNTER_BITS);
baseline_average_order <= 4;
adc_baseline <= to_std_logic(to_unsigned(260,ADC_BITS));
constant_fraction <= to_unsigned((2**17)/8,CFD_BITS-1); -- 20%
baseline_subtraction <= TRUE;
cfd_relative <= TRUE;
--
height_format <= SLOPE_INTEGRAL;
rel_to_min <= TRUE;
use_cfd_timing <= TRUE;
ready <= TRUE;
wait for CLK_PERIOD;
adc_sample <= adc_baseline;
reset <= '0';
wait for CLK_PERIOD;

wait;
end process stimulus;

end architecture testbench;
