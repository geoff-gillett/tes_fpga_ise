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
constant CHANNEL_WIDTH:integer:=3;
constant PEAK_COUNT_WIDTH:integer:=4;
constant TICKPERIOD_BITS:integer:=32;
constant RELATIVETIME_POS:integer:=16;
constant SIZE_POS:integer:=48; --LSB of size field
constant FLAGS_POS:integer:=11;

--------------------------------------------------------------------------------
--                            Discrete Types 
--------------------------------------------------------------------------------
-- type of detection
type detection_d is (
	PEAK_DETECTION_D,
	AREA_DETECTION_D,
	PULSE_DETECTION_D, --use fixed flag to indicate fixed/variable length
	TRACE_DETECTION_D
);

constant NUM_DETECTION_D:integer:=detection_d'pos(detection_d'high)+1;
constant DETECTION_D_BITS:integer:=ceilLog2(NUM_DETECTION_D);
function to_std_logic(d:detection_d;w:integer) return std_logic_vector;
function to_detection_d(s:std_logic_vector) return detection_d;
function to_detection_d(i:natural range 0 to NUM_DETECTION_D-1) 
return detection_d;

-- the point the relative time-stamp is taken
type timing_d is (
	PULSE_THRESH_TIMING_D,
	SLOPE_THRESH_TIMING_D,
	CFD_LOW_TIMING_D,
	RISE_START_TIMING_D
);

constant NUM_TIMING_D:integer:=timing_d'pos(timing_d'high)+1;
constant TIMING_D_BITS:integer:=ceilLog2(NUM_TIMING_D);
function to_std_logic(t:timing_d;w:integer) return std_logic_vector;
function to_timing_d(i:natural range 0 to NUM_TIMING_D-1) return timing_d;
function to_timing_d(s:std_logic_vector) return timing_d;
	
type height_d is (
	PEAK_HEIGHT_D,
	CFD_HIGH_D,
	SLOPE_INTEGRAL_D
);

constant NUM_HEIGHT_D:integer:=height_d'pos(height_d'high)+1;
constant HEIGHT_D_BITS:integer:=ceilLog2(NUM_HEIGHT_D);
function to_std_logic(h:height_d;w:integer) return std_logic_vector;
function to_height_d(s:std_logic_vector) return height_d;
function to_height_d(i:natural range 0 to NUM_HEIGHT_D-1) return height_d;

type trace_d is(
	NO_TRACE_D,
	RAW_TRACE_D,
	FILTERED_TRACE_D,
	SLOPE_TRACE_D
);

constant NUM_TRACE_D:integer:=trace_d'pos(trace_d'high)+1;
constant TRACE_D_BITS:integer:=ceilLog2(NUM_TRACE_D);
function to_std_logic(t:trace_d;w:integer) return std_logic_vector;
function to_trace_d(s:std_logic_vector) return trace_d;
function to_trace_d(i:natural range 0 to NUM_TRACE_D-1) return trace_d;

--------------------------------------------------------------------------------
--                            Event Types 
--------------------------------------------------------------------------------
-- tick regular event containing 64 bit time-stamp and overflow information
-- detection - 4 types 
-- NOTES:
-- multi-byte flags are transmitted in big endian order regardless of ENDIANNESS

----------------------- event_type flags 4 bits --------------------------------
-- event type - either tick or one of four detection types
--------------------------------------------------------------------------------
--         2       | 1  |    1     |
-- detection_type_d|tick|new_window|
type event_type_t is record
	detection_type:detection_d;
	tick:boolean;
end record;

function to_std_logic(e:event_type_t) return std_logic_vector;
function to_event_type_t(s:std_logic_vector) return event_type_t;
function to_event_type_t(sb:streambus_t) return event_type_t;

----------------------- event flags - 16 bits-----------------------------------
-- First byte
-- |    4     |   1    |   3   |
-- |peak_count|relative|channel|
-- Second byte
-- |  2   |     1       |      1      |    3     |     1    |
-- |timing|peak_overflow|time_overflow|event_type|new_window|
type detection_flags_t is record 
	peak_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0); 
	relative:boolean; -- not sure this is useful
	peak_overflow:boolean; 
	time_overflow:boolean; 
	timing_point:timing_d;
	channel:unsigned(CHANNEL_WIDTH-1 downto 0); 
	event_type:event_type_t; 
	new_window:boolean;
