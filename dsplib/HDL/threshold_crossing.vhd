library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
entity threshold_crossing is
generic(
  ADC_BITS:integer:=14
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  threshold:in signed(ADC_BITS downto 0);
  value:in signed(ADC_BITS downto 0);
  -- in registered arch these signals 
  above:out boolean;
  below:out boolean;
  upward:out boolean;
  downward:out boolean;
  -- 1 clk latency
  value_out:out signed(ADC_BITS downto 0)
);
end entity threshold_crossing;
--1 clk latency
--architecture registered of threshold_crossing is
--
--signal value_reg_above,value_reg_below:boolean;
--signal value_reg_upward,value_reg_downward:boolean;
--signal value_reg:signed(ADC_BITS downto 0 );
--
--begin
--
--below <= value_reg_below;
--above <= value_reg_above;
--upward <= value_reg_upward;
--downward <= value_reg_downward;
--value_out <= value_reg;
--
--pipeLine:process(clk)
--variable value_in_above,value_in_below,value_in_equal:boolean;
--begin
--if rising_edge(clk) then
--  if reset='1' then
--    value_reg <= (others => '-');
--    value_reg_below <= FALSE;
--    value_reg_above <= FALSE;
--    value_reg_upward <= FALSE;
--    value_reg_downward <= FALSE;
--  else
--    value_reg <= value;
--    
--    value_in_above := value > threshold;
--    value_in_below := value < threshold;
--    value_in_equal := value=threshold;
--    
--    value_reg_below <= value_in_below;
--    value_reg_above <= value_in_above;
--    
--    value_reg_upward <= (value_in_above or value_in_equal) and value_reg_below;
--    value_reg_downward <= (value_in_below or value_in_equal) and value_reg_above;
--  end if;
--end if;
--end process pipeLine;

--end architecture registered;

architecture combinatorial of threshold_crossing is

signal above_int,below_int,equal:boolean;
signal value_reg:signed(ADC_BITS downto 0);

begin

below_int <= value < threshold;
below <= below_int;
above_int <= value > threshold;
above <= above_int;
equal <= value=threshold;

upward <= (above_int or equal) and value_reg < threshold;
downward <= (below_int or equal) and value_reg > threshold;
value_out <= value_reg;

outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    value_reg <= (others => '0');
  else
    value_reg <= value;
  end if;
end if;
end process outputReg;
end architecture combinatorial;


