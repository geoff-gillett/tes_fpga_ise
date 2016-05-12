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
use work.adc.all; --TODO move to types
use work.dsptypes.all; --TODO move to types

entity measurement_overflow_TB is
generic(
	CHANNEL_BITS:integer:=1;
	EVENT_FRAMER_ADDRESS_BITS:integer:=8;
	ETHERNET_FRAMER_ADDRESS_BITS:integer:=10;
	ENDIANNESS:string:="LITTLE";
  MIN_TICKPERIOD:integer:=2**8;
  MCA_ADDRESS_BITS:integer:=14
);
end entity measurement_overflow_TB;

architecture testbench of measurement_overflow_TB is

constant CHANNELS:integer:=2**CHANNEL_BITS;

signal sample_clk:std_logic:='1';	
signal IO_clk:std_logic:='1';	
signal sample_reset:std_logic:='1';	
signal IO_reset:std_logic:='1';	
constant SAMPLE_CLK_PERIOD:time:=4 ns;
constant IO_CLK_PERIOD:time:=8 ns;

signal measurements:measurement_array(CHANNELS-1 downto 0);
signal dumps,commits:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams_valid:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams_ready:boolean_vector(CHANNELS-1 downto 0);
signal adc_samples,adc_delayed:adc_sample_array(CHANNELS-1 downto 0);
signal registers:channel_register_array(CHANNELS-1 downto 0);

-- discrete types as unsigned for reading into settings file
type height_type_array is array (natural range <>) of
		 unsigned(NUM_HEIGHT_D-1 downto 0);
signal height_types:height_type_array(CHANNELS-1 downto 0);
type detection_type_array is array (natural range <>) of
		 unsigned(DETECTION_D_BITS-1 downto 0);
signal detection_types:detection_type_array(CHANNELS-1 downto 0);
type trigger_type_array is array (natural range <>) of
		 unsigned(TIMING_D_BITS-1 downto 0);
signal trigger_types:trigger_type_array(CHANNELS-1 downto 0);
signal mca_value_type:unsigned(ceilLog2(NUM_MCA_VALUE_D)-1 downto 0);
signal mca_trigger_type:unsigned(ceilLog2(NUM_MCA_TRIGGER_D)-1 downto 0);
-- error signals
signal mux_overflows:boolean_vector(CHANNELS-1 downto 0);
signal mux_overflows_u:unsigned(CHANNELS-1 downto 0);
signal framer_overflows:boolean_vector(CHANNELS-1 downto 0);
signal framer_overflows_u:unsigned(CHANNELS-1 downto 0);
signal measurement_overflows:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal measurement_overflows_u:unsigned(CHANNELS-1 downto 0);
signal mux_full:boolean;
signal time_overflows,cfd_errors:boolean_vector(CHANNELS-1 downto 0);
signal time_overflows_u,cfd_errors_u:unsigned(CHANNELS-1 downto 0);
signal baseline_errors:boolean_vector(CHANNELS-1 downto 0);
signal baseline_errors_u:unsigned(CHANNELS-1 downto 0);
signal peak_overflows:boolean_vector(CHANNELS-1 downto 0);
signal peak_overflows_u:unsigned(CHANNELS-1 downto 0);
--
signal eventstreams:streambus_array(CHANNELS-1 downto 0);
signal tick_period:unsigned(TICK_PERIOD_BITS-1 downto 0);
signal starts:boolean_vector(CHANNELS-1 downto 0);
signal muxstream:streambus_t;
signal muxstream_valid:boolean;
signal muxstream_ready:boolean;
signal mcastream:streambus_t;
signal ethernetstream:streambus_t;
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
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
-- don't need bit for mca_trigger_d 0=DISABLED
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal mca_values:mca_value_array(CHANNELS-1 downto 0);
signal mca_value_valid:boolean;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal mca_value_valids:boolean_vector(CHANNELS-1 downto 0);
signal mca_value:signed(MCA_VALUE_BITS-1 downto 0);
signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:boolean;
signal bytestream_last:boolean;

begin
	
sample_clk <= not sample_clk after SAMPLE_CLK_PERIOD/2;
IO_clk <= not IO_clk after IO_CLK_PERIOD/2;

