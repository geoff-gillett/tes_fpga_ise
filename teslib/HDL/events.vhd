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

package events is

--------------------------------- NOTES ----------------------------------------
-- FPGA format is big endian 
-- rise is time from trigger to height valid

--------------------------------------------------------------------------------
--                            Constants
--------------------------------------------------------------------------------
constant CHANNEL_WIDTH:integer:=4;
constant PEAK_COUNT_WIDTH:integer:=4;
constant TICK_BIT:integer:=31; --FIXME remember to change this
constant RELATIVETIME_POS:integer:=16;
constant SIZE_POS:integer:=48; --LSB of size field
constant FLAGS_POS:integer:=11;

--------------------------------------------------------------------------------
--                            Discrete Types 
--------------------------------------------------------------------------------
type event_type_d is (
	PEAK_EVENT_D,
	AREA_EVENT_D,
	PULSE_EVENT_D, --use fixed flag to indicate fixed/variable length
	TRACE_EVENT_D);

constant NUM_EVENT_TYPES:integer:=event_type_d'pos(event_type_d'high)+1;
constant EVENT_TYPE_BITS:integer:=ceilLog2(NUM_EVENT_TYPES);

function to_unsigned(e:event_type_d;w:integer) return unsigned;
function to_std_logic(e:event_type_d;w:integer) return std_logic_vector;

type timing_trigger_d is (
	PULSE_THRESH_TRIGGER_D,
	SLOPE_THRESH_TRIGGER_D,
	CFD_LOW_TRIGGER_D);

constant NUM_TIMING_TRIGGER_TYPES:integer:=
																	timing_trigger_d'pos(timing_trigger_d'high)+1;
constant TIMING_TRIGGER_TYPE_BITS:integer:=ceilLog2(NUM_TIMING_TRIGGER_TYPES);
	
function to_unsigned(t:timing_trigger_d;w:integer) return unsigned;
function to_std_logic(t:timing_trigger_d;w:integer) return std_logic_vector;
	
type height_d is (PEAK_HEIGHT_D,
									CFD_HIGH_D,
									SLOPE_INTEGRAL_D);

constant NUM_HEIGHT_TYPES:integer:=height_d'pos(height_d'high)+1;
constant HEIGHT_TYPE_BITS:integer:=ceilLog2(NUM_HEIGHT_TYPES);

function to_unsigned(h:height_d;w:integer) return unsigned;
function to_std_logic(h:height_d;w:integer) return std_logic_vector;
function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
				 return height_d;
