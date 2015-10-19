--------------------------------------------------------------------------------
--    Engineer: Geoff Gillett
--     Project: TES_library 
--      design: TES_digitiser
--        File: types.vhd
-- Description: Part of TES library, defines types constants and functions.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
--
package types is
--------------------------------------------------------------------------------
-- AXI 
--------------------------------------------------------------------------------
-- AXI no error
constant AXI_OKAY:std_logic_vector(1 downto 0):="00";
-- AXI address decode error--Invalid address
constant AXI_DECERR:std_logic_vector(1 downto 0):="11";
-- AXI Slave error--Slave generated error while processing request
constant AXI_SLVERR:std_logic_vector(1 downto 0):="10";
constant AXI_EXOKAY:std_logic_vector(1 downto 0):="01"; --not used in AXIlite
--------------------------------------------------------------------------------
-- TES design constants and types
--------------------------------------------------------------------------------
--constant CHANNEL_BITS:integer:=3; -- 2**CHANNEL_BITS channels
constant GLOBALTIME_BITS:integer:=64; 
-- Bits in the event time-stamp NOTE the MSB is used to indicate a roll-over 
-- since the previous time-stamp 
--FIXME: rearrange libraries fix REL_SAMPLE_BITS
constant REL_SAMPLE_BITS:integer:=15; --ADC_BITS+1; -- sample relative to baseline 
constant TIME_BITS:integer:=14; -- size field (MSBs of bus)    
constant SIZE_BITS:integer:=5; -- Number of bits in a peak time-stamp
constant REL_TIME_BITS:integer:=14; --CHUNK_DATA_BITS;
-- pulse area big enough that it can't overflow
constant AREA_BITS:integer:=26;
--sum field bits actually put on the bus
constant AXI_DATA_BITS:integer:=32;
constant AXI_ADDRESS_BITS:integer:=32;
constant REGISTER_ADDRESS_BITS:integer:=24;
constant REGISTER_DATA_BITS:integer:=32;
--
subtype rel_sample_t is signed(REL_SAMPLE_BITS-1 downto 0);
type rel_sample_array is array (natural range <>) of rel_sample_t;
subtype pulse_area_t is unsigned(AREA_BITS-1 downto 0);
type pulse_area_array is array (natural range <>) of pulse_area_t;
subtype sample_area_t is signed(AREA_BITS downto 0);
type sample_area_array is array (natural range <>) of sample_area_t;
subtype time_t is unsigned(TIME_BITS-1 downto 0);
type time_array is array (natural range <>) of time_t;
-- useful types
subtype AXI_data is std_logic_vector(AXI_DATA_BITS-1 downto 0);
type AXI_data_array is array (natural range <>) of AXI_data;
subtype AXI_address is std_logic_vector(AXI_ADDRESS_BITS-1 downto 0);
type AXI_address_array is array (natural range <>) of AXI_address;
subtype registerdata is std_logic_vector(REGISTER_DATA_BITS-1 downto 0);
type registerdata_array is array (natural range <>) of registerdata;
subtype registeraddress is std_logic_vector(REGISTER_ADDRESS_BITS-1 downto 0);
type registeraddress_array is array (natural range <>) of registeraddress;
type boolean_vector is array (natural range <>) of boolean;
end;-- package definition ------------------------------------------------------
package body types is  
end;-- package body-------------------------------------------------------------