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

use work.dsptypes.all;
use work.functions.all;
use work.types.all;

--FIXME make this description understandable
--! the baseline is the maximum of the signal distribution
--! the distribution is collected in a MCA over timeconstant clks
--! and the average of the maximum of of the last two distributions is the
--! baseline.
--
entity baseline_estimator is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  BASELINE_BITS:integer:=11;
  --width of counters and stream
  COUNTER_BITS:integer:=18;
  TIMECONSTANT_BITS:integer:=32;
  MAX_AVERAGE_ORDER:integer:=6;
  OUT_BITS:integer:=18
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  sample:in sample_t;
  sample_valid:in boolean;
  --
  timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  -- above this threshold sample does not contribute to estimate
  threshold:unsigned(BASELINE_BITS-2 downto 0);
  -- count required before adding to average
  count_threshold:in unsigned(COUNTER_BITS-1 downto 0);
  average_order:natural range 0 to MAX_AVERAGE_ORDER;
  --only include a value in average if it different from the previous value
  new_only:in boolean;
  --
  baseline_estimate:out signed(OUT_BITS-1 downto 0);
  range_error:out boolean
);
end entity baseline_estimator;

architecture most_frequent of baseline_estimator is

signal baseline_sample:std_logic_vector(BASELINE_BITS-1 downto 0);
signal baseline_sample_valid:boolean;
signal most_frequent:std_logic_vector(BASELINE_BITS-1 downto 0);
signal previous_mf:std_logic_vector(BASELINE_BITS-1 downto 0);
signal mf_value:signed(BASELINE_BITS-1 downto 0);
signal av_enable:boolean;
signal most_frequent_av:signed(OUT_BITS-1 downto 0);
signal new_most_frequent:boolean;
signal new_mf:boolean;

begin
--FIXME I think the timing might be off for sample_valid
baselineControl:process(clk)
variable lowest,highest:sample_t;
constant HALF_RANGE:sample_t:=to_signed((2**BASELINE_BITS)/2,SAMPLE_BITS);
begin
if rising_edge(clk) then
  lowest:=-HALF_RANGE;
  highest:=HALF_RANGE-1;
  
  baseline_sample <= std_logic_vector(resize(sample,BASELINE_BITS));
	if (sample > resize(signed('0' & threshold), SAMPLE_BITS)) then 
		baseline_sample_valid <= FALSE;
		range_error <= FALSE;
	elsif sample > highest then 
		baseline_sample_valid <= FALSE;
		range_error <= TRUE;
	elsif sample < lowest then
		baseline_sample_valid <= FALSE;
		range_error <= TRUE;
	else
		baseline_sample_valid <= sample_valid;
		range_error <= FALSE;
	end if;
end if;
end process baselineControl;

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
  threshold => count_threshold,
  sample => baseline_sample,
  sample_valid => baseline_sample_valid,
  most_frequent => most_frequent,
  new_value => new_most_frequent
);

new_mf <= previous_mf /= most_frequent;
newOnly:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			previous_mf <= (others => '0');
			av_enable <= FALSE;
		else
			if new_most_frequent then
				previous_mf <= most_frequent;
				if new_only then
					if new_mf then
						av_enable <= TRUE;
						mf_value <= signed(most_frequent);
					else
						av_enable <= FALSE;	
					end if;
				else
					mf_value <= signed(most_frequent);
					av_enable <= TRUE;
				end if;
			else
				av_enable <= FALSE;
			end if;
		end if;
	end if;
end process newOnly;

average:entity work.average_filter
generic map(
  MAX_ORDER => MAX_AVERAGE_ORDER,
  IN_BITS   => BASELINE_BITS,
  OUT_BITS  => OUT_BITS
)
port map(
  clk => clk,
  enable => av_enable,
  sample => mf_value,
  order => average_order,
  average => most_frequent_av
);

outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    baseline_estimate <= to_signed(0,OUT_BITS);
  else
    if timeconstant=0 then
    	baseline_estimate <= to_signed(0,OUT_BITS);
    else
      baseline_estimate <=  most_frequent_av;
    end if;
  end if;
end if;
end process outputReg;
end architecture most_frequent;