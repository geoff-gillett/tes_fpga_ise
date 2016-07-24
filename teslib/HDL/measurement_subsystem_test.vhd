--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: event_mux_TB
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.ibufds;
use unisim.vcomponents.bufg;
use unisim.vcomponents.bufr;
use unisim.vcomponents.idelayctrl;
use unisim.vcomponents.iodelaye1;
use unisim.vcomponents.iddr;
use unisim.vcomponents.mmcm_adv;
 
library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library mcalib;

library streamlib;
use streamlib.types.all;

use work.types.all;
use work.functions.all;
use work.registers.all;
use work.adc.all;
use work.measurements.all;
use work.dsptypes.all;

entity measurement_subsystem_test is
generic(
  DSP_CHANNELS:integer:=2;
  EVENT_FRAMER_ADDRESS_BITS:integer:=11;
	ENET_FRAMER_ADDRESS_BITS:integer:=11;
	MCA_ADDRESS_BITS:integer:=14;
  MIN_TICKPERIOD:integer:=2**TIME_BITS;
	ENDIANNESS:string:="LITTLE";
	PACKET_GEN:boolean:=TRUE
);
port(
  clk:in std_logic;
  --reset0:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  mca_initialising:out boolean;
  
  samples:in adc_sample_array(DSP_CHANNELS-1 downto 0);
  
  channel_reg:in channel_register_array(DSP_CHANNELS-1 downto 0);
  global_reg:in global_registers_t;
  
  filter_config_data:in config_array(DSP_CHANNELS-1 downto 0);
  filter_config_valid:in std_logic_vector(DSP_CHANNELS-1 downto 0);
  filter_config_ready:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  filter_data:in coef_array(DSP_CHANNELS-1 downto 0);
  filter_valid:in std_logic_vector(DSP_CHANNELS-1 downto 0);
  filter_ready:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  filter_last:in std_logic_vector(DSP_CHANNELS-1 downto 0);
  filter_last_missing:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  filter_last_unexpected:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  dif_config_data:in config_array(DSP_CHANNELS-1 downto 0);
  dif_config_valid:in std_logic_vector(DSP_CHANNELS-1 downto 0);
  dif_config_ready:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  dif_data:in coef_array(DSP_CHANNELS-1 downto 0);
  dif_valid:in std_logic_vector(DSP_CHANNELS-1 downto 0);
  dif_ready:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  dif_last:in std_logic_vector(DSP_CHANNELS-1 downto 0);
  dif_last_missing:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  dif_last_unexpected:out std_logic_vector(DSP_CHANNELS-1 downto 0);
  
  measurements:out measurement_array(DSP_CHANNELS-1 downto 0);
  
  ethernetstream:out streambus_t;
  ethernetstream_valid:out boolean;
  ethernetstream_ready:in boolean
  
);
end entity measurement_subsystem_test;

architecture RTL of measurement_subsystem_test is
	
signal adc_delayed:adc_sample_array(DSP_CHANNELS-1 downto 0);

-- MCA
type value_sel_array is array (natural range <>) of 
  std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
  
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
signal value_sel_reg:value_sel_array(CHANNELS-1 downto 0);

signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal mca_values,mca_values_reg:mca_value_array(DSP_CHANNELS-1 downto 0);
signal mca_value_valids:boolean_vector(DSP_CHANNELS-1 downto 0);
signal dumps,event_dumps:boolean_vector(DSP_CHANNELS-1 downto 0);
signal commits,event_commits:boolean_vector(DSP_CHANNELS-1 downto 0);
signal starts,event_starts:boolean_vector(DSP_CHANNELS-1 downto 0);
signal baseline_errors:boolean_vector(DSP_CHANNELS-1 downto 0);
signal cfd_errors:boolean_vector(DSP_CHANNELS-1 downto 0);
signal time_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal peak_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal framer_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal channel_select:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal mca_value:signed(MCA_VALUE_BITS-1 downto 0);
signal mca_value_valid:boolean;

signal updated:boolean;
signal mcastream:streambus_t;
signal mcastream_valid,mca_valid:boolean;
signal mcastream_ready,mca_ready:boolean;

signal eventstreams:streambus_array(DSP_CHANNELS-1 downto 0);
signal eventstreams_valid,events_valid:boolean_vector(DSP_CHANNELS-1 downto 0);
signal eventstreams_ready,events_ready:boolean_vector(DSP_CHANNELS-1 downto 0);

signal muxstream:streambus_t;
signal muxstream_valid:boolean;
signal muxstream_ready:boolean;

signal mux_full:boolean;
signal mux_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal measurement_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);

-- test signals
signal framestream:streambus_t;
signal framestream_valid:boolean;
signal framestream_ready:boolean;

--------------------------------------------------------------------------------
--debug
constant DEBUG:string:="FALSE";
attribute MARK_DEBUG:string;

--attribute MARK_DEBUG of reset1:signal is DEBUG;
attribute MARK_DEBUG of muxstream_valid:signal is DEBUG;
attribute MARK_DEBUG of muxstream_ready:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_ready:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_valid:signal is DEBUG;

begin

--------------------------------------------------------------------------------
-- processing channels
--------------------------------------------------------------------------------
tesChannel:for c in DSP_CHANNELS-1 downto 0 generate

  delay:entity work.RAM_delay
  generic map(
    DEPTH => 2**DELAY_BITS,
    DATA_BITS => ADC_BITS
  )
  port map(
    clk => clk,
    data_in => samples(c),
    delay => to_integer(channel_reg(c).capture.delay),
    delayed => adc_delayed(c)
  );
