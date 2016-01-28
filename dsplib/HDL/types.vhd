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

package types is

constant DSP_BITS:integer:=18;
constant DSP_FRAC:integer:=3;
--constant SLOPE_FRAC:integer:=8;
constant CFD_BITS:integer:=18;
constant CFD_FRAC:integer:=17;

-- problem is has in and out
--type dsp_AXI_channels_t is record
--	config_data:std_logic_vector(7 downto 0);
--	config_valid:boolean;
--	config_ready:boolean;
--end record;

end package types;

package body types is
	
end package body types;
