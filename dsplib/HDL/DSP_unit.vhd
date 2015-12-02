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
library adclib;
use adclib.types.all;

entity dsp_unit is
generic(
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
  adc_sample:adc_sample_t;
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
  fixed_baseline:in sample_t;
  baseline_avn:in unsigned(bits(BASELINE_AV_BITS) downto 0);
  baseline_avn_updated:in boolean;
  --!* signals out
  baseline_relative:in boolean;
  baseline:out sample_t;
  sample:out sample_t;
  slope:out sample_t;
  valid:out boolean
);
end entity dsp_unit;
--
architecture power_of_2 of dsp_unit is

signal slope_valid,sample_av_valid:boolean;
signal delayed_sample_valid,sync_valid:boolean;
signal baseline_estimate:sample_t;
-- control registers
signal reset_int:std_logic;
signal sample_reg:sample_t;
signal sample_out,sample_av_int,delayed_sample
			 :std_logic_vector(SAMPLE_BITS-1 downto 0);
signal sample_av:sample_t;
signal adc_sample_int:sample_t;

begin

reset_int <= reset;
baseline <= baseline_estimate;
sample <= signed(sample_out);

--FIXME valid is poorly handled throughout
validReg:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
    	valid <= FALSE;
    	adc_sample_int <= fixed_baseline;
    else
      valid <= slope_valid and sample_av_valid and sync_valid and 
               delayed_sample_valid;
      if ADC_SIGNED_MODE then
      	adc_sample_int <= resize(signed(adc_sample),SAMPLE_BITS);
      else
      	adc_sample_int <= signed('0' & adc_sample);
      end if;
    end if;
  end if;
end process validReg;

signalDelay:entity teslib.ring_buffer
generic map(
  ADDRESS_BITS => SIGNAL_DELAY_BITS-1, --FIXME why -1
  DATA_BITS => SAMPLE_BITS
)
port map(
  clk => clk,
  reset => reset,
  data_in => to_std_logic(adc_sample_int),
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
  COUNTER_BITS => 18,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS,
  AVN_BITS => BASELINE_AV_BITS
)
port map(
  sample_valid => TRUE,
  clk => clk,
  reset => reset,
  timeconstant => baseline_timeconstant,
  count_threshold => baseline_threshold,
  fixed_baseline => fixed_baseline,
  avn => baseline_avn,
  avn_updated => baseline_avn_updated,
  sample => adc_sample_int, --delayed_sample,
  baseline_estimate => baseline_estimate,
  new_value => open
);

relSample:process(clk)
begin
if rising_edge(clk) then
	if baseline_relative then
    sample_reg <= adc_sample_int-baseline_estimate;
  else
		sample_reg <= adc_sample_int;
  end if;
end if;
end process relSample;

--FIXME use actual DSP!
signalAverage:entity work.average
generic map(
  ADDRESS_BITS => SIGNAL_AV_BITS,
  DATA_BITS => SAMPLE_BITS,
  SIGNED_DATA => TRUE
)
port map(
  clk => clk,
  reset => reset,
  data_in => to_std_logic(sample_reg),
  enable => TRUE,
  average => sample_av_int,
  n => signal_avn,
  n_updated => signal_avn_updated,
  valid => open,
  newvalue => open
);
avReg:process(clk) is
begin
if rising_edge(clk) then
	sample_av <= signed(sample_av_int);
end if;
end process avReg;

--
slopeUnit:entity work.slope
generic map(
	ADDRESS_BITS => SLOPE_ADDRESS_BITS,
	DATA_BITS => SAMPLE_BITS
)
port map(
	clk => clk,
  reset => reset,
  data => signed(sample_av),
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
	DATA_BITS => SAMPLE_BITS
)
port map(
	clk => clk,
  reset => reset,
  data_in => std_logic_vector(sample_av),
  wr_en => TRUE,
  zerodelay => open,
  delayed => sample_out,
  delay => sync_clks,
  delay_updated  => FALSE,
  newvalue => open,
  valid => open
);
end architecture power_of_2;
