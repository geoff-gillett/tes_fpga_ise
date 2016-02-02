--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: global
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;

--use work.mca.mca_registers;

package global is

constant CHANNEL_BITS:integer:=3;
constant CHANNELS:integer:=2**CHANNEL_BITS;
constant TICK_BITS:integer:=32;
constant TICK_COUNT_BITS:integer:=16;

-- DEFAULTS
constant DEFAULT_TICK_PERIOD:integer:=25000000;


end package global;

package body global is


end package body global;
