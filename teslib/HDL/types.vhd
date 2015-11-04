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
--not used in AXIlite
constant AXI_EXOKAY:std_logic_vector(1 downto 0):="01"; 
--------------------------------------------------------------------------------
-- TES design constants and types
--------------------------------------------------------------------------------
-- bits in a native ADC sample
constant ADC_BITS:integer:=14;
-- There are 2**CHANNEL_BITS channels
constant CHANNEL_BITS:integer:=3; 
-- Bits in a full full time-stamp (Tick event)
constant TIMESTAMP_BITS:integer:=64; 
-- Bits in a relative ADC sample (sample_t)
constant SAMPLE_BITS:integer:=ADC_BITS+1;
-- Bits in the size field of an event
constant SIZE_BITS:integer:=16; 
-- Bits in a relative time
constant TIME_BITS:integer:=16; --CHUNK_DATA_BITS;
-- Bits in an area measurement
constant AREA_BITS:integer:=32;
--
constant AXI_DATA_BITS:integer:=32;
constant AXI_ADDRESS_BITS:integer:=32;
constant REGISTER_ADDRESS_BITS:integer:=24;
constant REGISTER_DATA_BITS:integer:=32;
--
-- relative sample
subtype sample_t is signed(SAMPLE_BITS-1 downto 0);
-- relative sample array
type sample_array is array (natural range <>) of sample_t;
-- type representing areas
subtype area_t is signed(AREA_BITS-1 downto 0);
-- array of areas
type area_array is array (natural range <>) of area_t;
-- type representing a relative time
subtype time_t is unsigned(TIME_BITS-1 downto 0);
-- array of relative times
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
end package types;
package body types is  
end package body types;