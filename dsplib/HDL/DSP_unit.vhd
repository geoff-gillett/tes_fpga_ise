--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:14/01/2014 
--
-- Design Name: TES_digitiser
-- Module Name: signal_processor
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--FIXME add a baseline delay
library teslib;
use teslib.types.all;
use teslib.functions.all;
--

entity dsp_unit is
generic(
  ADC_BITS:integer:=14;
  SIGNAL_DELAY_BITS:integer:=13;
  SIGNAL_AV_BITS:integer:=6;
  SLOPE_ADDRESS_BITS:integer:=6;
  SYNC_ADDRESS_BITS:integer:=6;
  TIMECONSTANT_BITS:integer:=32;
  BASELINE_MCA_DATABITS:integer:=18;
  BASELINE_AV_BITS:integer:=10;
  BASELINE_BITS:integer:=12
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --!* parameters
  adc_sample:unsigned(ADC_BITS-1 downto 0);
  --
  signal_delay:in unsigned(SIGNAL_DELAY_BITS-1 downto 0);
  --! Moving average is over 2**n samples
  signal_avn:in unsigned(bits(SIGNAL_AV_BITS) downto 0);
  signal_avn_updated:in boolean;
  --! slope is calculated over 2**n+1 samples
  slope_n:in unsigned(bits(SLOPE_ADDRESS_BITS) downto 0);
  --! clks to delay moving average to align with slope
  sync_clks:in unsigned(SYNC_ADDRESS_BITS downto 0);
  --
  baseline_timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  baseline_threshold:in unsigned(BASELINE_MCA_DATABITS-1 downto 0);
  fixed_baseline:in unsigned(ADC_BITS-1 downto 0);
  baseline_avn:in unsigned(bits(BASELINE_AV_BITS) downto 0);
  baseline_avn_updated:in boolean;
  --!* signals out
  baseline_relative:in boolean;
  baseline:out unsigned(ADC_BITS-1 downto 0);
  sample:out signed(ADC_BITS downto 0);
  slope:out signed(ADC_BITS downto 0);
  valid:out boolean
);
end entity dsp_unit;
--
architecture power_of_2 of dsp_unit is

signal delayed_sample:std_logic_vector(ADC_BITS-1 downto 0);
signal slope_valid,sample_av_valid:boolean;
signal delayed_sample_valid,sync_valid:boolean;
signal baseline_estimate:std_logic_vector(ADC_BITS-1 downto 0);
-- control registers
signal reset_int:std_logic;
signal rel_sample_reg:signed(ADC_BITS downto 0);
signal sample_out:std_logic_vector(ADC_BITS downto 0);
signal sample_av:std_logic_vector(ADC_BITS-1 downto 0);

begin

reset_int <= reset;
baseline <= unsigned(baseline_estimate);
sample <= signed(sample_out);

validReg:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      valid <= FALSE;
    else
      valid <= slope_valid and sample_av_valid and sync_valid and 
               delayed_sample_valid;
    end if;
  end if;
end process validReg;

signalDelay:entity teslib.ring_buffer
generic map(
  ADDRESS_BITS => SIGNAL_DELAY_BITS-1,
  DATA_BITS => ADC_BITS
)
port map(
  clk => clk,
  reset => reset,
  data_in => to_std_logic(adc_sample),
  wr_en => TRUE,
  delay => signal_delay,
  delay_updated => FALSE,
  zerodelay => open,
  delayed => delayed_sample,
  newvalue => open,
  valid => delayed_sample_valid
);

baselineUnit:entity work.baseline
generic map(
  BASELINE_BITS => BASELINE_BITS,
  SAMPLE_BITS => ADC_BITS,
  COUNTER_BITS => 18,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS,
  AVN_BITS => BASELINE_AV_BITS
)
port map(
  clk => clk,
  reset => reset,
  timeconstant => baseline_timeconstant,
  threshold => baseline_threshold,
  fixed_baseline => fixed_baseline,
  avn => baseline_avn,
  avn_updated => baseline_avn_updated,
  sample => sample_av, --adc_sample,
  baseline_estimate => baseline_estimate,
  new_value => open
);

relSample:process(clk)
begin
if rising_edge(clk) then
  if baseline_relative then
    rel_sample_reg 
      <= signed('0' & sample_av)-signed('0' & baseline_estimate);
  else
    rel_sample_reg <= signed('0' & sample_av);
  end if;
end if;
end process relSample;

--FIXME add a second stage
signalAverage:entity work.average
generic map(
	ADDRESS_BITS => SIGNAL_AV_BITS,
	DATA_BITS => ADC_BITS,
	SIGNED_DATA => FALSE
)
port map(
	clk => clk,
  reset => reset,
  data_in => delayed_sample,--to_std_logic(rel_sample_reg),
  enable => TRUE,
  average => sample_av,
  n => signal_avn,
  n_updated => signal_avn_updated,
  valid => open,
  newvalue => open
);
--
slopeUnit:entity work.slope
generic map(
	ADDRESS_BITS => SLOPE_ADDRESS_BITS,
	DATA_BITS => ADC_BITS+1
)
port map(
	clk => clk,
  reset => reset,
  data => signed(rel_sample_reg),
  slope_n => slope_n,
  slope_n_updated => FALSE,
  slope_y => slope,
  slope => open,
  valid => open
);
--
sync:entity teslib.ring_buffer
generic map(
	ADDRESS_BITS => SYNC_ADDRESS_BITS,
	DATA_BITS => ADC_BITS+1
)
port map(
	clk => clk,
  reset => reset,
  data_in => std_logic_vector(rel_sample_reg),
  wr_en => TRUE,
  zerodelay => open,
  delayed => sample_out,
  delay => sync_clks,
  delay_updated  => FALSE,
  newvalue => open,
  valid => open
);
end architecture power_of_2;
