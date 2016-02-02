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

library streamlib;
use streamlib.stream.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

use work.channel.all;
use work.global.all;

package mca is
constant MCA_ADDRESS_BITS:integer:=14;
constant MCA_VALUE_BITS:integer:=32;
subtype mca_value_t is signed(MCA_VALUE_BITS-1 downto 0);
type mca_value_array is array (natural range <>) of mca_value_t;

-- NOTE selectors take a max of 12 inputs 
-- SEE teslib.select_1of12
constant NUM_MCA_VALUES:integer:=12;
type values_t is (FILTERED, -- the output of the dsp filter
									FILTERED_AREA, -- the area between zero crossings
									FILTERED_EXTREMA, -- max or min between zero crossings
									SLOPE, -- the output of the dsp differentiator
									SLOPE_AREA,
									SLOPE_EXTREMA,
									PULSE_AREA, -- the area between threshold crossings
									PULSE_EXTREMA, -- the maximum between threshold xings
									--SLOPE_XING, --signal when slope crosses threshold
									PEAK, -- the filtered signal a neg slope 0 xing
									-- the height of the peak relative to start
									--PEAK_COUNT, -- number of peaks in the pulse
									RAW,
									RAW_AREA,
									RAW_EXTREMA
									--JITTER -- time difference between channels
);
	
function get_values(m:channel_measurements) return mca_value_array;
function to_onehot(v:values_t) return std_logic_vector;
function to_values_t(i:natural range 0 to NUM_MCA_VALUES-1) return values_t;
function to_values_t(u:unsigned) return values_t;
function to_unsigned(v:values_t;w:natural) return unsigned;

--TODO check that 0xings are same as valids
type triggers_t is (DISABLED,
									 ALWAYS,
									 FILTERED_XING,
									 FILTERED_0XING,
									 SLOPE_0XING,
									 SLOPE_XING,
									 CFD_HIGH,
									 CFD_LOW,
									 PEAK,
									 PEAK_START,
									 RAW
);
constant NUM_MCA_TRIGGERS:integer:=11; 

function get_valids(m:channel_measurements) return std_logic_vector;
function to_onehot(t:triggers_t) return std_logic_vector;
function to_trigger_t(i:natural range 0 to NUM_MCA_TRIGGERS-1) return triggers_t;
function to_trigger_t(u:unsigned) return triggers_t;
function to_unsigned(t:triggers_t;w:natural) return unsigned;


type mca_registers is record
	bin_n:unsigned(4 downto 0);
	lowest_value:signed(MCA_VALUE_BITS-1 downto 0);
	-- NOTE must be multiple of 2 LSB ignored
	last_bin:unsigned(MCA_ADDRESS_BITS-1 downto 0);
	ticks:unsigned(TICK_COUNT_BITS-1 downto 0);
	tick_period:unsigned(TICK_BITS-1 downto 0);
	channel:unsigned(3 downto 0);
	value:values_t;
	trigger:triggers_t;
end record;

type mca_flags_t is record
	value:unsigned(3 downto 0);
	trigger:unsigned(3 downto 0);
	bin_n:unsigned(3 downto 0);
	channel:unsigned(3 downto 0);
end record;

constant MCA_PROTOCOL_HEADER_WORDS:integer:=4;
constant MCA_PROTOCOL_HEADER_CHUNKS:integer
				 :=MCA_PROTOCOL_HEADER_WORDS*BUS_CHUNKS;
				 
type mca_protocol_header is record
	size:unsigned(CHUNK_BITS-1 downto 0);
	last_bin:unsigned(CHUNK_BITS-1 downto 0);
	flags:mca_flags_t;
	most_frequent:unsigned(CHUNK_BITS-1 downto 0);
	-- word 2
	max_count:unsigned(2*CHUNK_BITS-1 downto 0);
	lowest_value:signed(2*CHUNK_BITS-1 downto 0);
	-- word 3
	start_time:unsigned(4*CHUNK_BITS-1 downto 0);
	stop_time:unsigned(4*CHUNK_BITS-1 downto 0);
end record;

function to_std_logic(f:mca_flags_t) return std_logic_vector;

function to_protocol_header(r:mca_registers;max,mf,start,stop:unsigned) 
return mca_protocol_header;

function to_streambus(h:mca_protocol_header;
										  w:natural range 0 to MCA_PROTOCOL_HEADER_WORDS-1)
											return streambus_t;
end package mca;

package body mca is
--------------------------------------------------------------------------------
-- values_t functions
--------------------------------------------------------------------------------
	
