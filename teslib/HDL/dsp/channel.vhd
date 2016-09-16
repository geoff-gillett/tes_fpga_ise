library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;

use work.registers.all;
use work.measurements.all;
use work.types.all;
--use work.adc.all;

entity channel is
generic(
  CHANNEL:integer:=0;
  FRAMER_ADDRESS_BITS:integer:=11;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  adc_sample:in adc_sample_t;
  registers:in channel_registers_t;
  
  stage1_FIR_ctl:in fir_control_in_t;
  stage1_FIR_events:out fir_control_out_t;
  stage2_FIR_ctl:in fir_control_in_t;
  stage2_FIR_events:out fir_control_out_t;
  baseline_av_ctl:in fir_control_in_t;
  baseline_av_events:out fir_control_out_t;
  
  --mux signals
  start:out boolean;
  commit:out boolean;
  dump:out boolean;
  
  measurements:out measurements_t;
  stream:out streambus_t;
  valid:out boolean;
  ready:out boolean
);
end entity channel;

architecture RTL of channel is
  
signal sample_in,raw,filtered,slope:signed(DSP_BITS-1 downto 0);
signal m:measurements_t;
signal sample:sample_t;
signal baseline_estimate:signed(DSP_BITS-1 downto 0);
signal range_error:boolean;
begin
measurements <= m;
  
sampleoffset:process(clk)
begin
if rising_edge(clk) then
	sample <= signed('0' & adc_sample) - 
						signed('0' & registers.baseline.offset);
end if;
end process sampleoffset;

baselineEstimator:entity work.baseline_estimator2
generic map(
  BASELINE_BITS => 11,
  COUNTER_BITS => 18,
  TIMECONSTANT_BITS => 32,
  OUT_BITS => 18
)
port map(
  clk => clk,
  reset => reset1,
  sample => sample,
  sample_valid => TRUE,
  timeconstant => registers.baseline.timeconstant,
  threshold => registers.baseline.threshold,
  count_threshold => registers.baseline.count_threshold,
  new_only => registers.baseline.new_only,
  baseline_estimate => baseline_estimate,
  range_error => range_error
);
m.baseline <= baseline_estimate;

baselineSubraction:process(clk)
begin
if rising_edge(clk) then
  if registers.baseline.subtraction then
    sample_in <= reshape(sample,0,DSP_BITS,DSP_FRAC) - baseline_estimate;		
  else
    sample_in <= reshape(sample,0,DSP_BITS,DSP_FRAC);	
  end if;
end if;
end process baselineSubraction;

FIR:entity work.two_stage_FIR
generic map(
  WIDTH => DSP_BITS
)
port map(
  clk => clk,
  sample_in => sample_in,
  stage1_config_data => stage1_config_data,
  stage1_config_valid => stage1_config_valid,
  stage1_config_ready => stage1_config_ready,
  stage1_reload_data  => stage1_reload_data,
  stage1_reload_valid => stage1_reload_valid,
  stage1_reload_ready => stage1_reload_ready,
  stage1_reload_last => stage1_reload_last,
  stage1_reload_last_missing => stage1_reload_last_missing,
  stage1_reload_last_unexpected => stage1_reload_last_unexpected,
  stage2_config_data => stage2_config_data,
  stage2_config_valid => stage2_config_valid,
  stage2_config_ready => stage2_config_ready,
  stage2_reload_data => stage2_reload_data,
  stage2_reload_valid => stage2_reload_valid,
  stage2_reload_ready => stage2_reload_ready,
  stage2_reload_last => stage2_reload_last,
  stage2_reload_last_missing => stage2_reload_last_missing,
  stage2_reload_last_unexpected => stage2_reload_last_unexpected,
  sample_out => raw,
  stage1 => filtered,
  stage2 => slope
);
  
measure:entity work.measure
generic map(
  CHANNEL => CHANNEL,
  WIDTH => DSP_BITS,
  FRAC => DSP_FRAC,
	WIDTH_OUT => SIGNAL_BITS,
	FRAC_OUT => SIGNAL_FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CFD_DELAY => 1027
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  registers => registers.capture,
  raw => raw,
  slope => slope,
  filtered => filtered,
  measurements => m
);

framer:entity work.measurement_framer
generic map(
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset => reset2,
  start => start,
  commit => commit,
  dump => dump,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
