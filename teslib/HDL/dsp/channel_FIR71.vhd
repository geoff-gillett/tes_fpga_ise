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

use work.registers.all;
use work.measurements.all;
use work.types.all;

entity channel_FIR71 is
generic(
  CHANNEL:natural:=0;
  BASELINE_BITS:natural:=12;
  WIDTH:natural:=18;
  FRAC:natural:=3;
  WIDTH_OUT:natural:=16;
  FRAC_OUT:natural:=1;
  ADC_WIDTH:natural:=14;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  ENDIAN:string:="LITTLE";
  STRICT_CROSSING:boolean:=TRUE
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  adc_sample:in unsigned(ADC_WIDTH-1 downto 0);
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
  framer_overflow:out boolean;
  framer_error:out boolean; -- event_lost;
  
  measurements:out measurements_t;
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity channel_FIR71;

architecture RTL of channel_FIR71 is
  
constant RAW_DELAY:natural:=1026;
  
signal sample_in,raw,filtered,slope:signed(DSP_BITS-1 downto 0);
signal sample_d:std_logic_vector(WIDTH-1 downto 0);
signal m,dsp_m:measurements_t;
signal sample,sample_inv:signed(WIDTH-1 downto 0);
signal baseline_estimate:signed(WIDTH-1 downto 0);
signal range_error:boolean;

--debug
constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of sample:signal is DEBUG;
attribute mark_debug of sample_in:signal is DEBUG;

--raw signal measurements
signal raw_x:signed(WIDTH-1 downto 0);
signal raw_0_pos_x,raw_0_neg_x,raw_0xing:boolean;
signal raw_rounded:signed(WIDTH_OUT-1 downto 0);
--pipelines
constant ALAT:natural:=5; --accumulator latency
constant RLAT:natural:=3; --round latency
constant XLAT:natural:=1; --crossing latency
constant ELAT:natural:=1; --extrema latency
constant DEPTH:integer:=ALAT;--5; --main pipeline depth
type pipe is array (natural range <>) of signed(WIDTH_OUT-1 downto 0);
signal raw_pipe:pipe(1 to DEPTH);
signal raw_0_pos_pipe,raw_0_neg_pipe:boolean_vector(1 to DEPTH);


begin
measurements <= m;
  
sampleoffset:process(clk)
begin
if rising_edge(clk) then
  if reset2='1' then
    sample_inv <= (others => '0');
    sample  <= (others => '0');
  else
    if registers.capture.invert then
      sample_inv <= -signed(reshape('0' & adc_sample,0,WIDTH,FRAC)); 
    else
      sample_inv <= signed(reshape('0' & adc_sample,0,WIDTH,FRAC)); 
    end if;
    sample <= sample_inv - signed('0' & registers.baseline.offset);
  end if;
end if;
end process sampleoffset;

baselineEstimator:entity work.baseline_estimator
generic map(
  BASELINE_BITS => BASELINE_BITS, --FIXME make generic in parent
  COUNTER_BITS => 18,
  TIMECONSTANT_BITS => 32,
  WIDTH => DSP_BITS
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
    sample_in <= sample - baseline_estimate;		
  else
    sample_in <= sample;	
  end if;
end if;
end process baselineSubraction;

rawDelay:entity dsp.sdp_bram_delay
generic map(
  DELAY => RAW_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(sample_in),
  delayed => sample_d
);
raw <= signed(sample_d);

FIR:entity dsp.two_stage_FIR71
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

measure:entity work.measure4
generic map(
  CHANNEL => CHANNEL,
  WIDTH => WIDTH,
  FRAC => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CFD_DELAY => RAW_DELAY-101-72,
  STRICT_CROSSING => STRICT_CROSSING
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

pipelines:process (clk) is
begin
  if rising_edge(clk) then
    raw_pipe(RLAT-XLAT to DEPTH) 
      <= raw_rounded & raw_pipe(RLAT-XLAT to DEPTH-1);
    raw_0_pos_pipe <= raw_0_pos_x & raw_0_pos_pipe(1 to DEPTH-1);
    raw_0_neg_pipe <= raw_0_neg_x & raw_0_neg_pipe(1 to DEPTH-1);
    m.raw.zero_xing <= raw_0_neg_pipe(DEPTH-1) or raw_0_pos_pipe(DEPTH-1);
  end if;
end process pipelines;

raw0xing:entity dsp.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => TRUE
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => raw,
  threshold => (others => '0'),
  signal_out => raw_x,
  pos => raw_0_pos_x,
  neg => raw_0_neg_x
);
raw_0xing <= raw_0_pos_x or raw_0_neg_x;

rawArea:entity dsp.area_acc3
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset1,
  xing => raw_0xing,
  sig => raw_x,
  signal_threshold => (others => '0'),
  area_threshold => (others => '0'),
  above_area_threshold => open,
  area => m.raw.area
);

rawRound:entity dsp.round2
generic map(
  WIDTH_IN => WIDTH,
  FRAC_IN => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  TOWARDS_INF => FALSE
)
port map(
  clk => clk,
  reset => reset1,
  input => raw,
  output_threshold => (others => '0'),
  output => raw_rounded,
  above_threshold => open
);

rawExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH_OUT
)
port map(
  clk => clk,
  reset => reset1,
  sig => raw_pipe(DEPTH-ELAT),
  pos_0xing => raw_0_pos_pipe(DEPTH-ELAT),
  neg_0xing => raw_0_neg_pipe(DEPTH-ELAT),
  extrema => m.raw.extrema
);

