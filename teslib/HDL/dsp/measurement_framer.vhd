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

entity measurement_framer is
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
end entity measurement_framer;

architecture RTL of measurement_framer is
  
constant CHUNKS:integer:=4;
 
signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal pulse_peak,pulse_p_reg:pulse_peak_t;
signal pulse_peak_we,pulse_p_we_reg:boolean_vector(CHUNKS-1 downto 0);

signal height:signal_t;
signal started,commit_frame,overflow_int,error_int:boolean;
signal frame_word:streambus_t;
signal frame_we:boolean_vector(CHUNKS-1 downto 0);
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal address,clear_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0);

signal dumped,framer_full,cleared,clear_last,pulse_started:boolean;
signal pulse_p_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
  
begin
m <= measurements;
overflow <= overflow_int;
error <= error_int;

--TODO move this into measure.vhd?
height_mux:process(m.filtered.sample,
  m.slope.area(15 downto 0), m.slope.extrema(15 downto 0),
  m.eflags.height
)
begin
  case m.eflags.height is
  when PEAK_HEIGHT_D =>
    height <= m.filtered.sample; 
  when CFD_HEIGHT_D =>
    height <= m.filtered.sample; 
  when SLOPE_INTEGRAL_D =>
    height <= m.slope.area(15 downto 0); 
  when SLOPE_MAX_D =>
    height <= m.slope.extrema(15 downto 0); 
  end case;
end process height_mux;

peak.height <= height; 
peak.rise_time <= m.rise_time;
peak.flags <= m.eflags;

area.flags <= m.eflags; 
area.area <= m.pulse_area;

pulse_peak.height <= height;
pulse_peak_we(0) <= m.height_valid;
pulse_peak.minima <= m.filtered.sample;
pulse_peak_we(1) <= m.stamp_peak;
pulse_peak.rise_time <= m.rise_time;
pulse_peak_we(2) <= m.height_valid;
pulse_peak.timestamp <= m.pulse_time;
pulse_peak_we(3) <= m.stamp_peak;

pulse.flags <= m.eflags;
pulse.size <= m.size;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;

--framer_full <= framer_free < m.size;
cleared <= clear_address < m.peak_address;

commit <= commit_frame;
frame:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      start <= FALSE;
      commit_frame <= FALSE;
      dump <= FALSE;
      pulse_started <= FALSE;
    else
      
      start <= FALSE;
      commit_frame <= FALSE;
      dump <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      frame_we <= (others => FALSE);
      address <= m.peak_address;
      frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
      
      if m.eflags.event_type.detection = PEAK_DETECTION_D then
        if m.stamp_peak and m.valid_peak then
          start <= TRUE;
          started <= TRUE;
        end if;
        
        if m.slope.neg_0xing then 
          started <= FALSE;
          if m.armed and m.above_pulse_threshold and not framer_full then
            commit_frame <= TRUE; -- can't be full if started 
          else
            overflow_int <= framer_full;
            dump <= started or (m.stamp_peak and m.valid_peak);
          end if;
        end if;
        
        frame_word <= to_streambus(peak,ENDIAN);
        if m.height_valid then
          if framer_full then
            overflow_int <= TRUE;
            dump <= started or (m.stamp_peak and m.valid_peak);
          else
            frame_we <= (others => TRUE);
          end if;
        end if;
      end if;
     
      if m.eflags.event_type.detection = AREA_DETECTION_D then
        if m.stamp_pulse and m.valid_peak then
          start <= TRUE;
          started <= TRUE;
        end if;
        
        frame_word <= to_streambus(area,ENDIAN);
        if m.pulse_threshold_neg then 
          started <= FALSE;
          if m.has_armed and m.above_area_threshold and not framer_full then
            commit_frame <= TRUE; 
            frame_we <= (others => TRUE);
          else
            overflow_int <= framer_full;
            dump <= started or (m.stamp_pulse and m.valid_peak);
          end if;
        end if;
      end if;
      
      if m.eflags.event_type.detection = PULSE_DETECTION_D then
        if m.stamp_pulse and m.valid_peak and not dumped then
          start <= TRUE;
          started <= TRUE;
        end if;
        
        if m.pulse_start then
          pulse_p_we_reg <= (others => FALSE);
          clear_address <= m.last_address;
          clear_last <= TRUE;
        end if;
        
        --header0 can't be dumped yet
        if m.pulse_start and m.valid_peak then
          
          framer_full <= framer_free < m.size;
          
          if framer_free <= m.size then
            overflow_int <= TRUE;
            dumped <= TRUE;
            dump <= started or (m.stamp_pulse and m.valid_peak);
            pulse_started <= FALSE;
          else
            pulse_started <= TRUE;
            address <= (others => '0');
            frame_word <= to_streambus(pulse,0,ENDIAN);
            frame_we <= (others => TRUE);
            if unaryOr(pulse_peak_we) then
              -- collision with peak data
              pulse_p_we_reg <= pulse_p_we_reg or pulse_peak_we;
              pulse_p_reg <= pulse_peak;
              pulse_p_address <= m.peak_address; 
            end if;
          end if;
        end if;
        
        --header1
        if m.pulse_threshold_neg then 
          dumped <= FALSE;
          started <= FALSE;
          pulse_started <= FALSE;
        end if;
        
        if m.pulse_threshold_neg and pulse_started then 
          --framer can't be full if pulse_started true
          if m.has_armed and m.above_area_threshold then
            
            if cleared and not unaryOr(pulse_peak_we) then
              address <= (0 => '1',others => '0');
              frame_word <= to_streambus(pulse,1,ENDIAN);
              frame_we <= (others => TRUE);
              commit_frame <= TRUE; 
            else
              error_int <= TRUE;
              dump <= (started or (m.stamp_pulse and m.valid_peak)) 
                       and not dumped;
            end if;
          else
            dump <= (started or (m.stamp_pulse and m.valid_peak));
            overflow_int <= TRUE;
          end if;
        elsif unaryOr(pulse_p_we_reg) and pulse_started then
          address <= pulse_p_address;
          frame_we <= pulse_p_we_reg;
          frame_word <= to_streambus(pulse_p_reg,m.last_peak,ENDIAN);
          pulse_p_we_reg <= pulse_peak_we;
          pulse_p_reg <= pulse_peak;
          pulse_p_address <= m.peak_address;
        elsif unaryOr(pulse_peak_we) and pulse_started then
          address <= m.peak_address;
          frame_we <= pulse_peak_we;
          frame_word <= to_streambus(pulse_peak,m.last_peak,ENDIAN);
        elsif not cleared and pulse_started then
          address <= clear_address;
          clear_address <= clear_address-1;
          frame_word.data <= (others => '-');
          frame_word.last <= (0 => clear_last, others => FALSE);
          frame_word.discard <= (others => FALSE);
          frame_we <= (others => TRUE);
          clear_last <= FALSE;
        end if;
      end if;
      
    end if;
  end if;
end process frame;

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
  commit => commit_frame,
  free => framer_free,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
