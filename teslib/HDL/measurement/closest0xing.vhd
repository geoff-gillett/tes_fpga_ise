--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:28 Dec 2015
--
-- Design Name: TES_digitiser
-- Module Name: signal_measurement
-- Project Name: dsplib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.logic.all;

use work.types.all;

entity closest0xing is
generic(
	WIDTH:integer:=18
);
port (
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  signal_out:out signed(WIDTH-1 downto 0);
  pos_xing:out boolean;
  neg_xing:out boolean
);
end entity closest0xing;

architecture RTL of closest0xing is
--FIXME add saturation check on area remove shifts and do them outside
signal above0,was_above0,below0,was_below0:boolean;
signal pos0,neg0:boolean;
signal diff,diff_reg:signed(WIDTH-1 downto 0):=(others => '0');
signal signal_reg,signal_reg2,signal_reg3:signed(WIDTH-1 downto 0)
       :=(others => '0');
signal first_closest,pos_xing_next,neg_xing_next:boolean;

begin
signal_out <= signal_reg3;

above0 <= signal_reg > 0;
below0 <= signal_reg(WIDTH-1)='1';

neg0 <= not above0 and was_above0;
pos0 <= not below0 and was_below0;

first_closest <= diff_reg < diff;

measurement:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    was_above0 <= FALSE;
    was_below0 <= FALSE;
  else
  	was_above0 <= above0;
  	was_below0 <= below0;
  	
    signal_reg <= signal_in;
    signal_reg2 <= signal_reg;
		signal_reg3 <= signal_reg2;
		
    diff <= abs(signal_in);
    diff_reg <= diff;
    
    pos_xing_next <= pos0 and not first_closest;
    neg_xing_next <= neg0 and not first_closest;

    pos_xing <= (pos0 and first_closest) or pos_xing_next;
    neg_xing <= (neg0 and first_closest) or neg_xing_next;
    
  end if;
end if;
end process measurement;

end architecture RTL;
