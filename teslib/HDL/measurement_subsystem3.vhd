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

library dsp;
use dsp.types.all;

use work.types.all;
use work.functions.all;
use work.registers.all;
use work.measurements.all;
use work.events.all;

entity measurement_subsystem3 is
generic(
  DSP_CHANNELS:natural:=2;
  ADC_CHANNELS:natural:=2;
  VALUE_PIPE_DEPTH:natural:=1;
	ENDIAN:string:="LITTLE";
	PACKET_GEN:boolean:=FALSE;
	ADC_WIDTH:integer:=14;
	WIDTH:integer:=18;
	FRAC:integer:=3;
	WIDTH_OUT:integer:=16;
	FRAC_OUT:integer:=3;
	SLOPE_FRAC:natural:=8;
	SLOPE_FRAC_OUT:natural:=8;
	AREA_WIDTH:natural:=32;
	AREA_FRAC:natural:=1
);
port(
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  mca_interrupt:out boolean;
  
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

architecture fixed_16_3 of measurement_subsystem3 is
	
attribute equivalent_register_removal:string;

signal adc_delayed,adc_mux:adc_sample_array(DSP_CHANNELS-1 downto 0);

-- MCA
--type value_sel_array is array (natural range <>) of 
--  std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
  
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);

signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal qualifier_select:std_logic_vector(NUM_MCA_QUAL_D-1 downto 0);
signal mca_values,mca_values_int:mca_value_array(DSP_CHANNELS-1 downto 0);

--constant VALUE_PIPE_DEPTH:natural:=MCA_VALUE_PIPE_DEPTH;
type value_pipe_t is array (1 to VALUE_PIPE_DEPTH) of
     mca_value_array(DSP_CHANNELS-1 downto 0);
signal value_pipe:value_pipe_t;
type value_valid_pipe_t is array (1 to VALUE_PIPE_DEPTH) of
     boolean_vector(DSP_CHANNELS-1 downto 0);
signal value_valid_pipe:value_valid_pipe_t;
attribute equivalent_register_removal of value_pipe,value_valid_pipe:signal is
          "FALSE";

--constant ADCPIPE_DEPTH:natural:=1; --TODO add DEPTH
type adc_pipeline is array (DSP_CHANNELS-1 downto 0) 
	   of adc_sample_array(ADC_CHANNELS-1 downto 0);
signal adc_pipe:adc_pipeline;
attribute equivalent_register_removal of adc_pipe:signal is "FALSE";

signal mca_value_valids:boolean_vector(DSP_CHANNELS-1 downto 0);
signal mca_value_valids_int:boolean_vector(DSP_CHANNELS-1 downto 0);
signal dumps:boolean_vector(DSP_CHANNELS-1 downto 0);
signal commits:boolean_vector(DSP_CHANNELS-1 downto 0);
signal starts:boolean_vector(DSP_CHANNELS-1 downto 0);
signal baseline_errors:boolean_vector(DSP_CHANNELS-1 downto 0);
signal cfd_errors:boolean_vector(DSP_CHANNELS-1 downto 0);
signal time_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal framer_errors:boolean_vector(DSP_CHANNELS-1 downto 0);
signal framer_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal channel_select:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal mca_value:signed(MCA_VALUE_BITS-1 downto 0);
signal mca_value_valid:boolean;

--signal updated:boolean;
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

--signal m,m_reg:measurements_array(DSP_CHANNELS-1 downto 0);
signal m:measurements_array(DSP_CHANNELS-1 downto 0);
signal c_reg:channel_register_array(DSP_CHANNELS-1 downto 0);
signal g_reg:global_registers_t;

signal tick_period_mux,tick_period_mca:unsigned(TICK_PERIOD_BITS-1 downto 0);
attribute equivalent_register_removal of tick_period_mux,tick_period_mca:signal
          is "no";

signal framestream:streambus_t;
signal framestream_valid:boolean;
signal framestream_ready:boolean;

--------------------------------------------------------------------------------
-- test signals
--------------------------------------------------------------------------------
--signal adc_delayed0,adc_mux0:adc_sample_t;
--signal adc_select:std_logic_vector(ADC_CHANNELS-1 downto 0);
--signal raw_sample,filtered_sample:signal_t;
--signal filtered_0xing,raw_0xing:boolean;
--signal peak_count:unsigned(PEAK_COUNT_BITS-1 downto 0);

--signal flags:std_logic_vector(15 downto 0);
--signal height_valid:boolean;
--signal height:signal_t;
--signal rise_time:time_t;
--signal framestream_firstbyte:std_logic_vector(7 downto 0);
--signal framestream_last,new_frame:boolean;


