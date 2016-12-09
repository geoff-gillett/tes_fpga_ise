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

package events is

--------------------------------- NOTES ----------------------------------------
-- FPGA format is big endian 
-- rise is time from trigger to height valid

--------------------------------------------------------------------------------
--                            Constants
--------------------------------------------------------------------------------
--constant RELATIVETIME_POS:integer:=16;
--constant SIZE_POS:integer:=48; --LSB of size field
--constant FLAGS_POS:integer:=11;

constant TICK_BUSWORDS:integer:=3;	-- must be 2 or 3
--constant CHANNEL_BITS:integer:=3;
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
-- detection_type_d|tick|new_window| -- new window is added by mux
type event_type_t is record
	detection:detection_d;
	tick:boolean;
end record;

function to_std_logic(e:event_type_t) return std_logic_vector;
function to_event_type_t(s:std_logic_vector) return event_type_t;
function to_event_type_t(sb:streambus_t;e:string) return event_type_t;

--FIXME reduce peak count to 3 bits
----------------------- event_flags_t - 16 bits---------------------------------
--|    4     |      1       |   3   ||  2   	|   2    |    3       |     1    |
--|peak_count| peak_overflow|channel||timing_d|height_d|event_type_t|new_window|
type detection_flags_t is record 
	peak_number:unsigned(PEAK_COUNT_BITS-1 downto 0); 
	peak_overflow:boolean; 
	height:height_d;
	timing:timing_d;
	channel:unsigned(CHANNEL_BITS-1 downto 0); 
	event_type:event_type_t; 
	new_window:boolean;
end record;

function to_std_logic(f:detection_flags_t) return std_logic_vector;

--------------------------- tick flags 16 bits ---------------------------------
-- First byte
-- | 2 |      1       |     1     |      3     |1|
-- | 0 | events_lost  | tick_lost | type_flags |0|

type tickflags_t is record 
	tick_lost:boolean;
	event_type:event_type_t; 
end record;

function to_std_logic(f:tickflags_t) return std_logic_vector;

---------------------------- peak event 8 bytes --------------------------------
-- |   16   |   16   |  16   |  16  |
-- | height |  rise  | flags | time |
--TODO make minima rise_time
type peak_detection_t is record -- entire peak only event
  height:signal_t; 
  rise_time:time_t;  
  flags:detection_flags_t; 
end record;

function to_streambus(e:peak_detection_t;endianness:string) return streambus_t;	
	
---------------------------- area event 8 bytes --------------------------------
-- | 32 | 16  | 16 |
-- |area|flags|time|
type area_detection_t is record
	area:area_t; 
	flags:detection_flags_t; 
end record;

function to_streambus(a:area_detection_t;endianness:string) return streambus_t;
  
---------------------------- test event 8 bytes --------------------------------
-- |   16   |   16   |  16   |  16  |
-- |  min   |  rise  | flags | time |
-- | low 1  |  low2  |  low thresh  |
-- | high 1 |  high2 | high thresh  |

type test_detection_t is record 
  flags:detection_flags_t; 
  high1,high2,low1,low2:signed(DSP_BITS-1 downto 0); 
  minima:signal_t;
  rise_time:time_t;
  low_threshold,high_threshold:signed(DSP_BITS-1 downto 0);
end record;

function to_streambus(
  t:test_detection_t;w:natural range 0 to 2;endianness:string
) return streambus_t;

