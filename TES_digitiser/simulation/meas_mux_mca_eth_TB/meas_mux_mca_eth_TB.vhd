--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:6 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: measurement_mux_mca_TB
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

library dsplib;
use dsplib.types.all;

library adclib;
use adclib.types.all;

library streamlib;
use streamlib.stream.all;

library eventlib;
use eventlib.events.all;

library adclib;
use adclib.types.all;

use work.registers.all;
use work.measurements.all;

entity meas_mux_mca_eth_TB is
generic(
  CHANNEL_BITS:integer:=1;
  MIN_TICKPERIOD:integer:=8;
  FRAMER_ADDRESS_BITS:integer:=10
);
end entity meas_mux_mca_eth_TB;

architecture testbench of meas_mux_mca_eth_TB is

constant CHANNELS:integer:=2**CHANNEL_BITS;

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	

constant CLK_PERIOD:time:=4 ns;
signal adc_samples:adc_sample_array(CHANNELS-1 downto 0);
signal measurement_registers:measurement_register_array(CHANNELS-1 downto 0);
signal overflows,time_overflows,cfd_errors:boolean_vector(CHANNELS-1 downto 0);
signal measurements:measurement_array(CHANNELS-1 downto 0);
signal starts,commits,dumps:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams:streambus_array(CHANNELS-1 downto 0);
signal eventstream_valids,eventstream_readys:boolean_vector(CHANNELS-1 downto 0);
signal value_select:std_logic_vector(MCA_VALUE_SELECT_BITS-1 downto 0);
signal mca_trigger_select:std_logic_vector(MCA_TRIGGER_SELECT_BITS-1 downto 0);
signal values_for_mca:mca_value_array(CHANNELS-1 downto 0);
signal values_for_mca_valids:boolean_vector(CHANNELS-1 downto 0);
signal eventstreammux_full:boolean;
signal tick_period:unsigned(TICKPERIOD_BITS-1 downto 0);
signal eventstream:streambus_t;
signal eventstream_valid:boolean;
signal eventstream_ready:boolean;
signal mca_initialising:boolean;
signal mca_update_asap:boolean;
signal mca_update_on_completion:boolean;
signal mca_updated:boolean;
signal mca_channel_select:std_logic_vector(2**CHANNEL_BITS-1 downto 0);
signal value_for_mca:signed(MCA_VALUE_BITS-1 downto 0);
signal value_for_mca_valid:boolean;
signal mcastream:streambus_t;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal mca_registers:mca_registers_t;

type enum_unsigned_array is array (natural range <>) of unsigned(3 downto 0);
signal height_unsigneds:enum_unsigned_array(CHANNELS-1 downto 0);
signal timing_unsigneds:enum_unsigned_array(CHANNELS-1 downto 0);
signal mca_value_unsigned:unsigned(3 downto 0);
signal mca_trigger_unsigned:unsigned(3 downto 0);
signal adc_sample:adc_sample_t;
signal mtu:unsigned(MTU_BITS-1 downto 0);
signal tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal ethernetstream:streambus_t;
signal ethernetstream_valid,ethernetstream_ready:boolean;

begin
	
clk <= not clk after CLK_PERIOD/2;
adcChans:process (clk) is
begin
	if rising_edge(clk) then
		adc_samples(0) <= adc_sample;
		adc_samples(1) <= adc_sample; --s(0);
	end if;
end process adcChans;

chanGen:for c in 0 to CHANNELS-1 generate
	measurement:entity work.measurement_unit
  generic map(
    CHANNEL => c,
    FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS
  )
  port map(
    clk => clk,
    reset => reset,
    adc_sample => adc_samples(c),
    registers => measurement_registers(c),
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
    overflow => overflows(c),
    time_overflow => time_overflows(c),
    cfd_error => cfd_errors(c),
    measurements => measurements(c),
    start => starts(c),
    commit => commits(c),
    dump => dumps(c),
    eventstream => eventstreams(c),
    valid => eventstream_valids(c),
    ready => eventstream_readys(c)
  );	
		
  valueMux:entity work.mca_value_selector
  generic map(
    VALUE_BITS => MCA_VALUE_BITS,
    NUM_VALUES => MCA_VALUE_SELECT_BITS,
    NUM_VALIDS => MCA_TRIGGER_SELECT_BITS
  )
  port map(
    clk => clk,
    reset => reset,
    measurements => measurements(c),
    value_select => value_select,
    trigger_select => mca_trigger_select,
    value => values_for_mca(c),
    valid => values_for_mca_valids(c)
  );
		
end generate;

mcaChannelSelector:entity work.mca_channel_selector
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  VALUE_BITS => MCA_VALUE_BITS
)
port map(
  clk => clk,
  reset => reset,
  channel_select => mca_channel_select,
  values => values_for_mca,
  valids => values_for_mca_valids,
  value => value_for_mca,
  valid => value_for_mca_valid
);

eventstreamMux:entity eventlib.eventstream_mux
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  RELTIME_BITS => RELATIVETIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICKPERIOD_BITS,
  MIN_TICKPERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH
)
port map(
  clk => clk,
  reset => reset,
  start => starts,
  commit => commits,
  dump => dumps,
  instreams => eventstreams,
  instream_valids => eventstream_valids,
  instream_readys => eventstream_readys,
  full => eventstreammux_full,
  tick_period => tick_period,
  overflows => overflows,
  stream => eventstream,
  valid => eventstream_valid,
  ready => eventstream_ready
);