function to_height_type(s:unsigned(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
				 return height_d;

--------------------------------------------------------------------------------
--                            Event Types 
--------------------------------------------------------------------------------

------------------------- type flags 4 bits ------------------------------------
-- fixed|trace|area|tick
type eventtype_flags_t is record
	tick:boolean; -- always FALSE for event; 
	--area:boolean; -- area measurement -- FIXME not needed 
	--trace:boolean; -- false for event --FIXME not needed
	fixed:boolean; -- fixed length -- size not used otherwise size is used
end record;

function to_std_logic(f:eventtype_flags_t) return std_logic_vector;

----------------------- event flags - 16 bits-----------------------------------
--        1      |      1      |     2    |   4   |    4     |    4
--  peak_overflow|time_overflow|event_type|channel|peak_count|type_flags
type eventflags_t is record -- 16 bits
	peak_overflow:boolean; 
	time_overflow:boolean; 
	event_type:event_type_d;
	peak_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0); -- 3
	channel:unsigned(CHANNEL_WIDTH-1 downto 0); -- 3
	type_flags:eventtype_flags_t; -- 4
end record;

function to_std_logic(f:eventflags_t) return std_logic_vector;

--------------------------- tick flags 48 bits ---------------------------------
-- |  16    |  15    |   1    |   4    |   4
--  overflow|reserved|ticklost|reserved|type flags
type tickflags_t is record --32
	typeflags:eventtype_flags_t; -- 4
	tick_lost:boolean;
	-- 11 reserved
	overflow:boolean_vector(15 downto 0); -- 16
end record;

function to_std_logic(f:tickflags_t) return std_logic_vector;

---------------------------- peak event 8 bytes --------------------------------
--  | height | rise | event flags | time |
type peakevent_t is record -- entire peak only event
  height:signal_t; -- 16
  rise_time:unsigned(TIME_BITS-1 downto 0); -- 16
  flags:eventflags_t;  -- 16
  reltimestamp:unsigned(TIME_BITS-1 downto 0); -- 16
end record;

function to_streambus(e:peakevent_t) return streambus_t;	
	
---------------------------- area event 8 bytes --------------------------------
--  |     area      | event flags | time |
type areaevent_t is record
	area:area_t; -- 32
	flags:eventflags_t; -- 16
	reltimestamp:unsigned(TIME_BITS-1 downto 0); --16
end record;

function to_streambus(a:areaevent_t) return	streambus_t;
	
-------------------------- tick event 16 bytes----------------------------------
--  |         tick flags          | time |
--  |          full time-stamp           |
type tickevent_t is record
	--event_flags:eventflags_t; --16
	-- reserved 16
  flags:tickflags_t; -- 32
	reltimestamp:unsigned(TIME_BITS-1 downto 0); --16
  full_timestamp:unsigned(TIMESTAMP_BITS-1 downto 0); --64
end record;

function to_streambus(t:tickevent_t) return streambus_array;

-- can specify fixed size (fixed bit set)
-- 0 to only get header 
---------------  pulse event (variable/fixed) 16 byte header -------------------
--  | size  | pulse_length | event flags |     time     |
--  |      area     |   ?    | ? |
--  repeating 8 byte peak records -- up to 7
-- TODO implement
type pulseheader_t is record -- entire peak only event
  flags:eventflags_t; -- 16
  size:unsigned(SIZE_BITS-1 downto 0); -- 16
  reltimestamp:unsigned(TIME_BITS-1 downto 0); -- 16
  pulse_length:signal_t; --16 --FIXME remove
  area:area_t; --32
  --height:signal_t;
  --rise_time:unsigned(TIME_BITS-1 downto 0);
end record;

type peakrecord_t is record
  min:signal_t;
  max:signal_t;
  height:signal_t;
	trigger_time:time_t;
end record;

type tracerecord_t is record
	start_time:time_t;
	rise_time:time_t;
	trigger_time:time_t;
	height:signal_t;
end record;

end package events;

package body events is


------------------------- type flags 4 bits ------------------------------------
-- fixed|trace|area|tick
function to_std_logic(f:eventtype_flags_t) return std_logic_vector is
begin
	return to_std_logic(f.fixed) &
				 "00" &
				 --to_std_logic(f.trace) &
				 --to_std_logic(f.area) &
				 to_std_logic(f.tick);
end function;

----------------------- event flags - 16 bits-----------------------------------
--        1      |      1      |     2    |   4   |    4     |    4
--  peak_overflow|time_overflow|event_type|channel|peak_count|type_flags
function to_std_logic(f:eventflags_t) return std_logic_vector is 
begin
	return to_std_logic(f.peak_overflow) &
				 to_std_logic(f.time_overflow) &  
				 to_std_logic(f.event_type,2) &
				 to_std_logic(f.channel) & 
				 to_std_logic(f.peak_count) & 
				 to_std_logic(f.type_flags); 
end function;

------------------------- tick flags - 48 bits ---------------------------------
-- |  16    |  15    |   1    |   4    |   4
--  overflow|reserved|ticklost|reserved|type flags
--
function to_std_logic(f:tickflags_t) return std_logic_vector is 
begin
	return to_std_logic(f.overflow) & -- 16 bits
				 to_std_logic(0,15) &
				 to_std_logic(f.tick_lost) &
				 to_std_logic(0,4) &
				 to_std_logic(f.typeflags);
end function;

---------------------------- peak event 8 bytes --------------------------------
--  | height | rise | event flags | time |
function to_streambus(e:peakevent_t) return	streambus_t is
variable sba:streambus_t;
begin
	sba.data := to_std_logic(e.height) &
							to_std_logic(e.rise_time) &
							to_std_logic(e.flags) & 
							to_std_logic(e.reltimestamp);
	sba.keep_n := (others => FALSE);
	sba.last := (0 => TRUE, others => FALSE);
	return sba;
end function;

---------------------------- area event 8 bytes --------------------------------
--  |      32       |     16      |  16  |
--  |     area      | event flags | time |
function to_streambus(a:areaevent_t) return	streambus_t is
variable sba:streambus_t;
begin
	sba.data := to_std_logic(a.area) &
							to_std_logic(a.flags) & 
							to_std_logic(a.reltimestamp);
	sba.keep_n := (others => FALSE);
	sba.last := (0 => TRUE, others => FALSE);
	return sba;
end function;

-------------------------- tick event 16 bytes----------------------------------
--  |         tick flags          | time |
--  |          full time-stamp           |
function to_streambus(t:tickevent_t) return	streambus_array is
variable sba:streambus_array(1 downto 0);
begin
	sba(0).data :=  to_std_logic(t.flags) & to_std_logic(t.reltimestamp);
	sba(0).keep_n := (others => FALSE);
	sba(0).last := (others => FALSE);
	sba(1).data := to_std_logic(t.full_timestamp);
	sba(1).keep_n := (others => FALSE);
	sba(1).last := (0 => TRUE, others => FALSE);					
	return sba;
end function;

-----------------  pulse event (variable) 16 byte header -----------------------
--  | size  |  start  | event flags | time |
--  |      area       | height      | rise | -- height and rise of first peak
--  repeating 8 byte peak records (up to 7) for extra peaks.

--------------------- Discrete type conversion functions -----------------------
function to_height_type(s:unsigned(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
return height_d is
variable i:integer range 0 to NUM_HEIGHT_TYPES;
begin
	i:=to_integer(s);
	return to_height_type(i);
end function;

function to_unsigned(h:height_d;w:integer) return unsigned is
begin
	return to_unsigned(height_d'pos(h),w);
end function;

function to_std_logic(h:height_d;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(h,w));
end function;

function to_unsigned(t:timing_trigger_d;w:integer) return unsigned is
begin
	return to_unsigned(timing_trigger_d'pos(t),w);
end function;

function to_std_logic(t:timing_trigger_d;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(timing_trigger_d'pos(t),w));
end function;

function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
return height_d is
begin
	return height_d'val(i);
end function;

function to_unsigned(e:event_type_d;w:integer) return unsigned is
begin
	return to_unsigned(event_type_d'pos(e),w);
end function;
	
function to_std_logic(e:event_type_d;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(e,w));
end function;

end package body events;
