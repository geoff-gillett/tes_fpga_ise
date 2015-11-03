--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:08/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: measurement_unit
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
--
library teslib;
--use TES.events.all;
use teslib.types.all;
use teslib.functions.all;
--

entity measurement is
generic(
  ADC_BITS:integer:=14;
  TIME_BITS:integer:=14;
  AREA_BITS:integer:=26
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  pulse_threshold:in unsigned(ADC_BITS-1 downto 0);
  baseline_relative:in boolean;
  --
  slope_threshold:in unsigned(ADC_BITS-1 downto 0); 
  --! always absolute and positive. The minimum positive slope that will trigger
  --! an extrema
  slope_crossing_level:in unsigned(ADC_BITS-1 downto 0);
  --! the value of the slope that the sample is taken at
  --! FALSE and sample threshold is taken when slope falls this far from its max
  baseline_in:in unsigned(ADC_BITS-1 downto 0);
  sample_in:in signed(ADC_BITS downto 0);
  slope_in:in signed(ADC_BITS downto 0);
  -- latency adjusted  outputs
  sample_out:out signed(ADC_BITS downto 0); -- sample out
  slope_out:out signed(ADC_BITS downto 0);
  baseline_out:out unsigned(ADC_BITS-1 downto 0);
  --
  local_maxima:out boolean;
  local_minima:out boolean;
  --! sample measurements relative to baseline
  sample_zero_crossing:out boolean;
  sample_extrema:out signed(ADC_BITS downto 0);
  sample_area:out signed(AREA_BITS downto 0);
  --pulse measurements valid at stop
  pulse_area:out unsigned(AREA_BITS-1 downto 0);
  pulse_length:out unsigned(TIME_BITS-1 downto 0);
  pulse_start:out boolean;
  pulse_stop:out boolean; --pulse variables valid
  --slope measurement
  slope_zero_crossing:out boolean;
  slope_extrema:out signed(ADC_BITS downto 0);
  slope_area:out signed(AREA_BITS downto 0)
);
end entity measurement;
--
architecture RTL of measurement is
--
signal rel_sample:signed(ADC_BITS downto 0):=(others => '0');
signal sample_reg1,sample_reg2,sample_reg3:signed(ADC_BITS downto 0)
       :=(others => '0');
signal baseline_reg1,baseline_reg2,baseline_reg3:unsigned(ADC_BITS-1 downto 0)
       :=(others => '0');
--
begin
--
--pulse_area <= pulse_area_int;
--pulse_length <= relative_time;
--sample <= sample_int;
--------------------------------------------------------------------------------
-- pipeline                   
--               sample             slope            pulse
--------------------------------------------------------------------------------
-- stage 1 (in)  relative sample    crossing         threshold rel
-- stage 2 (reg) crossings          slope min max    area
-- stage 3 (out)                                     
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- slope 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- sample measurements
--------------------------------------------------------------------------------
relSample:process(clk)
begin
if rising_edge(clk) then
  sample_reg1 <= sample_in;
  sample_reg2 <= sample_reg1;
  sample_reg3 <= sample_reg2;
  sample_out <= sample_reg2;
  baseline_reg1 <= baseline_in;
  baseline_reg2 <= baseline_reg1;
  baseline_reg3 <= baseline_reg2;
  baseline_out <= baseline_reg3;
  if baseline_relative then
    rel_sample <= sample_reg1;
  else
    rel_sample <= sample_reg1-signed('0' & baseline_reg1);
  end if;
end if;
end process relSample;

sampleZeroCrossing:entity work.zero_crossing_measurements
generic map(
  ADC_BITS => ADC_BITS,
  AREA_BITS => AREA_BITS
)
port map(
  clk => clk,
  reset => reset,
  sample => rel_sample,
  sample_out => open,
  zero_crossing => sample_zero_crossing,
  extrema => sample_extrema,
  area => sample_area
);
--------------------------------------------------------------------------------
-- pulse measurements
--------------------------------------------------------------------------------
pulseMeasurement:entity work.pulse_measurement
generic map(
  ADC_BITS => ADC_BITS,
  TIME_BITS => TIME_BITS,
  AREA_BITS => AREA_BITS
)
port map(
  clk => clk,
  reset => reset,
  threshold => pulse_threshold,
  sample => sample_in,
  area => pulse_area,
  length => pulse_length,
  start => pulse_start,
  stop => pulse_stop
);
--
slopeMeasurement:entity work.slope_measurement
generic map(
  ADC_BITS => ADC_BITS,
  AREA_BITS => AREA_BITS
)
port map(
  clk => clk,
  reset => reset,
  slope => slope_in,
  slope_out => slope_out,
  downward_arming_threshold => signed('0' & slope_threshold),
  upward_arming_threshold => (others => '0'),
  downward_crossing_threshold => signed('0' & slope_crossing_level),
  upward_crossing_threshold => (others => '0'),
  downward_crossing => local_maxima,
  upward_crossing => local_minima,
  zero_crossing => slope_zero_crossing,
  extrema => slope_extrema,
  area => slope_area
);

end architecture RTL;