mca:entity work.mca_unit
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  ADDRESS_BITS => MCA_ADDRESS_BITS,
  COUNTER_BITS => MCA_COUNTER_BITS,
  VALUE_BITS => MCA_VALUE_BITS,
  TOTAL_BITS => MCA_TOTAL_BITS,
  TICKCOUNT_BITS => MCA_TICKCOUNT_BITS,
  TICKPERIOD_BITS => TICKPERIOD_BITS,
  MIN_TICK_PERIOD => MIN_TICKPERIOD
)
port map(
  clk => clk,
  reset => reset,
  initialising => mca_initialising,
  update_asap => mca_update_asap,
  update_on_completion => mca_update_on_completion,
  updated => mca_updated,
  registers => mca_registers,
  tick_period => tick_period,
  channel_select => mca_channel_select,
  value_select => value_select,
  trigger_select => mca_trigger_select,
  value => value_for_mca,
  value_valid => value_for_mca_valid,
  stream => mcastream,
  valid => mcastream_valid,
  ready => mcastream_ready
);

ethernet:entity work.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  TICK_LATENCY_BITS => TICK_LATENCY_BITS,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY
)
port map(
  clk => clk,
  reset => reset,
  mtu => mtu,
  tick_latency => tick_latency,
  eventstream => eventstream,
  eventstream_valid => eventstream_valid,
  eventstream_ready => eventstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

height_unsigneds(0) 
	<= to_unsigned(measurement_registers(0).capture.height_form,4);
height_unsigneds(1) 
	<= to_unsigned(measurement_registers(1).capture.height_form,4);
	
timing_unsigneds(0) 
	<= to_unsigned(measurement_registers(0).capture.timing_trigger,4);
timing_unsigneds(1) 
	<= to_unsigned(measurement_registers(1).capture.timing_trigger,4);
	
mca_value_unsigned <= to_unsigned(mca_registers.value,4);
mca_trigger_unsigned <= to_unsigned(mca_registers.trigger,4);

stimulus:process is
begin
mca_registers.bin_n <= to_unsigned(0,MCA_BIN_N_WIDTH);
mca_registers.channel <= to_unsigned(0,CHANNEL_WIDTH);
mca_registers.value <= FILTERED;
mca_registers.trigger <= CLOCK;
mca_registers.last_bin <= to_unsigned(2**MCA_ADDRESS_BITS-1,MCA_ADDRESS_BITS);
mca_registers.lowest_value <= to_signed(-1,MCA_VALUE_BITS);
mca_registers.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
tick_period <= to_unsigned(32,TICKPERIOD_BITS);
mca_update_asap <= FALSE;
mca_update_on_completion <= FALSE;
--value <= (others => '0');
--value_valid <= TRUE;
--mcastream_ready <= TRUE;
--
measurement_registers(0).dsp.pulse_threshold 
	<= to_unsigned(300,CFD_BITS-CFD_FRAC-1) & to_unsigned(0,CFD_FRAC);
measurement_registers(1).dsp.pulse_threshold 
	<= to_unsigned(300,CFD_BITS-CFD_FRAC-1) & to_unsigned(0,CFD_FRAC);
measurement_registers(0).dsp.slope_threshold 
	<= to_unsigned(10,CFD_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
measurement_registers(1).dsp.slope_threshold 
	<= to_unsigned(10,CFD_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
measurement_registers(0).dsp.baseline.timeconstant
	<= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);
measurement_registers(1).dsp.baseline.timeconstant
	<= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);
measurement_registers(0).dsp.baseline.threshold 
	<= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
measurement_registers(1).dsp.baseline.threshold 
	<= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
measurement_registers(0).dsp.baseline.count_threshold 
	<= to_unsigned(150,BASELINE_COUNTER_BITS);
measurement_registers(1).dsp.baseline.count_threshold 
	<= to_unsigned(150,BASELINE_COUNTER_BITS);
measurement_registers(0).dsp.baseline.average_order <= 4;
measurement_registers(1).dsp.baseline.average_order <= 4;
measurement_registers(0).dsp.baseline.offset <= to_std_logic(260,ADC_BITS);
measurement_registers(1).dsp.baseline.offset <= to_std_logic(260,ADC_BITS);
measurement_registers(0).dsp.constant_fraction 
	<= to_unsigned((2**17)/8,CFD_BITS-1); 
measurement_registers(1).dsp.constant_fraction 
	<= to_unsigned((2**17)/8,CFD_BITS-1); 
measurement_registers(0).dsp.baseline.subtraction <= TRUE;
measurement_registers(1).dsp.baseline.subtraction <= TRUE;
measurement_registers(0).dsp.cfd_relative <= TRUE;
measurement_registers(1).dsp.cfd_relative <= TRUE;
measurement_registers(0).capture.height_form <= CFD_HEIGHT;
measurement_registers(1).capture.height_form <= CFD_HEIGHT;
measurement_registers(0).capture.rel_to_min <= TRUE;
measurement_registers(1).capture.rel_to_min <= TRUE;
measurement_registers(0).capture.timing_trigger <= CFD;
measurement_registers(1).capture.timing_trigger <= CFD;
--eventstream_ready <= TRUE;
--
tick_period <= to_unsigned(2**14-1,TICKPERIOD_BITS);
mtu <= to_unsigned(1500,MTU_BITS);
tick_latency <= to_unsigned((2**14-1)*2,TICK_LATENCY_BITS);
ethernetstream_ready <= TRUE;
--
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait until not mca_initialising;
mca_update_asap <= TRUE;
wait for CLK_PERIOD;
mca_update_asap <= FALSE;

wait;
end process stimulus;

end architecture testbench;
