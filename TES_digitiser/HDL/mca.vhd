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


package mca is

constant VALUE_BITS:integer:=32;
subtype mca_value_t is signed(VALUE_BITS-1 downto 0);
type mca_value_array is array (natural range <>) of mca_value_t;

type distribution_t is (FILTERED, -- the output of the dsp filter
												FILTERED_AREA, -- the area between zero crossings
												FILTERED_EXTREMA, -- max or min between zero crossings
												SLOPE, -- the output of the dsp differentiator
												SLOPE_AREA,
												SLOPE_EXTREMA,
												PULSE_AREA, -- the area between threshold crossings
												PULSE_EXTREMA, -- the maximum between threshold xings
												
												--PEAK, -- the filtered signal a neg slope 0 xing
												HEIGHT, -- the height of the peak relative to start
												PEAK_COUNT, -- number of peaks in the pulse
												JITTER -- time difference between channels
											 );
	

type filtered_trigger_t is (ALWAYS,
														SLOPE_XING,
														CFD_HIGH,
														CFD_LOW,
														PEAK,
														PEAK_START
);

end package mca;

package body mca is
	
end package body mca;
