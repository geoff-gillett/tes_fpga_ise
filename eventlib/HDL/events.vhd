library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;
--use work.functions.all; 

package events is

constant MAX_CHANNEL_BITS:integer:=4;
constant MAX_PEAK_COUNT_BITS:integer:=4;
constant TICK_BIT:integer:=31;

type height_t is (PEAK_HEIGHT,CFD_HEIGHT,SLOPE_INTEGRAL);

constant NUM_HEIGHT_TYPES:integer:=height_t'pos(height_t'high)+1;
constant HEIGHT_TYPE_BITS:integer:=ceilLog2(NUM_HEIGHT_TYPES);


type headerflags is record
	tick:boolean; -- always FALSE for event; 
	trace:boolean; -- false for event
	fixed:boolean; -- fixed length event
	reserved:boolean;
end record;

type eventheader is record
  size:unsigned(SIZE_BITS-1 downto 0);
  timestamp:unsigned(TIME_BITS-1 downto 0);
  flags:headerflags;
end record;

type eventflags is record
	rel_to_min:boolean;
	peak_overflow:boolean;
	height_type:height_t; -- 2 bits
	peak_count:unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
	channel:unsigned(MAX_CHANNEL_BITS-1 downto 0);
end record;

type peakevent is record -- entire peak only event
	header:eventheader;
  flags:eventflags;
  height:signal_t;
end record;

type tickflags is record
	tick_lost:boolean;
	overflow:boolean_vector(15 downto 0);
end record;

type tickevent is record
	header:eventheader;
  flags:tickflags;
  full_timestamp:unsigned(TIMESTAMP_BITS-1 downto 0);
end record;

--function to_std_logic(e:eventheader) return std_logic_vector;
function to_std_logic(f:eventflags) return std_logic_vector;
function to_std_logic(f:tickflags) return std_logic_vector;
	
function to_streambus(t:tickevent) return streambus_array;
function to_streambus(e:peakevent) return streambus_t;	
function to_unsigned(h:height_t;w:integer) return unsigned;
function to_std_logic(h:height_t;w:integer) return std_logic_vector;
	
function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
return height_t;

function to_height_type(s:unsigned(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
return height_t;

end package events;

package body events is

-- 12 bits
function to_std_logic(f:eventflags) return std_logic_vector is 
begin
	return to_std_logic(f.rel_to_min) &
				 to_std_logic(f.peak_overflow) &
				 to_std_logic(f.height_type,2) & --2 bits
				 to_std_logic(f.peak_count) & --4 bits
				 to_std_logic(f.channel); --4 bits
end function;

function to_std_logic(f:tickflags) return std_logic_vector is 
begin
	return to_std_logic(0,11) & --reserved
				 to_std_logic(f.tick_lost) &
				 to_std_logic(f.overflow); -- 16 bits
end function;

function to_streambus(t:tickevent) return	streambus_array is
variable sba:streambus_array(1 downto 0);
begin
	sba(0).data := to_std_logic(8,SIZE_BITS) & --size always 8 chunks 16 bytes
							 	 to_std_logic(t.header.timestamp) & 
								 '1' & -- tick flag
					  		 '0' & -- trace flag
								 '1' & -- fixed flag
								 '0' & -- reserved
								 to_std_logic(t.flags.tick_lost) &
								 to_std_logic(0,11) & 
								 to_std_logic(t.flags.overflow); --16 bits reserved
	sba(0).keep_n := (others => FALSE);
	sba(0).last := (others => FALSE);
	sba(1).data := to_std_logic(t.full_timestamp);
	sba(1).keep_n := (others => FALSE);
	sba(1).last := (0 => TRUE, others => FALSE);					
	return sba;
end function;

function to_streambus(e:peakevent) return	streambus_t is
variable sba:streambus_t;
begin
	sba.data := to_std_logic(4,SIZE_BITS) & --size always 4 chunks 8 bytes
							to_std_logic(e.header.timestamp) & 
							'0' & -- tick flag
					  	'0' & -- trace flag
							'1' & -- fixed flag
							'0' & -- reserved
							to_std_logic(e.flags) &
							to_std_logic(e.height); 
	sba.keep_n := (others => FALSE);
	sba.last := (0 => TRUE, others => FALSE);
	return sba;
end function;

function to_height_type(s:unsigned(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
return height_t is
variable i:integer range 0 to NUM_HEIGHT_TYPES;
begin
	i:=to_integer(s);
	return to_height_type(i);
end function;

function to_unsigned(h:height_t;w:integer) return unsigned is
begin
	return to_unsigned(height_t'pos(h),w);
end function;

function to_std_logic(h:height_t;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(h,w));
end function;

function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
return height_t is
begin
	return height_t'val(i);
end function;

end package body events;
