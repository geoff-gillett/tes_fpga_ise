--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:3 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: closest_xing
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
use teslib.functions.all;
-- Threshold crossing flagging the closest signal_in to the threshold
-- IE can flag the sample just before the crossing
-- 3 clock latency.
-- NOTE: It's possible to have simultaneous positive and negative crossing 
entity closest_xing is
generic(
	WIDTH:integer:=18
);
port(
  clk:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  signal_out:out signed(WIDTH-1 downto 0);
  pos:out boolean;
  neg:out boolean
);
end entity closest_xing;

architecture RTL of closest_xing is

signal above,below,was_above,was_below:boolean;	
signal pos_int,neg_int,first_closest:boolean;
signal diff,diff_reg,signal_reg,signal_reg2:signed(WIDTH-1 downto 0);
signal neg_xing_next,pos_xing_next:boolean;
	
begin
	
above <= to_0IfX(signal_reg) > to_0IfX(threshold);
below <= to_0IfX(signal_reg) < to_0IfX(threshold);

pos_int <= not below and was_below;
neg_int <= not above and was_above;

first_closest <= to_0ifX(diff_reg) < to_0ifX(diff);

reg:process (clk) is
begin
	if rising_edge(clk) then
		was_above <= above;
		was_below <= below;
		
		signal_reg <= signal_in;
		signal_reg2 <= signal_reg;
		signal_out <= signal_reg2;
		
		diff <= abs(threshold-signal_in);
		diff_reg <= diff;
    pos_xing_next <= pos_int and not first_closest;
    neg_xing_next <= neg_int and not first_closest;
    pos <= (pos_int and first_closest) or pos_xing_next;
    neg <= (neg_int and first_closest) or neg_xing_next;
	end if;
end process reg;
end architecture RTL;