mca_value_type 
	<= unsigned(to_std_logic(mca_registers.value,ceilLog2(NUM_MCA_VALUE_D)));
mca_trigger_type 
	<= unsigned(to_std_logic(mca_registers.value,ceilLog2(NUM_MCA_TRIGGER_D)));

chanGen:for c in 0 to CHANNELS-1 generate
begin	
	
	--FIXME	move delay into measurement_unit so that it acts on the signal after
	-- baseline
	delay:entity work.RAM_delay
  generic map(
    DEPTH     => 2**DELAY_BITS,
    DATA_BITS => ADC_BITS
  )
  port map(
    clk => sample_clk,
    data_in => adc_samples(c),
    delay => to_integer(registers(c).capture.delay),
    delayed => adc_delayed(c)
  );

	measurementUnit:entity work.measurement_unit
  generic map(
    FRAMER_ADDRESS_BITS => EVENT_FRAMER_ADDRESS_BITS,
    CHANNEL => c,
    ENDIANNESS => ENDIANNESS
  )
  port map(
    clk => sample_clk,
    reset => sample_reset,
    adc_sample => adc_delayed(c),
    registers => registers(c),
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
    mux_full => mux_full,
    start => starts(c),
    dump => dumps(c),
    commit => commits(c),
    cfd_error => cfd_errors(c),
    time_overflow => time_overflows(c),
    peak_overflow => peak_overflows(c),
    framer_overflow => framer_overflows(c),
    mux_overflow => mux_overflows(c),
    measurement_overflow => measurement_overflows(c),
    baseline_underflow => baseline_errors(c),
    eventstream => eventstreams(c),
    valid => eventstreams_valid(c),
    ready => eventstreams_ready(c)
  );
	
  detection_types(0) 
  	<= unsigned(to_std_logic(registers(0).capture.detection,DETECTION_D_BITS));
  height_types(0) 
  	<= unsigned(to_std_logic(registers(0).capture.height,HEIGHT_D_BITS));
  trigger_types(0) 
  	<= unsigned(to_std_logic(registers(0).capture.timing,TIMING_D_BITS));
end generate chanGen;

-- unsigned value for writing to file
baseline_errors_u <= to_unsigned(baseline_errors);
cfd_errors_u <= to_unsigned(cfd_errors);
time_overflows_u <= to_unsigned(time_overflows);
peak_overflows_u <= to_unsigned(peak_overflows);
framer_overflows_u <= to_unsigned(framer_overflows);
mux_overflows_u <= to_unsigned(mux_overflows);
measurement_overflows_u <= to_unsigned(measurement_overflows);

-- each channel sees same adc_sample delayed by its channel number
mux:entity work.eventstream_mux
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  RELTIME_BITS => TIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICKPERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
  start => starts,
  commit => commits,
  dump => dumps,
  instreams => eventstreams,
  instream_valids => eventstreams_valid,
  instream_readys => eventstreams_ready,
  full => mux_full,
  tick_period => tick_period,
  window => window,
  cfd_errors => cfd_errors,
  framer_overflows => framer_overflows,
  mux_overflows => mux_overflows,
  measurement_overflows => measurement_overflows,
  peak_overflows => peak_overflows,
  time_overflows => time_overflows,
  baseline_underflows => baseline_errors,
  muxstream => muxstream,
  valid => muxstream_valid,
  ready => muxstream_ready
);

mcaChanSel:entity work.mca_channel_selector
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  VALUE_BITS   => MCA_VALUE_BITS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
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
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICK_PERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
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
  FRAMER_ADDRESS_BITS => ETHERNET_FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
  mtu => mtu,
  tick_latency => tick_latency,
  eventstream => muxstream,
  eventstream_valid => muxstream_valid,
  eventstream_ready => muxstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

cdc:entity work.CDC_bytestream_adapter
port map(
  s_clk => sample_clk,
  s_reset => sample_reset,
  streambus => ethernetstream,
  streambus_valid => ethernetstream_valid,
  streambus_ready => ethernetstream_ready,
  b_clk => IO_clk,
  b_reset => IO_reset,
  bytestream => bytestream,
  bytestream_valid => bytestream_valid,
  bytestream_ready => bytestream_ready,
  bytestream_last => bytestream_last
);