--signal mca_value_debug:signed(MCA_VALUE_BITS-1 downto 0);
--signal mca_value_valid_debug:boolean;

--constant DEBUG:string:="FALSE";
--attribute MARK_DEBUG:string;
--attribute MARK_DEBUG of mca_value_debug:signal is DEBUG;
--attribute MARK_DEBUG of mca_value_valid_debug:signal is DEBUG;
--attribute MARK_DEBUG of framestream:signal is DEBUG;
--attribute MARK_DEBUG of framestream_valid:signal is DEBUG;
--attribute MARK_DEBUG of framestream_ready:signal is DEBUG;
--attribute MARK_DEBUG of framestream_firstbyte:signal is DEBUG;
--attribute MARK_DEBUG of framestream_last:signal is DEBUG;
--attribute MARK_DEBUG of new_frame:signal is DEBUG;

--attribute MARK_DEBUG of muxstream_valid:signal is DEBUG;
--attribute MARK_DEBUG of muxstream_ready:signal is DEBUG;

--attribute MARK_DEBUG of value_select:signal is DEBUG;
--attribute MARK_DEBUG of channel_select:signal is DEBUG;
--attribute MARK_DEBUG of adc_mux0:signal is DEBUG;
--attribute MARK_DEBUG of adc_delayed0:signal is DEBUG;
--attribute MARK_DEBUG of adc_select:signal is DEBUG;
--attribute MARK_DEBUG of raw_sample:signal is DEBUG;
--attribute MARK_DEBUG of filtered_sample:signal is DEBUG;
--attribute MARK_DEBUG of raw_0xing:signal is DEBUG;
--attribute MARK_DEBUG of filtered_0xing:signal is DEBUG;
--attribute MARK_DEBUG of peak_count:signal is DEBUG;
--attribute MARK_DEBUG of flags:signal is DEBUG;
--attribute MARK_DEBUG of height_valid:signal is DEBUG;
--attribute MARK_DEBUG of height:signal is DEBUG;

begin
--------------------------------------------------------------------------------
--test signals
--------------------------------------------------------------------------------
 --adc_delayed0 <= adc_delayed(0);
 --adc_mux0 <= adc_mux(0);
 --adc_select <= c_reg(0).capture.adc_select;
-- raw_sample <= m(0).raw.sample;
-- filtered_sample <= m(0).filtered.sample;
-- raw_0xing <= m(0).raw.zero_xing;
-- filtered_0xing <= m(0).filtered.zero_xing;
 --peak_count <= m(0).eflags.peak_count;
-- framestream_firstbyte <= framestream.data(63 downto 56);
-- framestream_last <= framestream.last(0);
-- frameStart : process (clk) is
-- begin
--   if rising_edge(clk) then
--     if reset1 = '1' then
--       new_frame <= FALSE;
--     else
--       if framestream_ready and framestream_valid then
--         new_frame <= framestream_last;
--       end if;
--     end if;
--   end if;
-- end process frameStart;
 
-- mca_value_debug <= mca_values(0);
-- mca_value_valid_debug <= mca_value_valids(0);
-- 
-- flags <= to_std_logic(m(0).eflags);
-- height_valid <= m(0).height_valid;
-- height <= m(0).height;
-- rise_time <= m(0).rise_time;
 
--------------------------------------------------------------------------------
-- processing channels
--------------------------------------------------------------------------------
measurements <= m;

-- helps timing and P&R
chanReg:process(clk)
begin
  if rising_edge(clk) then
--    c_reg <= channel_reg;
    tick_period_mux <= global_reg.tick_period;
    tick_period_mca <= global_reg.tick_period;
--    g_reg <= global_reg;
  end if;
end process chanReg;
c_reg <= channel_reg;
g_reg <= global_reg;

