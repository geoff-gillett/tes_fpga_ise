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
 
signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse,pulse_reg:pulse_detection_t;
signal pulse_peak,pulse_peak_clear:pulse_peak_t;
signal pulse_peak_we,pulse_peak_we_reg:boolean_vector(CHUNKS-1 downto 0);

--signal height_mux:signal_t;
signal frame_commit,overflow_int:boolean;
signal frame_word,pulse_H1_word,pulse_H0_word:streambus_t;
signal frame_we:boolean_vector(CHUNKS-1 downto 0);
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal clear_address:unsigned(PEAK_COUNT_BITS downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0);

signal framer_full,cleared:boolean;
--signal height:signal_t;
--signal height_valid:boolean;
--signal rise_time:unsigned(TIME_BITS-1 downto 0);
--signal stamp_peak:boolean;
--signal minima:signal_t;

signal peak_we:boolean_vector(CHUNKS-1 downto 0);
signal pulse_h0_we,pulse_h1_we:boolean_vector(CHUNKS-1 downto 0);
signal pulse_h0_we_reg,pulse_h1_we_reg:boolean_vector(CHUNKS-1 downto 0);
signal area_we:boolean_vector(CHUNKS-1 downto 0);
signal dump_int:boolean;
signal lost:boolean;
signal start_int:boolean;

type pulseFSMstate is (
  IDLE_S,PEAK_S,AREA_S,PULSE_PEAK_S,PULSE_CLEAR_S,COMMIT_S,PULSE_HEADER_S
);
signal state:pulseFSMstate;
signal pulse_done:boolean;
signal last_peak_address : unsigned(PEAK_COUNT_BITS downto 0);
  
begin
m <= measurements;
overflow <= overflow_int;
error <= lost;
commit <= frame_commit;
start <= start_int;
dump <= dump_int;

pulse.flags <= m.eflags;
pulse.size <= m.size;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;

peak.height <= m.height; 
peak.rise_time <= m.rise_time;
peak.flags <= m.eflags;
peak_we(3) <= m.height_valid;
peak_we(2) <= m.height_valid;
peak_we(1) <= m.peak_start;
peak_we(0) <= m.peak_start;

area.flags <= m.eflags; 
area.area <= m.pulse_area;
area_we <= (others => m.pulse_threshold_neg);

framer_full <= framer_free < m.size;

pulse_peak.height <= m.height;                 
pulse_peak.minima <= m.filtered.sample;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.timestamp <= m.pulse_time;
pulse_peak_we(3) <= m.height_valid;
pulse_peak_we(2) <= m.height_valid;
pulse_peak_we(1) <= m.peak_start;
pulse_peak_we(0) <= m.stamp_peak;

pulse_peak_clear.height <= (others => '0');
pulse_peak_clear.minima <= (others => '0');
pulse_peak_clear.rise_time <= (others => '0');
pulse_peak_clear.timestamp <= (others => '0');
    
