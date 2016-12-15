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

entity measurement_framer2 is
generic(
  FRAMER_ADDRESS_BITS:integer:=11;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  measurements:in measurements_t;
  
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
end entity measurement_framer2;

architecture RTL of measurement_framer2 is
  
constant CHUNKS:integer:=4;
 
signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal pulse_peak_we:boolean_vector(CHUNKS-1 downto 0);

--signal height_mux:signal_t;
signal started,commit_event,overflow_int,error_int:boolean;
signal frame_word:streambus_t;
signal frame_we:boolean_vector(CHUNKS-1 downto 0);
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal address,clear_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0);

signal dumped,framer_full,cleared,clear_last,pulse_started:boolean;
signal height:signal_t;
signal height_addr,stamp_peak_addr:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal height_valid:boolean;
signal rise_time,peak_timestamp:unsigned(TIME_BITS-1 downto 0);
signal stamp_peak:boolean;
signal minima:signal_t;
signal flags:detection_flags_t;
signal size:unsigned(SIZE_BITS-1 downto 0);
signal pulse_start,pulse_end,stamp_pulse:boolean;
signal pulse_length,pulse_offset:unsigned(TIME_BITS-1 downto 0);
signal pulse_area:area_t;
signal clear_addr :unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal max,last_peak:boolean;
signal stamp_peak_ovfl:boolean;
signal has_armed,above_area_threshold:boolean;
signal clear_address_m1:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal above_pulse_threshold:boolean;
signal armed:boolean;

signal peak_we:boolean_vector(CHUNKS-1 downto 0);
signal area_we:boolean_vector(CHUNKS-1 downto 0);
signal overflowed : boolean;
signal valid_max : boolean;
  
--constant DEBUG:string:="FALSE";
--attribute MARK_DEBUG:string;
--attribute MARK_DEBUG of height:signal is DEBUG;
--attribute MARK_DEBUG of rise_time:signal is DEBUG;
--attribute MARK_DEBUG of commit_event:signal is DEBUG;
--attribute MARK_DEBUG of above_pulse_threshold:signal is DEBUG;
--attribute MARK_DEBUG of armed:signal is DEBUG;

begin
m <= measurements;
overflow <= overflow_int;
error <= error_int;

--dataReg:process(clk)
--begin
--  if rising_edge(clk) then
--    if reset = '1' then
--      pulse_peak_we <= (others => FALSE); 
--    else
--      
--      framer_full <= framer_free < m.size;
--      
--      --height_valid <= m.height_valid and m.valid_peak;
--      if m.height_valid then --pulse_peak_we 0,2
--        height <= m.height;
--        rise_time <= m.rise_time;
--        height_addr <= m.peak_address;
--        above_pulse_threshold <= m.above_pulse_threshold;
--        armed <= m.armed;
--      end if;
--      
--      stamp_peak <= m.stamp_peak and m.valid_peak and enable;
--      if m.stamp_peak then --pulse_peak_we 1,3
--        stamp_peak_addr <= m.peak_address;
--        minima <= m.filtered.sample;
--        peak_timestamp <= m.pulse_time;
--        last_peak <= m.last_peak;
--      end if;
--      
--      pulse_start <= m.pulse_start and m.valid_peak;
--      if m.pulse_start then
--        flags.channel <= m.eflags.channel;
--        flags.event_type <= m.eflags.event_type;
--        flags.height <= m.eflags.height;
--        flags.new_window <= m.eflags.new_window;
--        flags.peak_overflow <= m.eflags.peak_overflow;
--        flags.timing <= m.eflags.timing;
--        size <= m.size;
--        clear_addr <= m.last_address;
--      end if;
--      
--      stamp_pulse <= m.stamp_pulse and m.valid_peak and enable; 
--      
--      max <=  m.slope.neg_0xing;
--      flags.peak_number <= m.eflags.peak_number;
--      
--      pulse_end <= m.pulse_threshold_neg;
--      if m.pulse_threshold_neg then
--        pulse_length <= m.pulse_length;
--        pulse_offset <= m.time_offset;
--        pulse_area <= m.pulse_area;
--        has_armed <= m.has_armed;
--        above_area_threshold <= m.above_area_threshold;
--      end if;
--      
--    end if;
--  end if;
--end process dataReg;

