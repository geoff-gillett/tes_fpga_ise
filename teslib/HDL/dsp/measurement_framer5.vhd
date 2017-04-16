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

entity measurement_framer5 is
generic(
  FRAMER_ADDRESS_BITS:integer:=11;
  ENDIAN:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  measurements:in measurements_t;
 
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
end entity measurement_framer5;

architecture RTL of measurement_framer5 is
  
constant CHUNKS:integer:=4;
 
signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal test:test_detection_t;
signal pulse_peak,pulse_peak_clear:pulse_peak_t;
signal pulse_peak_we:boolean_vector(CHUNKS-1 downto 0);

--signal height_mux:signal_t;
signal frame_commit,overflow_int:boolean;
signal frame_word,pulse_H1_word,pulse_H0_word:streambus_t;
signal test_H_word,test_high_word:streambus_t;
signal frame_we:boolean_vector(CHUNKS-1 downto 0);
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal clear_address:unsigned(PEAK_COUNT_BITS downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0);

signal framer_full:boolean;

signal mux_full_reg:boolean;
attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full_reg:signal is "no";

signal peak_we:boolean_vector(CHUNKS-1 downto 0);
signal area_we:boolean_vector(CHUNKS-1 downto 0);
signal dump_int:boolean;
signal error_int:boolean;
signal start_int:boolean;
signal filtered_reg:signed(DSP_BITS-1 downto 0);
signal minima:signal_t;

type pulseFSMstate is (
  IDLE_S,PEAK_S,AREA_S,PULSE_PEAK_S,PULSE_CLEAR_S,COMMIT_S,PULSE_HEADER_S,
  TEST_S,TEST_H_S
);
signal state:pulseFSMstate;
signal done,stamped:boolean;
signal free_after_commit:unsigned(FRAMER_ADDRESS_BITS downto 0);
  
begin
m <= measurements;
overflow <= overflow_int;
error <= error_int;
commit <= frame_commit;
start <= start_int;
dump <= dump_int;

pulse.flags <= m.eflags;
pulse.size <= m.size;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;

peak.height <= m.height; 
peak.minima <= m.filtered.sample;
peak.flags <= m.eflags;
peak_we(3) <= m.height_valid;
peak_we(2) <= m.peak_start;
peak_we(1) <= m.height_valid;
peak_we(0) <= m.peak_start;

area.flags <= m.eflags; 
area.area <= m.pulse_area;
area_we <= (others => m.pulse_threshold_neg);

pulse_peak.height <= m.height;                 
pulse_peak.minima <= m.filtered.sample;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.timestamp <= m.pulse_time;
pulse_peak_we(3) <= m.height_valid;
pulse_peak_we(2) <= m.peak_start;
pulse_peak_we(1) <= m.height_valid;
pulse_peak_we(0) <= m.stamp_peak;

pulse_peak_clear.height <= (others => '0');
pulse_peak_clear.minima <= (others => '0');
pulse_peak_clear.rise_time <= (others => '0');
pulse_peak_clear.timestamp <= (others => '0');

test.flags <= m.eflags;
test.high1 <= filtered_reg;
test.high2 <= m.filtered_long;
test.low1 <= filtered_reg;
test.low2 <= m.filtered_long;
test.high_threshold <= m.height_threshold;
test.low_threshold <= m.timing_threshold; --FIXME this should be pulse thresh 
test.rise_time <= m.rise_time; --write at commit
test.minima <= minima;
    
frame_commit <= state=COMMIT_S;
--cleared <= clear_address <= last_peak_address;
FSMtransition:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= IDLE_S;
    else
      --FIXME this could be an issue as the framer fills
      --want not framer_full to be accurate at minima
      --framer_free can only decrease after commit
      --This FSM needs to be cleaned up it should be possible to avoid errors
      --At least for peak and area
      mux_full_reg <= mux_full;
      
      free_after_commit <= framer_free - frame_length;
      if state=COMMIT_S then -- problem if commit and pulse/peak start
        framer_full <= free_after_commit < m.pre_size; --needs to be next size
      else
        framer_full <= framer_free < m.size; -- size changes at minima
      end if;
      
      filtered_reg <= m.filtered_long; 
      
      if m.eflags.event_type.detection=PEAK_DETECTION_D or 
         m.eflags.event_type.detection=TRACE_DETECTION_D then
         error_int <= m.peak_start and state/=IDLE_S;
         overflow_int <= m.peak_start and (framer_full or mux_full_reg);
      else
        error_int <= m.pulse_start and state/=IDLE_S;
        overflow_int <= m.pulse_start and (framer_full or mux_full_reg);
      end if;
      
      -- defaults
      start_int <= FALSE;
      dump_int <= FALSE;
      frame_address <= (others => '0');
      frame_we <= (others => FALSE);
 
      --FIXME clear when IDLE? 
      case state is 
      when IDLE_S => 
        case m.eflags.event_type.detection is
        when PEAK_DETECTION_D => 
          if m.peak_start and not (framer_full or mux_full_reg) then
            state <= PEAK_S;
            frame_word <= to_streambus(peak,ENDIAN);
            frame_we <= peak_we;
            start_int <= m.stamp_peak;
            frame_length <= (0 => '1', others => '0');
          end if;
        when AREA_DETECTION_D =>
          if m.pulse_start and not (framer_full or mux_full_reg) then
            state <= AREA_S;
            frame_word <= to_streambus(area,ENDIAN);
            frame_we <= area_we;
            start_int <= m.stamp_pulse;
            frame_length <= (0 => '1', others => '0');
          end if;
        when PULSE_DETECTION_D =>
          -- first write the peak then the headers
          -- FIXME see if wait states can be removed
          if m.pulse_start and not (framer_full or mux_full_reg) then
            state <= PULSE_PEAK_S;
            frame_word <= to_streambus(pulse_peak,m.last_peak,ENDIAN);
            frame_we <= pulse_peak_we;
            frame_address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
            start_int <= m.stamp_pulse;
            clear_address <= m.last_peak_address; 
            frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
            done <= FALSE;
            stamped <= m.stamp_pulse;
          end if;
        when TRACE_DETECTION_D =>
          if m.peak_start and not (framer_full or mux_full_reg) then
            state <= TEST_S;
            frame_address <= (0 => '1', others => '0');
            frame_word <= to_streambus(test,1,ENDIAN);
            frame_we <= (others => m.stamp_peak);
            start_int <= m.stamp_peak;
            frame_length <= (1 downto 0 => '1', others => '0');
            stamped <= m.stamp_peak;
            done <= FALSE;
            minima <= m.filtered.sample;
          end if;
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
        if m.stamp_pulse then
          stamped <= TRUE;
        end if;
        
        if m.height_valid and m.last_peak then
          state <= PULSE_HEADER_S;
          done <= FALSE;
        elsif m.pulse_threshold_neg then -- should not occur when height valid
          pulse_H1_word <= to_streambus(pulse,1,ENDIAN);
          pulse_H0_word <= to_streambus(pulse,0,ENDIAN);
          done <= TRUE;
          if m.above_area_threshold then
            if clear_address < m.peak_address then --cleared
              state <= PULSE_HEADER_S;
              frame_word <= to_streambus(pulse,0,ENDIAN);
              frame_we <= (others => TRUE);
              frame_address <= (others => '0');
            else
              state <= PULSE_CLEAR_S;
              frame_word <= to_streambus(pulse_peak_clear,TRUE,ENDIAN);
              frame_we <= (others => TRUE);
              frame_address <= resize(clear_address, FRAMER_ADDRESS_BITS);
              clear_address <= clear_address-1;
            end if;
          else
            state <= IDLE_S;
            dump_int <= TRUE;
          end if;
        end if;
        
      when PULSE_CLEAR_S =>
        
        if m.pulse_threshold_neg then
          pulse_H1_word <= to_streambus(pulse,1,ENDIAN);
          pulse_H0_word <= to_streambus(pulse,0,ENDIAN);
          done <= TRUE;
          if m.above_area_threshold then
            state <= PULSE_HEADER_S;
            frame_word <= to_streambus(pulse,0,ENDIAN);
            frame_we <= (others => TRUE);
            frame_address <= (others => '0');
          else
            state <= IDLE_S;
            dump_int <= TRUE;
          end if;
        elsif done then
          state <= PULSE_HEADER_S;
          frame_word <= pulse_H0_word;
          frame_we <= (others => TRUE);
          frame_address <= (others => '0');
        end if;
        
        if not (clear_address < m.peak_address) then
          frame_address <= resize(clear_address, FRAMER_ADDRESS_BITS);
          clear_address <= clear_address-1;
          frame_word <= to_streambus(pulse_peak_clear,FALSE,ENDIAN);
          frame_we <= (others => TRUE);
          state <= PULSE_CLEAR_S;
        end if;
          
      when PULSE_HEADER_S => 
        if m.pulse_threshold_neg then
          pulse_H1_word <= to_streambus(pulse,1,ENDIAN);
          if m.above_area_threshold then
            done <= TRUE;
            state <= PULSE_HEADER_S;
            frame_word <= to_streambus(pulse,0,ENDIAN);
            frame_we <= (others => TRUE);
            frame_address <= (others => '0');
          else
            state <= IDLE_S;
            dump_int <= TRUE;
          end if;
        elsif done then
          state <= COMMIT_S;
          frame_address <= (0 => '1',others => '0');
          frame_we <= (others => TRUE);
          frame_word <= pulse_H1_word;
        end if;
        
      when TEST_S => 
        -- handle simultaneous stamp and height valid
        if m.height_valid then
          test_H_word <= to_streambus(test,0,ENDIAN);
          test_high_word <= to_streambus(test,2,ENDIAN);
          done <= TRUE;
          if stamped then
            state <= TEST_H_S;
            frame_word <= to_streambus(test,2,ENDIAN);
            frame_we <= (others => TRUE);
            frame_address <= (1 => '1', others => '0');
          end if;
        end if;
        if m.stamp_peak then
          if stamped then
            dump_int <= TRUE;
            error_int <= TRUE;
            state <= IDLE_S;
          else
            frame_word <= to_streambus(test,1,ENDIAN);
            frame_we <= (others => TRUE);
            start_int <= TRUE;
            frame_address <= (0 => '1', others => '0');
            stamped <= TRUE;
          end if;
          if done then
            state <= TEST_H_S;
            frame_word <= test_high_word;
            frame_we <= (others => TRUE);
            frame_address <= (1 => '1', others => '0');
          end if;
        end if;
        
      when TEST_H_S => 
        state <= COMMIT_S;
        frame_word <= test_H_word;
        frame_we <= (others => TRUE);
        frame_address <= (others => '0');
      when COMMIT_S =>
        state <= IDLE_S;
      end case;
    end if;
  end if;
end process FSMtransition;

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