frame_commit <= state=COMMIT_S;
cleared <= clear_address <= last_peak_address;
pulseTransition:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= IDLE_S;
    else
      
      
      pulse_reg <= pulse;
      pulse_peak_we_reg <= pulse_peak_we;
      pulse_h0_we_reg <= pulse_h0_we;
      pulse_h1_we_reg <= pulse_h1_we;
      
      
      if m.eflags.event_type.detection=PEAK_DETECTION_D then
        lost <= m.peak_start and (state/=IDLE_S or framer_full);
      else
        lost <= m.pulse_start and (state/=IDLE_S or framer_full);
      end if;
      
      -- defaults
      start_int <= FALSE;
      dump_int <= FALSE;
      --frame_commit <= FALSE;
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
            frame_length <= (0 => '1', others => '0');
          end if;
        when AREA_DETECTION_D =>
          if m.pulse_start and not framer_full then
            state <= AREA_S;
            frame_word <= to_streambus(area,ENDIAN);
            frame_we <= area_we;
            start_int <= m.stamp_pulse;
            frame_length <= (0 => '1', others => '0');
          end if;
        when PULSE_DETECTION_D =>
          -- first write the peak then the headers
          -- FIXME see if wait states can be removed
          if m.pulse_start then
            state <= PULSE_PEAK_S;
            frame_word <= to_streambus(pulse_peak,m.last_peak,ENDIAN);
            frame_we <= pulse_peak_we;
            frame_address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
            start_int <= m.stamp_pulse;
            clear_address <= m.last_peak_address; 
            last_peak_address <= (others  => '0');
            frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
            pulse_done <= FALSE;
          end if;
        when TEST_DETECTION_D =>
          null;
        end case;
          
      when PEAK_S =>
        if m.slope.neg_0xing and m.valid_peak then
          state <= COMMIT_S;
        end if;
        frame_word <= to_streambus(peak,ENDIAN);
        frame_we <= peak_we;
        start_int <= m.stamp_peak;
        
      when AREA_S =>
        if m.pulse_threshold_neg and m.valid_peak then
          if m.above_area_threshold then
            state <= COMMIT_S;
          else
            dump_int <= TRUE;
            state <= IDLE_S;
          end if;
        end if;
        frame_word <= to_streambus(peak,ENDIAN);
        frame_we <= peak_we;
        start_int <= m.stamp_peak;
        
      when PULSE_PEAK_S =>
        frame_word <= to_streambus(pulse_peak,m.last_peak,ENDIAN);
        frame_we <= pulse_peak_we;
        frame_address <= resize(m.peak_address,FRAMER_ADDRESS_BITS); 
        start_int <= m.stamp_pulse;
        if m.height_valid and m.last_peak then
          state <= PULSE_HEADER_S;
          pulse_done <= FALSE;
        elsif m.pulse_threshold_neg then -- should not occur when height valid
          pulse_H1_word <= to_streambus(pulse,1,ENDIAN);
          pulse_H0_word <= to_streambus(pulse,0,ENDIAN);
          if m.above_area_threshold then
            pulse_done <= TRUE;
            if cleared then
              state <= PULSE_HEADER_S;
              frame_word <= to_streambus(pulse,0,ENDIAN);
              frame_we <= (others => TRUE);
              frame_address <= (others => '0');
            else
              state <= PULSE_CLEAR_S;
              frame_word <= to_streambus(pulse_peak_clear,TRUE,ENDIAN);
              frame_we <= (others => TRUE);
              frame_address <= resize(clear_address, FRAMER_ADDRESS_BITS);
            end if;
          else
            state <= IDLE_S;
            dump_int <= TRUE;
          end if;
        end if;
        
      when PULSE_CLEAR_S =>
        if clear_address > m.last_peak_address then
          frame_address <= resize(clear_address, FRAMER_ADDRESS_BITS);
          clear_address <= clear_address-1;
          frame_word <= to_streambus(pulse_peak_clear,FALSE,ENDIAN);
          frame_we <= (others => TRUE);
        elsif m.pulse_threshold_neg then
          pulse_H1_word <= to_streambus(pulse,1,ENDIAN);
          pulse_H0_word <= to_streambus(pulse,0,ENDIAN);
          if m.above_area_threshold then
            pulse_done <= TRUE;
            state <= PULSE_HEADER_S;
            frame_word <= to_streambus(pulse,0,ENDIAN);
            frame_we <= (others => TRUE);
            frame_address <= (others => '0');
          else
            state <= IDLE_S;
            dump_int <= TRUE;
          end if;
        elsif pulse_done then
          state <= PULSE_HEADER_S;
          frame_word <= pulse_H0_word;
          frame_we <= (others => TRUE);
          frame_address <= (others => '0');
        end if;
          
      when PULSE_HEADER_S => 
        if m.pulse_threshold_neg then
          pulse_H1_word <= to_streambus(pulse,1,ENDIAN);
          if m.above_area_threshold then
            pulse_done <= TRUE;
            state <= PULSE_HEADER_S;
            frame_word <= to_streambus(pulse,0,ENDIAN);
            frame_we <= (others => TRUE);
            frame_address <= (others => '0');
          else
            state <= IDLE_S;
            dump_int <= TRUE;
          end if;
        elsif pulse_done then
          state <= COMMIT_S;
          frame_address <= (0 => '1',others => '0');
          frame_we <= (others => TRUE);
          frame_word <= pulse_H1_word;
        end if;
        
        
      when COMMIT_S =>
          state <= IDLE_S;
      end case;
      
    end if;
  end if;
end process pulseTransition;


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