end record;

function to_std_logic(f:detection_flags_t) return std_logic_vector;

--------------------------- tick flags 16 bits ---------------------------------
-- First byte
-- |    8    |
-- |overflows|
-- Second byte
-- |3|    1    |     3    |1|
-- |0|tick_lost|type_flags|0|
type tickflags_t is record 
	overflow:boolean_vector(7 downto 0); 
	tick_lost:boolean;
	event_type:event_type_t; 
end record;

function to_std_logic(f:tickflags_t) return std_logic_vector;

---------------------------- peak event 8 bytes --------------------------------
-- |  16  |  16  |  16 | 16 |
-- |height|minima|flags|time|
type peak_detection_t is record -- entire peak only event
  height:signal_t; 
  minima:signal_t;  
  flags:detection_flags_t; 
  rel_timestamp:time_t; -- 16
end record;

function to_streambus(e:peak_detection_t;endianness:string) return streambus_t;	
	
---------------------------- area event 8 bytes --------------------------------
-- | 32 | 16  | 16 |
-- |area|flags|time|
type area_detection_t is record
	area:area_t; 
	flags:detection_flags_t; 
	rel_timestamp:time_t; 
end record;

function to_streambus(a:area_detection_t;endianness:string) return streambus_t;
	
-------------------------- tick event 16 bytes----------------------------------
--     |  32  |  16 | 16 |
-- w=0 |period|flags|time|
-- w=1 | full time-stamp |
type tick_event_t is record
  period:unsigned(TICKPERIOD_BITS-1 downto 0);
  flags:tickflags_t; 
	rel_timestamp:time_t; 
  full_timestamp:unsigned(TIMESTAMP_BITS-1 downto 0); --64
end record;

function to_streambus(t:tick_event_t;w:natural range 0 to 1;endianness:string) 
return streambus_t;

--TODO implement
-----------------  pulse event - 16 byte header --------------------------------
--  | size | plength |   flags  |   time   |
--  |     area       | pthresh? | sthresh? |  
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | minima | rise | time |
type pulse_detection_t is
record
	size:unsigned(SIZE_BITS-1 downto 0);
	length:time_t;
	flags:detection_flags_t;
	rel_timestamp:time_t;
	area:area_t;
	pulse_threshold:unsigned(SIGNAL_BITS-1 downto 0);
	slope_threshold:unsigned(SIGNAL_BITS-1 downto 0);
end record;

function to_streambus(
	p:pulse_detection_t;
	w:natural range 0 to 1;
	endianness:string
) return streambus_t;

type pulse_peak_t is
record
	height:signal_t;
	minima:signal_t;
	rise_time:time_t;
	rel_timestamp:time_t;
end record;

function to_std_logic(p:pulse_peak_t;endianness:string) return std_logic_vector;

--TODO implement
-----------------  trace event - 16 byte header --------------------------------
--  |   16   |     16      |     16     |      16      |
--  |  size  | trace_flags |   flags    |     time     |
--  |   res  | p thresh    |  s thresh  | pulse length | 
--  |        res           |           area            | 
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | length |  time_idx   | height_idx |     time     | 
-- need to traverse length to find trace segments
type trace_detection_t is
record
	size:unsigned(SIZE_BITS-1 downto 0);
	length:time_t;
	flags:detection_flags_t;
	max_peaks:unsigned(PEAK_COUNT_WIDTH-1 downto 0);
	rel_timestamp:time_t;
	area:area_t;
	pulse_threshold:unsigned(SIGNAL_BITS-1 downto 0);
	slope_threshold:unsigned(SIGNAL_BITS-1 downto 0);
	trace0:trace_d;
	trace1:trace_d;
end record;

type trace_peak_t is record
	height_idx:time_t;
	length:time_t;
	time_idx:time_t;
	rel_timestamp:time_t;
end record;

end package events;

package body events is