--TODO add flag to indicate the first tick after reset	
-------------------------- tick event 16 bytes----------------------------------
--     |                   32                |  16  |  16  |
-- w=0 |                  period             | flags| time |
-- w=1 |                    full time-stamp                |
-- last word only when TICK_BUSWORDS=3
--     |     8      |    8    |    8     |     8     |    8     |    8     |16|
-- w=2 | framer_ovf | mux_ovf | meas_ovf | cfd_error | peak_ovf | time_ovf | 0|
type tick_event_t is record
  period:unsigned(TICK_PERIOD_BITS-1 downto 0);
  flags:tickflags_t; 
	rel_timestamp:time_t; 
  full_timestamp:unsigned(TIMESTAMP_BITS-1 downto 0); --64
  events_lost:boolean_vector(CHANNELS-1 downto 0);
  framer_overflows:boolean_vector(CHANNELS-1 downto 0);
  measurement_overflows:boolean_vector(CHANNELS-1 downto 0);
  mux_overflows:boolean_vector(CHANNELS-1 downto 0);
  peak_overflows:boolean_vector(CHANNELS-1 downto 0);
  time_overflows:boolean_vector(CHANNELS-1 downto 0);
  baseline_underflows:boolean_vector(CHANNELS-1 downto 0);
  cfd_errors:boolean_vector(CHANNELS-1 downto 0);
  commits:unsigned(23 downto 0);
  dumps:unsigned(23 downto 0);
end record;

function to_streambus(t:tick_event_t;w:natural range 0 to 2;endianness:string) 
return streambus_t;

-----------------  pulse event - 16 byte header --------------------------------
--  | size | reserved |   flags  |   time   |
--  |      area       |  length  |  offset  |  
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | rise | minima | time |
type pulse_detection_t is
record
	size:unsigned(SIZE_BITS-1 downto 0);
	length:time_t;
	flags:detection_flags_t;
	area:area_t;
	offset:unsigned(15 downto 0);
end record;

function to_streambus(
	p:pulse_detection_t;
	w:natural range 0 to 1;
	endianness:string
) return streambus_t;

--  |   16   |   16   |  16  |  16  |
--  | height |  rise  |minima| time |
type pulse_peak_t is
record
	height:signal_t;
	minima:signal_t;
	rise_time:time_t;
	timestamp:time_t;
end record;

function to_std_logic(p:pulse_peak_t;endianness:string) return std_logic_vector;
function to_streambus(p:pulse_peak_t;last:boolean;endianness:string) 
return streambus_t;

-- |  7  |  1  ||   2  |  2  	|   4		  |
-- |resvd|full ||trace0|trace1|max_peaks|
type trace_flags_t is
record
	trace0:trace_d;
	trace1:trace_d;
	max_peaks:unsigned(PEAK_COUNT_BITS-1 downto 0);
	full:boolean;
end record;

function to_std_logic(f:trace_flags_t) return std_logic_vector;

--FIXME make compatible with pulse header
-----------------  trace event - 16 byte header --------------------------------
--  |    16     |     16      |     16     |      16      |
--  |   size    | trace_flags | det flags  |     time     |
--  |  offset   | p thresh    |  s thresh  | pulse length | 
--  |   resvd   |    resvd    |           area            |  

--  trace length only used if full_trace
--  pulse length is pos thresh xing to neg xing
--  repeating (max_peaks+1) 8 byte peak records fixed space 
--  indexs are relative to pulse start
type trace_detection_t is
record
	size:unsigned(SIZE_BITS-1 downto 0);
	length:time_t; 
	detection_flags:detection_flags_t;
	trace_flags:trace_flags_t;
	offset:time_t;  -- redundant
	rel_timestamp:time_t;
	area:area_t;
	pulse_threshold:unsigned(SIGNAL_BITS-1 downto 0);
	slope_threshold:unsigned(SIGNAL_BITS-1 downto 0);
end record;

function to_streambus(
	t:trace_detection_t;
	w:natural range 0 to 2;
	endianness:string) return streambus_t;

--  length = (max_idx - min_idx)+1
--	|   16    |     16     |   16    |    16    |
--  | min_idx | height_idx | max_idx | time_idx | 
type trace_peak_t is record
	min_idx:time_t; -- negative rel to time_idx
	height_idx:time_t; 
	peak_idx:time_t;
	trigger_idx:time_t;
end record;-- peak_indx-min_idx=length

function to_std_logic(t:trace_peak_t;endianness:string) return std_logic_vector;
function to_streambus(t:trace_peak_t;endianness:string)
return streambus_t;

end package events;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
package body events is

