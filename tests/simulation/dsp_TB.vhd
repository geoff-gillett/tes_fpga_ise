--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:13 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: FIR_stages_TB
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
--
library streamlib;
use streamlib.types.all;
-- 
library adclib;
use adclib.types.all;
--
library dsplib;

entity dsp_TB is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3;
  BASELINE_BITS:integer:=10;
  BASELINE_COUNTER_BITS:integer:=18;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_MAX_AVERAGE_ORDER:integer:=7;
  CFD_BITS:integer:=18;
  CFD_FRAC:integer:=17
);
end entity dsp_TB;

architecture testbench of dsp_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;
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
signal adc_sample:adc_sample_t;
signal baseline_subtraction:boolean;
signal baseline_timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
signal baseline_threshold:unsigned(BASELINE_BITS-2 downto 0);
signal baseline_count_threshold:unsigned(BASELINE_COUNTER_BITS-1 downto 0);
signal baseline_average_order:natural range 0 to BASELINE_MAX_AVERAGE_ORDER;
--signal raw:signal_t;
signal adc_baseline:adc_sample_t;
signal constant_fraction:unsigned(CFD_BITS-2 downto 0);
signal slope_threshold:unsigned(WIDTH-2 downto 0);
signal filtered:signal_t;
signal slope:signal_t;
signal raw_area,filtered_area,slope_area:area_t;
signal new_raw_measurement,new_filtered_measurement:boolean;
signal new_slope_measurement:boolean;
signal pulse_detected:boolean;
signal pulse_area:area_t;
signal peak:boolean;
signal raw_extrema:signal_t;
signal filtered_extrema,slope_extrema:signal_t;
signal cfd_relative:boolean;
signal pulse_threshold:unsigned(WIDTH-2 downto 0);
signal pulse_extrema:signal_t;
signal new_pulse_measurement:boolean;
signal slope_threshold_xing:boolean;
signal cfd:boolean;
signal minima:signal_t;
signal cfd_error:boolean;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.dsp
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
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
  raw_valid => new_raw_measurement,
  filtered_area => filtered_area,
  filtered_extrema => filtered_extrema,
  filtered_valid => new_filtered_measurement,
  slope_area => slope_area,
  slope_extrema => slope_extrema,
  slope_valid => new_slope_measurement,
  pulse_area => pulse_area,
  --pulse_length => pulse_length,
  pulse_extrema => pulse_extrema,
  slope => slope,
  --baseline => baseline,
  --raw => raw,
  filtered => filtered,
  pulse_valid => new_pulse_measurement,
  slope_threshold_xing => slope_threshold_xing,
  pulse_detected => pulse_detected,
  peak => peak,
  minima => minima,
  cfd => cfd,
  cfd_error => cfd_error
);

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
pulse_threshold <= to_unsigned(10,WIDTH-FRAC-1) & 
										to_unsigned(0,FRAC);
slope_threshold <= to_unsigned(3,WIDTH-SLOPE_FRAC-1) & 
										to_unsigned(0,SLOPE_FRAC);
baseline_timeconstant <= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);
baseline_threshold <= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
baseline_count_threshold <= to_unsigned(150,BASELINE_COUNTER_BITS);
baseline_average_order <= 4;
adc_baseline <= to_std_logic(to_unsigned(260,ADC_BITS));
constant_fraction <= to_unsigned((2**17)/2,CFD_BITS-1); -- 20%
baseline_subtraction <= TRUE;
cfd_relative <= TRUE;
adc_sample <= adc_baseline;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*16;
adc_sample <= to_std_logic(to_unsigned(2048,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(0,ADC_BITS));
wait for CLK_PERIOD;
adc_sample <= adc_baseline;
wait for CLK_PERIOD*20;
adc_sample <= to_std_logic(to_unsigned(2048,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(0,ADC_BITS));
wait for CLK_PERIOD;
adc_sample <= adc_baseline;
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(512,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(1024,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(2048,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(4096,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(2048,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(1024,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(512,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(256,ADC_BITS));
--wait for CLK_PERIOD*16;
----adc_sample <= (others => '0');
----wait for CLK_PERIOD*32;
----adc_sample <= to_std_logic(to_unsigned(256,ADC_BITS));
----wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(512,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(1024,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(2048,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(4096,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(2048,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(1024,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(512,ADC_BITS));
--wait for CLK_PERIOD;
--adc_sample <= to_std_logic(to_unsigned(256,ADC_BITS));
wait;
end process stimulus;

end architecture testbench;
