
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
--! the baseline is the maximum of the signal distribution
--! the distribution is collected in a MCA over 2**TIMECONSTANT clks
--! and the average of the maximum of of the last two distributions is the
--! baseline.
entity baseline is
generic(
  --The distributions are acquired over 2**TIMECONSTANT_BITS clks
  --number of bins (channels) = 2**ADDRESS_BITS
  BASELINE_BITS:integer:=12;
  SAMPLE_BITS:integer:=14;
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
  threshold:in unsigned(COUNTER_BITS-1 downto 0);
  --offset to center of mca range 
  fixed_baseline:in unsigned(SAMPLE_BITS-1 downto 0);
  avn:in unsigned(bits(AVN_BITS) downto 0);
  avn_updated:in boolean;
  --
  sample:in std_logic_vector(SAMPLE_BITS-1 downto 0);
  --sample_valid:in boolean;
  --
  baseline_estimate:out std_logic_vector(SAMPLE_BITS-1 downto 0);
  new_value:out boolean
);
end entity baseline;
--
architecture most_frequent of baseline is

signal baseline_sample:std_logic_vector(BASELINE_BITS-1 downto 0);
signal baseline_lowest_value:unsigned(SAMPLE_BITS-1 downto 0);
signal baseline_sample_valid:boolean;
signal most_frequent,most_frequent_av:std_logic_vector(BASELINE_BITS-1 downto 0);
signal new_most_frequent,new_average:boolean;

begin

baselineControl:process(clk)
variable offset,offset_sample:signed(SAMPLE_BITS downto 0);
variable highest_value:unsigned(SAMPLE_BITS downto 0);
constant HALF_WIDTH:unsigned(SAMPLE_BITS-1 downto 0)
         :=to_unsigned((2**BASELINE_BITS)/2,SAMPLE_BITS);
begin
if rising_edge(clk) then
  
  offset:=signed('0' & fixed_baseline)-signed(HALF_WIDTH);
  highest_value:=('0' & fixed_baseline)+HALF_WIDTH;
  
  if offset(SAMPLE_BITS)='1' then --less than 0
    baseline_lowest_value <= (others => '0');
  elsif highest_value(SAMPLE_BITS)='1' then --greater than 2**SAMPLE_BITS-1
    baseline_lowest_value 
      <= to_unsigned((2**SAMPLE_BITS-1)-(2**BASELINE_BITS-1),SAMPLE_BITS);
  else
    baseline_lowest_value <= unsigned(offset(SAMPLE_BITS-1 downto 0));
  end if;
  offset_sample:=signed('0' & sample)-signed('0' & baseline_lowest_value);
  baseline_sample <= to_std_logic(offset_sample(BASELINE_BITS-1 downto 0));
  if offset_sample(SAMPLE_BITS)='1' then
    baseline_sample_valid <= FALSE;
  elsif offset_sample(BASELINE_BITS)='1' then
    baseline_sample_valid <= FALSE;
  else
    baseline_sample_valid <= TRUE;
  end if;
end if;
end process baselineControl;
--
mostFrequent:entity work.most_frequent
generic map(
  SAMPLE_BITS => BASELINE_BITS,
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
  SIGNED_DATA => FALSE
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
    baseline_estimate <= to_std_logic(fixed_baseline);
  else
    new_value <= new_average;
    if timeconstant=0 then
      baseline_estimate <= to_std_logic(fixed_baseline);
    elsif new_average then
      baseline_estimate 
        <= to_std_logic(unsigned(most_frequent_av)+baseline_lowest_value);
    end if;
  end if;
end if;
end process outputReg;
end architecture most_frequent;