tesChannel:for c in DSP_CHANNELS-1 downto 0 generate
  
  adcPipe:process(clk)
  begin
    if rising_edge(clk) then
      adc_pipe(c) <= samples;
    end if;
  end process adcPipe;
  
  inputMux:entity work.input_mux
  generic map(
    CHANNELS => ADC_CHANNELS
  )
  port map(
    clk => clk,
    samples_in => adc_pipe(c),
    sel => resize(c_reg(c).capture.adc_select,ADC_CHANNELS),
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
    ENDIAN => ENDIAN,
    BASELINE_BITS => BASELINE_BITS,
    WIDTH => WIDTH,
    FRAC => FRAC,
    WIDTH_OUT => WIDTH_OUT,
    FRAC_OUT => FRAC_OUT,
    SLOPE_FRAC => SLOPE_FRAC,
    SLOPE_FRAC_OUT => SLOPE_FRAC_OUT,
    ADC_WIDTH => ADC_WIDTH,
    AREA_WIDTH => AREA_WIDTH,
    AREA_FRAC => AREA_FRAC,
    STRICT_CROSSING => TRUE 
  )
  port map(
    clk => clk,
    reset1 => reset1,
    reset2 => reset2,
    adc_sample => signed(adc_delayed(c)),
    registers => c_reg(c),
    event_enable => to_boolean(g_reg.channel_enable(c)),
    stage1_config => filter_config(c),
    stage1_events => filter_events(c),
    stage2_config => slope_config(c),
    stage2_events => slope_events(c),
    baseline_config => baseline_config(c),
    baseline_events => baseline_events(c),
    start => starts(c),
    commit => commits(c),
    dump => dumps(c),
    framer_overflow => framer_overflows(c),
    framer_error => framer_errors(c),
    measurements => m(c),
    stream => eventstreams(c),
    valid => eventstream_valids(c),
    ready => eventstream_readys(c)
  );
  cfd_errors(c) <= m(c).cfd_error;
  
  valueMux:entity work.mca_value_selector3
  generic map(
    VALUE_BITS => MCA_VALUE_BITS,
    NUM_VALUES => NUM_MCA_VALUE_D,
    NUM_VALIDS => NUM_MCA_TRIGGER_D-1,
    NUM_QUALS => NUM_MCA_QUAL_D
  )
  port map(
    clk => clk,
    reset => reset1,
    --measurements => m_reg(c),
    measurements => m(c),
    value_select => value_select,
    trigger_select => trigger_select,
    qualifier_select => qualifier_select,
    value => mca_values(c),
    valid => mca_value_valids(c)
  );
end generate tesChannel;

valuePipeGen:if VALUE_PIPE_DEPTH/=0 generate
  mcaPipe:process(clk)
  begin
    if rising_edge(clk) then
      --m_reg <= m;
      value_pipe <= mca_values & value_pipe(1 to VALUE_PIPE_DEPTH-1);
      value_valid_pipe 
        <= mca_value_valids & value_valid_pipe(1 to VALUE_PIPE_DEPTH-1);
    end if;
  end process mcaPipe;
end generate;

mcaValue:process(mca_values,mca_value_valids,value_pipe,value_valid_pipe)
begin
  if VALUE_PIPE_DEPTH/=0 then
    mca_values_int <= value_pipe(VALUE_PIPE_DEPTH);
    mca_value_valids_int <= value_valid_pipe(VALUE_PIPE_DEPTH);
  else
    mca_values_int <= mca_values;
    mca_value_valids_int <= mca_value_valids;
  end if;
end process mcaValue;

mcaChanSel:entity work.mca_channel_selector
generic map(
  CHANNELS => DSP_CHANNELS,
  VALUE_BITS   => MCA_VALUE_BITS
)
port map(
  clk => clk,
  reset => reset1,
  channel_select => channel_select,
  values => mca_values_int,
  valids => mca_value_valids_int,
  value => mca_value,
  valid => mca_value_valid
);

--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
mux:entity work.eventstream_mux
generic map(
  --CHANNEL_BITS => CHANNEL_BITS,
  CHANNELS => DSP_CHANNELS,
  MIN_TICKPERIOD => MIN_TICK_PERIOD,
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
  framer_errors => framer_errors,
  time_overflows => time_overflows,
  baseline_underflows => baseline_errors, -- use for something else
  muxstream => muxstream,
  valid => muxstream_valid,
  ready => muxstream_ready
);

mca:entity work.mca
generic map(
  CHANNELS => DSP_CHANNELS,
  ADDRESS_BITS => MCA_ADDRESS_BITS,
  COUNTER_BITS => MCA_COUNTER_BITS,
  VALUE_BITS => MCA_VALUE_BITS,
  TOTAL_BITS => MCA_TOTAL_BITS,
  TICKCOUNT_BITS => MCA_TICKCOUNT_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  VALUE_PIPE_DEPTH => VALUE_PIPE_DEPTH,
  MINIMUM_TICK_PERIOD => MIN_TICK_PERIOD,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset1,
  updated => mca_interrupt,
  registers => g_reg.mca,
  tick_period => g_reg.tick_period,
  channel_select => channel_select,
  value_select => value_select,
  trigger_select => trigger_select,
  qualifier_select => qualifier_select,
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

end architecture fixed_16_3;
