library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.types.all;
use work.measurements.all;
use work.events.all;
use work.registers.all;

entity measurement_framer6 is
generic(
  FRAMER_ADDRESS_BITS:integer:=11;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  measurements:in measurements_t;
  enable:in boolean; 
  mux_full:in boolean; 
  --signals to MUX
  start:out boolean;
  commit:out boolean;
  dump:out boolean;
  overflow:out boolean;
  error:out boolean;
  
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity measurement_framer6;

architecture RTL of measurement_framer6 is

--  
constant CHUNKS:integer:=BUS_CHUNKS;
constant DEPTH:integer:=3;

type write_buffer is array (DEPTH-1 downto 0) of streambus_t;
signal queue:write_buffer;
signal rd_ptr:integer range 0 to DEPTH-1:=0;
signal queue_full:boolean;

signal stream_int:streambus_t;
signal valid_int:boolean;

signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal pulse_peak:pulse_peak_t;

signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal framer_full:boolean;

attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full:signal is "no";

signal free_after_commit:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0):=(others => '0');

signal offset:unsigned(CHUNK_DATABITS-1 downto 0);
signal minima:signed(CHUNK_DATABITS-1 downto 0);
--
signal peak_time:unsigned(CHUNK_DATABITS-1 downto 0);

signal pulse_valid,single_valid,pulse_peak_valid:boolean;
signal pulse_overflow:boolean;
signal frame_word:streambus_t;
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame,start_int:boolean;
signal peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal area_overflow,peak_overflow:boolean;
signal pulse_started,pulse_error:boolean;
signal last_peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal thresh:signed(CHUNK_DATABITS-1 downto 0);

signal detection:detection_d;
  
--debugging
signal flags:std_logic_vector(7 downto 0);
signal pending:signed(3 downto 0):=(others => '0');
signal head:boolean;

attribute keep:string;
--attribute MARK_DEBUG:string;

constant DEBUG:string:="TRUE";

attribute keep of pending:signal is DEBUG;
attribute keep of flags:signal is DEBUG;
attribute keep of head:signal is DEBUG;
--attribute MARK_DEBUG of framer_full:signal is DEBUG;
--attribute MARK_DEBUG of framer_free:signal is DEBUG;
--attribute MARK_DEBUG of commit_frame:signal is DEBUG;
--attribute MARK_DEBUG of frame_we:signal is DEBUG;
--attribute MARK_DEBUG of frame_address:signal is DEBUG;
--attribute MARK_DEBUG of frame_length:signal is DEBUG;

begin
m <= measurements;
commit <= commit_frame;
flags <= stream_int.data(23 downto 16);
stream <= stream_int;
valid <= valid_int;
start <= start_int;

-- FIXME add timing threshold to the header in reserved spot
-----------------  pulse event - 16 byte header --------------------------------
--  | size |  reserved  |   flags  |   time   |  wr_en @ pulse end
--  |       area        |  length  |  offset  |        @ pulse end -1
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | minima | rise | time |                  @ maxima
--
--  | height | low1 |  low2  | time | -- use this for pulse2
                                      -- low2 is @ time
pulse.size <= m.size;
pulse.flags <= m.eflags;
pulse.length <= m.pulse_length;
pulse.offset <= offset;
pulse.area <= m.pulse_area;

pulse_peak.minima <= minima;
pulse_peak.timestamp <= peak_time;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.height <= m.height;

peak.height <= m.height;
peak.minima <= minima;
peak.flags <= m.eflags;

area.flags <= m.eflags;
area.area <= m.pulse_area;

queue_full <= pulse_valid and ((rd_ptr/=DEPTH-1) or pulse_peak_valid);
capture:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      start_int <= FALSE;
      dump <= FALSE;
      overflow <= FALSE;
      error <= FALSE;
      pulse_valid <= FALSE;
      pulse_peak_valid <= FALSE;
      pulse_error <= FALSE;
      single_valid <= FALSE; 
      frame_length <= (0 => '1', others => '0');
      pulse_overflow <= FALSE;
      area_overflow <= FALSE;
      pulse_started <= FALSE;
      if DEBUG="TRUE" then
        pending <= (others => '0');
      end if;
    else
      start_int <= FALSE;
      dump <= FALSE;
      overflow <= FALSE;
      error <= FALSE;
      commit_frame <= FALSE;
      frame_we <= (others => FALSE);
      --
      --DEBUGGING
      
      if DEBUG="TRUE" then
        if ready and valid_int then
          head <= stream_int.last(0);
        end if;
      end if;
      
      free_after_commit 
        <= framer_free - 16; --resize(m.pre2_size,FRAMER_ADDRESS_BITS) - 1;
      framer_full 
        <= free_after_commit <= resize(m.pre_size,FRAMER_ADDRESS_BITS); 
      
      if m.pre_peak_start then
        detection <= m.eflags.event_type.detection;
      end if;
      
      if m.peak_start then
        minima <= m.filtered.sample;
      end if;
      
      if pulse_valid then
        frame_word <= queue(rd_ptr);
        frame_we <= (others => TRUE);
        frame_address <= to_unsigned(rd_ptr,FRAMER_ADDRESS_BITS);
        if rd_ptr=DEPTH-1 then
          frame_we <= (0 => TRUE, others => FALSE);
          commit_frame <= TRUE; 
          pulse_valid <= FALSE;
          frame_address <=  last_peak_address;
          if DEBUG="TRUE" then
            if not start_int then
              pending <= pending-1; --commit
            end if;
          end if;
        else
          rd_ptr <= rd_ptr+1;
        end if;
      elsif pulse_peak_valid then
        frame_word <= queue(0);
        frame_address <= peak_address;
        frame_we <= (others => TRUE);
        pulse_peak_valid <= FALSE;
