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
--FIXME fixed signed overflows
entity measurement is
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  pulse_threshold:in sample_t;
  baseline_relative:in boolean;
  --
  slope_threshold:in sample_t; 
  --! always absolute and positive. The minimum positive slope that will trigger
  --! an extrema
  slope_crossing_level:in sample_t;
  --! the value of the slope that the sample is taken at
  --! FALSE and sample threshold is taken when slope falls this far from its max
  baseline_in:in sample_t;
  sample_in:in sample_t;
  slope_in:in sample_t;
  -- latency adjusted  outputs
  sample_out:out sample_t; -- sample out
  slope_out:out sample_t;
  baseline_out:out sample_t;
  --
  local_maxima:out boolean;
  local_minima:out boolean;
  --! sample measurements relative to baseline
  sample_zero_crossing:out boolean;
  sample_extrema:out sample_t;
  sample_area:out area_t;
  --pulse measurements valid at stop
  pulse_area:out area_t;
  pulse_length:out time_t;
  pulse_start:out boolean;
  pulse_stop:out boolean; --pulse variables valid
  --slope measurement
  slope_zero_crossing:out boolean;
  slope_extrema:out sample_t;
  slope_area:out area_t
);
end entity measurement;
--
architecture RTL of measurement is
--
signal rel_sample:sample_t:=(others => '0');
signal sample_reg1,sample_reg2,sample_reg3:sample_t:=(others => '0');
signal baseline_reg1,baseline_reg2,baseline_reg3:sample_t:=(others => '0');
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
    rel_sample <= sample_reg1-baseline_reg1;
  end if;
end if;
end process relSample;

sampleZeroCrossing:entity work.zero_crossing_measurements
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
port map(
  clk => clk,
  reset => reset,
  slope => slope_in,
  slope_out => slope_out,
  downward_arming_threshold => slope_threshold,
  upward_arming_threshold => (others => '0'),
  downward_crossing_threshold => slope_crossing_level,
  upward_crossing_threshold => (others => '0'),
  downward_crossing => local_maxima,
  upward_crossing => local_minima,
  zero_crossing => slope_zero_crossing,
  extrema => slope_extrema,
  area => slope_area
);

end architecture RTL;