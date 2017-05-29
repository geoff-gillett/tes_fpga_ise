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

--FIXME remove internal precision
entity channel12 is
generic(
  CHANNEL:natural:=0;
  CF_WIDTH:natural:=18;
  CF_FRAC:natural:=17;
  BASELINE_N:natural:= 19;
  WIDTH:natural:=16; 
  FRAC:natural:=3; 
  SLOPE_FRAC:natural:=8; 
  ADC_WIDTH:natural:=14;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  FRAMER_ADDRESS_BITS:natural:=10;
  ACCUMULATOR_WIDTH:natural:=36;
  ACCUMULATE_N:natural:=18;
  TRACE_CHUNKS:natural:=512;
  TRACE_FROM_STAMP:boolean:=TRUE;
  ENDIAN:string:="LITTLE";
  STRICT_CROSSING:boolean:=TRUE
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
end entity channel12;

architecture fixed_16_3 of channel12 is
  
constant RAW_DELAY:natural:=1026;
  
signal sample_in,raw,filtered,slope:signed(WIDTH-1 downto 0);
signal sample_d:std_logic_vector(WIDTH-1 downto 0);
signal m,dsp_m:measurements_t;
signal sample_inv,baseline_sample:signed(ADC_WIDTH+FRAC-1 downto 0);
signal baseline_estimate,baseline_in:signed(WIDTH-1 downto 0);
signal sat:boolean;
signal baseline_sign:std_logic;
signal baseline_threshold:signed(WIDTH-1 downto 0);

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
--attribute keep of sample_inv:signal is DEBUG;
--attribute mark_debug of sample_inv:signal is DEBUG;

--raw signal measurements
signal raw_x:signed(WIDTH-1 downto 0);
signal raw_0_pos_x,raw_0_neg_x,raw_0xing:boolean;
--signal raw_rounded:signed(WIDTH-1 downto 0);
--pipelines
constant ALAT:natural:=5; --accumulator latency
--constant RLAT:natural:=3; --round latency
constant XLAT:natural:=1; --crossing latency
constant ELAT:natural:=1; --extrema latency
constant DEPTH:integer:=ALAT;--5; --main pipeline depth
type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);
signal raw_pipe:pipe(1 to DEPTH);
signal raw_0_pos_pipe,raw_0_neg_pipe:boolean_vector(1 to DEPTH);

begin
measurements <= m;

-- baseline offset is fixed WIDTH.FRAC
--FIXME use a DSP slice?
sat <= not (unaryAND(baseline_sample(ADC_WIDTH+FRAC-1 downto WIDTH-1)) or 
       not unaryOR(baseline_sample(ADC_WIDTH+FRAC-1 downto WIDTH-1)));
baseline_sign <= baseline_sample(ADC_WIDTH+FRAC-1);
sampleoffset:process(clk)
begin
if rising_edge(clk) then
  if reset2='1' then
    --FIXME sample_inv could be a variable
    sample_inv <= (others => '0');
    baseline_sample  <= (others => '0');
  else
    if registers.capture.invert then
      sample_inv <= shift_left(-resize(adc_sample,ADC_WIDTH+FRAC),FRAC); 
    else
      sample_inv <= shift_left(resize(adc_sample,ADC_WIDTH+FRAC),FRAC); 
    end if;
    
    baseline_sample 
      <= sample_inv - resize(registers.baseline.offset,ADC_WIDTH+FRAC);
    if sat then
      baseline_in <= (WIDTH-1 => baseline_sign, others => not baseline_sign);
    else
      baseline_in <= resize(baseline_sample, WIDTH);
    end if;
--    baseline_threshold 
--      <= resize((signed('0' & registers.baseline.threshold)),WIDTH); 
  end if;
end if;
end process sampleoffset;

--baseline_threshold <= (WIDTH-1 => '0',others => '1');
baseline_threshold <= resize(signed('0' & registers.baseline.threshold),WIDTH);
baselineAv:entity dsp.average_fixed_n
generic map(
  WIDTH => WIDTH,
  DIVIDE_N => BASELINE_N
)
port map(
  clk => clk,
  reset => reset1,
  threshold => baseline_threshold, 
  sample => baseline_in,
  average => baseline_estimate
);

