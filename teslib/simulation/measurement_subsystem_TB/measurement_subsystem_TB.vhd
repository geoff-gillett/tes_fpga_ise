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

entity measurement_subsystem_TB is
generic(
	CHANNEL_BITS:integer:=1;
	FRAMER_ADDRESS_BITS:integer:=14;
	ENDIANNESS:string:="LITTLE";
  MIN_TICK_PERIOD:integer:=2**16;
  MCA_ADDRESS_BITS:integer:=14
);
end entity measurement_subsystem_TB;

architecture testbench of measurement_subsystem_TB is

constant CHANNELS:integer:=2**CHANNEL_BITS;

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal measurements:measurement_array_t(CHANNELS-1 downto 0);
signal dumps,commits,peak_overflows:boolean_vector(CHANNELS-1 downto 0);
signal time_overflows,cfd_errors:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams_valid:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams_ready:boolean_vector(CHANNELS-1 downto 0);
signal adc_samples:adc_sample_array_t(CHANNELS-1 downto 0);
signal adc_sample_reg:adc_sample_array_t(CHANNELS-1 downto 0);
signal adc_sample:adc_sample_t;
signal registers:measurement_registers_t;
signal height_type:unsigned(HEIGHT_TYPE_BITS-1 downto 0);
signal detection_type:unsigned(DETECTION_TYPE_BITS-1 downto 0);
signal trigger_type:unsigned(TIMING_TRIGGER_TYPE_BITS-1 downto 0);
signal eventstreams_int:streambus_array_t(CHANNELS-1 downto 0);
signal baseline_range_errors:boolean_vector(CHANNELS-1 downto 0);
signal framer_overflows:boolean_vector(CHANNELS-1 downto 0);
signal mux_full:boolean;
signal tick_period:unsigned(TICKPERIOD_BITS-1 downto 0);
signal starts:boolean_vector(CHANNELS-1 downto 0);
signal mux_overflows:boolean_vector(CHANNELS-1 downto 0);
signal mux_overflows_u:unsigned(CHANNELS-1 downto 0);
signal muxstream:streambus_t;
signal muxstream_valid:boolean;
signal muxstream_ready:boolean;
signal mcastream:streambus_t;
signal ethernetstream_int:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
signal mtu:unsigned(MTU_BITS-1 downto 0);
signal tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal window:unsigned(TIME_BITS-1 downto 0);
--mca
signal mca_initialising:boolean;
signal update_asap:boolean;
signal update_on_completion:boolean;
signal updated:boolean;
signal mca_registers:mca_registers_t;
signal channel_select:std_logic_vector(CHANNELS-1 downto 0);
signal value_select:std_logic_vector(NUM_MCA_VALUES-1 downto 0);
-- don't need bit for mca_trigger_d 0=DISABLED
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGERS-2 downto 0);
signal mca_values:mca_value_array(CHANNELS-1 downto 0);
signal mca_value_valid:boolean;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal mca_value_valids:boolean_vector(CHANNELS-1 downto 0);
signal mca_value:signed(MCA_VALUE_BITS-1 downto 0);
signal mca_value_type:unsigned(ceilLog2(NUM_MCA_VALUES)-1 downto 0);
signal mca_trigger_type:unsigned(ceilLog2(NUM_MCA_TRIGGERS)-1 downto 0);
begin
	
clk <= not clk after CLK_PERIOD/2;

detection_type <= to_unsigned(
	registers.capture.detection_type,DETECTION_TYPE_BITS
);
height_type <= to_unsigned(registers.capture.height_type,HEIGHT_TYPE_BITS);
trigger_type <= to_unsigned(
	registers.capture.trigger_type,TIMING_TRIGGER_TYPE_BITS
);
mca_value_type <= to_unsigned(mca_registers.value,ceilLog2(NUM_MCA_VALUES));
mca_trigger_type <= to_unsigned(mca_registers.value,ceilLog2(NUM_MCA_TRIGGERS));

chanGen:for c in 0 to CHANNELS-1 generate
begin	
  measurementUnit:entity work.measurement_unit
  generic map(
    CHANNEL => c,
    FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
    ENDIANNESS => ENDIANNESS
  )
  port map(
    clk => clk,
    reset => reset,
    adc_sample => adc_samples(c),
    registers => registers, -- use same registers for all channels
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
    measurements => measurements(c),
    mca_value_select => value_select,
    mca_trigger_select => trigger_select,
    mca_value => mca_values(c),
    mca_value_valid => mca_value_valids(c),
    dump => dumps(c),
    commit => commits(c),
    baseline_range_error => baseline_range_errors(c),
    cfd_error => cfd_errors(c),
    time_overflow => time_overflows(c),
    peak_overflow => peak_overflows(c),
    framer_overflow => framer_overflows(c),
    eventstream => eventstreams_int(c),
    valid => eventstreams_valid(c),
    ready => eventstreams_ready(c)
  );
	starts(c) <= measurements(c).trigger;  -- pull out  the mux start signal 
