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
entity channel is
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
signal sample_inv,baseline_sample:signed(ADC_WIDTH+FRAC downto 0);
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

begin
measurements <= m;

-- baseline offset is fixed WIDTH.FRAC
--FIXME use a DSP slice?
sat <= not ( unaryAND(baseline_sample(ADC_WIDTH+FRAC downto WIDTH-1)) or 
       (unaryAND(not baseline_sample(ADC_WIDTH+FRAC downto WIDTH-1))) );
baseline_sign <= baseline_sample(ADC_WIDTH+FRAC);
sampleoffset:process(clk)
begin
if rising_edge(clk)  then
  if reset1='1' then
    --FIXME sample_inv could be a variable
    sample_inv <= (others => '0');
    baseline_sample  <= (others => '0');
    resetn <= '0';
  else
    resetn <= '1';
    if registers.capture.invert then
      sample_inv <= shift_left(-resize(adc_sample,ADC_WIDTH+FRAC+1),FRAC); 
    else
      sample_inv <= shift_left(resize(adc_sample,ADC_WIDTH+FRAC+1),FRAC); 
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
