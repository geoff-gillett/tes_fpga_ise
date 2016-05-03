--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: signal_processor_TB
-- Project Name: teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.dsptypes.all;
use work.registers.all;
use work.measurements.all;
use work.adc.all;
use work.events.all;
use work.types.all;
use work.functions.all;

entity signal_processor_TB is
end entity signal_processor_TB;

architecture testbench of signal_processor_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal adc_sample:adc_sample_t;
signal registers:channel_registers_t;
signal measurements:measurement_t;
signal cfd_error:boolean;
signal time_overflow:boolean;
signal height_type:std_logic_vector(NUM_HEIGHT_D-1 downto 0);
signal event_type:std_logic_vector(DETECTION_D_BITS-1 downto 0);
signal trigger_type:std_logic_vector(TIMING_D_BITS-1 downto 0);
signal peak_overflow:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

event_type <= to_std_logic(registers.capture.event_type,DETECTION_D_BITS);
height_type <= to_std_logic(registers.capture.height,NUM_HEIGHT_D);
trigger_type 
	<= to_std_logic(registers.capture.timing,TIMING_D_BITS);

UUT:entity work.signal_processor
generic map(
  WIDTH => DSP_BITS,
  FRAC => DSP_FRAC,
  TIME_BITS => TIME_BITS,
  TIME_FRAC => TIME_FRAC,
  BASELINE_BITS => BASELINE_BITS,
  BASELINE_COUNTER_BITS => BASELINE_COUNTER_BITS,
  BASELINE_TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  BASELINE_MAX_AV_ORDER => BASELINE_MAX_AV_ORDER,
  CFD_BITS => CFD_BITS,
  CFD_FRAC => CFD_FRAC
)
port map(
  clk => clk,
  reset => reset,
  adc_sample => adc_sample,
  registers => registers,
  filter_config_data => (others => '0'),
  filter_config_valid => FALSE,
  filter_config_ready => open,
  filter_reload_data => (others => '0'),
  filter_reload_valid => FALSE,
  filter_reload_ready => open,
  filter_reload_last => FALSE,
  differentiator_config_data => (others => '0'),
  differentiator_config_valid => FALSE,
  differentiator_config_ready => open,
  differentiator_reload_data=> (others => '0'),
  differentiator_reload_valid => FALSE,
  differentiator_reload_ready => open,
  differentiator_reload_last => FALSE,
  measurements => measurements,
  cfd_error => cfd_error,
  time_overflow => time_overflow,
  peak_overflow => peak_overflow
);

stimulus:process is
begin
registers.capture.pulse_threshold 
	<= to_unsigned(300,DSP_BITS-DSP_FRAC-1) & to_unsigned(0,DSP_FRAC);
registers.capture.slope_threshold 
	<= to_unsigned(10,DSP_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
	
registers.baseline.timeconstant 
	<= to_unsigned(2**18,BASELINE_TIMECONSTANT_BITS);
registers.baseline.threshold 
	<= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
registers.baseline.count_threshold 
	<= to_unsigned(300,BASELINE_COUNTER_BITS);
registers.baseline.average_order <= 4;
registers.baseline.offset <= to_std_logic(200,ADC_BITS);

registers.capture.constant_fraction <= to_unsigned((2**17)/8,CFD_BITS-1); --20%
registers.baseline.subtraction <= FALSE;
registers.capture.cfd_rel2min <= TRUE;

registers.capture.height <= CFD_HEIGHT_D;
registers.capture.threshold_rel2min <= TRUE;
registers.capture.area_threshold <= to_signed(500,AREA_BITS);
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait;
end process stimulus;

end architecture testbench;
