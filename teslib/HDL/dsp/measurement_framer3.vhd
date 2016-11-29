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

entity measurement_framer3 is
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
end entity measurement_framer3;

architecture RTL of measurement_framer3 is
  
constant CHUNKS:integer:=4;
 
signal m,m_reg:measurements_t;
signal peak,peak_reg:peak_detection_t;
signal area,area_reg:area_detection_t;
signal pulse,pulse_reg:pulse_detection_t;
signal pulse_peak,pulse_peak_reg:pulse_peak_t;
signal pulse_peak_we,pulse_peak_we_reg:boolean_vector(CHUNKS-1 downto 0);
signal we_reg:boolean_vector(CHUNKS-1 downto 0);

--signal height_mux:signal_t;
signal started,commit_event,frame_commit,overflow_int,error_int:boolean;
signal frame_word,next_word:streambus_t;
signal frame_we:boolean_vector(CHUNKS-1 downto 0);
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_address,clear_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
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


signal peak_we,peak_we_reg:boolean_vector(CHUNKS-1 downto 0);
signal pulse_h0_we,pulse_h1_we:boolean_vector(CHUNKS-1 downto 0);
signal pulse_h0_we_reg,pulse_h1_we_reg:boolean_vector(CHUNKS-1 downto 0);
signal area_we,next_we:boolean_vector(CHUNKS-1 downto 0);
signal overflowed : boolean;
signal valid_max : boolean;
signal full,dump_int,busy:boolean;
signal free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal next_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal lost:boolean;
signal stamp:boolean;
signal next_length:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal start_int : boolean;

type pulseFSMstate is (
  IDLE_S,PEAK_S,AREA_S,PULSE_IDLE_S,PULSE_PEAK_S,PULSE_H1_S,PULSE_H0_S,
  PULSE_CLEAR,COMMIT_S
);
signal state,nextstate:pulseFSMstate;

  
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
commit <= frame_commit;
start <= start_int;
dump <= dump_int;


pulse_peak.height <= m.height;
pulse_peak.minima <= m.filtered.sample;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.timestamp <= m.pulse_time;

pulse_peak_we(0) <= m.stamp_peak;
pulse_peak_we(1) <= m.height_valid;
pulse_peak_we(2) <= m.peak_start;
pulse_peak_we(3) <= m.height_valid;

pulse_h0_we(0) <= m.pulse_start;
pulse_h0_we(1) <= m.height_valid;
pulse_h0_we(2) <= m.pulse_start;
pulse_h0_we(3) <= m.pulse_start;

pulse_h1_we(0) <= m.pulse_threshold_neg; 
pulse_h1_we(1) <= m.pulse_threshold_neg;
pulse_h1_we(2) <= m.pulse_threshold_neg;
pulse_h1_we(3) <= m.pulse_threshold_neg;

pulse.flags <= m.eflags;
pulse.size <= m.size;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;

peak.height <= m.height; 
peak.rise_time <= m.rise_time;
peak.flags <= m.eflags;

--peak_reg.height <= m_reg.height; 
--peak_reg.rise_time <= m_reg.rise_time;
--peak_reg.flags <= m_reg.eflags;

peak_we(3) <= m.height_valid;
peak_we(2) <= m.height_valid;
peak_we(1) <= m.peak_start;
peak_we(0) <= m.peak_start;

peak_we_reg(3) <= m_reg.height_valid;
peak_we_reg(2) <= m_reg.height_valid;
peak_we_reg(1) <= m_reg.peak_start;
peak_we_reg(0) <= m_reg.peak_start;

area.flags <= m.eflags; 
area.area <= m.pulse_area;
area_we <= (others => m.pulse_threshold_neg);

--FIXME there is an issue here when the commit is registered because
--the framer could go full after commit, and framer_full will still be FALSE
--for one clock
--cheap fix use busy signal 

framer_full <= framer_free < m.size;


