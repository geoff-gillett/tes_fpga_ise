--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:10 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: priority1of8_select
-- Project Name:teslib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library unisim;
use unisim.vcomponents.LUT6;
use unisim.vcomponents.MUXCY;
--
-- 1 bit of 12 data selector (MUX)
-- Uses the CARRY4 block in a slice, the techniques are described in XAPP522.
-- TODO XAPP522 suggests that priority encoding can be incorporated by changing
-- the LUT equation, Currently can't see how that would work.
-- 0x5533550f553355ff would priority select at each LUT but the the carry chain
-- would mess things up when there is a hot bit in two different LUTS.
--
entity select_1of12 is
port(
	input:std_logic_vector(11 downto 0);
	-- sel is one hot
	sel:in std_logic_vector(11 downto 0);
	output:out std_logic
);
end entity select_1of12;

architecture low_level_structure of select_1of12 is
signal  muxcy_sel:std_logic_vector(3 downto 0);
signal  muxcy_carry:std_logic_vector(2 downto 0);
	
begin

selection0_lut:LUT6
generic map (INIT => X"0000000F003355FF")
port map(
	I0 => input(0),
  I1 => input(1),
  I2 => input(2),
  I3 => sel(0),
  I4 => sel(1),
  I5 => sel(2),
  O => muxcy_sel(0)
);                     

combiner0_muxcy:MUXCY
port map( 
	DI => '1',
  CI => '0',
  S => muxcy_sel(0),
  O => muxcy_carry(0)
);

selection1_lut:LUT6
generic map (INIT => X"0000000F003355FF")
port map( 
	I0 => input(3),
  I1 => input(4),
  I2 => input(5),
  I3 => sel(3),
  I4 => sel(4),
  I5 => sel(5),
  O => muxcy_sel(1)
);                     

combiner1_muxcy:MUXCY
port map( 
	DI => '1',
  CI => muxcy_carry(0),
  S => muxcy_sel(1),
  O => muxcy_carry(1)
);


selection2_lut:LUT6
generic map (INIT => X"0000000F003355FF")
port map( 
	I0 => input(6),
  I1 => input(7),
  I2 => input(8),
  I3 => sel(6),
  I4 => sel(7),
  I5 => sel(8),
  O => muxcy_sel(2)
);                     

combiner2_muxcy:MUXCY
port map(
	DI => '1',
  CI => muxcy_carry(1),
  S => muxcy_sel(2),
  O => muxcy_carry(2)
);

selection3_lut: LUT6
generic map (INIT => X"0000000F003355FF")
port map( 
	I0 => input(9),
  I1 => input(10),
  I2 => input(11),
  I3 => sel(9),
  I4 => sel(10),
  I5 => sel(11),
  O => muxcy_sel(3)  
);                     

combiner3_muxcy:MUXCY
port map(
	DI => '1',
  CI => muxcy_carry(2),
  S => muxcy_sel(3),
  O => output
);

end architecture low_level_structure;
