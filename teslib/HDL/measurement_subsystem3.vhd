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
use work.measurements.all;

entity measurement_subsystem3 is
generic(
  DSP_CHANNELS:integer:=2;
	ENDIAN:string:="LITTLE";
	PACKET_GEN:boolean:=FALSE
);
port(
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  mca_initialising:out boolean;
  
  samples:in adc_sample_array(ADC_CHANNELS-1 downto 0);
  
  channel_reg:in channel_register_array(DSP_CHANNELS-1 downto 0);
  global_reg:in global_registers_t;
  
  filter_config:in fir_ctl_in_array(DSP_CHANNELS-1 downto 0);
  filter_events:out fir_ctl_out_array(DSP_CHANNELS-1 downto 0);
  slope_config:in fir_ctl_in_array(DSP_CHANNELS-1 downto 0);
  slope_events:out fir_ctl_out_array(DSP_CHANNELS-1 downto 0);
  baseline_config:in fir_ctl_in_array(DSP_CHANNELS-1 downto 0);
  baseline_events:out fir_ctl_out_array(DSP_CHANNELS-1 downto 0);
  
  measurements:out measurements_array(DSP_CHANNELS-1 downto 0);
  
  ethernetstream:out streambus_t;
  ethernetstream_valid:out boolean;
  ethernetstream_ready:in boolean
  
);
end entity measurement_subsystem3;

architecture RTL of measurement_subsystem3 is
	
signal adc_delayed,adc_mux:adc_sample_array(DSP_CHANNELS-1 downto 0);

-- MCA
--type value_sel_array is array (natural range <>) of 
--  std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
  
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);

signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal mca_values,mca_values_reg:mca_value_array(DSP_CHANNELS-1 downto 0);
signal mca_value_valids:boolean_vector(DSP_CHANNELS-1 downto 0);
signal mca_value_valids_reg:boolean_vector(DSP_CHANNELS-1 downto 0);
signal dumps:boolean_vector(DSP_CHANNELS-1 downto 0);
signal commits:boolean_vector(DSP_CHANNELS-1 downto 0);
signal starts:boolean_vector(DSP_CHANNELS-1 downto 0);
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
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;

signal eventstreams:streambus_array(DSP_CHANNELS-1 downto 0);
signal eventstream_valids:boolean_vector(DSP_CHANNELS-1 downto 0);
signal eventstream_readys:boolean_vector(DSP_CHANNELS-1 downto 0);

signal muxstream:streambus_t;
signal muxstream_valid:boolean;
signal muxstream_ready:boolean;

signal mux_full:boolean;
signal mux_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal measurement_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);

signal m:measurements_array(DSP_CHANNELS-1 downto 0);
signal c_reg:channel_register_array(DSP_CHANNELS-1 downto 0);
signal g_reg:global_registers_t;

signal tick_period_mux,tick_period_mca:unsigned(TICK_PERIOD_BITS-1 downto 0);
attribute equivalent_register_removal:string;
attribute equivalent_register_removal of tick_period_mux,tick_period_mca:signal
          is "no";
          
-- test signals
signal framestream:streambus_t;
signal framestream_valid:boolean;
signal framestream_ready:boolean;

begin
measurements <= m;
--------------------------------------------------------------------------------
-- processing channels
--------------------------------------------------------------------------------
-- helps timing and P&R
chanReg:process(clk)
begin
  if rising_edge(clk) then
    c_reg <= channel_reg;
    tick_period_mux <= global_reg.tick_period;
    tick_period_mca <= global_reg.tick_period;
    g_reg <= global_reg;
  end if;
end process chanReg;

tesChannel:for c in DSP_CHANNELS-1 downto 0 generate

  inputMux:entity work.input_mux
  generic map(
    CHANNELS => ADC_CHIPS*ADC_CHIP_CHANNELS
  )
  port map(
    clk => clk,
    samples_in => samples,
    sel => c_reg(c).capture.adc_select,
    sample_out => adc_mux(c)
  );

  delay:entity work.dynamic_RAM_delay
  generic map(
    DEPTH => 2**DELAY_BITS,
    DATA_BITS => ADC_BITS
  )
  port map(
    clk => clk,
    data_in => adc_mux(c),
    delay => to_integer(c_reg(c).capture.delay),
    delayed => adc_delayed(c)
  );

  processingChannel:entity work.channel
  generic map(
    CHANNEL => c,
    ENDIAN => ENDIAN
  )
  port map(
    clk => clk,
    reset1 => reset1,
    reset2 => reset2,
    adc_sample => adc_delayed(c),
    registers => c_reg(c),
    stage1_config => filter_config(c),
    stage1_events => filter_events(c),
    stage2_config => slope_config(c),
    stage2_events => slope_events(c),
    baseline_config => baseline_config(c),
    baseline_events => baseline_events(c),
    start => starts(c),
    commit => commits(c),
    dump => dumps(c),
    measurements => m(c),
    stream => eventstreams(c),
    valid => eventstream_valids(c),
    ready => eventstream_readys(c)
  );
  
  valueMux:entity work.mca_value_selector2
  generic map(
    VALUE_BITS => MCA_VALUE_BITS,
    NUM_VALUES => NUM_MCA_VALUE_D,
    NUM_VALIDS => NUM_MCA_TRIGGER_D-1
  )
  port map(
    clk => clk,
    reset => reset1,
    measurements => m(c),
    value_select => value_select,
    trigger_select => trigger_select,
    value => mca_values(c),
    valid => mca_value_valids(c)
  );
  
end generate tesChannel;

valueReg:process(clk)
begin
  if rising_edge(clk) then
    mca_values_reg <= mca_values; --can't meet timing without this
    mca_value_valids_reg <= mca_value_valids;
  end if;
end process valueReg;
--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------

mux:entity work.eventstream_mux
generic map(
  --CHANNEL_BITS => CHANNEL_BITS,
  CHANNELS => DSP_CHANNELS,
  ENDIANNESS => ENDIAN
)
port map(
  clk => clk,
  reset => reset1,
  start => starts,
  commit => commits,
  dump => dumps,
  instreams => eventstreams,
  instream_valids => eventstream_valids,
  instream_readys => eventstream_readys,
  full => mux_full,
  tick_period => g_reg.tick_period,
  window => g_reg.window,
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
  valids => mca_value_valids_reg,
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
  update_asap => g_reg.mca.update_asap,
  --TODO remove redundant register port
  update_on_completion => g_reg.mca.update_on_completion,
  updated => updated, --TODO implement CPU interupt
  registers => g_reg.mca,
  --TODO remove redundant register port
  tick_period => g_reg.tick_period,
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
  clk => clk,
  reset => reset1,
  mtu => global_reg.mtu,
  tick_latency => g_reg.tick_latency,
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

-- test packet generator for debuging ethernet problems
packetGen:if PACKET_GEN generate
  packetGen:entity work.packet_generator
  port map(
    clk => clk,
    reset => reset1,
    period => g_reg.tick_period,
    stream => ethernetstream,
    ready => ethernetstream_ready,
    valid => ethernetstream_valid
  );
end generate packetGen;

end architecture RTL;