--FSMreg:process (clk) is
--begin
--  if rising_edge(clk) then
--    if reset = '1' then
--      state <= IDLE_S;
--    else
--      state <= nextstate;
--      
--      
--    end if;
--  end if;
--end process FSMreg;
frame_commit <= state=COMMIT_S;
pulseTransition:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= IDLE_S;
    else
      
      m_reg <= m;
      
      
      
      
      pulse_reg <= pulse;
      pulse_peak_we_reg <= pulse_peak_we;
      pulse_h0_we_reg <= pulse_h0_we;
      pulse_h1_we_reg <= pulse_h1_we;
      
      
      
      lost <= (m.peak_start or m.pulse_start) and (state/=IDLE_S or framer_full);
      
      -- defaults
      start_int <= FALSE;
      dump_int <= FALSE;
      --frame_commit <= FALSE;
      frame_length <= (0 => '1', others => '0');
      frame_address <= (others => '0');
      frame_we <= (others => FALSE);
  
  
      case state is 
      when IDLE_S => 
        case m.eflags.event_type.detection is
        when PEAK_DETECTION_D => 
          if m.peak_start and not framer_full then
            state <= PEAK_S;
            frame_word <= to_streambus(peak,ENDIAN);
            frame_we <= peak_we;
            start_int <= m.stamp_peak;
          end if;
        when AREA_DETECTION_D =>
          if m.pulse_start and not framer_full then
            state <= AREA_S;
          end if;
        when PULSE_DETECTION_D =>
          if m.pulse_start then
            state <= PULSE_PEAK_S;
          end if;
        when TEST_DETECTION_D =>
          null;
        end case;
          
      when PULSE_IDLE_S =>
        if m.pulse_start and m.eflags.event_type.detection=PULSE_DETECTION_D then
          nextstate <= PULSE_H0_S;
          next_we <= pulse_H0_we;
        end if;
        when PULSE_H0_S =>
          next_address <= (others  => '0');
          if unaryOr(pulse_peak_we_reg) then
            nextstate <= PULSE_PEAK_S;
            next_we <= pulse_peak_we_reg;
          elsif unaryOr(pulse_peak_we) then
            nextstate <= PULSE_PEAK_S;
            next_we <= pulse_peak_we;
          else
            if clear_address < m.peak_address then 
              nextstate <= PULSE_CLEAR;
            end if;
          end if;
        when PULSE_PEAK_S =>
          next_address <= (others  => '0');
          if unaryOr(pulse_peak_we_reg) then
            nextstate <= PULSE_PEAK_S;
            next_we <= pulse_peak_we_reg;
          elsif unaryOr(pulse_peak_we) then
            nextstate <= PULSE_PEAK_S;
            next_we <= pulse_peak_we;
          else
            if clear_address < m.peak_address then 
              nextstate <= PULSE_CLEAR;
            end if;
          end if;
        when PULSE_H1_S =>
          null;
        when PEAK_S =>
          if m.slope.neg_0xing and m.valid_peak then
            state <= COMMIT_S;
          end if;
          frame_word <= to_streambus(peak,ENDIAN);
          frame_we <= peak_we;
          start_int <= m.stamp_peak;
        when AREA_S =>
          null;
        when PULSE_CLEAR =>
          null;
        when COMMIT_S =>
          state <= IDLE_S;
      end case;
      
    end if;
  end if;
end process pulseTransition;



--valid_max <= m.slope.neg_0xing and m.valid_peak;
--framing:process(clk)
--begin
--  if rising_edge(clk) then
--    if reset = '1' then
--      start <= FALSE;
--      commit_event <= FALSE;
--      pulse_started <= FALSE;
--    else
--      
--      start <= FALSE;
--      commit_event <= FALSE;
--      dump_int <= FALSE;
--      overflow_int <= FALSE;
----      error_int <= FALSE;
----      frame_we <= (others => FALSE);
----      address <= m.peak_address;
--      frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
--     
--      case m.eflags.event_type.detection is
--      when PEAK_DETECTION_D => 
--        -- never needs dumping
--        start <= m.stamp_peak and not framer_full;
--        frame_word <= to_streambus(peak,ENDIAN);
--        frame_we <= peak_we;
--        address <= (others => '0');
--        if m.peak_start then 
--          if framer_full then --this always is at the minima
--            overflowed <= TRUE;
--            overflow_int <= TRUE;
--          else
--            overflowed <= FALSE;
--          end if;
--        end if;
--        if (valid_max and not overflowed) or (valid_max and m.peak_start) then
--          commit_event <= TRUE;
--        end if;
--        
--      when AREA_DETECTION_D => 
--        start <= m.stamp_pulse and not framer_full;
--        frame_word <= to_streambus(area,ENDIAN);
--        frame_we <= area_we;
--        address <= (others => '0');
--        if m.pulse_start then 
--          if framer_full then --this always is at the minima
--            overflowed <= TRUE;
--            overflow_int <= TRUE;
--          else
--            overflowed <= FALSE;
--          end if;
--        end if;
--        if (m.pulse_threshold_neg and not overflowed) then
--          if m.above_area_threshold then 
--            commit_event <= TRUE;
--          else
--            dump_int <= TRUE;
--          end if;
--        end if;
--        null;
--      
--      when PULSE_DETECTION_D => 
-------------------  pulse event - 16 byte header --------------------------------
---- w=0 | size | reserved |   flags  |   time   |
---- w=1 |      area       |  length  |  offset  |  
----  repeating 8 byte peak records (up to 16) for extra peaks.
----  | height | minima | rise | time | 
---- w=1 must be written at pulse_threshold_neg flags when?
---- minima will be valid at pulse_start, save and write at height_valid?
---- peak time written at stamp_peak
---- need to clear unused peaks
---- how do I handle simultaneous writes to different words? two deep FIFO?
---- 
--
--
--        
--      when others => null; --FIXME add others
--      end case;
--      
--      
--    end if;
--  end if;
--end process framing;

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
  commit => frame_commit,
  free => framer_free,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
