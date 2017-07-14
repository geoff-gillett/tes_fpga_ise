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

--latency = 1
entity crossing20 is
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
  above:out boolean
);
end entity crossing20;

architecture RTL of crossing20 is


signal isbelow,isabove,above_int:boolean;

begin
above <= above_int;

reg:process (clk) is
begin
	if rising_edge(clk) then
	  if reset='1' then
	    above_int <= FALSE;
	  else
	    signal_out <= signal_in;
	    
      isbelow <= signal_in < threshold;
      isabove <= signal_in > threshold;
      
      if isabove then
        above_int <= TRUE;
      end if;
      if isbelow then
        above_int <= FALSE;
      end if;
      pos <= isabove and not above_int;
      neg <= isbelow and above_int;
    end if;
	end if;
end process reg;
end architecture RTL;
