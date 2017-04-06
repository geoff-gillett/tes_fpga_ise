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

--latency = 2
entity crossing2 is
generic(
	WIDTH:integer:=18;
	STRICT:boolean:=FALSE
);
port(
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  
  signal_out:out signed(WIDTH-1 downto 0);
  pos:out boolean;
  neg:out boolean
);
end entity crossing2;

architecture RTL of crossing2 is

constant DEPTH:integer:=2;	
type pipe_t is array (natural range <>) of signed(WIDTH-1 downto 0);
signal pipe:pipe_t(1 to DEPTH):=(others => (others => '0'));

signal below,above,was_below,was_above,notequal:boolean;
signal was_notequal:boolean;

begin
signal_out <= pipe(DEPTH);


reg:process (clk) is
begin
	if rising_edge(clk) then
	  if reset='1' then
	    pipe <= (others => (others => '0'));
	  else
	    pipe <= signal_in & pipe(1 to DEPTH-1);
	    
      below <= signal_in < threshold;
      above <= signal_in > threshold;
      notequal <= signal_in /= threshold;
      was_notequal  <= notequal;
      
      if STRICT then
        -- must strictly cross 
        if notequal then -- does not change if equal
          was_below <= below;
          was_above <= above;
        end if;
      else 
        -- equal generates crossing
        if not notequal then --equal to crossing  
          if was_notequal then
            was_below <= not was_below;
            was_above <= not was_above;
          end if;
        else
          was_below <= below;
          was_above <= above;
        end if;
      end if;

      if STRICT then
        pos <= was_below and above;
        neg <= was_above and below;
      else
        --FIXME problem with multiple equals in a row
        pos <= was_below and not below;
        neg <= was_above and not above;
      end if;
      
    end if;
	end if;
end process reg;
end architecture RTL;
