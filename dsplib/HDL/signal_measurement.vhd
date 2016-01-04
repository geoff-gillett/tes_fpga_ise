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
--TODO add closest xings
entity signal_measurement is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3
);
port (
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  signal_out:out signed(WIDTH-1 downto 0);
  pos_xing:out boolean;
  neg_xing:out boolean;
  pos_0xing:out boolean;
  neg_0xing:out boolean; 
  --closest sample to 0 positive going
  pos_0closest:out boolean;
  --closest sample to 0 negative going
  neg_0closest:out boolean;
  area:out signed(AREA_BITS-1 downto 0);
  extrema:out signed(WIDTH-1 downto 0);
  valid:out boolean
);
end entity signal_measurement;

architecture RTL of signal_measurement is
constant AREA_WIDTH:integer:=AREA_BITS+FRAC-AREA_FRAC;
signal area_int:signed(AREA_WIDTH-1 downto 0);
signal extrema_int:signed(WIDTH-1 downto 0);
signal above0,was_above0,below0,was_below0,xing0:boolean;
signal pos0,neg0,pos_reg,neg_reg:boolean;
signal diff,diff_reg:signed(WIDTH-1 downto 0);
signal signal_reg,signal_reg2:signed(WIDTH-1 downto 0);
signal first_closest:boolean;
signal pos_xing_next:boolean;
signal neg_xing_next:boolean;
signal above,was_above:boolean;

begin
	
above0 <= signal_reg > 0;
below0 <= signal_reg(WIDTH-1)='1';
above <= signal_reg2 > threshold;

neg0 <= not above0 and was_above0;
pos0 <= not below0 and was_below0;
xing0 <= neg0 or pos0;

first_closest <= diff_reg < diff;

measurement:process (clk) is
begin
if rising_edge(clk) then
  if reset = '1' then
    was_above0 <= FALSE;
    was_below0 <= FALSE;
    area_int <= (others => '0');
    extrema_int <= (others => '0');
    was_above <= FALSE;
  else
    was_above <= above;
  	was_above0 <= above0;
  	was_below0 <= below0;
  	valid <= xing0;
		pos_reg <= pos0;
		neg_reg <= neg0;
  	pos_0xing <= pos_reg;
  	neg_0xing <= neg_reg;
  	pos_xing <= not was_above and above;
  	neg_xing <= not above and was_above;
  	
    signal_reg <= signal_in;
    signal_reg2 <= signal_reg;
		signal_out <= signal_reg2;
		
    diff <= abs(signal_in);
    diff_reg <= diff;
    
    pos_xing_next <= pos0 and not first_closest;
    neg_xing_next <= neg0 and not first_closest;

    pos_0closest <= (pos0 and first_closest) or pos_xing_next;
    neg_0closest <= (neg0 and first_closest) or neg_xing_next;
    
  	if xing0 then
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
