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

library extensions;
use extensions.logic.all;

use work.functions.all;

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

signal pos_int,neg_int,first_closest:boolean;
signal diff,diff_reg:signed(WIDTH-1 downto 0);
signal neg_xing_next,pos_xing_next:boolean;

constant DEPTH:integer:=6;	
type pipe_t is array (natural range <>) of signed(WIDTH-1 downto 0);
signal pipe:pipe_t(1 to DEPTH);
signal dif0,dif1:signed(WIDTH-1 downto 0);
signal xing:std_logic;
signal dif_0,dif_was0:boolean;

begin

first_closest <= dif0 < dif1;
xing <= dif0(WIDTH-1) xor dif1(WIDTH-1);
pos_int <= (xing and dif1(WIDTH-1))='1';
neg_int <= (xing='1' and dif1(WIDTH-1)='0') or (dif_0 and not dif_was0);

reg:process (clk) is
begin
	if rising_edge(clk) then
	  
	  pipe(1) <= signal_in;
	  pipe(2 to DEPTH) <= pipe(1 to DEPTH-1);
	  
	  dif_0 <= signal_in=threshold;
	  dif_was0 <= dif_0;
	  
	  dif0 <= threshold-signal_in; 
	  dif1 <= pipe(1)-threshold;
		
		diff <= abs(threshold-signal_in);
		diff_reg <= diff;
		
    pos_xing_next <= pos_int and not first_closest;
    neg_xing_next <= neg_int and not first_closest;
    pos <= (pos_int and first_closest) or pos_xing_next;
    neg <= (neg_int and first_closest) or neg_xing_next;
	end if;
end process reg;
end architecture RTL;
