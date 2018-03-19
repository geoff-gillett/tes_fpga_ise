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

--FIXME remove internal precision
entity channel is
generic(
  CHANNEL:natural:=0;
  CF_WIDTH:natural:=18;
  CF_FRAC:natural:=17;
  BASELINE_N:natural:= 19;
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
signal adc_inv,baseline_sample:signed(ADC_WIDTH-1 downto 0);
signal baseline_sum:signed(WIDTH-1 downto 0);
signal baseline_dif,diff_reg:signed(BASELINE_BITS downto 0);
signal baseline_estimate:signed(WIDTH-1 downto 0);
signal baseline_in:signed(BASELINE_BITS-1 downto 0);
signal sat:boolean;
signal baseline_sign:std_logic;
signal baseline_threshold:signed(WIDTH-1 downto 0);
signal baseline:unsigned(BASELINE_BITS-1 downto 0);
signal new_baseline_value:boolean;
signal baseline_count:unsigned(17 downto 0);
signal new_bl_value:boolean;
type baseline_pipe is array (natural range <>) of 
     signed(BASELINE_BITS-1 downto 0);
signal baseline_p:baseline_pipe(1 to 8);
signal baseline_valid:boolean_vector(1 to 8);
signal count_above,new_bl:boolean;
signal baseline_ready:boolean;
signal new_sum:boolean;

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

-- baseline offset is fixed WIDTH.FRAC
--FIXME use a DSP slice?

sampleoffset:process(clk)
begin
if rising_edge(clk)  then
  if reset1='1' then
    --FIXME sample_inv could be a variable
    adc_inv <= (others => '0');
    baseline_sample  <= (others => '0');
--    resetn <= '0';
  else
    resetn <= '1';
    if registers.capture.invert then
      adc_inv <= -adc_sample; 
    else
      adc_inv <= adc_sample; 
    end if;
    baseline_sample 
      <= adc_inv-resize(shift_right(registers.baseline.offset,FRAC),ADC_WIDTH);
    baseline_threshold 
      <= resize((signed('0' & registers.baseline.threshold)),WIDTH); 
  end if;
end if;
end process sampleoffset;
baseline_in <= resize(baseline_sample,BASELINE_BITS);

baselineMCA:entity mcalib.most_frequent
generic map(
  ADDRESS_BITS => BASELINE_BITS,
  COUNTER_BITS => BASELINE_COUNTER_BITS,
  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS
)
port map(
  clk => clk,
  reset => reset1,
  timeconstant => registers.baseline.timeconstant,
  count_threshold => registers.baseline.count_threshold,
  sample => to_std_logic(baseline_in),
  sample_valid => TRUE,
  most_frequent_bin => baseline,
  new_most_frequent_bin => new_bl_value,
  most_frequent_count => baseline_count,
  new_most_frequent => new_bl
);

baselinePipe:process (clk) is
begin
  if rising_edge(clk) then
    if reset1 = '1' then
      baseline_valid <= (others => FALSE);
      baseline_dif <= (others => '0');
      baseline_estimate <= (others => '0');
      baseline_sum <= (others => '0');
    else
      new_sum <= FALSE;
      if (not registers.baseline.new_only and new_bl) or 
         (registers.baseline.new_only and new_bl_value) then
        baseline_valid <= TRUE & baseline_valid(1 to 7);
        baseline_p <= signed(baseline) & baseline_p(1 to 7); 
--        baseline_dif 
--          <= resize(signed(baseline),BASELINE_BITS+1)-baseline_p(8);
        if baseline_valid(8) then
          baseline_dif 
            <= resize(signed(baseline),BASELINE_BITS+1)-baseline_p(8);
          new_sum <= TRUE;
          baseline_estimate <= baseline_estimate + baseline_dif;
        else
          baseline_sum <= baseline_sum+signed(baseline);
        end if;
      end if;
      if new_sum and baseline_valid(8) then
        baseline_sum <= baseline_sum + baseline_dif;
      end if;
    end if;
  end if;
end process baselinePipe;

--FIXME in principle this could overflow
baselineSubraction:process(clk)
begin
if rising_edge(clk) then
  baseline_ready <= baseline_valid(8);
  if registers.baseline.subtraction and baseline_ready then
    sample_in <= shift_left(resize(baseline_in,WIDTH),FRAC) - baseline_sum;	
  else
    sample_in 
      <= shift_left(resize(adc_inv,WIDTH),FRAC) - registers.baseline.offset;
  end if;
end if;
end process baselineSubraction;

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
