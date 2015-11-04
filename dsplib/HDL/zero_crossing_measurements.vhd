library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;

entity zero_crossing_measurements is
port (
  clk:in std_logic;
  reset:in std_logic;
  sample:in sample_t;
  sample_out:out sample_t;
  zero_crossing:out boolean;
  extrema:out sample_t;
  area:out area_t
);
end entity zero_crossing_measurements;

architecture RTL of zero_crossing_measurements is

signal max,min,sample_reg:sample_t;
signal upward,downward,upward_reg,downward_reg:boolean;
  
begin
sample_out <= sample_reg;

zeroCrossing:entity work.threshold_crossing(combinatorial)
port map(
  clk => clk,
  reset => reset,
  threshold => (others => '0'),
  value => sample,
  above => open,
  below => open,
  upward => upward,
  downward => downward,
  value_out => sample_reg
);

maxMin:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    max <= (others => '0');
    min <= (others => '0');
  else
    zero_crossing <= upward or downward;
    if sample > max then
      max <= sample;
    end if;
    if sample < min then
      min <= sample;
    end if;
    if upward then
      extrema <= min;
      min <= sample;
    end if;
    if downward then
      extrema <= max;
      max <= sample;
    end if;
  end if;
end if;
end process maxMin;
--FIXME add saturation to area
sampleArea:process(clk)
variable area_int:signed(AREA_BITS-1 downto 0);
begin
if rising_edge(clk) then
  if reset = '1' then
    area_int:=(others => '0');
    upward_reg <= FALSE;
    downward_reg <= FALSE;
  else
    upward_reg <= upward;
    downward_reg <= downward;
    if upward_reg or downward_reg then
      area_int:=resize(sample_reg,AREA_BITS);
    else
      area_int:=area_int+sample_reg;
    end if;
    area <= resize(area_int,AREA_BITS);
  end if;
end if;
end process sampleArea;
end architecture RTL;
