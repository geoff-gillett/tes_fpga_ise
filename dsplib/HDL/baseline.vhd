--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: histogram_unit
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library adclib;
use adclib.types.all;
--FIXME make this description understandable
--! the baseline is the maximum of the signal distribution
--! the distribution is collected in a MCA over timeconstant clks
--! and the average of the maximum of of the last two distributions is the
--! baseline.
entity baseline is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  BASELINE_BITS:integer:=12;
  --width of counters and stream
  COUNTER_BITS:integer:=18;
  TIMECONSTANT_BITS:integer:=32;
  AVN_BITS:integer:=4
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  -- count required before adding to average
  threshold:in unsigned(COUNTER_BITS-1 downto 0);
  --offset to center of mca range 
  fixed_baseline:in sample_t;
  avn:in unsigned(bits(AVN_BITS) downto 0);
  avn_updated:in boolean;
  --
  sample:in sample_t;
  --sample_valid:in boolean;
  --
  baseline_estimate:out sample_t;
  range_error:out boolean;
  new_value:out boolean
);
end entity baseline;
--TODO bring start_threshold into the picture
architecture most_frequent of baseline is

signal baseline_sample:std_logic_vector(BASELINE_BITS-1 downto 0);
signal baseline_sample_valid:boolean;
signal most_frequent,most_frequent_av
			 :std_logic_vector(BASELINE_BITS-1 downto 0);
signal new_most_frequent,new_average:boolean;
signal offset_sample,offset,limit:sample_t;

begin

baselineControl:process(clk)
variable lowest,highest:sample_t;
constant HALF_RANGE:sample_t:=to_signed((2**BASELINE_BITS)/2,SAMPLE_BITS);
begin
if rising_edge(clk) then
  lowest:=fixed_baseline-HALF_RANGE;
  highest:=fixed_baseline+HALF_RANGE-1;
  offset <= lowest;
  limit <= highest;
  
  offset_sample <= sample-offset;
  baseline_sample <= to_std_logic(resize(offset_sample,BASELINE_BITS));
	
	if offset_sample > limit then 
		baseline_sample_valid <= FALSE;
		range_error <= FALSE;
	elsif offset_sample < offset then
		baseline_sample_valid <= FALSE;
		range_error <= TRUE;
	else
		baseline_sample_valid <= TRUE;
		range_error <= FALSE;
	end if;
end if;
end process baselineControl;
--
mostFrequent:entity work.most_frequent
generic map(
  ADDRESS_BITS => BASELINE_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS
)
port map(
  clk => clk,
  reset => reset,
  timeconstant => timeconstant,
  threshold => threshold,
  sample => baseline_sample,
  sample_valid => baseline_sample_valid,
  most_frequent => most_frequent,
  new_value => new_most_frequent
);
--
average:entity work.average
generic map(
  ADDRESS_BITS => AVN_BITS,
  DATA_BITS => BASELINE_BITS,
  SIGNED_DATA => TRUE
)
port map(
  clk => clk,
  reset => reset,
  enable => new_most_frequent,
  data_in => most_frequent,
  average => most_frequent_av,
  valid => open,
  n => avn,
  n_updated => avn_updated,
  newvalue => new_average 
);
--
outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    baseline_estimate <= fixed_baseline;
  else
    new_value <= new_average;
    if timeconstant=0 then
      baseline_estimate <= fixed_baseline;
    elsif new_average then
      baseline_estimate <= resize(signed(most_frequent_av)+offset,SAMPLE_BITS);
    end if;
  end if;
end if;
end process outputReg;
end architecture most_frequent;