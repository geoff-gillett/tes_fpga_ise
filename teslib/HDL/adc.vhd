library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
use work.types.ADC_BITS;
--

package adc is
constant ADC_SIGNED_MODE:boolean:=FALSE;
--
subtype iodelay_tap is std_logic_vector(4 downto 0);
type iodelay_tap_array is array(natural range <>,natural range <>) of iodelay_tap;
--
subtype adc_sample_t is std_logic_vector(ADC_BITS-1 downto 0);
type adc_sample_array_t is array(natural range <>) of adc_sample_t;
-- LVDS positive or negative clock edge data from ADC 
subtype ddr_sample is std_logic_vector(ADC_BITS/2-1 downto 0);
type ddr_sample_array is array(natural range <>) of ddr_sample;
end package adc;

package body adc is
	
end package body adc;
