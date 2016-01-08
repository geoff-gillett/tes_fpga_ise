library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

package events is

constant MAX_PEAK_COUNT_BITS:integer:=2;

type event_t is (PEAK,PULSE_FIXED,PULSE_VARIABLE);
constant NUM_EVENT_TYPES:integer:=3;
constant EVENT_TYPE_BITS:integer:=bits(NUM_EVENT_TYPES);

type event_flags is record
	channel:unsigned(CHANNEL_BITS-1 downto 0);
	peak_overflow:boolean;
	time_overflow:boolean;
	pad:std_logic_vector(15-2-CHANNEL_BITS-MAX_PEAK_COUNT_BITS downto 0);
	extra_peak_count:unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
end record;

type extra_peak is record
	timestamp:unsigned(TIME_BITS-1 downto 0);
	height:signal_t;
end record;

type event_header is record
  size:unsigned(SIZE_BITS-1 downto 0);
  timestamp:unsigned(TIME_BITS-1 downto 0);
  flags:event_flags;
end record;

type peak_event is record
	header:event_header;
	height:signal_t;
end record;

-- maximum 2 peaks;
type pulse_event is record
	header:event_header;
	height:signal_t;
	area:area_t;
end record;

function to_std_logic(e:event_t) return std_logic_vector;	
	
end package events;

package body events is

function to_std_logic(e:event_t) return std_logic_vector is
begin
	return to_std_logic(event_t'pos(e),EVENT_TYPE_BITS);
end function;
	
end package body events;