------------------------- event_type_t - 3 bits --------------------------------
--         2       | 1  |
-- detection_type_d|tick|
function to_std_logic(e:event_type_t) return std_logic_vector is
begin
	return to_std_logic(e.detection,2) &
				 to_std_logic(e.tick);
end function;

function to_event_type_t(s:std_logic_vector) return event_type_t is
	variable e:event_type_t;
begin
	e.detection := to_detection_d(s(s'high downto s'high-1));
	e.tick := to_boolean(s(s'high-2));
	--e.new_window:=to_boolean(s(s'high-3));
	return e;
end function;

function to_event_type_t(sb:streambus_t;e:string) return event_type_t is
	variable et:event_type_t;
begin
  if endianness="BIG" then
	  et := to_event_type_t(sb.data(19 downto 16));
	elsif endianness="LITTLE" then
	  et := to_event_type_t(sb.data(27 downto 24));
	else
	  assert FALSE report "endianness must be either BIG or LITTLE" 
	               severity FAILURE;
	end if;
	return et;
end function;

----------------------- event_flags_t - 16 bits---------------------------------
--|    4     |      1       |   3   ||   2   	|    2   |     3      |     1    |
--|peak_count|peak_overflow |channel||timing_d|height_d|event_type_t|new_window|
function to_std_logic(f:detection_flags_t) return std_logic_vector is 
	variable slv:std_logic_vector(15 downto 0);
begin    
				 -- first transmitted byte
  slv(15 downto 12) := to_std_logic(f.peak_number);
  slv(11) := to_std_logic(f.peak_overflow);
  slv(10 downto 8) := to_std_logic(f.channel);
				 -- second transmitted byte
  slv(7 downto 6) := to_std_logic(f.timing,2);
  slv(5 downto 4) := to_std_logic(f.height,2);
  slv(3 downto 1) := to_std_logic(f.event_type);
  slv(0) := to_std_logic(f.new_window);
  return slv;
end function;

------------------------- tick flags - 8 bits ---------------------------------
-- | 3 |     1     |      3     | 1 |
-- | 0 | tick_lost | type_flags | 0 |
function to_std_logic(f:tickflags_t) 
return std_logic_vector is 
variable slv:std_logic_vector(7 downto 0);
begin
  slv := to_std_logic(0,3) &
         to_std_logic(f.tick_lost) &
         to_std_logic(f.event_type) &
         '0';
	return slv;
end function;

---------------------------- peak event 8 bytes --------------------------------
-- |   16   |   16   |  16   |  16  |
-- | height |  rise  | flags | time |
function to_streambus(e:peak_detection_t;endianness:string) 
return	streambus_t is
	variable sb:streambus_t;
begin
  sb.data := set_endianness(e.height,endianness) &
             set_endianness(e.rise_time,endianness) &
             set_endianness(to_std_logic(e.flags),endianness) & --FIXME set endianess 
             "0000000000000000"; 
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
             set_endianness(to_std_logic(a.flags),endianness) & 
             "0000000000000000"; -- replaced with rel_timestamp by mux
	sb.discard := (others => FALSE);
	sb.last := (0 => TRUE, others => FALSE);
	return sb;
end function;

-- TODO add the extra 8 bytes
-------------------------- tick event 16 bytes----------------------------------
--     |                   32                |  16  |  16  |
-- w=0 |                  period             | flags| time |
-- w=1 |                    full time-stamp                |
-- last word only when TICK_BUSWORDS=3
--     |     8      |    8    |    8     |     8     |    8     |    8     | ...
-- w=2 | framer_ovf | mux_ovf | meas_ovf | cfd_error | peak_ovf | time_ovf | ...
-- ... |      8       | 8 |
-- ... | baseline_unf | 0 |   
function to_streambus(t:tick_event_t;w:natural range 0 to 2;endianness:string) 
return streambus_t is
variable sb:streambus_t;
begin
	case w is
	when 0 =>
	  if endianness="BIG" then
      sb.data := set_endianness(t.period,endianness) &
                 to_std_logic(0,8) & -- reserved
                 to_std_logic(t.flags) &
                 "0000000000000000"; -- replaced with rel_timestamp by mux
    end if;
	  if endianness="LITTLE" then
      sb.data := set_endianness(t.period,endianness) &
                 to_std_logic(t.flags) &
                 to_std_logic(0,8) & -- reserved
                 "0000000000000000"; -- replaced with rel_timestamp by mux
    end if;
      
    sb.discard := (others => FALSE);
    sb.last := (others => FALSE);
  when 1 =>
    sb.data := set_endianness(t.full_timestamp,endianness);
    sb.discard := (others => FALSE);
    sb.last := (0 => TICK_BUSWORDS=2, others => FALSE);					
  when 2 =>
    sb.data := resize(to_std_logic(t.framer_overflows),CHANNELS) &
    					 resize(to_std_logic(t.mux_overflows),CHANNELS) &
    					 resize(to_std_logic(t.measurement_overflows),CHANNELS) &
    					 resize(to_std_logic(t.cfd_errors),CHANNELS) &
    					 resize(to_std_logic(t.peak_overflows),CHANNELS) &
    					 resize(to_std_logic(t.time_overflows),CHANNELS) &
    					 resize(to_std_logic(t.baseline_underflows),CHANNELS) &
    					 to_std_logic(0, 8);
    sb.discard := (others => FALSE);
    sb.last := (0 => TRUE, others => FALSE);					
  when others =>
		assert FALSE report "bad word number in tick_event_t to_streambus()"	
						 severity ERROR;
	end case;
	return sb;
end function;

-----------------  pulse event - 16 byte header --------------------------------
--  | size | reserved |   flags  |   time   | --fixme size could be removed?
--  |     area        |  length  |  offset  |  
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | rise | minima | time |
function to_streambus(p:pulse_detection_t;w:natural range 0 to 1;
											endianness:string) return streambus_t is
	variable sb:streambus_t;
begin
	case w is
	when 0 =>
  	sb.data(63 downto 48) := set_endianness(p.size,endianness);
		sb.data(47 downto 32) := (others => '0');
		sb.data(31 downto 16) := set_endianness(to_std_logic(p.flags),endianness); 
		sb.data(15 downto 0) := (others => '0');
	when 1 =>
		sb.data(63 downto 32) := set_endianness(p.area,endianness);
		sb.data(31 downto 16) := set_endianness(p.length,endianness);
		sb.data(15 downto 0) := set_endianness(p.offset,endianness);
	when others =>
		assert FALSE report "bad word number in pulse_detection_t to_streambus"	
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
	       set_endianness(p.rise_time,endianness) &
	       set_endianness(p.minima,endianness) &
	       set_endianness(p.timestamp,endianness);
end function;

function to_streambus(p:pulse_peak_t;last:boolean;endianness:string)
return streambus_t is
	variable sb:streambus_t;
begin
	sb.data := to_std_logic(p, endianness);
	sb.last := (0 => last, others => FALSE);
	sb.discard := (others => FALSE);
	return sb;
end function;

---------------------------- test event 3*8 bytes --------------------------------
-- |   16   |   16   |  16   |  16  |
-- |  min   |  rise  | flags | time |
-- | low 1  |  low2  |  low thresh  |
-- | high 1 |  high2 | high thresh  |
function to_streambus(
  t:test_detection_t;w:natural range 0 to 2;endianness:string
) return streambus_t is
	variable sb:streambus_t;
begin
  case w is
  when 0 => 
  	sb.data(63 downto 48) := set_endianness(t.minima,endianness);
		sb.data(47 downto 32) := set_endianness(t.rise_time,endianness);
		sb.data(31 downto 16) := set_endianness(to_std_logic(t.flags),endianness); 
		sb.data(15 downto 0) := (others => '0');
    sb.last := (others => FALSE);
  when 1 => 
    sb.data(63 downto 54) := (others => '0');
  	sb.data(53 downto 36) := to_std_logic(t.low1);
		sb.data(35 downto 18) := to_std_logic(t.low2);
		sb.data(17 downto 0) := to_std_logic(t.low_threshold); 
		sb.data := set_endianness(sb.data,endianness);
		sb.last := (others => FALSE);
  when 2 => 
    sb.data(63 downto 54) := (others => '0');
  	sb.data(53 downto 36) := to_std_logic(t.high1);
		sb.data(35 downto 18) := to_std_logic(t.high2);
		sb.data(17 downto 0) := to_std_logic(t.high_threshold); 
		sb.data := set_endianness(sb.data,endianness);
    sb.last := (others => TRUE);
  end case;
  sb.discard := (others => FALSE);
  return sb;
    
end function;
  
------------------------ trace_flags_t 16 bits ---------------------------------
-- |  7  |   1  ||   2  |  2   |    4    |
-- |resvd| full ||trace0|trace1|max_peaks|
function to_std_logic(f:trace_flags_t) return std_logic_vector is
	variable slv:std_logic_vector(15 downto 0):=(others => '0');
begin
	slv(8):=to_std_logic(f.full);
	slv(7 downto 6):=to_std_logic(f.trace0,2);
	slv(5 downto 4):=to_std_logic(f.trace1,2);
	slv(3 downto 0):=to_std_logic(f.max_peaks);
	return slv;
end function;

-----------------  trace event - 24 byte header --------------------------------
--  |    16     |     16      |     16     |      16      |
--  |   size    | trace_flags | det flags  |     time     |
--  |  offset   | p thresh    |  s thresh  | pulse length | 
--  |   resvd   |    resvd    |           area            | 

--  trace length only used if full_trace
--  pulse length is pos thresh xing to neg xing
--  repeating (max_peaks+1) 8 byte peak records fixed space 
--  indexs are relative to pulse start
--  | min_idx | height_idx | max_idx | time_idx | 
--  trace data follows
function to_streambus(t:trace_detection_t;w:natural range 0 to 2;
	endianness:string) return streambus_t is
	variable sb:streambus_t;
begin
	case w is
	when 0 => 
		sb.data(63 downto 48):=set_endianness(t.size,endianness);
		sb.data(47 downto 32):=to_std_logic(t.trace_flags);
		sb.data(31 downto 16):=to_std_logic(t.detection_flags);
		sb.data(15 downto 0):=(others => '0');
	when 1 => 
		sb.data(63 downto 48):=set_endianness(t.offset,endianness);
		sb.data(47 downto 32):=set_endianness(t.pulse_threshold,endianness);
		sb.data(31 downto 16):=set_endianness(t.slope_threshold,endianness);
		sb.data(15 downto 0):=set_endianness(t.length,endianness);
	when 2 => 
		sb.data(63 downto 32):=(others => '0');
		sb.data(31 downto 0):=set_endianness(t.area,endianness);
	end case;
  sb.discard:=(others => FALSE);
  sb.last:=(others => FALSE);
  return sb;
end function;

---------------------------- trace_peak_t --------------------------------------
--  |    16   |     16     |    16   |    16    |
--  | min_idx | height_idx | max_idx | time_idx | 
function to_std_logic(t:trace_peak_t;endianness:string)
return std_logic_vector is
	variable slv:std_logic_vector(BUS_DATABITS-1 downto 0);
begin
	slv(63 downto 48):=set_endianness(t.min_idx,endianness);
	slv(47 downto 32):=set_endianness(t.height_idx,endianness);
	slv(31 downto 16):=set_endianness(t.peak_idx,endianness);
	slv(15 downto 0):=set_endianness(t.trigger_idx,endianness);
	return slv;
end function;

function to_streambus(t:trace_peak_t;endianness:string)
return streambus_t is
	variable sb:streambus_t;
begin
	sb.data:=to_std_logic(t,endianness);
  sb.discard:=(others => FALSE);
  sb.last:=(others => FALSE);
  return sb;
end function;
	
end package body events;