function to_onehot(v:values_t) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_VALUES-1 downto 0):=(others => '0');
begin
		o:=to_onehot(values_t'pos(v),NUM_MCA_VALUES);
	return o;
end function;

function to_values_t(i:natural range 0 to NUM_MCA_VALUES-1) return values_t is
begin
	return values_t'val(i);
end function;
	
function to_values_t(u:unsigned) return values_t is
begin
	return to_values_t(to_integer(u));
end function;
	
function to_unsigned(v:values_t;w:natural) return unsigned is
begin
	return to_unsigned(values_t'pos(v),w);
end function;
	
function get_values(m:channel_measurements) return mca_value_array is
variable va:mca_value_array(NUM_MCA_VALUES-1 downto 0);
begin

  va(0) := resize(m.filtered_signal,MCA_VALUE_BITS);
  va(1) := resize(m.filtered.area,MCA_VALUE_BITS);
  va(2) := resize(m.filtered.extrema,MCA_VALUE_BITS);
  va(3) := resize(m.slope_signal,MCA_VALUE_BITS);
  va(4) := resize(m.slope.area,MCA_VALUE_BITS);
  va(5) := resize(m.slope.extrema,MCA_VALUE_BITS);
  va(6) := resize(m.pulse.area,MCA_VALUE_BITS);
  va(7) := resize(m.pulse.extrema,MCA_VALUE_BITS);
  va(9) := resize(signed('0' & m.peak_count),MCA_VALUE_BITS);
  va(10) := resize(m.raw_signal,MCA_VALUE_BITS);
  va(11) := resize(m.raw.area,MCA_VALUE_BITS);
  va(12) := resize(m.raw.extrema,MCA_VALUE_BITS);
  
  return va;
end function;

--------------------------------------------------------------------------------
-- triggers_t functions
--------------------------------------------------------------------------------

function to_onehot(t:triggers_t) return std_logic_vector is
variable o:std_logic_vector(NUM_MCA_TRIGGERS-2 downto 0):=(others => '0');
begin
	if t/=DISABLED then
		o:=to_onehot(triggers_t'pos(t)-1,NUM_MCA_TRIGGERS-1);
	end if;
	return o;
end function;

function to_trigger_t(i:natural range 0 to NUM_MCA_TRIGGERS-1) 
return triggers_t is
begin
	return triggers_t'val(i);
end function;

function to_trigger_t(u:unsigned) return triggers_t is 
begin
	return to_trigger_t(to_integer(u));
end function;
	
function to_unsigned(t:triggers_t;w:natural) return unsigned is
begin
	return to_unsigned(triggers_t'pos(t),w);
end function;
	
function get_valids(m:channel_measurements) return std_logic_vector is
begin
	return to_std_logic(
						FALSE &
						TRUE & 
						m.filtered_xing &
						m.filtered.valid &
						m.slope.valid &
						m.slope_xing	&
						m.cfd_high &
						m.cfd_low &
						m.peak &
						m.peak_start &
						m.raw.valid
					);
end function;

function to_std_logic(f:mca_flags_t) return std_logic_vector is
begin
	return to_std_logic(f.bin_n) &
				 to_std_logic(f.value) &
				 to_std_logic(f.trigger) &
				 to_std_logic(f.channel);
end function;

--------------------------------------------------------------------------------
-- mca_protocol_header functions
--------------------------------------------------------------------------------

-- NOTE this infers some logic should be used in a sequential process
function to_protocol_header(r:mca_registers;max,mf,start,stop:unsigned) 
return mca_protocol_header is
variable h:mca_protocol_header;
begin
	h.size := shift_right(r.last_bin,1) + MCA_PROTOCOL_HEADER_CHUNKS;
	h.last_bin := r.last_bin;
	h.flags.value := to_unsigned(r.value,4);  
	h.flags.trigger := to_unsigned(r.trigger,4);  
	h.flags.bin_n := r.bin_n;  
	h.flags.channel := r.channel;  
	h.lowest_value := r.lowest_value;
	h.max_count:=max;
	h.most_frequent:=mf;
	h.start_time:=start;
	h.stop_time:=stop;
	return h;
end function;

-- w should be a constant as logic is infered
function to_streambus(h:mca_protocol_header;
										  w:natural range 0 to MCA_PROTOCOL_HEADER_WORDS-1)
											return streambus_t is
variable sb:streambus_t;
begin
	sb.keep_n := (others => FALSE);
	sb.last := (others => FALSE);
	case w is
	when 0 =>
		sb.data:= to_std_logic(h.size) &
  						to_std_logic(h.last_bin) &
  						to_std_logic(h.flags) &
  						to_std_logic(h.most_frequent);
  when 1 =>
  	sb.data := to_std_logic(h.max_count) &
  						 to_std_logic(h.lowest_value);
  when 2 => 
  	sb.data := to_std_logic(h.start_time);
  when 3 => 
  	sb.data := to_std_logic(h.stop_time);
  when others =>
  	null;
	end case;
	return sb;
end function;

end package body mca;
