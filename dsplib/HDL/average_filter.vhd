library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
--
-- Implements a Gaussian like filter (by central limit theorem) 
-- Running average over 2 samples applied order times
-- Not area efficient but usable with stages less <= 8 and narrow widths
-- average precision will be w=OUT_BITS f=OUT_BITS-IN_BITS
-- OUT_BITS must be >= IN_BITS
-- TODO make unsigned arch, latency could be reduced
--
entity average_filter is
generic(
	--minimum 2
	MAX_ORDER:integer:=8;
	IN_BITS:integer:=11;
	OUT_BITS:integer:=16
);
port(
  clk:in std_logic;
  enable:in boolean;
  sample:in signed(IN_BITS-1 downto 0);
  order:in integer range 0 to MAX_ORDER;
  average:out signed(OUT_BITS-1 downto 0)
);
end entity average_filter;

architecture unsigned of average_filter is

type pipeline is array (natural range <>) of signed(OUT_BITS-1 downto 0);
signal stage:pipeline(1 to MAX_ORDER):=(others =>(others => '0'));
signal reg:pipeline(0 to MAX_ORDER-1):=(others =>(others => '0'));
signal sample_int:signed(OUT_BITS-1 downto 0);

begin
stages:process(clk) is
begin
if rising_edge(clk) then
	if enable then
    sample_int <= shift_left(resize(sample,OUT_BITS), OUT_BITS-IN_BITS);
    reg(0) <= sample_int;
    stage(1) <= shift_right(reg(0)+sample_int,1);
    for i in 1 to MAX_ORDER-1 loop
      reg(i) <= stage(i);
      stage(i+1) <= shift_right(reg(i)+stage(i),1);
    end loop;
	end if;
end if;
end process stages;

outputReg:process (clk) is
begin
if rising_edge(clk) then
	average <= reg(order);
end if;
end process outputReg;


end architecture unsigned;
