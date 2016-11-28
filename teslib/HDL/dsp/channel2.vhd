library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;

library dsp;
use dsp.types.all;

use work.registers.all;
use work.measurements.all;
use work.types.all;

entity channel2 is
generic(
  CHANNEL:natural:=0;
  WIDTH:natural:=18;
  FRAC:natural:=3;
  WIDTH_OUT:natural:=16;
  FRAC_OUT:natural:=1;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  CFD_DELAY:natural:=1026;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  adc_sample:in adc_sample_t;
  registers:in channel_registers_t;
  event_enable:in boolean;
  
  stage1_config:in fir_control_in_t;
  stage1_events:out fir_control_out_t;
  stage2_config:in fir_control_in_t;
  stage2_events:out fir_control_out_t;
  baseline_config:in fir_control_in_t;
  baseline_events:out fir_control_out_t;
  
  --mux signals
  start:out boolean;
  commit:out boolean;
  dump:out boolean;
  
  measurements:out measurements_t;
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity channel2;

architecture RTL of channel2 is
  
signal sample_in,raw,filtered,slope:signed(DSP_BITS-1 downto 0);
signal sample_d:std_logic_vector(WIDTH-1 downto 0);
signal m,dsp_m:measurements_t;
signal sample,sample_inv:sample_t;
signal baseline_estimate:signed(DSP_BITS-1 downto 0);
signal range_error:boolean;

--debug

constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of sample:signal is DEBUG;
attribute mark_debug of sample_in:signal is DEBUG;

begin
measurements <= m;
  
sampleoffset:process(clk)
begin
if rising_edge(clk) then
  if registers.capture.invert then
	 sample_inv <= -signed('0' & adc_sample); 
  else
	 sample_inv <= signed('0' & adc_sample); 
  end if;
	sample <= sample_inv - signed('0' & registers.baseline.offset);
end if;
end process sampleoffset;

--FIXME need to move this after the first stage
baselineEstimator:entity work.baseline_estimator
generic map(
  BASELINE_BITS => BASELINE_BITS,
  COUNTER_BITS => 18,
  TIMECONSTANT_BITS => 32,
  OUT_BITS => DSP_BITS
)
port map(
  clk => clk,
  reset => reset1,
  sample => sample,
  sample_valid => TRUE,
  av_config => baseline_config,
  av_events => baseline_events,
  timeconstant => registers.baseline.timeconstant,
  threshold => registers.baseline.threshold,
  count_threshold => registers.baseline.count_threshold,
  new_only => registers.baseline.new_only,
  baseline_estimate => baseline_estimate,
  range_error => range_error
);

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

fiteredDelay:entity dsp.sdp_bram_delay
generic map(
  DELAY => CFD_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(sample_in),
  delayed => sample_d
);
raw <= signed(sample_d);

FIR:entity dsp.two_stage_FIR2
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  sample_in => sample_in,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  stage1 => filtered,
  stage2 => slope
);

measure:entity work.measure2
generic map(
  CHANNEL => CHANNEL,
  WIDTH => WIDTH,
  FRAC => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CFD_DELAY => CFD_DELAY-101,
  FRAMER_ADDRESS_BITS => MEASUREMENT_FRAMER_ADDRESS_BITS
)
port map(
  enable => event_enable,
  clk => clk,
  reset => reset1,
  registers => registers.capture,
  slope => slope,
  filtered => filtered,
  measurements => dsp_m
);

--TODO cleanup this ugly patch
m.filtered <= dsp_m.filtered;
m.slope <= dsp_m.slope;
m.above_area_threshold <= dsp_m.above_area_threshold;
m.above_pulse_threshold <= dsp_m.above_pulse_threshold;
m.armed <= dsp_m.armed;
--m.baseline <= dsp_m.baseline;
m.cfd_error <= dsp_m.cfd_error;
m.cfd_high <= dsp_m.cfd_high;
m.cfd_low <= dsp_m.cfd_low;
m.eflags <= dsp_m.eflags;
m.height <= dsp_m.height;
m.height_valid <= dsp_m.height_valid;
--m.last_address <= dsp_m.last_address;
m.last_peak <= dsp_m.last_peak;
m.max_peaks <= dsp_m.max_peaks;
m.max_slope <= dsp_m.max_slope;
m.peak_address <= dsp_m.peak_address;
m.peak_start <= dsp_m.peak_start;
m.pulse_area <= dsp_m.pulse_area;
m.pulse_length <= dsp_m.pulse_length;
m.pulse_start <= dsp_m.pulse_start;
m.pulse_threshold_neg <= dsp_m.pulse_threshold_neg;
m.pulse_threshold_pos <= dsp_m.pulse_threshold_pos;
m.pulse_time <= dsp_m.pulse_time;
m.rise_time <= dsp_m.rise_time;
m.size <= dsp_m.size;
m.slope_threshold_neg <= dsp_m.slope_threshold_neg;
m.slope_threshold_pos <= dsp_m.slope_threshold_pos;
m.stamp_peak <= dsp_m.stamp_peak;
m.stamp_pulse <= dsp_m.stamp_pulse;
m.time_offset <= dsp_m.time_offset;
m.valid_peak <= dsp_m.valid_peak;

rawMeas:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
	WIDTH_OUT => WIDTH_OUT,
	FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => raw,
  threshold => (others => '0'),
  signal_out => m.raw.sample,
  pos_xing => m.raw.pos_0xing,
  neg_xing => m.raw.neg_0xing,
  xing => m.raw.zero_xing,
  area => m.raw.area,
  extrema => m.raw.extrema
);

framer:entity work.measurement_framer2
generic map(
  FRAMER_ADDRESS_BITS => MEASUREMENT_FRAMER_ADDRESS_BITS,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset => reset2,
  --enable => event_enable,
  start => start,
  commit => commit,
  dump => dump,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
