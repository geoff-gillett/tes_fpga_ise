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

entity threshold_xing is
generic(
	WIDTH:integer:=18
);
port(
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  
  signal_out:out signed(WIDTH-1 downto 0);
  pos:out boolean;
  neg:out boolean;
  pos_closest:out boolean;
  neg_closest:out boolean
);
end entity threshold_xing;

architecture RTL of threshold_xing is

signal pos_int,neg_int,first_closest,pos_reg,neg_reg:boolean;
signal neg_xing_next,pos_xing_next:boolean;

constant DEPTH:integer:=3;	
type pipe_t is array (natural range <>) of signed(WIDTH-1 downto 0);
signal pipe:pipe_t(1 to DEPTH):=(others => (others => '0'));
signal dif0,dif1:signed(WIDTH-1 downto 0);
signal sign_change:std_logic;
signal dif_is0,dif_was0:boolean;

begin
signal_out <= pipe(DEPTH);
first_closest <= dif0 < dif1;
sign_change <= not (dif0(WIDTH-1) xor dif1(WIDTH-1));
pos_int <= ((sign_change='1' or dif_is0) and dif1(WIDTH-1)='1');-- or 
           --(dif_is0 and dif1(WIDTH-1)='1');
neg_int <= (sign_change='1' and dif1(WIDTH-1)='0') and not dif_was0;

reg:process (clk) is
begin
	if rising_edge(clk) then
	  if reset='1' then
	    pipe <= (others => (others => '0'));
	    dif0 <= (others => '0');
	    dif1 <= (others => '0');
	    dif_is0 <= TRUE;
	    dif_was0 <= TRUE;
	  else
      pipe(1) <= signal_in;
      pipe(2 to DEPTH) <= pipe(1 to DEPTH-1);
      
      dif_is0 <= signal_in=threshold;
      dif_was0 <= dif_is0;
      
      dif0 <= threshold-signal_in; 
      dif1 <= pipe(1)-threshold;
      
      pos_xing_next <= pos_int and not first_closest;
      neg_xing_next <= neg_int and first_closest;
      pos_closest <= (pos_int and first_closest) or pos_xing_next;
      neg_closest <= (neg_int and not first_closest) or neg_xing_next;
      pos_reg <= pos_int;
      neg_reg <= neg_int;
      pos <= pos_reg;
      neg <= neg_reg;
    end if;
	end if;
end process reg;
end architecture RTL;