------------------------- event_type_t - 4 bits --------------------------------
--         2       | 1  |    1     |
-- detection_type_d|tick|new_window|
function to_std_logic(e:event_type_t) return std_logic_vector is
begin
	return to_std_logic(e.detection_type,2) &
				 to_std_logic(e.tick);
end function;

function to_event_type_t(s:std_logic_vector) return event_type_t is
	variable e:event_type_t;
begin
	e.detection_type:=to_detection_d(s(s'high downto s'high-1));
	e.tick:=to_boolean(s(s'high-2));
	--e.new_window:=to_boolean(s(s'high-3));
	return e;
end function;

function to_event_type_t(sb:streambus_t) return event_type_t is
	variable e:event_type_t;
begin
	e := to_event_type_t(sb.data(19 downto 16));
	return e;
end function;

----------------------- event_flags_t - 16 bits---------------------------------
-- 		first byte transmitted  ||          second byte transmitted
--      4    |   1    |   3   ||  2   |     1       |      1      |    4     |
-- peak_count|relative|channel||timing|peak_overflow|time_overflow|event_type|
function to_std_logic(f:detection_flags_t) return std_logic_vector is 
variable slv:std_logic_vector(15 downto 0);
begin    
				 -- first transmitted byte
  slv := to_std_logic(f.peak_count) & 
         to_std_logic(f.relative) &
         to_std_logic(f.channel) &
				 -- second transmitted byte
         to_std_logic(f.timing_point,2) &
         to_std_logic(f.peak_overflow) &
         to_std_logic(f.time_overflow) &  
         to_std_logic(f.event_type) &
         to_std_logic(f.new_window);
  return slv;
end function;

------------------------- tick flags - 16 bits ---------------------------------
-- |    8    ||3|    1    |    3     |1|
-- |overflows||0|tick_lost|type_flags|0|
function to_std_logic(f:tickflags_t) 
return std_logic_vector is 
variable slv:std_logic_vector(15 downto 0);
begin
				 -- first byte transmitted 
  slv := to_std_logic(f.overflow) &
				 -- second byte transmitted 
         to_std_logic(0,3) &
         to_std_logic(f.tick_lost) & 
         to_std_logic(f.event_type) &
         '0';
	return slv;
end function;

---------------------------- peak event 8 bytes --------------------------------
-- |  16  |  16  |  16 | 16 |
-- |height|minima|flags|time|
function to_streambus(e:peak_detection_t;endianness:string) 
return	streambus_t is
	variable sb:streambus_t;
begin
  sb.data := set_endianness(e.height,endianness) &
             set_endianness(e.minima,endianness) &
             to_std_logic(e.flags) & 
             set_endianness(e.rel_timestamp,endianness);
	sb.discard := (others => FALSE);
	sb.last := (0 => TRUE, others => FALSE);
	return sb;
end function;

---------------------------- area event 8 bytes --------------------------------
--  |      32       |   16  |  16  |
--  |     area      | flags | time |
function to_streambus(a:area_detection_t;endianness:string) 
return	streambus_t is
	variable sb:streambus_t;
begin
  sb.data := set_endianness(a.area,endianness) &
             to_std_logic(a.flags) & 
  					 set_endianness(a.rel_timestamp,endianness);
	sb.discard := (others => FALSE);
	sb.last := (0 => TRUE, others => FALSE);
	return sb;
end function;

-------------------------- tick event 16 bytes----------------------------------
--     |  32  |  16 | 16 |
-- w=0 |period|flags|time|
-- w=1 | full time-stamp |
function to_streambus(t:tick_event_t;w:natural range 0 to 1;endianness:string) 
return streambus_t is
variable sb:streambus_t;
begin
	case w is
	when 0 =>
    sb.data := set_endianness(t.period,endianness) &
               to_std_logic(t.flags) &
    					 set_endianness(t.rel_timestamp,endianness);
    sb.discard := (others => FALSE);
    sb.last := (others => FALSE);
  when 1 =>
    sb.data := set_endianness(t.full_timestamp,endianness);
    sb.discard := (others => FALSE);
    sb.last := (0 => TRUE, others => FALSE);					
  when others =>
		assert FALSE report "bad word number in tick_event_t to_streambus()"	
						 severity ERROR;
	end case;
	return sb;
end function;

-----------------  pulse event - 16 byte header --------------------------------
--  | size | plength |   flags  |   time   | --fixme size could be removed?
--  |     area       | pthresh? | sthresh? |  
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | minima | rise | time |

function to_streambus(
	p:pulse_detection_t;
	w:natural range 0 to 1;
	endianness:string
) return streambus_t is
	variable sb:streambus_t;
begin
	case w is
	when 0 =>
		sb.data(63 downto 48):=set_endianness(p.size,endianness);
		sb.data(47 downto 32):=set_endianness(p.length,endianness);
		sb.data(31 downto 16):=set_endianness(p.rel_timestamp,endianness);
	when 1 =>
		sb.data(63 downto 32):=set_endianness(p.area,endianness);
		sb.data(31 downto 16):=set_endianness(p.pulse_threshold,endianness);
		sb.data(15 downto 0):=set_endianness(p.slope_threshold,endianness);
	when others =>
		assert FALSE report "bad word number in pulse_detection_t to_streambus()"	
						 		 severity ERROR;
	end case;
  sb.discard := (others => FALSE);
  sb.last := (others => FALSE);
  return sb;
end function;

function to_std_logic(p:pulse_peak_t;endianness:string) 
return std_logic_vector is
begin
	return set_endianness(p.height,endianness) &
	       set_endianness(p.minima,endianness) &
	       set_endianness(p.rise_time,endianness) &
	       set_endianness(p.rel_timestamp,endianness);
end function;

--TODO implement
-----------------  trace event - 16 byte header --------------------------------
--  | size | plength |  flags  |   time   |
--  |     area       | pthresh | sthresh  |  
--  | num slots | trace type
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | length | time idx | height idx | time | need to traverse to find trace segments

--------------------------------------------------------------------------------
--               Discrete type conversion functions
--------------------------------------------------------------------------------

-- height_d
function to_std_logic(h:height_d;w:integer) return std_logic_vector is
begin
	if w < HEIGHT_D_BITS then
		assert FALSE report "w to small to represent height_d" severity ERROR;
	end if;
	return to_std_logic(to_unsigned(height_d'pos(h),w));
end function;

function to_height_d(s:std_logic_vector) return height_d is
begin
	return to_height_d(to_integer(unsigned(s)));
end function;

function to_height_d(i:natural range 0 to NUM_HEIGHT_D-1) return height_d is
begin
	return height_d'val(i);
end function;

-- timing_d
function to_std_logic(t:timing_d;w:integer) return std_logic_vector is
begin
	if w < TIMING_D_BITS then
		assert FALSE report "w to small to represent timing_d" severity ERROR;
	end if;
	return to_std_logic(to_unsigned(timing_d'pos(t),w));
end function;

function to_timing_d(i:natural range 0 to NUM_TIMING_D-1) 
return timing_d is
begin
	return timing_d'val(i);
end function;

function to_timing_d(s:std_logic_vector) return timing_d is
begin
	return to_timing_d(to_integer(unsigned(s)));
end function;

-- detection_d
function to_detection_d(i:natural range 0 to NUM_DETECTION_D-1) 
return detection_d is
begin
	return detection_d'val(i);
end function;

function to_detection_d(s:std_logic_vector) return detection_d is
begin
	return to_detection_d(to_integer(unsigned(s)));
end function;

function to_std_logic(d:detection_d;w:integer) return std_logic_vector is
begin
	if w < DETECTION_D_BITS then
		assert FALSE report "w to small to represent detection_d" severity ERROR;
	end if;
	return to_std_logic(to_unsigned(detection_d'pos(d),w));
end function;

-- trace_d
function to_std_logic(t:trace_d;w:integer) return std_logic_vector is
begin
	if w < TRACE_D_BITS then
		assert FALSE report "w to small to represent trace_d" severity ERROR;
	end if;
	return to_std_logic(to_unsigned(trace_d'pos(t),w));
end function;

function to_trace_d(i:natural range 0 to NUM_TRACE_D-1) return trace_d is
begin
	return trace_d'val(i);
end function;

function to_trace_d(s:std_logic_vector) return trace_d is
begin
	return to_trace_d(to_integer(unsigned(s)));
end function;
	
end package body events;
