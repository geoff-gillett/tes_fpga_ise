--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:5 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: robust_fabric differentiator architecture
-- Project Name: dsplib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

-- fabric architectures
-- dif = -x(n)/16+x(n-2)-x(n-4)+x(n-6)/16
-- has a gain of ~1.68
architecture simple_fabric of differentiator is
signal delay:sample_array(1 to 6);
signal sum1,sum2,sum3:sample_t;
begin

diff:process(clk)
begin
if rising_edge(clk) then
	delay(1) <= sample;
	for i in 2 to 6 loop
	  delay(i) <= delay(i-1);
	end loop;
	sum1 <= delay(6) - sample;
	sum2 <= delay(2) - delay(4);
	sum3 <= sum2 + shift_right(sum1,4);
end if;
end process diff;
derivitive <= sum3;
sample_out <= delay(4);

end architecture simple_fabric;