library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

use work.stream.all;
--use work.functions.all; 

package events is

constant MAX_CHANNEL_BITS:integer:=4;
constant MAX_PEAK_COUNT_BITS:integer:=4;

type heighttype is (PEAK_HEIGHT,CFD_HEIGHT,SLOPE_INTEGRAL);
constant NUM_HEIGHT_FORMS:integer:=3;

type eventflags is record
	tick:boolean; -- always FALSE for event;
	trace:boolean; -- false for event
	fixed:boolean; -- fixed length event
	height_type:heighttype;
	rel_to_min:boolean;
	peak_overflow:boolean;
	channel:unsigned(MAX_CHANNEL_BITS-1 downto 0);
	not_first:boolean;
	peak_count:unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
end record;

type eventheader is record -- entire peak only event
  size:unsigned(SIZE_BITS-1 downto 0);
  timestamp:unsigned(TIME_BITS-1 downto 0);
  flags:eventflags;
  height:signal_t;
end record;

type tickflags is record
	tick:boolean; -- always TRUE;
	trace:boolean; -- always FALSE;
	tick_lost:boolean;
	overflow:boolean_vector(15 downto 0);
end record;

type tickevent is record
  size:unsigned(SIZE_BITS-1 downto 0);
  timestamp:unsigned(TIME_BITS-1 downto 0);
  flags:tickflags;
  full_timestamp:unsigned(TIMESTAMP_BITS-1 downto 0);
end record;

function to_std_logic(e:eventheader) return std_logic_vector;
function to_std_logic(f:eventflags) return std_logic_vector;
function to_std_logic(h:heighttype) return std_logic_vector;
function to_std_logic(t:tickflags) return std_logic_vector;
function to_streambus(t:tickevent) return streambus_array;
function to_streambus(e:eventheader) return streambus;
	
function to_height_form(i:natural range 0 to NUM_HEIGHT_FORMS-1) 
return heighttype;
function to_height_form(
	s:unsigned(ceilLog2(NUM_HEIGHT_FORMS)-1 downto 0)
) return heighttype;

end package events;

package body events is

function to_streambus(e:eventheader) return streambus is
variable sb:streambus;
begin
	sb.data:=to_std_logic(e);
	sb.keeps:=to_boolean(to_std_logic(2**BUS_CHUNKS-1,BUS_CHUNKS));
	sb.lasts:= to_boolean(to_std_logic(1,BUS_CHUNKS));					
	return sb;
end function;

function to_streambus(t:tickevent) return	streambus_array is
variable sba:streambus_array(1 downto 0);
begin
	sba(0).data:= to_std_logic(8,SIZE_BITS) & --size always 8 chunks 16
								to_std_logic(t.timestamp) & 
								'1' & -- tick flag
								'0' & -- trace flag
								to_std_logic(t.flags.tick_lost) &
								to_std_logic(0,13) & 
								to_std_logic(t.flags.overflow);
	sba(0).keeps:= to_boolean(to_std_logic(2**BUS_CHUNKS-1,BUS_CHUNKS));
	sba(0).lasts:= to_boolean(to_std_logic(0,BUS_CHUNKS));
	sba(1).data:= to_std_logic(t.full_timestamp);
	sba(1).keeps:= to_boolean(to_std_logic(2**BUS_CHUNKS-1,BUS_CHUNKS));
	sba(1).lasts:= to_boolean(to_std_logic(1,BUS_CHUNKS));					
	return sba;
end function;

function to_std_logic(t:tickflags) return std_logic_vector is
begin
	return to_std_logic(t.tick) &
				 to_std_logic(t.trace) &
				 to_std_logic(t.tick_lost) &
				 to_std_logic(0,13) &
				 to_std_logic(t.overflow);	
end function;

function to_height_form(
	s:unsigned(ceilLog2(NUM_HEIGHT_FORMS)-1 downto 0)
) return heighttype is
variable i:integer range 0 to NUM_HEIGHT_FORMS;
begin
	i:=to_integer(s);
	assert i < NUM_HEIGHT_FORMS report "bad height_form index" severity error;
	return to_height_form(i);
end function;

function to_std_logic(h:heighttype) return std_logic_vector is
begin
	return to_std_logic(heighttype'pos(h),2);
end function;

function to_height_form(i:natural range 0 to NUM_HEIGHT_FORMS-1) 
return heighttype is
begin
	return heighttype'val(i);
end function;

function to_std_logic(f:eventflags) return std_logic_vector is
begin
	return '0' & -- tick
				 to_std_logic(f.trace) & 
				 to_std_logic(f.rel_to_min) &
				 to_std_logic(f.peak_overflow) &
				 to_std_logic(f.not_first) &
				 '0' & -- reserved
				 to_std_logic(f.height_type) &
				 to_std_logic(f.peak_count) & 
				 to_std_logic(f.channel);
end function;

function to_std_logic(e:eventheader) 
return std_logic_vector is
begin
	return to_std_logic(e.size) &
				 to_std_logic(0,TIME_BITS) &
				 to_std_logic(e.flags) &
				 to_std_logic(e.height);
end function;
	
end package body events;