--
	measurement:entity work.measurement_unit
  generic map(
    FRAMER_ADDRESS_BITS => EVENT_FRAMER_ADDRESS_BITS,
    CHANNEL => c,
    ENDIANNESS => ENDIANNESS
  )
  port map(
    clk => clk,
    reset => reset2,
    adc_sample => samples(c),
    registers => channel_reg(c),
    filter_config_data => filter_config_data(c),
    filter_config_valid => filter_config_valid(c),
    filter_config_ready => filter_config_ready(c),
    filter_reload_data => filter_data(c),
    filter_reload_valid => filter_valid(c),
    filter_reload_ready => filter_ready(c),
    filter_reload_last => filter_last(c),
    filter_reload_last_missing => filter_last_missing(c),
    filter_reload_last_unexpected => filter_last_unexpected(c),
    dif_config_data => dif_config_data(c),
    dif_config_valid => dif_config_valid(c),
    dif_config_ready => dif_config_ready(c),
    dif_reload_data => dif_data(c),
    dif_reload_valid => dif_valid(c),
    dif_reload_ready => dif_ready(c),
    dif_reload_last => dif_last(c),
    dif_reload_last_missing => dif_last_missing(c),
    dif_reload_last_unexpected => dif_last_unexpected(c),
    measurements => measurements(c),
    mca_value_select => value_sel_reg(c),
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
  
  valueReg:process(clk)
  begin
    if rising_edge(clk) then
      value_sel_reg(c) <= value_select; 
      mca_values_reg(c) <= mca_values(c); --can meet timing without this
    end if;
  end process valueReg;
  
end generate tesChannel;
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
--tickTest:if TICK_TEST generate
--  events_valid <= (others => FALSE);
--  eventstreams_ready <= (others => FALSE);
--  mcastream_ready <= FALSE;
--  mca_valid <= FALSE;
--  event_starts <= (others => FALSE);
--  event_commits <= (others => FALSE);
--  event_dumps <= (others => FALSE);
--end generate tickTest;


--noTickTest:if not TICK_TEST generate
--  events_valid <= eventstreams_valid;
--  eventstreams_ready <= events_ready;
--  mca_valid <= mcastream_valid;
--  mcastream_ready <= mca_ready;
--  event_starts <= starts;
--  event_commits <= commits;
--  event_dumps <= dumps;
--end generate noTickTest;

mux:entity work.eventstream_mux
generic map(
  --CHANNEL_BITS => CHANNEL_BITS,
  CHANNELS => DSP_CHANNELS,
  TIME_BITS => TIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICKPERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset1,
  start => (others => FALSE),
  commit => (others => FALSE),
  dump => (others => FALSE),
  instreams => eventstreams,
  instream_valids => eventstreams_valid,
  instream_readys => eventstreams_ready,
  full => mux_full,
  tick_period => to_unsigned(2**16,32), --global_reg.tick_period,
  window => to_unsigned(25, 16), --global_reg.window,
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
  CHANNELS => DSP_CHANNELS,
  VALUE_BITS   => MCA_VALUE_BITS
)
port map(
  clk => clk,
  reset => reset1,
  channel_select => channel_select,
  values => mca_values_reg,
  valids => mca_value_valids,
  value => mca_value,
  valid => mca_value_valid
);

mca:entity work.mca_unit
generic map(
  CHANNELS => DSP_CHANNELS,
  ADDRESS_BITS => MCA_ADDRESS_BITS,
  COUNTER_BITS => MCA_COUNTER_BITS,
  VALUE_BITS => MCA_VALUE_BITS,
  TOTAL_BITS => MCA_TOTAL_BITS,
  TICKCOUNT_BITS => MCA_TICKCOUNT_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICK_PERIOD => MIN_TICK_PERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset1,
  initialising => mca_initialising,
  --TODO remove redundant register port
  update_asap => global_reg.mca.update_asap,
  --TODO remove redundant register port
  update_on_completion => global_reg.mca.update_on_completion,
  updated => updated, --TODO implement CPU interupt
  registers => global_reg.mca,
  --TODO remove redundant register port
  tick_period => global_reg.tick_period,
  channel_select => channel_select,
  value_select => value_select,
  trigger_select => trigger_select,
  value => mca_value,
  value_valid => mca_value_valid,
  stream => mcastream,
  valid => mcastream_valid,
  ready => mcastream_ready
);


--eventGen:entity work.event_generator
--port map(
--  clk => clk,
--  reset => reset2,
--  stream => muxstream,
--  valid => muxstream_valid,
--  ready => muxstream_ready
--);

enet:entity work.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  FRAMER_ADDRESS_BITS => ENET_FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset2,
  mtu => to_unsigned(1500,MTU_BITS),
  tick_latency => global_reg.tick_latency,
  eventstream => muxstream,
  eventstream_valid => muxstream_valid,
  eventstream_ready => muxstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => framestream,
  ethernetstream_valid => framestream_valid,
  ethernetstream_ready => framestream_ready
);

noPacketGen:if not PACKET_GEN generate
  ethernetstream <= framestream;
  ethernetstream_valid <= framestream_valid;
  framestream_ready <= ethernetstream_ready;
end generate noPacketGen;

packetGen:if PACKET_GEN generate
  packetGen:entity work.packet_generator
  port map(
    clk => clk,
    reset => reset2,
    period => to_unsigned(25000000,32),
    stream => ethernetstream,
    ready => ethernetstream_ready,
    valid => ethernetstream_valid
  );
end generate packetGen;

end architecture RTL;
