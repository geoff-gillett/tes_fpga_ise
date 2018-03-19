library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library dsp;
use dsp.types.all;

library mcalib;

use work.registers.all;
use work.measurements.all;
use work.types.all;

entity channel is
generic(
  CHANNEL:natural:=0;
  CF_WIDTH:natural:=18;
  CF_FRAC:natural:=17;
  BASELINE_BITS:natural:=10;
  WIDTH:natural:=16; 
  FRAC:natural:=3; 
  SLOPE_FRAC:natural:=8; 
  ADC_WIDTH:natural:=14;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  FRAMER_ADDRESS_BITS:natural:=10;
  ACCUMULATOR_WIDTH:natural:=36;
  ACCUMULATE_N:natural:=18;
  TRACE_FROM_STAMP:boolean:=TRUE;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  adc_sample:in signed(ADC_WIDTH-1 downto 0);
  registers:in channel_registers_t;
  event_enable:in boolean;
  
  stage1_config:in fir_control_in_t;
  stage1_events:out fir_control_out_t;
  stage2_config:in fir_control_in_t;
  stage2_events:out fir_control_out_t;
  
  --mux signals
  mux_full:in boolean;
  start:out boolean;
  commit:out boolean;
  dump:out boolean;
  framer_overflow:out boolean;
  framer_error:out boolean; -- event_lost;
  
  measurements:out measurements_t;
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity channel;

architecture fixed_16_3 of channel is
  
constant RAW_DELAY:natural:=1026;
signal resetn:std_logic:='0';  
signal sample_in,filtered,slope:signed(WIDTH-1 downto 0);
signal m:measurements_t;
signal baseline_sample:signed(ADC_WIDTH-1 downto 0);

--debug
constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute keep:string;
attribute keep of adc_sample:signal is DEBUG;
attribute mark_debug of adc_sample:signal is DEBUG;
attribute keep of baseline_sample:signal is DEBUG;
attribute mark_debug of baseline_sample:signal is DEBUG;
attribute keep of sample_in:signal is DEBUG;
attribute mark_debug of sample_in:signal is DEBUG;

begin
measurements <= m;

resetP:process (clk) is
begin
  if rising_edge(clk) then
    resetn <= not reset1;
  end if;
end process resetP;


estimator:entity mcalib.baseline
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  ADC_WIDTH => ADC_WIDTH,
  BASELINE_BITS => BASELINE_BITS,
  COUNTER_BITS => BASELINE_COUNTER_BITS,
  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS
)
port map(
  clk => clk,
  reset => reset1,
  timeconstant => registers.baseline.timeconstant,
  count_threshold  => registers.baseline.count_threshold,
  dynamic => registers.baseline.subtraction,
  new_only => registers.baseline.new_only,
  invert => registers.capture.invert,
  offset => registers.baseline.offset,
  adc_sample => adc_sample,
  adc_sample_valid => TRUE,
  sample => sample_in,
  sample_valid => open
);


FIR:entity dsp.FIR_SYM141_ASYM23_OUT16_3
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  SLOPE_FRAC => SLOPE_FRAC
)
port map(
  clk => clk,
  resetn => resetn,
  sample_in => sample_in,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  stage1 => filtered,
  stage2 => slope
);

measure:entity work.measure
generic map(
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  RAW_DELAY => RAW_DELAY --101-72-38-2
)
port map(
  clk => clk,
  reset => reset1,
  event_enable => event_enable,
  registers => registers.capture,
  raw => sample_in,
  s => slope,
  f => filtered,
  measurements => m
);

framer:entity work.measurement_framer
generic map(
  CHANNEL => CHANNEL,
  WIDTH => WIDTH,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH,
  ACCUMULATE_N => ACCUMULATE_N,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  DP_ADDRESS_BITS => FRAMER_ADDRESS_BITS+2,
  TRACE_FROM_STAMP => TRACE_FROM_STAMP,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset => reset2,
  mux_full => mux_full,
  start => start,
  commit => commit,
  dump => dump,
  overflow => framer_overflow,
  error => framer_error,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture fixed_16_3;
