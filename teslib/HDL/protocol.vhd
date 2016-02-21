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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.types.all;
use work.functions.all;
use work.registers.all;

package protocol is
--subtype mca_value_t is signed(MCA_VALUE_BITS-1 downto 0);
constant ENDIANESS:string:="LITTLE";

--------------------------------------------------------------------------------
-- Ethernet protocol
--------------------------------------------------------------------------------
type ethernet_header_t is record
	destination_address:unsigned(47 downto 0);
	source_address:unsigned(47 downto 0);
	ethernet_type:unsigned(15 downto 0);
	frame_sequence:unsigned(15 downto 0);
	length:unsigned(15 downto 0);
	protocol_sequence:unsigned(15 downto 0);
end record;

constant ETHERNET_HEADER_WORDS:integer:=3;
constant ETHERNET_SEQUENCE_BITS:integer:=32;

function to_streambus(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1)
											return streambus_t;

function to_std_logic(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1)
											return std_logic_vector;
--------------------------------------------------------------------------------
-- MCA protocol
--------------------------------------------------------------------------------
constant MCA_PROTOCOL_HEADER_WORDS:integer:=5;
constant MCA_PROTOCOL_HEADER_CHUNKS:integer
				 :=MCA_PROTOCOL_HEADER_WORDS*BUS_CHUNKS;
				 
type mca_flags_t is record  -- 32 bits
	value:unsigned(7 downto 0);
	trigger:unsigned(7 downto 0);
	bin_n:unsigned(7 downto 0);
	channel:unsigned(7 downto 0);
end record;

type mca_header_registers is record
	size:unsigned(CHUNK_DATABITS-1 downto 0);
	last_bin:unsigned(CHUNK_DATABITS-1 downto 0);
	flags:mca_flags_t;
	lowest_value:signed(2*CHUNK_DATABITS-1 downto 0);
end record;

type mca_header_measurements is record
	most_frequent:unsigned(CHUNK_DATABITS-1 downto 0);
	-- word 3
	total:unsigned(MCA_TOTAL_BITS-1 downto 0);
	-- word 4
	start_time:unsigned(4*CHUNK_DATABITS-1 downto 0);
	-- word 5
	stop_time:unsigned(4*CHUNK_DATABITS-1 downto 0);
end record;
				 
function to_std_logic(f:mca_flags_t) return std_logic_vector;

function to_mca_header_registers(r:mca_registers_t;size:unsigned) 
				 return mca_header_registers;

function to_streambus(r:mca_header_registers;m:mca_header_measurements;
										  word:natural range 0 to MCA_PROTOCOL_HEADER_WORDS-1)
											return streambus_t;
end package protocol;

package body protocol is

--------------------------------------------------------------------------------
-- Ethernet protocol
--------------------------------------------------------------------------------
--FIXME is a streambus_array a better option? c.f. tick_event
function to_streambus(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1)
 											return streambus_t is 
variable sb:streambus_t;
begin
	sb.keep_n := (others => FALSE); 
	sb.last := (others => FALSE);
	case w is
	when 0 => 
    sb.data := to_std_logic(e.source_address) &
               to_std_logic(e.destination_address(47 downto 32));
	when 1 =>
		sb.data := to_std_logic(e.destination_address(31 downto 0)) &
							 to_std_logic(e.ethernet_type) &
							 to_std_logic(e.length);
	when 2 => 
		sb.data := to_std_logic(0,16) &
							 to_std_logic(e.frame_sequence) &
							 to_std_logic(0,16) &
							 to_std_logic(e.protocol_sequence);
	when others => 
		assert FALSE report "bad word number in ethernet_header to_streambus()"	
						 severity ERROR;
	end case;
	return sb;
end function;

function to_std_logic(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1)
 											return std_logic_vector is 
variable slv:std_logic_vector(BUS_DATABITS-1 downto 0);
begin
	case w is
	when 0 => 
    slv := to_std_logic(e.source_address) &
           to_std_logic(e.destination_address(47 downto 32));
	when 1 =>
		slv := to_std_logic(e.destination_address(31 downto 0)) &
					 to_std_logic(e.ethernet_type) &
					 to_std_logic(e.length);
	when 2 => 
		slv := to_std_logic(0,16) &
					 to_std_logic(e.frame_sequence) &
					 to_std_logic(0,16) &
					 to_std_logic(e.protocol_sequence);
	when others => 
		assert FALSE report "bad word number in ethernet_header to_streambus()"	
						 severity ERROR;
	end case;
	return slv;
end function;
--------------------------------------------------------------------------------
-- MCA protocol functions
--------------------------------------------------------------------------------
function to_std_logic(f:mca_flags_t) return std_logic_vector is
begin
	return to_std_logic(f.value) &
				 to_std_logic(f.trigger) &
				 to_std_logic(f.bin_n) &
				 to_std_logic(f.channel);
end function;

-- NOTE this infers some logic should be used in a sequential process
function to_mca_header_registers(r:mca_registers_t;size:unsigned) 
				 return mca_header_registers is
variable h:mca_header_registers;
begin
	h.size := resize(size,CHUNK_DATABITS);
	h.last_bin := resize(r.last_bin,CHUNK_DATABITS);
	h.flags.value := to_unsigned(r.value,8);  
	h.flags.trigger := to_unsigned(r.trigger,8);  
	h.flags.bin_n := resize(r.bin_n,8);  
	h.flags.channel := resize(r.channel,8);  
	h.lowest_value := resize(r.lowest_value,2*CHUNK_DATABITS);
	return h;
end function;

-- w should be a constant as logic is infered
function to_streambus(r:mca_header_registers;m:mca_header_measurements;
										  word:natural range 0 to MCA_PROTOCOL_HEADER_WORDS-1)
											return streambus_t is
variable sb:streambus_t;
begin
	sb.keep_n := (others => FALSE);
	sb.last := (others => FALSE);
	case word is
	when 0 =>
		sb.data:= to_std_logic(r.size) &
  						to_std_logic(r.last_bin) &
  						to_std_logic(r.flags);
  when 1 =>
  	sb.data := to_std_logic(r.lowest_value) &
  						 to_std_logic(0,16) &
  						 to_std_logic(m.most_frequent);
  when 2 =>
  	sb.data := to_std_logic(m.total);
  when 3 => 
  	sb.data := to_std_logic(m.start_time);
  when 4 => 
  	sb.data := to_std_logic(m.stop_time);
  when others =>
  	null;
	end case;
	return sb;
end function;

end package body protocol;
