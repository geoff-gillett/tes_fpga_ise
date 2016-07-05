--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: channel
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dsptypes is

constant DSP_BITS:integer:=18;
constant DSP_FRAC:integer:=3;
--constant SLOPE_FRAC:integer:=8;
constant CFD_BITS:integer:=18;
constant CFD_FRAC:integer:=17;

-- DSP coefficient reload
constant COEF_BITS:integer:=25;
constant COEF_WIDTH:integer:=32;
constant CONFIG_BITS:integer:=8;
constant CONFIG_WIDTH:integer:=8;

type config_array is array (natural range <>) of 
	std_logic_vector(CONFIG_WIDTH-1 downto 0);
type coef_array is array (natural range <>) of 
	std_logic_vector(COEF_WIDTH-1 downto 0);

end package dsptypes;

package body dsptypes is
	
end package body dsptypes;
