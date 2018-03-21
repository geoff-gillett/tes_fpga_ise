--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:19 Mar. 2018
--
-- Design Name: TES_digitiser
-- Module Name: baseline_estimator
-- Project Name: mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library extensions;
use extensions.logic.all;
use extensions.boolean_vector.all;

entity baseline is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  WIDTH:natural:=16;
  FRAC:natural:=3;
  ADC_WIDTH:natural:=14;
  --MCA address width
  BASELINE_BITS:natural:=10;
  --width of counters and stream
  COUNTER_BITS:natural:=18;
  TIMECONSTANT_BITS:natural:=32;
  BUILD_DYNAMIC:boolean:=TRUE;
  SATURATE:boolean:=FALSE
);
port(
  clk:in std_logic;
  reset:in std_logic;

  timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  
  -- count threshold before most frequent value is used in the average
  count_threshold:in unsigned(COUNTER_BITS-1 downto 0);
  -- use the mca for estimation
  dynamic:in boolean;
  --only include new bins in average not (new bin or new count)
  new_only:in boolean;
  invert:in boolean;
  offset:in signed(WIDTH-1 downto 0);
  --
  adc_sample:in signed(ADC_WIDTH-1 downto 0);
  adc_sample_valid:in boolean;
  --baseline corrected sample.
  sample:out signed(WIDTH-1 downto 0);
  baseline:out signed(WIDTH-1 downto 0); 
  valid:out boolean
);
end entity baseline;

architecture RTL of baseline is
constant DEPTH:natural:=2**(FRAC-1);
constant VDEPTH:natural:=2;

signal estimate_f1:signed(BASELINE_BITS downto 0);
signal new_estimate:boolean;
signal adc_inv,offset_adc:signed(ADC_WIDTH-1 downto 0);
signal baseline_sample:signed(BASELINE_BITS-1 downto 0);
signal baseline_sample_valid,msb_0,msb_1:boolean;
signal baseline_sum:signed(WIDTH-1 downto 0);
signal baseline_dif:signed(BASELINE_BITS+1 downto 0);
type baseline_pipe is array (natural range <>) of 
     signed(BASELINE_BITS downto 0);
signal baseline_p:baseline_pipe(1 to DEPTH);
signal baseline_valid:boolean_vector(1 to DEPTH);
signal new_sum:boolean;
signal baseline_ready:boolean;
signal not_sat:boolean;
signal valid_pipe:boolean_vector(1 to VDEPTH):=(others => FALSE);
  
begin
  
sampleoffset:process(clk)
begin
if rising_edge(clk)  then
  if reset='1' then
    adc_inv <= (others => '0');
    offset_adc  <= (others => '0');
  else
    valid_pipe <= adc_sample_valid & valid_pipe(1 to VDEPTH-1);
    --adc_inv valid @ 1
    if invert then
      adc_inv <= -adc_sample; 
    else
      adc_inv <= adc_sample; 
    end if;
    --offset correction valid @ 2
    offset_adc <= adc_inv-resize(shift_right(offset,FRAC),ADC_WIDTH);
  end if;
end if;
end process sampleoffset;

msb_0 <= not unaryOR(offset_adc(ADC_WIDTH-1 downto BASELINE_BITS-1));
msb_1 <= unaryAND(offset_adc(ADC_WIDTH-1 downto BASELINE_BITS-1));
not_sat <= msb_0 xor msb_1;
baselineSat:process(clk)
begin
  if rising_edge(clk) then
    baseline_sample_valid <= valid_pipe(2);
    if not_sat then
      baseline_sample <= offset_adc(BASELINE_BITS-1 downto 0);
    else
      --saturate
      if SATURATE then
        baseline_sample <= (
          BASELINE_BITS-1 => offset_adc(ADC_WIDTH-1),
          others => '0'
        );
      else
        baseline_sample <= (others => '-');
        baseline_sample_valid <= FALSE;
      end if;
    end if;
  end if;
end process baselineSat;

dyngen:if BUILD_DYNAMIC generate
mca:entity work.baseline_mca
generic map(
  ADDRESS_BITS => BASELINE_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS
)
port map(
  clk => clk,
  reset => reset,
  timeconstant => timeconstant,
  count_threshold => count_threshold,
  new_only => new_only,
  sample => baseline_sample,
  sample_valid => baseline_sample_valid,
  estimate_f1 => estimate_f1,
  new_estimate => new_estimate
);

baselinePipe:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      baseline_valid <= (others => FALSE);
      baseline_dif <= (others => '0');
      baseline_sum <= (others => '0');
    else
      new_sum <= FALSE;
      if new_estimate then
        baseline_valid <= TRUE & baseline_valid(1 to DEPTH-1);
        baseline_p <= signed(estimate_f1) & baseline_p(1 to DEPTH-1); 
        if baseline_valid(DEPTH) then
          baseline_dif <= resize(
                            signed(estimate_f1),BASELINE_BITS+2
                          )-baseline_p(DEPTH);
          new_sum <= TRUE;
        else
          baseline_sum <= baseline_sum+signed(estimate_f1);
        end if;
      end if;
      if new_sum and baseline_valid(DEPTH) then
        baseline_sum <= baseline_sum + baseline_dif;
      end if;
    end if;
  end if;
end process baselinePipe;

--FIXME in principle this could overflow
baselineSubraction:process(clk)
begin
if rising_edge(clk) then
  baseline_ready <= baseline_valid(DEPTH);
  if dynamic and baseline_ready then
    sample <= shift_left(resize(offset_adc,WIDTH),FRAC)-baseline_sum;	
    baseline <= baseline_sum;
    valid <= valid_pipe(2);
  else
    sample <= shift_left(resize(adc_inv,WIDTH),FRAC)-offset;
    baseline <= (others => '0');
    valid <= valid_pipe(1);
  end if;
end if;
end process baselineSubraction;
end generate;

nodyngen:if not BUILD_DYNAMIC generate
  outreg:process (clk) is
  begin
    if rising_edge(clk) then
      sample <= shift_left(resize(adc_inv,WIDTH),FRAC)-offset;
      valid <= valid_pipe(1);
    end if;
  end process outreg;
end generate;

end architecture RTL;