--        commit_frame <= TRUE;
      elsif single_valid then
        frame_word <= queue(0);
        frame_address <= (others => '0');
        frame_we <= (others => TRUE);
        single_valid <= FALSE;
        commit_frame <= TRUE;
      end if;
      
      case detection is
      when PULSE_DETECTION_D => 
        
        if m.pulse_threshold_neg and pulse_started then
          pulse_started <= FALSE;
          if m.above_area_threshold then
            if queue_full or pulse_error then
              error <= TRUE;
              dump <= TRUE;
              if DEBUG="TRUE" then
                pending <= pending-1;
              end if;
            else
              queue(0) <= to_streambus(pulse,0,ENDIAN);
              queue(1) <= to_streambus(pulse,1,ENDIAN);
              queue(2) <= to_streambus(pulse_peak,TRUE,ENDIAN);
              pulse_valid <= TRUE;
              frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
              rd_ptr <= 0;
            end if;
          else
            dump <= TRUE;
            if DEBUG="TRUE" then
              pending <= pending-1; --DUMP
            end if;
          end if;
        end if;
        
        if m.height_valid and not pulse_overflow then
          if queue_full then
            pulse_error <= TRUE;
          else
            queue(0) <= to_streambus(pulse_peak,FALSE,ENDIAN);
            peak_address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
            pulse_peak_valid <= pulse_started;
          end if;
        end if;
        
        if m.stamp_pulse and enable then
          pulse_started <= TRUE;
          pulse_error  <= FALSE;
          if not framer_full and not mux_full then
            last_peak_address 
              <= resize(m.last_peak_address,FRAMER_ADDRESS_BITS);
            offset <= m.pulse_time;
            start_int <= TRUE;
            pulse_overflow <= FALSE;  -- pulse_overflow means never started
            if DEBUG="TRUE" then
              pending <= pending+1;
            end if;
          else
            pulse_overflow <= TRUE;
            overflow <= framer_full;
          end if;
        end if;
        
        if m.stamp_peak then
          peak_time <= m.pulse_time;
          thresh  <= resize(m.timing_threshold,CHUNK_DATABITS);
        end if;
        
      when TRACE_DETECTION_D => --change to trace 
        frame_length <= (0 => '1', others => '0');
        
      when PEAK_DETECTION_D => -- FIXME will miss stamp at max
        frame_length <= (0 => '1', others => '0');
        if m.height_valid and not peak_overflow then
          queue(0) <= to_streambus(peak,ENDIAN);
          single_valid <= TRUE;
        end if;
        
        if m.stamp_peak and enable then 
          if not framer_full and not mux_full then
            start_int <= TRUE;
            peak_overflow <= FALSE;
          else
            peak_overflow <= TRUE;
            overflow <= framer_full;
            error <= mux_full;
          end if;
        end if;
        
      when AREA_DETECTION_D => 
        frame_length <= (0 => '1', others => '0');
        if m.stamp_pulse and enable then 
          if  framer_full and not mux_full then
            start_int <= TRUE;
            area_overflow <= FALSE;
          else
            overflow <= framer_full;
            area_overflow <= TRUE;
          end if;
        end if;
        
        if m.pulse_threshold_neg and not area_overflow then
          if m.above_area_threshold then
            queue(0) <= to_streambus(area,ENDIAN);
            single_valid <= TRUE;
          else
            dump <= TRUE;
          end if;
        end if;
        
      end case;
    end if;
  end if;
end process capture;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => CHUNKS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => frame_word,
  address => frame_address,
  chunk_we => frame_we,
  length => frame_length,
  commit => commit_frame,
  free => framer_free,
  stream => stream_int,
  valid => valid_int,
  ready => ready
);

end architecture RTL;