--FIXME in principle this could overflow
baselineSubraction:process(clk)
begin
if rising_edge(clk) then
  if registers.baseline.subtraction then
    sample_in <= baseline_in - baseline_estimate;	
  else
    sample_in <= baseline_in;	
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

--FIXME make this width 16 with dynamic frac
FIR:entity dsp.FIR_142SYM_23NSYM_16bit
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  SLOPE_FRAC => SLOPE_FRAC
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

measure:entity work.measure8
generic map(
  CHANNEL => CHANNEL,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CFD_DELAY => RAW_DELAY-101-72-38,
  STRICT_CROSSING => STRICT_CROSSING
)
port map(
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
    raw_pipe(XLAT to DEPTH) 
      <= raw & raw_pipe(XLAT to DEPTH-1);
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

rawExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH
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

--m.trace_signal <= dsp_m.trace_signal;
--m.trace_type <= dsp_m.trace_type;
m.pre_tflags <= dsp_m.pre_tflags;
m.tflags <= dsp_m.tflags;

--TODO cleanup this ugly patch
m.min_value <= dsp_m.min_value;
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
m.pre_eflags <= dsp_m.pre_eflags;
m.height <= dsp_m.height;
m.height_valid <= dsp_m.height_valid;
m.peak_overflow <= dsp_m.peak_overflow;
m.last_peak_address <= dsp_m.last_peak_address;
m.offset <= dsp_m.offset;
m.last_peak <= dsp_m.last_peak;
m.max_slope <= dsp_m.max_slope;
m.peak_address <= dsp_m.peak_address;
m.peak_start <= dsp_m.peak_start;
m.peak_stop <= dsp_m.peak_stop;
m.pre_peak_start <= dsp_m.pre_peak_start;
m.pulse_area <= dsp_m.pulse_area;
m.pulse_length <= dsp_m.pulse_length;
m.pulse_start <= dsp_m.pulse_start;
m.pre_pulse_start <= dsp_m.pre_pulse_start;
m.pulse_threshold_neg <= dsp_m.pulse_threshold_neg;
m.pre_pulse_threshold_neg <= dsp_m.pre_pulse_threshold_neg;
m.pulse_threshold_pos <= dsp_m.pulse_threshold_pos;
m.pulse_time <= dsp_m.pulse_time;
m.rise_time <= dsp_m.rise_time;
m.time_offset <= dsp_m.time_offset;
m.peak_time <= dsp_m.peak_time;
m.size <= dsp_m.size;
m.pre_size <= dsp_m.pre_size;
m.slope_threshold_pos <= dsp_m.slope_threshold_pos;
m.stamp_peak <= dsp_m.stamp_peak;
m.stamp_pulse <= dsp_m.stamp_pulse;
m.pre_stamp_peak <= dsp_m.pre_stamp_peak;
m.pre_stamp_pulse <= dsp_m.pre_stamp_pulse;
m.peak_stamped <= dsp_m.peak_stamped;
m.pulse_stamped <= dsp_m.pulse_stamped;
--m.time_offset <= dsp_m.time_offset;
m.valid_peak <= dsp_m.valid_peak;
m.valid_peak0 <= dsp_m.valid_peak0;
m.valid_peak1 <= dsp_m.valid_peak1;
m.valid_peak2 <= dsp_m.valid_peak2;
--m.height_threshold <= dsp_m.height_threshold;
m.timing_threshold <= dsp_m.timing_threshold;
m.filtered_long <= dsp_m.filtered_long;

framer:entity work.measurement_framer12
generic map(
  WIDTH => WIDTH,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH,
  ACCUMULATE_N => ACCUMULATE_N,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  TRACE_CHUNKS => TRACE_CHUNKS,
  TRACE_FROM_STAMP => TRACE_FROM_STAMP,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset => reset2,
  enable => event_enable,
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
