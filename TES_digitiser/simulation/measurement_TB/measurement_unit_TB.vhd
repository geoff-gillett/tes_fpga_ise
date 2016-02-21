--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:22 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: measurement_TB
-- Project Name: TES_digitier
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

library adclib;
use adclib.adc.all;

library streamlib;
use streamlib.stream.all;

library dsplib;
use dsplib.types.all;

library eventlib;
use eventlib.events.all;

use work.registers.all;
use work.measurements.all;

entity measurement_unit_TB is
generic(
	CHANNEL:integer:=0;
	FRAMER_ADDRESS_BITS:integer:=10
);
end entity measurement_unit_TB;

architecture testbench of measurement_unit_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal adc_sample:adc_sample_t;
signal registers:measurement_registers;
signal overflow:boolean;
signal time_overflow:boolean;
signal measurements:measurement_t;
signal commit:boolean;
signal dump:boolean;
signal eventstream:streambus_t;
signal valid:boolean;
signal ready:boolean;
signal height_slv:std_logic_vector(HEIGHT_TYPE_BITS-1 downto 0);
signal cfd_error:boolean;
signal start:boolean;
begin

clk <= not clk after CLK_PERIOD/2;

UUT:entity work.measurement_unit
generic map(
  CHANNEL => CHANNEL,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS
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
  differentiator_reload_data => (others => '0'),
  differentiator_reload_valid => FALSE,
  differentiator_reload_ready => open,
  differentiator_reload_last => FALSE,
  overflow => overflow,
  time_overflow => time_overflow,
  cfd_error => cfd_error,
  measurements => measurements,
  start => start,
  commit => commit,
  dump => dump,
  eventstream => eventstream,
  valid => valid,
  ready => ready
);

height_slv <= to_std_logic(registers.capture.height_form,2);

stimulus:process is
begin
registers.dsp.pulse_threshold <= to_unsigned(300,DSP_BITS-DSP_FRAC-1) & 
																 to_unsigned(0,DSP_FRAC);
registers.dsp.slope_threshold <= to_unsigned(10,DSP_BITS-SLOPE_FRAC-1) & 
																 to_unsigned(0,SLOPE_FRAC);
registers.dsp.baseline.timeconstant 
	<= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);
registers.dsp.baseline.threshold 
	<= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
registers.dsp.baseline.count_threshold 
	<= to_unsigned(150,BASELINE_COUNTER_BITS);
registers.dsp.baseline.average_order <= 4;
registers.dsp.baseline.offset <= to_std_logic(to_unsigned(260,ADC_BITS));
registers.dsp.constant_fraction <= to_unsigned((2**17)/8,CFD_BITS-1); -- 20%
registers.dsp.baseline.subtraction <= TRUE;
registers.dsp.cfd_relative <= TRUE;
--
registers.capture.height_form <= CFD_HEIGHT;
registers.capture.rel_to_min <= TRUE;
registers.capture.use_cfd_timing <= TRUE;
wait for CLK_PERIOD;
ready <= TRUE;
reset <= '0';
wait;
end process stimulus;

end architecture testbench;
