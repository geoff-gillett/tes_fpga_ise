library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slope_measurement is
generic(
  ADC_BITS:integer:=14;
  AREA_BITS:integer:=26
);
port (
  clk:in std_logic;
  reset:in std_logic;
  slope:in signed(ADC_BITS downto 0);
  -- 2 clk latency
  slope_out:out signed(ADC_BITS downto 0);
  --signal rising above this threshold arms the downward crossing 
  downward_arming_threshold:in signed(ADC_BITS downto 0); 
  --signal going below this threshold arms the upward crossing 
  upward_arming_threshold:in signed(ADC_BITS downto 0); 
  -- 
  downward_crossing_threshold:in signed(ADC_BITS downto 0);
  upward_crossing_threshold:in signed(ADC_BITS downto 0);
  --
  downward_crossing:out boolean;
  upward_crossing:out boolean;
  --
  zero_crossing:out boolean; --extrema valid
  extrema:out signed(ADC_BITS downto 0);
  area:out signed(AREA_BITS downto 0)
);
end entity slope_measurement;

architecture RTL of slope_measurement is
signal maxima,minima,max_found,max_armed,min_armed:boolean;
signal slope_reg1,slope_reg2:signed(ADC_BITS downto 0);
  
begin

downwardCrossing:entity work.threshold_crossing(combinatorial)
port map(
  clk => clk,
  reset => reset,
  threshold => downward_crossing_threshold,
  value => slope,
  above => open,
  below => open,
  upward => open,
  downward => maxima,
  value_out => open
);

upwardCrossing:entity work.threshold_crossing(combinatorial)
port map(
  clk => clk,
  reset => reset,
  threshold => upward_crossing_threshold,
  value => slope,
  above => open,
  below => open,
  upward => minima,
  downward => open,
  value_out => open
);

slopeZeroCrossing:entity work.zero_crossing_measurements
generic map(
  ADC_BITS => ADC_BITS,
  AREA_BITS => AREA_BITS
)
port map(
  clk => clk,
  reset => reset,
  sample => slope,
  sample_out => slope_out,
  zero_crossing => zero_crossing,
  extrema => extrema,
  area => area
);

peakDetect:process(clk)
begin
if rising_edge(clk) then

  if reset = '1' then
    max_armed <= FALSE;
    min_armed <= FALSE;
    max_found <= FALSE;
  else
    slope_reg2 <= slope_reg1;
    --slope_out <= slope_reg1;
    if minima and min_armed and max_found then
      upward_crossing <= TRUE;
      min_armed <= FALSE;
      max_found <= FALSE;
    else
      upward_crossing <= FALSE;
    end if;
    if maxima and max_armed then
      downward_crossing <= TRUE;
      max_armed <= FALSE;
      max_found <= TRUE;
    else
      downward_crossing <= FALSE;
    end if;
    if slope >= downward_arming_threshold then
      max_armed <= TRUE;
    end if;
    if slope <= upward_arming_threshold then
      min_armed <= TRUE;
    end if;
  end if;
end if;
end process peakDetect;

end architecture RTL;
