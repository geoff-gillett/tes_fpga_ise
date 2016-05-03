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

-- Assumes FRAC >= AREA_FRAC
--TODO handle for AREA_FRAC > FRAC
--TODO add closest xings

entity signal_measurement is
generic(
	WIDTH:integer:=18;
	--FRAC:integer:=3;
	AREA_BITS:integer:=18+16
);
port (
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  signal_out:out signed(WIDTH-1 downto 0);
  --TODO add closest for these
  pos_threshxing:out boolean;
  neg_threshxing:out boolean;
  pos_0xing:out boolean;
  neg_0xing:out boolean; 
  --closest sample to 0 positive going
  pos_0closest:out boolean;
  --closest sample to 0 negative going
  neg_0closest:out boolean;
  area:out signed(AREA_BITS-1 downto 0);
  extrema:out signed(WIDTH-1 downto 0);
  -- area and extrema both valid  
  zero_xing:out boolean
);
end entity signal_measurement;

architecture RTL of signal_measurement is
--FIXME add saturation check on area remove shifts and do them outside
signal area_int:signed(AREA_BITS-1 downto 0);
signal extrema_int:signed(WIDTH-1 downto 0);
signal above0,was_above0,below0,was_below0,xing0_reg:boolean;
signal pos0,neg0,pos_reg,neg_reg:boolean;
signal diff,diff_reg:signed(WIDTH-1 downto 0);
signal signal_reg,signal_reg2:signed(WIDTH-1 downto 0);
signal first_closest:boolean;
signal pos_xing_next:boolean;
signal neg_xing_next:boolean;
signal above,was_above:boolean;
signal xing0:boolean;

--constant PIPELINE_DEPTH:integer:=3;
--type pipeline is array (natural range <>) of signed(WIDTH-1 downto 0);
--signal pipe:pipeline(1 to PIPELINE_DEPTH);

begin
--area <= area_int;
	
above0 <= signal_reg > 0;
below0 <= signal_reg(WIDTH-1)='1';
above <= signal_reg2 > threshold;

neg0 <= not above0 and was_above0;
pos0 <= not below0 and was_below0;
xing0_reg <= neg_reg or pos_reg;
xing0 <= neg0 or pos0;

first_closest <= diff_reg < diff;

--FIXME could remove some register levels
measurement:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    was_above0 <= FALSE;
    was_below0 <= FALSE;
    area_int <= (others => '0');
    extrema_int <= (others => '0');
    was_above <= FALSE;
  else
  	
--  	pipe(1) <= signal_in;
--  	pipe(2 to PIPELINE_DEPTH) <= pipe(1 to PIPELINE_DEPTH-1);
  	
    was_above <= above;
  	was_above0 <= above0;
  	was_below0 <= below0;
  	zero_xing <= xing0_reg;
		pos_reg <= pos0;
		neg_reg <= neg0;
  	pos_0xing <= pos_reg;
  	neg_0xing <= neg_reg;
  	pos_threshxing <= not was_above and above;
  	neg_threshxing <= not above and was_above;
  	
    signal_reg <= to_0ifX(signal_in);
    signal_reg2 <= signal_reg;
		signal_out <= signal_reg2;
		
    diff <= abs(signal_in);
    diff_reg <= diff;
    
    pos_xing_next <= pos0 and not first_closest;
    neg_xing_next <= neg0 and not first_closest;

    pos_0closest <= (pos0 and first_closest) or pos_xing_next;
    neg_0closest <= (neg0 and first_closest) or neg_xing_next;
    
 		area <= area_int;
  	if xing0_reg then
  		area_int <= resize(signal_reg2,AREA_BITS);
  	else
  		area_int <= area_int + signal_reg2;
  	end if;
  	
 		extrema <= extrema_int;
  	if xing0_reg then
  		extrema_int <= signal_reg2;
  	else
  		if was_above0 then
  			if signal_reg2 > extrema_int then
  				extrema_int <= signal_reg2;
  			end if;
  		elsif was_below0 then
  			if signal_reg2 < extrema_int then
  				extrema_int <= signal_reg2;
  			end if;
  		end if;
  	end if;
  end if;
end if;
end process measurement;

end architecture RTL;
