library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
-- latency 2
-- Want xing 
entity threshold_xing is
generic(
  THRESHOLD_BITS:integer:=32;
  THRESHOLD_FRAC:integer:=17;
  OUT_BITS:integer:=16;
  OUT_FRAC:integer:=1
);
port(
  clk:in std_logic;
  --
  threshold:in signed(THRESHOLD_BITS-1 downto 0);
  value:in signed(THRESHOLD_BITS-1 downto 0);
  -- in registered arch these signals 
  pos_threshold_xing:out boolean;
  neg_threshold_xing:out boolean;
  pos_0_xing:out boolean;
  neg_0_xing:out boolean;
  value_out:out signed(OUT_BITS-1 downto 0)
);
end entity threshold_xing;

architecture rtl of threshold_xing is

signal above,below,above_0,below_0:boolean;
signal value_reg:signed(THRESHOLD_BITS-1 downto 0);
signal pos_0_xing_reg,neg_0_xing_reg,pos_threshold_xing_reg,
			 neg_threshold_xing_reg:boolean;

begin

below <= value < threshold;
above <= value > threshold;
above_0 <= value > 0;
below_0 <= value < 0;

outputReg:process(clk)
begin
if rising_edge(clk) then
  value_reg <= value;
  value_out <= resize(shift_right(
  	value_reg,THRESHOLD_FRAC-OUT_FRAC),OUT_BITS);
  pos_threshold_xing_reg <= above and value_reg <= threshold;
  neg_threshold_xing_reg <= below and value_reg >= threshold;
  pos_0_xing_reg <= above_0 and value_reg <= 0;
  neg_0_xing_reg <= below_0 and value_reg >= 0;
  pos_0_xing <= pos_0_xing_reg;
  neg_0_xing <= neg_0_xing_reg;
  pos_threshold_xing <= pos_threshold_xing_reg;
  neg_threshold_xing <= neg_threshold_xing_reg;
end if;
end process outputReg;
end architecture rtl;
