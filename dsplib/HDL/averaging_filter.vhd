library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;

entity averaging_filter is
generic(
	--minimum 2
	STAGES:integer:=8
);
port(
  clk:in std_logic;
  sample:in sample_t;
  n:in integer range 0 to STAGES;
  average:out sample_t
);
end entity averaging_filter;

architecture RTL of averaging_filter is
signal stage:sample_array(1 to STAGES);
signal reg:sample_array(0 to STAGES-1);
begin

stage0:process(clk) is
begin
if rising_edge(clk) then
	reg(0) <= sample;
	stage(1) <= shift_right(reg(0)+sample,1);
	for i in 1 to STAGES-1 loop
  	 reg(i) <= stage(i);
  	 stage(i+1) <= shift_right(reg(i)+stage(i),1);
	end loop;
end if;
end process stage0;

outputReg:process (clk) is
begin
if rising_edge(clk) then
	average <= stage(n);
end if;
end process outputReg;


end architecture RTL;