pulse_peak.height <= m.height;
pulse_peak.minima <= m.filtered.sample;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.timestamp <= m.pulse_time;

pulse.flags <= m.eflags;
pulse.size <= m.size;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;

peak.height <= m.height; 
peak.minima <= m.rise_time;
peak.flags <= m.eflags;

peak_we(3) <= m.height_valid;
peak_we(2) <= m.height_valid;
peak_we(1) <= m.peak_start;
peak_we(0) <= m.peak_start;

area.flags <= m.eflags; 
area.area <= m.pulse_area;
area_we <= (others => m.pulse_threshold_neg);

--FIXME there is an issue here when the commit is registered because
--the framer could go full after commit, and framer_full will still be FALSE
-- for one clock

framer_full <= framer_free < m.size;
commit <= commit_event;

valid_max <= m.slope.neg_0xing and m.valid_peak;
framing:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      start <= FALSE;
      commit_event <= FALSE;
      pulse_started <= FALSE;
    else
      
      start <= FALSE;
      commit_event <= FALSE;
      dump <= FALSE;
      overflow_int <= FALSE;
--      error_int <= FALSE;
--      frame_we <= (others => FALSE);
--      address <= m.peak_address;
      frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
     
      case m.eflags.event_type.detection is
      when PEAK_DETECTION_D => 
        -- never needs dumping
        start <= m.stamp_peak and not framer_full;
        frame_word <= to_streambus(peak,ENDIAN);
        frame_we <= peak_we;
        address <= (others => '0');
        if m.peak_start then 
          if framer_full then --this always is at the minima
            overflowed <= TRUE;
            overflow_int <= TRUE;
          else
            overflowed <= FALSE;
          end if;
        end if;
        if (valid_max and not overflowed) or (valid_max and m.peak_start) then
          commit_event <= TRUE;
        end if;
        
      when AREA_DETECTION_D => 
        start <= m.stamp_pulse and not framer_full;
        frame_word <= to_streambus(area,ENDIAN);
        frame_we <= area_we;
        address <= (others => '0');
        if m.pulse_start then 
          if framer_full then --this always is at the minima
            overflowed <= TRUE;
            overflow_int <= TRUE;
          else
            overflowed <= FALSE;
          end if;
        end if;
        if (m.pulse_threshold_neg and not overflowed) then
          if m.above_area_threshold then 
            commit_event <= TRUE;
          else
            dump <= TRUE;
          end if;
        end if;
        null;
      
      when PULSE_DETECTION_D => 
-----------------  pulse event - 16 byte header --------------------------------
-- w=0 | size | reserved |   flags  |   time   |
-- w=1 |      area       |  length  |  offset  |  
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | minima | rise | time | 
-- w=1 must be written at pulse_threshold_neg flags when?
-- minima will be valid at pulse_start, save and write at height_valid?
-- peak time written at stamp_peak
-- need to clear unused peaks
-- how do I handle simultaneous writes to different words? two deep FIFO?
-- 


        
      when others => null; --FIXME add others
      end case;
      
