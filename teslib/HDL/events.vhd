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
type detection_type_d is (
	PEAK_DETECTION_D,
	AREA_DETECTION_D,
	PULSE_DETECTION_D, --use fixed flag to indicate fixed/variable length
	TRACE_DETECTION_D
);

constant NUM_DETECTION_TYPES:integer:=
				 detection_type_d'pos(detection_type_d'high)+1;
constant DETECTION_TYPE_BITS:integer:=ceilLog2(NUM_DETECTION_TYPES);
function to_unsigned(e:detection_type_d;w:integer) return unsigned;
function to_std_logic(e:detection_type_d;w:integer) return std_logic_vector;
function to_detection_type(
	s:std_logic_vector(ceilLog2(NUM_DETECTION_TYPES)-1 downto 0)
) return detection_type_d;
function to_detection_type(s:unsigned(ceilLog2(NUM_DETECTION_TYPES)-1 downto 0)) 
return detection_type_d;
function to_detection_type(i:natural range 0 to NUM_DETECTION_TYPES-1) 
return detection_type_d;

-- the point the relative time-stamp is taken
type timing_d is (
	PULSE_THRESH_TIMING_D,
	SLOPE_THRESH_TIMING_D,
	CFD_LOW_TIMING_D,
	RISE_START_TIMING_D
);

constant NUM_TIMING_TRIGGER_TYPES:integer:=
				 timing_d'pos(timing_d'high)+1;
constant TIMING_TRIGGER_TYPE_BITS:integer:=ceilLog2(NUM_TIMING_TRIGGER_TYPES);
function to_unsigned(t:timing_d;w:integer) return unsigned;
function to_std_logic(t:timing_d;w:integer) return std_logic_vector;
	
type height_d is (
	PEAK_HEIGHT_D,
	CFD_HIGH_D,
	SLOPE_INTEGRAL_D
);

constant NUM_HEIGHT_TYPES:integer:=height_d'pos(height_d'high)+1;
constant HEIGHT_TYPE_BITS:integer:=ceilLog2(NUM_HEIGHT_TYPES);
function to_unsigned(h:height_d;w:integer) return unsigned;
function to_std_logic(h:height_d;w:integer) return std_logic_vector;
function to_height_type(
				 s:std_logic_vector(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
				 return height_d;
function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
				 return height_d;
function to_height_type(s:unsigned(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
				 return height_d;

type trace_type_d is(
	NONE_D,
	RAW_D,
	FILTERED_D,
	SLOPE_D
);

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
	detection_type:detection_type_d;
	tick:boolean;
	new_window:boolean;
end record;

function to_std_logic(e:event_type_t) return std_logic_vector;
function to_event_type(s:std_logic_vector) return event_type_t;
function to_event_type(sb:streambus_t) return event_type_t;

----------------------- event flags - 16 bits-----------------------------------
--      4    |   1    |   3   ||  2   |     1       |      1      |    4     |
-- peak_count|relative|channel||timing|peak_overflow|time_overflow|event_type|
type detection_flags_t is record 
	peak_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0); 
	relative:boolean; -- not sure this is useful
	peak_overflow:boolean; 
	time_overflow:boolean; 
	timing_point:timing_d;
	channel:unsigned(CHANNEL_WIDTH-1 downto 0); 
	event_type:event_type_t; 
end record;

function to_std_logic(f:detection_flags_t) return std_logic_vector;

--------------------------- tick flags 16 bits ---------------------------------
-- |    8    ||3|    1    |    4     | 
-- |overflows||0|tick_lost|type_flags| 
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
	trace0:trace_type_d;
	trace1:trace_type_d;
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
				 to_std_logic(e.tick) &
				 to_std_logic(e.new_window);
end function;

function to_event_type(s:std_logic_vector) return event_type_t is
	variable e:event_type_t;
begin
	e.detection_type:=to_detection_type(s(s'high downto s'high-1));
	e.tick:=to_boolean(s(s'high-2));
	e.new_window:=to_boolean(s(s'high-3));
	return e;
end function;

function to_event_type(sb:streambus_t) return event_type_t is
	variable e:event_type_t;
begin
	e := to_event_type(sb.data(19 downto 16));
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
         to_std_logic(f.event_type); 
  return slv;
end function;

------------------------- tick flags - 16 bits ---------------------------------
-- |    8    ||3|    1    |    4     | 
-- |overflows||0|tick_lost|type_flags| 
function to_std_logic(f:tickflags_t) 
return std_logic_vector is 
variable slv:std_logic_vector(47 downto 0);
begin
				 -- first byte transmitted 
  slv := to_std_logic(f.overflow) &
				 -- second byte transmitted 
         to_std_logic(0,3) &
         to_std_logic(f.tick_lost) & 
         to_std_logic(f.event_type); 
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
	sb.keep_n := (others => FALSE);
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
	sb.keep_n := (others => FALSE);
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
    sb.keep_n := (others => FALSE);
    sb.last := (others => FALSE);
  when 1 =>
    sb.data := set_endianness(t.full_timestamp,endianness);
    sb.keep_n := (others => FALSE);
    sb.last := (0 => TRUE, others => FALSE);					
  when others =>
		assert FALSE report "bad word number in tick_event_t to_streambus()"	
						 severity ERROR;
	end case;
	return sb;
end function;

-----------------  pulse event - 16 byte header --------------------------------
--  | size | plength |   flags  |   time   |
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
  sb.keep_n := (others => FALSE);
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

--------------------- Discrete type con version functions -----------------------

function to_unsigned(h:height_d;w:integer) return unsigned is
begin
	return to_unsigned(height_d'pos(h),w);
end function;

function to_std_logic(h:height_d;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(h,w));
end function;

function to_unsigned(t:timing_d;w:integer) return unsigned is
begin
	return to_unsigned(timing_d'pos(t),w);
end function;

function to_std_logic(t:timing_d;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(timing_d'pos(t),w));
end function;

function to_height_type(
	s:std_logic_vector(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)
) return height_d is
variable i:integer range 0 to NUM_HEIGHT_TYPES;
begin
	i:=to_integer(unsigned(s));
	return to_height_type(i);
end function;

function to_height_type(s:unsigned(ceilLog2(NUM_HEIGHT_TYPES)-1 downto 0)) 
return height_d is
variable i:integer range 0 to NUM_HEIGHT_TYPES;
begin
	i:=to_integer(s);
	return to_height_type(i);
end function;

function to_height_type(i:natural range 0 to NUM_HEIGHT_TYPES-1) 
return height_d is
begin
	return height_d'val(i);
end function;

function to_detection_type(
	s:std_logic_vector(ceilLog2(NUM_DETECTION_TYPES)-1 downto 0)
) 
return detection_type_d is
variable i:natural range 0 to NUM_DETECTION_TYPES;
begin
	i:=to_integer(unsigned(s));
	return to_detection_type(i);
end function;

function to_detection_type(s:unsigned(ceilLog2(NUM_DETECTION_TYPES)-1 downto 0)) 
return detection_type_d is
variable i:natural range 0 to NUM_DETECTION_TYPES;
begin
	i:=to_integer(s);
	return to_detection_type(i);
end function;

function to_detection_type(i:natural range 0 to NUM_DETECTION_TYPES-1) 
return detection_type_d is
begin
	return detection_type_d'val(i);
end function;

function to_unsigned(e:detection_type_d;w:integer) return unsigned is
begin
	return to_unsigned(detection_type_d'pos(e),w);
end function;
	
function to_std_logic(e:detection_type_d;w:integer) return std_logic_vector is
begin
	return to_std_logic(to_unsigned(e,w));
end function;

end package body events;
