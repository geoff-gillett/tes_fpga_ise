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
--
library teslib;
use teslib.types.all;
-- Assumes FRAC >= AREA_FRAC
--TODO handle for AREA_FRAC > FRAC
entity signal_measurement is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3
);
port (
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  signal_out:out signed(WIDTH-1 downto 0);
  pos_xing:out boolean;
  neg_xing:out boolean;
  area:out signed(AREA_BITS-1 downto 0);
  extrema:out signed(WIDTH-1 downto 0);
  valid:out boolean
);
end entity signal_measurement;

architecture RTL of signal_measurement is
constant AREA_WIDTH:integer:=AREA_BITS+FRAC-AREA_FRAC;
signal area_int:signed(AREA_WIDTH-1 downto 0);
signal extrema_int:signed(WIDTH-1 downto 0);
signal above0,was_above0,below0,was_below0,xing:boolean;
signal pos_xing_int,neg_xing_int:boolean;

begin
	
above0 <= signal_in > 0;
below0 <= signal_in(WIDTH-1)='1';
neg_xing_int <= not above0 and was_above0;
pos_xing_int <= not below0 and was_below0;
xing <= neg_xing_int or pos_xing_int;

measurement:process (clk) is
begin
if rising_edge(clk) then
  if reset = '1' then
    was_above0 <= FALSE;
    was_below0 <= FALSE;
    area_int <= (others => '0');
    extrema_int <= (others => '0');
  else
  	was_above0 <= above0;
  	was_below0 <= below0;
  	valid <= xing;
  	pos_xing <= pos_xing_int;
  	neg_xing <= neg_xing_int;
		signal_out <= signal_in;

  	if xing then
  		area_int <= resize(signal_in,AREA_WIDTH);
  		area <= resize(shift_right(area_int,FRAC-AREA_FRAC),AREA_BITS);
  		extrema_int <= signal_in;
  		extrema <= extrema_int;
  	else
  		area_int <= area_int+signal_in;
  		if above0 then
  			if signal_in > extrema_int then
  				extrema_int <= signal_in;
  			end if;
  		else
  			if signal_in < extrema_int then
  				extrema_int <= signal_in;
  			end if;
  		end if;
  	end if;
  end if;
end if;
end process measurement;

end architecture RTL;
