--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:5 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: differentiator
-- Project Name: dsplib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;


entity differentiator is
port (
  clk:in std_logic;
  sample:in sample_t;
  derivitive:out sample_t;
  sample_out:out sample_t
);
end entity differentiator;

architecture robust_fabric of differentiator is
signal delay:sample_array(1 to 4);
signal result,sum1,sum2:signed(SAMPLE_BITS+1 downto 0);
begin

diff:process(clk)
begin
if rising_edge(clk) then
	delay(1) <= sample;
	for i in 2 to 4 loop
	  delay(i) <= delay(i-1);
	end loop;
	sum1 <= resize(sample-delay(4),SAMPLE_BITS+2);
	sum2 <= resize(delay(1) - delay(3),SAMPLE_BITS+2);
	result <= sum2 + shift_left(sum1,1);
	derivitive <= resize(shift_right(result, 3),SAMPLE_BITS);
	sample_out <= delay(4);
end if;
end process diff;

end architecture robust_fabric;