-- all channels see same register settings
stimulus:process is
begin
mtu <= to_unsigned(800,MTU_BITS);
tick_period <= to_unsigned(2**14,TICK_PERIOD_BITS);
window <= to_unsigned(2,TIME_BITS);
tick_latency <= to_unsigned(2**16,TICK_PERIOD_BITS);

-- register settings common to all channels
for c in CHANNELS-1 downto 0 loop 
  registers(c).capture.pulse_threshold 
  	<= to_unsigned(0,DSP_BITS-DSP_FRAC-1) & to_unsigned(0,DSP_FRAC);
  registers(c).capture.slope_threshold 
  	<= to_unsigned(5,DSP_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
  registers(c).baseline.timeconstant 
    <= to_unsigned(2**12,BASELINE_TIMECONSTANT_BITS);
  registers(c).baseline.threshold 
    <= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
  registers(c).baseline.count_threshold 
    <= to_unsigned(30,BASELINE_COUNTER_BITS);
  registers(c).baseline.average_order <= 4;
  registers(c).baseline.offset <= to_std_logic(20,ADC_BITS);
  registers(c).baseline.subtraction <= FALSE;
  registers(c).capture.constant_fraction 
    <= to_unsigned((2**(CFD_BITS-1))/5,CFD_BITS-1); --20%
  registers(c).capture.cfd_rel2min <= TRUE;
  registers(c).capture.height <= PEAK_HEIGHT_D;
  registers(c).capture.detection <= AREA_DETECTION_D;
  registers(c).capture.timing <= PULSE_THRESH_TIMING_D;
  registers(c).capture.threshold_rel2min <= FALSE;
  registers(c).capture.height_rel2min <= FALSE;
  registers(c).capture.area_threshold <= to_signed(300000,AREA_BITS);
  registers(c).capture.max_peaks <= (0 => '0', others => '0');
  registers(c).capture.delay <= to_unsigned(0,DELAY_BITS);
  registers(c).capture.full_trace <= TRUE;
  registers(c).capture.trace0 <= NO_TRACE_D;
  registers(c).capture.trace1 <= NO_TRACE_D;
end loop;

--registers(1).capture.detection <= TRACE_DETECTION_D;
--registers(1).capture.trace0 <= FILTERED_TRACE_D;
--registers(1).capture.trace1 <= RAW_TRACE_D;
--registers(2).capture.detection <= PULSE_DETECTION_D;
--registers(2).capture.max_peaks <= (0 => '1', others => '0');
--registers(3).capture.detection <= TRACE_DETECTION_D;
--registers(3).capture.trace0 <= FILTERED_TRACE_D;
--registers(3).capture.trace1 <= RAW_TRACE_D;
--registers(4).capture.detection <= TRACE_DETECTION_D;
--registers(4).capture.trace0 <= FILTERED_TRACE_D;
--registers(4).capture.trace1 <= SLOPE_TRACE_D;
--registers(4).capture.full_trace <= FALSE;
--registers(7).capture.detection <= AREA_DETECTION_D;

mca_registers.channel <= (others => '0');
mca_registers.bin_n <= (others => '0');
mca_registers.last_bin <= (others => '1');
mca_registers.lowest_value <= to_signed(-1000, MCA_VALUE_BITS);
mca_registers.value <= MCA_FILTERED_AREA_D;
mca_registers.trigger <= DISABLED_MCA_TRIGGER_D;
mca_registers.ticks <= (0 => '1', others => '0');

update_on_completion <= FALSE;

wait for IO_CLK_PERIOD;
sample_reset <= '0';
IO_reset <= '0';
bytestream_ready <= FALSE;
wait until not mca_initialising;
wait for SAMPLE_CLK_PERIOD;
update_asap <= TRUE;
wait for SAMPLE_CLK_PERIOD;
update_asap <= FALSE;
wait for IO_CLK_PERIOD*10;
wait until bytestream_last and bytestream_ready and bytestream_valid;
bytestream_ready <= FALSE;
wait for IO_CLK_PERIOD*24;
bytestream_ready <= TRUE;
wait;
end process stimulus;

end architecture testbench;
