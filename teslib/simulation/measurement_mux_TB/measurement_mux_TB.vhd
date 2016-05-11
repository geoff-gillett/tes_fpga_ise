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

entity measurement_mux_TB is
generic(
	CHANNEL_BITS:integer:=1;
	FRAMER_ADDRESS_BITS:integer:=10;
	ENDIANNESS:string:="LITTLE"
);
end entity measurement_mux_TB;

architecture testbench of measurement_mux_TB is

constant CHANNELS:integer:=2**CHANNEL_BITS;

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal measurements:measurement_array(CHANNELS-1 downto 0);
signal dumps,commits,peak_overflows:boolean_vector(CHANNELS-1 downto 0);
signal time_overflows,cfd_errors:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams:streambus_array(CHANNELS-1 downto 0);
signal eventstreams_valid:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams_ready:boolean_vector(CHANNELS-1 downto 0);
signal adc_samples:adc_sample_array(CHANNELS-1 downto 0);
signal adc_sample_reg:adc_sample_array(CHANNELS-1 downto 0);
signal adc_sample:adc_sample_t;
signal registers:channel_registers_t;
signal height_type:unsigned(NUM_HEIGHT_D-1 downto 0);
signal event_type:unsigned(DETECTION_D_BITS-1 downto 0);
signal trigger_type:unsigned(TIMING_D_BITS-1 downto 0);
signal eventstreams_int:streambus_array(CHANNELS-1 downto 0);
--
signal baseline_range_errors:boolean_vector(CHANNELS-1 downto 0);
signal framer_overflows:boolean_vector(CHANNELS-1 downto 0);
signal mux_full:boolean;
signal tick_period:unsigned(TICKPERIOD_BITS-1 downto 0);
signal starts:boolean_vector(CHANNELS-1 downto 0);
signal mux_overflows:boolean_vector(CHANNELS-1 downto 0);
signal mux_overflows_u:unsigned(CHANNELS-1 downto 0);
signal muxstream_int,muxstream:streambus_t;
signal muxstream_valid:boolean;
signal muxstream_ready:boolean;
signal window:unsigned(TIME_BITS-1 downto 0);
begin
	
clk <= not clk after CLK_PERIOD/2;

event_type <= to_unsigned(registers.capture.event_type,DETECTION_D_BITS);
height_type <= to_unsigned(registers.capture.height,NUM_HEIGHT_D);
trigger_type 
	<= to_unsigned(registers.capture.timing,TIMING_D_BITS);

chanGen:for c in 0 to CHANNELS-1 generate
begin	
  measurementUnit:entity work.measurement_unit
  generic map(
    CHANNEL => c,
    FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS
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
    mca_value_select => (others => FALSE),
    mca_value => open,
    dump => dumps(c),
    commit => commits(c),
    baseline_underflow => baseline_range_errors(c),
    cfd_error => cfd_errors(c),
    time_overflow => time_overflows(c),
    peak_overflow => peak_overflows(c),
    framer_overflow => framer_overflows(c),
    eventstream => eventstreams_int(c),
    valid => eventstreams_valid(c),
    ready => eventstreams_ready(c)
  );
  
	starts(c) <= measurements(c).trigger;  -- pull out  the mux start signal 
	eventstreams(c) <= SetEndianness(eventstreams_int(c),ENDIANNESS);
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
  TICKPIPE_DEPTH => TICKPIPE_DEPTH
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
  mux_overflows => mux_overflows,
  muxstream => muxstream_int,
  valid => muxstream_valid,
  ready => muxstream_ready
);

mux_overflows_u <= to_unsigned(mux_overflows);
muxstream <= SetEndianness(muxstream_int,ENDIANNESS);

-- all channels see same register settings
stimulus:process is
begin
tick_period <= to_unsigned(2**16-1, TICKPERIOD_BITS);
window <= to_unsigned(1,TIME_BITS);

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
registers.capture.event_type <= PEAK_DETECTION_D;
registers.capture.timing <= CFD_LOW_TIMING_D;
registers.capture.threshold_rel2min <= FALSE;
registers.capture.area_threshold <= to_signed(500,AREA_BITS);
registers.capture.max_peaks <= (others => '1');
wait for CLK_PERIOD;
reset <= '0';
muxstream_ready <= TRUE;
wait for CLK_PERIOD;
wait;
end process stimulus;

end architecture testbench;
