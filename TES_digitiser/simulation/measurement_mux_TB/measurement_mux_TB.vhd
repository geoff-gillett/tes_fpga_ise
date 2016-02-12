--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: measurement_mux_TB
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
use dsplib.types.all;

library streamlib;
use streamlib.stream.all;

library eventlib;
use eventlib.events.all;

library adclib;
use adclib.types.all;

--library main;
use work.registers.all;
use work.measurements.all;

entity measurement_mux_TB is
generic(
  CHANNEL_BITS:integer:=1;
  FRAMER_ADDRESS_BITS:integer:=10;
  BASELINE_BITS:integer:=10;
  BASELINE_COUNTER_BITS:integer:=18;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  TICK_BITS:integer:=32;
  MIN_TICKPERIOD:integer:=8
);
end entity measurement_mux_TB;

architecture testbench of measurement_mux_TB is

constant CHANNELS:integer:=2**CHANNEL_BITS; 

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal adc_sample:adc_sample_t;
signal cfd_errors:boolean_vector(CHANNELS-1 downto 0);
signal time_overflows:boolean_vector(CHANNELS-1 downto 0);

signal overflows:boolean_vector(CHANNELS-1 downto 0);
signal dumps:boolean_vector(CHANNELS-1 downto 0);
signal commits:boolean_vector(CHANNELS-1 downto 0);

signal eventstreams:streambus_array(CHANNELS-1 downto 0);
signal valids:boolean_vector(CHANNELS-1 downto 0);
signal readys:boolean_vector(CHANNELS-1 downto 0);
--signal event_LE:std_logic_vector(BUS_DATABITS-1 downto 0);
--signal height_slv:std_logic_vector(1 downto 0);
signal adc_samples:adc_sample_array(CHANNELS-1 downto 0);
signal full:boolean;
signal tick_period:unsigned(TICK_BITS-1 downto 0);
signal outstream:streambus_t;
signal valid:boolean;
signal ready:boolean;
type heighttype_slv_array is array (natural range <>) of 
		 std_logic_vector(HEIGHT_TYPE_BITS-1 downto 0);
signal height_slvs:heighttype_slv_array(CHANNELS-1 downto 0);
--
signal registers:measurement_register_array(CHANNELS-1 downto 0);
signal measurements:measurement_array(CHANNELS-1 downto 0);
signal starts:boolean_vector(CHANNELS-1 downto 0);
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
	measure:entity work.measurement_unit
  generic map(
    CHANNEL => c,
    FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS
  )
  port map(
    clk => clk,
    reset => reset,
    adc_sample => adc_samples(c),
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
    overflow => overflows(c),
    time_overflow => time_overflows(c),
    cfd_error => cfd_errors(c),
    measurements => measurements(c),
    start => starts(c),
    commit => commits(c),
    dump => dumps(c),
    eventstream => eventstreams(c),
    valid => valids(c),
    ready => readys(c)
  );
end generate;

mux:entity eventlib.eventstream_mux
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  RELTIME_BITS => TIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICK_BITS,
  MIN_TICKPERIOD => MIN_TICKPERIOD
)
port map(
  clk => clk,
  reset => reset,
  start => starts,
  commit => commits,
  dump => dumps,
  instreams => eventstreams,
  instream_valids => valids,
  instream_readys => readys,
  full => full,
  tick_period => tick_period,
  overflows => overflows,
  stream => outstream,
  valid => valid,
  ready => ready
);

height_slvs(0) <= to_std_logic(registers(0).capture.height_form,2);
height_slvs(1) <= to_std_logic(registers(1).capture.height_form,2);

stimulus:process is
begin
registers(0).dsp.pulse_threshold 
	<= to_unsigned(300,CFD_BITS-CFD_FRAC-1) & to_unsigned(0,CFD_FRAC);
registers(1).dsp.pulse_threshold 
	<= to_unsigned(300,CFD_BITS-CFD_FRAC-1) & to_unsigned(0,CFD_FRAC);
	
registers(0).dsp.slope_threshold 
	<= to_unsigned(10,CFD_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
registers(1).dsp.slope_threshold 
	<= to_unsigned(10,CFD_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
	
registers(0).dsp.baseline.timeconstant
	<= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);
registers(1).dsp.baseline.timeconstant
	<= to_unsigned(2**15,BASELINE_TIMECONSTANT_BITS);

registers(0).dsp.baseline.threshold 
	<= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
registers(1).dsp.baseline.threshold 
	<= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);

registers(0).dsp.baseline.count_threshold 
	<= to_unsigned(150,BASELINE_COUNTER_BITS);
registers(1).dsp.baseline.count_threshold 
	<= to_unsigned(150,BASELINE_COUNTER_BITS);

registers(0).dsp.baseline.average_order <= 4;
registers(1).dsp.baseline.average_order <= 4;

registers(0).dsp.baseline.offset <= to_std_logic(to_unsigned(260,ADC_BITS));
registers(1).dsp.baseline.offset <= to_std_logic(to_unsigned(260,ADC_BITS));

registers(0).dsp.constant_fraction <= to_unsigned((2**17)/8,CFD_BITS-1); 
registers(1).dsp.constant_fraction <= to_unsigned((2**17)/8,CFD_BITS-1); 

registers(0).dsp.baseline.subtraction <= TRUE;
registers(1).dsp.baseline.subtraction <= TRUE;

registers(0).dsp.cfd_relative <= TRUE;
registers(1).dsp.cfd_relative <= TRUE;

registers(0).capture.height_form <= CFD_HEIGHT;
registers(1).capture.height_form <= CFD_HEIGHT;

registers(0).capture.rel_to_min <= TRUE;
registers(1).capture.rel_to_min <= TRUE;

registers(0).capture.use_cfd_timing <= TRUE;
registers(1).capture.use_cfd_timing <= TRUE;

ready <= TRUE;
tick_period <= to_unsigned(2**16,TICK_BITS);
wait for CLK_PERIOD;
--adc_samples <= adc_baselines;
reset <= '0';
wait for CLK_PERIOD;

wait;
end process stimulus;

end architecture testbench;
