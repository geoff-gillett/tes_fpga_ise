library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

use work.types.all;
use work.functions.all; 

package events is

constant MAX_CHANNEL_BITS:integer:=4;
constant MAX_PEAK_COUNT_BITS:integer:=4;

type height_form is (PEAK_HEIGHT,CFD_HEIGHT,SLOPE_INTEGRAL);
constant NUM_HEIGHT_FORMS:integer:=3;

type event_flags is record
	channel:unsigned(MAX_CHANNEL_BITS-1 downto 0);
	peak_overflow:boolean;
	multipeak:boolean;
	peak_count:unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
end record;

type event_header is record
  size:unsigned(SIZE_BITS-1 downto 0);
  timestamp:unsigned(TIME_BITS-1 downto 0);
  flags:event_flags;
  height:signal_t;
end record;

function to_std_logic(e:event_header) return std_logic_vector;
function to_std_logic(f:event_flags) return std_logic_vector;
function to_std_logic(h:height_form) return std_logic_vector;
function to_height_form(i:natural range 0 to NUM_HEIGHT_FORMS-1) 
return height_form;
function to_height_form(
	s:unsigned(ceilLog2(NUM_HEIGHT_FORMS)-1 downto 0)
) return height_form;

end package events;

package body events is

function to_height_form(
	s:unsigned(ceilLog2(NUM_HEIGHT_FORMS)-1 downto 0)
) return height_form is
variable i:integer range 0 to NUM_HEIGHT_FORMS;
begin
	i:=to_integer(s);
	assert i < NUM_HEIGHT_FORMS report "bad height_form index" severity error;
	return to_height_form(i);
end function;

--FIXME I think XST can't handle pos attribute so this does not work
function to_std_logic(h:height_form) return std_logic_vector is
begin
	return to_std_logic(height_form'pos(h),2);
end function;

function to_height_form(i:natural range 0 to NUM_HEIGHT_FORMS-1) 
return height_form is
begin
	return height_form'val(i);
end function;

function to_std_logic(f:event_flags) return std_logic_vector is
begin
	return to_std_logic(f.channel) &
				 to_std_logic(f.peak_overflow) &
				 to_std_logic(f.multipeak) &
				 to_std_logic(0,6) &
				 to_std_logic(f.peak_count); 
end function;

function to_std_logic(e:event_header) 
return std_logic_vector is
begin
	return to_std_logic(e.size) &
				 to_std_logic(0,TIME_BITS) &
				 to_std_logic(e.flags) &
				 to_std_logic(e.height);
end function;
	
end package body events;