end generate chanGen;

-- each channel sees same adc_sample delayed by its channel number
sample:process(clk)
begin
	if rising_edge(clk) then
		adc_samples(0) <= adc_sample;
		adc_sample_reg(0) <= adc_sample;
	end if;
end process sample;

delayGen:for i in 1 to CHANNELS-1 generate
  sampleDelay:process (clk) is
  begin
    if rising_edge(clk) then
      adc_samples(i) <= adc_sample_reg(i-1);
      adc_sample_reg(i) <= adc_sample_reg(i-1);
    end if;
  end process sampleDelay;
end generate delayGen;

mux:entity work.eventstream_mux
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  RELTIME_BITS => TIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICKPERIOD_BITS,
  MIN_TICKPERIOD => 2**14,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset,
  start => starts,
  commit => commits,
  dump => dumps,
  instreams => eventstreams_int,
  instream_valids => eventstreams_valid,
  instream_readys => eventstreams_ready,
  full => mux_full,
  tick_period => tick_period,
  window => window,
  overflows => mux_overflows,
  muxstream => muxstream,
  valid => muxstream_valid,
  ready => muxstream_ready
);
mux_overflows_u <= to_unsigned(mux_overflows);

mcaChanSel:entity work.mca_channel_selector
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  VALUE_BITS   => MCA_VALUE_BITS
)
port map(
  clk => clk,
  reset => reset,
  channel_select => channel_select,
  values => mca_values,
  valids => mca_value_valids,
  value => mca_value,
  valid => mca_value_valid
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
  MIN_TICK_PERIOD => MIN_TICK_PERIOD,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset,
  initialising => mca_initialising,
  update_asap => update_asap,
  update_on_completion => update_on_completion,
  updated => updated,
  registers => mca_registers,
  tick_period => tick_period,
  channel_select => channel_select,
  value_select => value_select,
  trigger_select => trigger_select,
  value => mca_value,
  value_valid => mca_value_valid,
  stream => mcastream,
  valid => mcastream_valid,
  ready => mcastream_ready
);

enet:entity work.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  TICK_LATENCY_BITS => TICK_LATENCY_BITS,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset,
  mtu => mtu,
  tick_latency => tick_latency,
  eventstream => muxstream,
  eventstream_valid => muxstream_valid,
  eventstream_ready => muxstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => ethernetstream_int,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

-- all channels see same register settings
stimulus:process is
begin
mtu <= to_unsigned(1500,MTU_BITS);
tick_period <= to_unsigned(2**16, TICKPERIOD_BITS);
window <= to_unsigned(1,TIME_BITS);
tick_latency <= to_unsigned(2**16, TICKPERIOD_BITS);

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
registers.capture.constant_fraction 
	<= to_unsigned((2**(CFD_BITS-1))/5,CFD_BITS-1); --20%
registers.capture.cfd_rel2min <= TRUE;
registers.capture.height_type <= PEAK_HEIGHT_D;
registers.capture.detection_type <= PEAK_DETECTION_D;
registers.capture.trigger_type <= CFD_LOW_TIMING_D;
registers.capture.threshold_rel2min <= FALSE;
registers.capture.height_rel2min <= FALSE;
registers.capture.pulse_area_threshold <= to_signed(500,AREA_BITS);
registers.capture.max_peaks <= (others => '1');

mca_registers.channel <= (others => '0');
mca_registers.bin_n <= (others => '0');
mca_registers.last_bin <= (others => '1');
mca_registers.lowest_value <= to_signed(-1000, MCA_VALUE_BITS);
mca_registers.value <= MCA_FILTERED_SIGNAL;
mca_registers.trigger <= CLOCK_MCA_TRIGGER;
mca_registers.ticks <= (0 => '1', others => '0');

update_on_completion <= FALSE;

wait for CLK_PERIOD;
reset <= '0';
ethernetstream_ready <= TRUE;
wait until not mca_initialising;
wait for CLK_PERIOD;
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait;
end process stimulus;

end architecture testbench;