--      if m.eflags.event_type.detection = PEAK_DETECTION_D then
--        
--        if m.stamp_peak then
--          if framer_full then
--          else
--            start <= TRUE;
--            started <= TRUE;
--          end if;
--        end if;
--        --what if 
--        commit_event <= (started or m.stamp_peak) and m.slope.neg_0xing;
--        
--        if m.slope.neg_0xing then 
--          started <= FALSE;
--          commit_event <= TRUE;
--          --if m.armed and m.above_pulse_threshold and not framer_full and
--          if armed and above_pulse_threshold and not framer_full and
--             (started or stamp_peak) then
--            commit_event <= TRUE; 
--          else
--            overflow_int <= framer_full;
--            dump <= started or (stamp_peak and not framer_full);
--          end if;
--        end if;
--        
--        if height_valid then
--          if framer_full then
--            overflow_int <= TRUE;
--            dump <= started or stamp_peak;
--          else
--            frame_we <= (others => TRUE);
--          end if;
--        end if;
--      end if;
--     
--      if m.eflags.event_type.detection = AREA_DETECTION_D then
--        if stamp_pulse then
--          if framer_full then
--            overflow_int <= TRUE;
--          else
--            start <= TRUE;
--            started <= TRUE;
--          end if;
--        end if;
--        
--        frame_word <= to_streambus(area,ENDIAN);
--        if pulse_end then 
--          started <= FALSE;
--          if m.has_armed and m.above_area_threshold and not framer_full then
--            commit_event <= TRUE; 
--            frame_we <= (others => TRUE);
--          else
--            overflow_int <= framer_full;
--            dump <= started or (stamp_pulse and not framer_full);
--          end if;
--        end if;
--      end if;
--     
--      --TODO this could be improved 
--      if m.eflags.event_type.detection = PULSE_DETECTION_D then
--        if stamp_pulse and not dumped then
--          if framer_full then
--            overflow_int <= TRUE;
--          else
--            start <= TRUE;
--            started <= TRUE;
--          end if;
--        end if;
--        
--        --header0 can't be dumped yet
--        if pulse_start then
--          clear_address <= clear_addr;
--          clear_address_m1 <= clear_addr-1;
--          cleared <= FALSE;
--          clear_last <= TRUE;
--          
--          if framer_full then
--            overflow_int <= TRUE;
--            dumped <= TRUE;
--            dump <= started or (stamp_pulse and not dumped);
--            pulse_started <= FALSE;
--          else
--            pulse_started <= TRUE;
--            address <= (others => '0');
--            frame_word <= to_streambus(pulse,0,ENDIAN);
--            frame_we <= (others => TRUE);
--            stamp_peak_ovfl <= stamp_peak;
--          end if;
--        end if;
--        
--        --header1
--        if pulse_end then 
--          dumped <= FALSE;
--          started <= FALSE;
--          pulse_started <= FALSE;
--        end if;
--        
--        -- Assumes height_valid can't fire at same time as pulse_threshold_neg 
--        -- but this means pulse reg can which is a problem
--        if pulse_end and pulse_started then 
--          
--          --framer can't be full if pulse_started true
--          if has_armed and above_area_threshold and not dumped then
--            
--            if cleared then
--              address <= (0 => '1',others => '0');
--              frame_word <= to_streambus(pulse,1,ENDIAN);
--              frame_we <= (others => TRUE);
--              commit_event <= TRUE; 
--            else
--              error_int <= TRUE;
--              dump <= started or stamp_pulse;
--            end if;
--          else
--            dump <= started or stamp_pulse;
--          end if;
--        elsif stamp_peak and pulse_started then -- 3 must be set too
--          address <= stamp_peak_addr;
--          frame_we <= (FALSE,TRUE,FALSE,TRUE);
--          frame_word <= to_streambus(pulse_peak,last_peak,ENDIAN);
--        elsif height_valid and pulse_started then -- 2 must be set too
--          address <= height_addr; 
--          frame_we <= (TRUE,FALSE,TRUE,FALSE);
--          frame_word <= to_streambus(pulse_peak,last_peak,ENDIAN);
--        elsif not cleared and pulse_started then
--          address <= clear_address;
--          clear_address <= clear_address_m1;
--          clear_address_m1 <= clear_address_m1-1;
--          cleared <= clear_address_m1 < m.peak_address;
--          frame_word.data <= (others => '-');
--          frame_word.last <= (0 => clear_last, others => FALSE);
--          frame_word.discard <= (others => FALSE);
--          frame_we <= (others => TRUE);
--          clear_last <= FALSE;
--        end if;
--      end if;
      
    end if;
  end if;
end process framing;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => CHUNKS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => frame_word,
  address => address,
  chunk_we => frame_we,
  length => frame_length,
  commit => commit_event,
  free => framer_free,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
