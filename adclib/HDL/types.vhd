library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
constant ADC_BITS:integer:=14; -- Number of bits in an ADC sample;
subtype iodelay_tap is std_logic_vector(4 downto 0);
type iodelay_tap_array is array(natural range <>,natural range <>) of iodelay_tap;
--
subtype adc_sample_t is std_logic_vector(ADC_BITS-1 downto 0);
type adc_sample_array is array(natural range <>) of adc_sample_t;
subtype sample_t is unsigned(ADC_BITS-1 downto 0);
type sample_array is array(natural range <>) of sample_t;
-- LVDS positive or negative clock edge data from ADC 
subtype ddr_sample is std_logic_vector(ADC_BITS/2-1 downto 0);
type ddr_sample_array is array(natural range <>) of ddr_sample;
end package types;

package body types is
	
end package body types;
