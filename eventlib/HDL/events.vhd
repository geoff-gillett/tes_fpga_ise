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

--------------------------------- NOTES ----------------------------------------
-- FPGA format is big endian 

--------------------------------------------------------------------------------
--                            Constants
--------------------------------------------------------------------------------
constant CHANNEL_WIDTH:integer:=3;
constant PEAK_COUNT_WIDTH:integer:=3;
constant TICK_BIT:integer:=31; --FIXME remember to change this
constant RELATIVETIME_POS:integer:=16;
constant SIZE_POS:integer:=48; --LSB of size field
constant FLAGS_POS:integer:=11;

--------------------------------------------------------------------------------
--                            Discrete Types 
--------------------------------------------------------------------------------
type event_type_t is (
	PEAK_EVENT,
	AREA_EVENT,
	PULSE_EVENT,
	TRACE);

constant NUM_EVENT_TYPES:integer:=event_type_t'pos(event_type_t'high)+1;
constant EVENT_TYPE_BITS:integer:=ceilLog2(NUM_EVENT_TYPES);

function to_unsigned(e:event_type_t;w:integer) return unsigned;
function to_std_logic(e:event_type_t;w:integer) return std_logic_vector;

type trigger_t is (
	PULSE_THRESHOLD,
	SLOPE_THRESHOLD,
	CFD);

constant NUM_TIMING_TRIGGER_TYPES:integer:=
																	trigger_t'pos(trigger_t'high)+1;
constant TIMING_TRIGGER_TYPE_BITS:integer:=ceilLog2(NUM_TIMING_TRIGGER_TYPES);
	
function to_unsigned(t:trigger_t;w:integer) return unsigned;
function to_std_logic(t:trigger_t;w:integer) return std_logic_vector;
	
type height_t is (PEAK_HEIGHT,
									CFD_HEIGHT,
									SLOPE_INTEGRAL);

constant NUM_HEIGHT_TYPES:integer:=height_t'pos(height_t'high)+1;
constant HEIGHT_TYPE_BITS:integer:=ceilLog2(NUM_HEIGHT_TYPES);

function to_unsigned(h:height_t;w:integer) return unsigned;
function to_std_logic(h:height_t;w:integer) return std_logic_vector;
function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
				 return height_t;
function to_height_type(s:unsigned(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
				 return height_t;

--------------------------------------------------------------------------------
--                            Event Types 
--------------------------------------------------------------------------------

------------------------- type flags 4 bits ------------------------------------
-- fixed|trace|area|tick
type eventtype_flags_t is record
	tick:boolean; -- always FALSE for event; 
	area:boolean; -- area measurement
	trace:boolean; -- false for event 
	fixed:boolean; -- fixed length -- size not used otherwise size is used
end record;

function to_std_logic(f:eventtype_flags_t) return std_logic_vector;

----------------------- event flags - 16 bits-----------------------------------
--     2    |   2    |    1     |   3     |     1     |  3    |   4
--  timing_t|height_t|rel_to_min|peakcount|include min|channel|type flags
type eventflags_t is record -- 16 bits
	typeflags:eventtype_flags_t; -- 4
	rel_to_min:boolean; -- if 0 rel to baseline
	trigger:trigger_t; -- 2 bits
	height:height_t; -- 2 bits
	peak_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0); -- 3
	include_minima:boolean; -- when not fixed include minima in peak record
	channel:unsigned(CHANNEL_WIDTH-1 downto 0); -- 3
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
  flags:eventflags_t;  -- 16
  height:signal_t; -- 16
  rise_time:unsigned(TIME_BITS-1 downto 0); -- 16
  reltimestamp:unsigned(TIME_BITS-1 downto 0); -- 16
end record;

function to_streambus(e:peakevent_t) return streambus_t;	
	
---------------------------- area event 8 bytes --------------------------------
--  |     area      | event flags | time |
type areaevent_t is record
	reltimestamp:unsigned(TIME_BITS-1 downto 0); --16
	flags:eventflags_t; -- 16
	area:area_t; -- 32
end record;

function to_streambus(a:areaevent_t) return	streambus_t;
	
-------------------------- tick event 16 bytes----------------------------------
--  |         tick flags          | time |
--  |          full time-stamp           |
type tickevent_t is record
	reltimestamp:unsigned(TIME_BITS-1 downto 0); --16
	--event_flags:eventflags_t; --16
	-- reserved 16
  flags:tickflags_t; -- 32
  full_timestamp:unsigned(TIMESTAMP_BITS-1 downto 0); --64
end record;

function to_streambus(t:tickevent_t) return streambus_array;

-----------------  pulse event (variable) 16 byte header -----------------------
--  | size  |  start  | event flags | time |
--  |      area       | height      | rise |
--  repeating 8 byte peak records (up to 7), 3 extra peaks if including minima
-- TODO implement
type pulseheader_t is record -- entire peak only event
  event_flags:eventflags_t; -- 16
  size:unsigned(SIZE_BITS-1 downto 0); -- 16
  reltimestamp:unsigned(TIME_BITS-1 downto 0); -- 16
  start_height:signal_t; --16
  area:area_t; --32
  height:signal_t;
  rise_time:unsigned(TIME_BITS-1 downto 0);
end record;

type peakrecord_t is record
  min:signal_t;
  min_reltime:unsigned(TIME_BITS-1 downto 0); -- rel to start
  max:signal_t; -- depends on rel_to_min flag
  rise_time:unsigned(TIME_BITS-1 downto 0); -- rel to min_start
end record;

end package events;

package body events is


------------------------- type flags 4 bits ------------------------------------
-- fixed|trace|area|tick
function to_std_logic(f:eventtype_flags_t) return std_logic_vector is
begin
	return to_std_logic(f.fixed) &
				 to_std_logic(f.trace) &
				 to_std_logic(f.area) &
				 to_std_logic(f.tick);
end function;

----------------------- event flags - 16 bits-----------------------------------
--     2    |   2    |    1     |   3     |     1     |  3    |   4
--  timing_t|height_t|rel_to_min|peakcount|include min|channel|type flags
function to_std_logic(f:eventflags_t) return std_logic_vector is 
begin
	return 
				 to_std_logic(f.rel_to_min) &
				 to_std_logic(f.trigger,2) & -- 2 bits
				 to_std_logic(f.height,2) & --2 bits
				 to_std_logic(f.peak_count) & --3 bits
				 to_std_logic(f.include_minima) &
				 to_std_logic(f.channel) & -- 3 bits
				 to_std_logic(f.typeflags);
end function;

--------------------------- tick flags 48 bits ---------------------------------
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
--  |      area       | height      | rise |
--  repeating 8 byte peak records (up to 7) = 3 extra peaks if including minima
-- TODO implement

--------------------- Discrete type conversion functions -----------------------
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

function to_unsigned(t:trigger_t;w:integer) return unsigned is
begin
	return to_unsigned(trigger_t'pos(t),w);
end function;

function to_std_logic(t:trigger_t;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(trigger_t'pos(t),w));
end function;

function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
return height_t is
begin
	return height_t'val(i);
end function;

function to_unsigned(e:event_type_t;w:integer) return unsigned is
begin
	return to_unsigned(event_type_t'pos(e),w);
end function;
	
function to_std_logic(e:event_type_t;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(e,w));
end function;

end package body events;
