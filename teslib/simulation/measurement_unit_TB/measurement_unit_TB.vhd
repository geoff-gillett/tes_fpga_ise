--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:18 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: measurement_unit_TB
-- Project Name: tes library (teslib)
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

use work.types.all;
use work.registers.all;
use work.events.all;
use work.measurements.all;
use work.adc.all;
use work.dsptypes.all;

entity measurement_unit_TB is
generic(
	CHANNEL:integer:=7;
	FRAMER_ADDRESS_BITS:integer:=10;
	ENDIANNESS:string:="LITTLE"
);
end entity measurement_unit_TB;

architecture testbench of measurement_unit_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal peak_overflow:boolean;
signal time_overflow:boolean;
signal cfd_error:boolean;
signal measurements:measurement_t;
signal commit:boolean;
signal dump:boolean;
signal eventstream:streambus_t;
signal eventstream_valid:boolean;
signal eventstream_ready:boolean;
signal adc_sample:adc_sample_t;
signal registers:channel_registers_t;
signal height_type:std_logic_vector(NUM_HEIGHT_D-1 downto 0);
signal event_type:std_logic_vector(DETECTION_D_BITS-1 downto 0);
signal trigger_type:std_logic_vector(TIMING_D_BITS-1 downto 0);
--
signal mca_value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
signal mca_trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal mca_value:signed(MCA_VALUE_BITS-1 downto 0);
signal baseline_error:boolean;
signal framer_overflow:boolean;

begin
	
clk <= not clk after CLK_PERIOD/2;
event_type <= to_std_logic(registers.capture.detection,DETECTION_D_BITS);
height_type <= to_std_logic(registers.capture.height,NUM_HEIGHT_D);
trigger_type <= to_std_logic(registers.capture.timing,TIMING_D_BITS);
	
UUT:entity work.measurement_unit
generic map(
  CHANNEL => CHANNEL,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  ENDIANNESS => ENDIANNESS
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
  measurements => measurements,
  mca_value_select => mca_value_select,
  mca_trigger_select => mca_trigger_select,
  mca_value => mca_value,
  dump => dump,
  commit => commit,
  baseline_range_error => baseline_error,
  cfd_error => cfd_error,
  time_overflow => time_overflow,
  peak_overflow => peak_overflow,
  framer_overflow => framer_overflow,
  eventstream => eventstream,
  valid => eventstream_valid,
  ready => eventstream_ready
);

stimulus:process is
begin
registers.capture.pulse_threshold <= to_unsigned(300,DSP_BITS-DSP_FRAC-1) & 
																 to_unsigned(0,DSP_FRAC);
registers.capture.slope_threshold <= to_unsigned(10,DSP_BITS-SLOPE_FRAC-1) & 
																 to_unsigned(0,SLOPE_FRAC);
registers.baseline.timeconstant 
	<= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);
registers.baseline.threshold 
	<= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
registers.baseline.count_threshold 
	<= to_unsigned(150,BASELINE_COUNTER_BITS);
registers.baseline.average_order <= 4;
registers.baseline.offset <= to_std_logic(260,ADC_BITS);
registers.baseline.subtraction <= TRUE;
registers.capture.constant_fraction --<= (CFD_BITS-2 => '1',others => '0');
	<= to_unsigned((2**(CFD_BITS-1))/5,CFD_BITS-1); --20%
registers.capture.cfd_rel2min <= TRUE;
registers.capture.height <= PEAK_HEIGHT_D;
registers.capture.detection <= TRACE_DETECTION_D;
registers.capture.timing <= CFD_LOW_TIMING_D;
registers.capture.trace0 <= FILTERED_TRACE_D;
registers.capture.trace1 <= NO_TRACE_D;
registers.capture.threshold_rel2min <= FALSE;
registers.capture.area_threshold <= to_signed(500,AREA_BITS);
registers.capture.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);
registers.capture.full_trace <= TRUE;

wait for CLK_PERIOD;
reset <= '0';
eventstream_ready <= TRUE;
wait for CLK_PERIOD;
wait;
end process stimulus;

end architecture testbench;
