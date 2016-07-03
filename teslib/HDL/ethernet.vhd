--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:6 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: ethernet package
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;

use work.events.all;

package ethernet is

constant ETHERNET_HEADER_WORDS:integer:=3;
constant MIN_FRAME:integer:=8;
constant SEQUENCE_BITS:integer:=16;
type ethernet_header_t is record
	destination_address:unsigned(47 downto 0);
	source_address:unsigned(47 downto 0);
	ethernet_type:unsigned(15 downto 0);
	frame_sequence:unsigned(SEQUENCE_BITS-1 downto 0);
	length:unsigned(15 downto 0);
	protocol_sequence:unsigned(SEQUENCE_BITS-1 downto 0);
	frame_type:event_type_t;
end record;

signal header:ethernet_header_t;
signal mca_sequence,event_sequence:unsigned(SEQUENCE_BITS-1 downto 0);
signal trace_sequence:unsigned(SEQUENCE_BITS-1 downto 0);
	
function to_std_logic(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1;
											endianness:string)
 											return std_logic_vector; 
 											
function to_streambus(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1;
											endianness:string)
 											return streambus_t;
end package ethernet;

package body ethernet is

function to_std_logic(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1;
											endianness:string)
 											return std_logic_vector is 
variable slv:std_logic_vector(BUS_DATABITS-1 downto 0);
begin
	case w is
	when 0 => 
    slv := to_std_logic(e.destination_address) &
           to_std_logic(e.source_address(47 downto 32));
	when 1 =>
		slv := to_std_logic(e.source_address(31 downto 0)) &
					 to_std_logic(e.ethernet_type) &
           to_std_logic(0,16);
					 --set_endianness(e.length, endianness);
	when 2 => 
    slv := set_endianness(e.frame_sequence,endianness) &
           set_endianness(e.protocol_sequence,endianness) &
           "0000" & to_std_logic(e.frame_type) & '0' &
           to_std_logic(0,24);
	when others => 
		assert FALSE report "bad word number in ethernet_header to_streambus()"	
						 severity ERROR;
	end case;
	return slv;
end function;

function to_streambus(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1;
											endianness:string)
 											return streambus_t is 
variable sb:streambus_t;
begin
	sb.discard := (others => FALSE); 
	sb.last := (others => FALSE);
  sb.data := to_std_logic(e,w,endianness);
	return sb;
end function;
end package body ethernet;
