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
	THRESHOLD_BITS:integer:=25;
	THRESHOLD_FRAC:integer:=9;
	INTERSTAGE_SHIFT:integer:=25;
	STAGE1_IN_BITS:integer:=18;
	STAGE1_IN_FRAC:integer:=3;
	STAGE1_BITS:integer:=48;
	STAGE1_FRAC:integer:=28;
	STAGE2_BITS:integer:=48;
	STAGE2_FRAC:integer:=28;
  BASELINE_BITS:integer:=12;
  BASELINE_COUNTER_BITS:integer:=18;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_MAX_AVERAGE_ORDER:integer:=8;
  CFD_BITS:integer:=17;
  CFD_FRAC:integer:=17
);
end entity dsp_TB;

architecture testbench of dsp_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;
signal stage1_config_data:std_logic_vector(7 downto 0);
signal stage1_config_valid:boolean;
signal stage1_config_ready:boolean;
signal stage1_reload_data:std_logic_vector(31 downto 0);
signal stage1_reload_valid:boolean;
signal stage1_reload_ready:boolean;
signal stage1_reload_last:boolean;
signal stage2_config_data:std_logic_vector(7 downto 0);
signal stage2_config_valid:boolean;
signal stage2_config_ready:boolean;
signal stage2_reload_data:std_logic_vector(31 downto 0);
signal stage2_reload_valid:boolean;
signal stage2_reload_ready:boolean;
signal stage2_reload_last:boolean;
signal adc_sample:adc_sample_t;
signal baseline_subtraction:boolean;
signal baseline_timeconstant:unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
signal baseline_threshold:unsigned(BASELINE_BITS-2 downto 0);
signal baseline_count_threshold:unsigned(BASELINE_COUNTER_BITS-1 downto 0);
signal baseline_average_order:natural range 0 to BASELINE_MAX_AVERAGE_ORDER;
signal raw:signal_t;
signal baseline:signal_t;
signal adc_baseline:adc_sample_t;
signal constant_fraction:unsigned(CFD_BITS-2 downto 0);
signal pulse_threshold:unsigned(THRESHOLD_BITS-2 downto 0);
signal slope_threshold:unsigned(THRESHOLD_BITS-2 downto 0);
signal filtered:signal_t;
signal slope:signal_t;
signal raw_area,stage1_area,stage2_area:area_t;
signal new_raw_area,new_stage1_area,new_stage2_area:boolean;
signal pulse_area_threshold:unsigned(AREA_BITS-2 downto 0);
signal pulse_detected:boolean;
signal accept_pulse:boolean;
signal reject_pulse:boolean;
signal pulse_area:area_t;
signal pulse_length:time_t;
signal peak:signal_t;
signal new_peak:boolean;
signal cfd_value:signal_t;
signal new_cfd_value:boolean;
signal raw_extrema:signal_t;
signal stage1_extrema,stage2_extrema:signal_t;

begin
clk <= not clk after CLK_PERIOD/2;
--

UUT:entity dsplib.dsp
generic map(
  THRESHOLD_BITS => THRESHOLD_BITS,
  THRESHOLD_FRAC => THRESHOLD_FRAC,
  INTERSTAGE_SHIFT => INTERSTAGE_SHIFT,
  STAGE1_IN_BITS => STAGE1_IN_BITS,
  STAGE1_IN_FRAC => STAGE1_IN_FRAC,
  STAGE1_BITS => STAGE1_BITS,
  STAGE1_FRAC => STAGE1_FRAC,
  STAGE2_BITS => STAGE2_BITS,
  STAGE2_FRAC => STAGE2_FRAC,
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
  stage1_config_data => stage1_config_data,
  stage1_config_valid => stage1_config_valid,
  stage1_config_ready => stage1_config_ready,
  stage1_reload_data => stage1_reload_data,
  stage1_reload_valid => stage1_reload_valid,
  stage1_reload_ready => stage1_reload_ready,
  stage1_reload_last => stage1_reload_last,
  stage2_config_data => stage2_config_data,
  stage2_config_valid => stage2_config_valid,
  stage2_config_ready => stage2_config_ready,
  stage2_reload_data => stage2_reload_data,
  stage2_reload_valid => stage2_reload_valid,
  stage2_reload_ready => stage2_reload_ready,
  stage2_reload_last => stage2_reload_last,
  constant_fraction => constant_fraction,
  pulse_threshold => pulse_threshold,
  slope_threshold => slope_threshold,
  pulse_area_threshold => pulse_area_threshold,
  raw => raw,
  raw_area => raw_area,
  raw_extrema => raw_extrema,
  new_raw_area => new_raw_area,
  baseline => baseline,
  stage1 => filtered,
  stage1_area => stage1_area,
  stage1_extrema => stage1_extrema,
  new_stage1_area => new_stage1_area,
  stage2 => slope,
  stage2_area => stage2_area,
  stage2_extrema => stage2_extrema,
  new_stage2_area => new_stage2_area,
  pulse_detected => pulse_detected,
  accept_pulse => accept_pulse,
  reject_pulse => reject_pulse,
  pulse_area => pulse_area,
  pulse_length => pulse_length,
  peak => peak,
  new_peak => new_peak,
  cfd_value => cfd_value,
  new_cfd_value => new_cfd_value
);
--
stimulus:process is
begin
adc_sample <= (others => '0');
stage1_config_data <= (others => '0');
stage1_config_valid <= FALSE;
stage1_reload_data <= (others => '0');
stage1_reload_valid <= FALSE;
stage1_reload_last <= FALSE;
stage2_config_data <= (others => '0');
stage2_config_valid <= FALSE;
stage2_reload_data <= (others => '0');
stage2_reload_valid <= FALSE;
stage2_reload_last <= FALSE;
pulse_threshold <= to_unsigned(200,THRESHOLD_BITS-THRESHOLD_FRAC-1) & 
										to_unsigned(0,THRESHOLD_FRAC);
slope_threshold <= to_unsigned(10,THRESHOLD_BITS-THRESHOLD_FRAC-1) & 
										to_unsigned(0,THRESHOLD_FRAC);
baseline_subtraction <= FALSE;
baseline_timeconstant <= to_unsigned(2**16,BASELINE_TIMECONSTANT_BITS);
baseline_threshold <= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
baseline_count_threshold <= to_unsigned(150,BASELINE_COUNTER_BITS);
baseline_average_order <= 6;
adc_baseline <= to_std_logic(to_unsigned(260,ADC_BITS));
constant_fraction <= to_unsigned(117965,CFD_BITS-1);
pulse_area_threshold <= to_unsigned(10,AREA_BITS-1);
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*64;
adc_sample <= to_std_logic(to_unsigned(2**14-1,ADC_BITS));
wait for CLK_PERIOD;
adc_sample <= (others => '0');
wait;
end process stimulus;

end architecture testbench;