m.raw.sample <= raw_pipe(DEPTH);
m.raw.pos_0xing <= raw_0_pos_pipe(DEPTH);
m.raw.neg_0xing <= raw_0_neg_pipe(DEPTH);

--TODO cleanup this ugly patch
m.minima <= dsp_m.minima;
m.filtered <= dsp_m.filtered;
m.slope <= dsp_m.slope;
m.above_area_threshold <= dsp_m.above_area_threshold;
m.above_pulse_threshold <= dsp_m.above_pulse_threshold;
m.will_go_above <= dsp_m.will_go_above;
m.armed <= dsp_m.armed;
m.will_arm <= dsp_m.will_arm;
m.cfd_error <= dsp_m.cfd_error;
m.cfd_valid <= dsp_m.cfd_valid;
m.cfd_high <= dsp_m.cfd_high;
m.cfd_low <= dsp_m.cfd_low;
m.eflags <= dsp_m.eflags;
m.height <= dsp_m.height;
m.height_valid <= dsp_m.height_valid;
m.last_peak_address <= dsp_m.last_peak_address;
m.last_peak <= dsp_m.last_peak;
m.max_slope <= dsp_m.max_slope;
m.peak_address <= dsp_m.peak_address;
m.peak_start <= dsp_m.peak_start;
m.pre_peak_start <= dsp_m.pre_peak_start;
m.pulse_area <= dsp_m.pulse_area;
m.pulse_length <= dsp_m.pulse_length;
m.pulse_start <= dsp_m.pulse_start;
m.pre_pulse_start <= dsp_m.pre_pulse_start;
m.pulse_threshold_neg <= dsp_m.pulse_threshold_neg;
m.pulse_threshold_pos <= dsp_m.pulse_threshold_pos;
m.pulse_time <= dsp_m.pulse_time;
m.rise_time <= dsp_m.rise_time;
m.size <= dsp_m.size;
m.pre_size <= dsp_m.pre_size;
--m.slope_threshold_neg <= dsp_m.slope_threshold_neg;
m.slope_threshold_pos <= dsp_m.slope_threshold_pos;
m.stamp_peak <= dsp_m.stamp_peak;
m.stamp_pulse <= dsp_m.stamp_pulse;
m.time_offset <= dsp_m.time_offset;
m.valid_peak <= dsp_m.valid_peak;
m.valid_peak0 <= dsp_m.valid_peak0;
m.valid_peak1 <= dsp_m.valid_peak1;
m.valid_peak2 <= dsp_m.valid_peak2;
m.height_threshold <= dsp_m.height_threshold;
m.timing_threshold <= dsp_m.timing_threshold;
m.filtered_long <= dsp_m.filtered_long;

framer:entity work.measurement_framer4
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
  overflow => framer_overflow,
  error => framer_error,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
