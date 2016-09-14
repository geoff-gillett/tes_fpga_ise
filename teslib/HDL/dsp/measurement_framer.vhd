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
  
  --signals to MUX
  start:out boolean;
  commit:out boolean;
  dump:out boolean;
  measurements:in measurements_t;
  
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

signal peak_we,area_we,pulse_peak_we:boolean_vector(CHUNKS-1 downto 0);
signal pulse_head0_we,pulse_head1_we:boolean_vector(CHUNKS-1 downto 0);


signal height:signal_t;
signal peak_commit,area_commit,pulse_commit:boolean;
signal peak_wr,area_wr,pulse_p_wr:boolean;

signal started,commit_frame,overflow:boolean;

signal frame_word:streambus_t;
signal frame_we:boolean_vector(CHUNKS-1 downto 0);
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal address,clear_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0);

signal dumped,framer_full,cleared:boolean;
signal clear_last:boolean;

  
begin
m <= measurements;

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
peak_we <= (others => m.height_valid); 
peak_commit <= m.height_valid;

area.flags <= m.eflags; -- are flags registered at pulse_start?
area.area <= m.pulse_area;
area_we <= (others => m.pulse_threshold_neg);
area_commit <= m.pulse_threshold_neg;

-- need registration of pulse_peak
pulse_peak.height <= height;
pulse_peak_we(0) <= m.height_valid;
pulse_peak.minima <= m.filtered.sample;
pulse_peak_we(1) <= m.peak_start;
pulse_peak.rise_time <= m.rise_time;
pulse_peak_we(2) <= m.height_valid;
pulse_peak.timestamp <= m.pulse_time;
pulse_peak_we(3) <= m.peak_start;

pulse.flags <= m.eflags;
pulse.size <= m.size;
pulse_head0_we <= (others => m.pulse_start); --FIXME same as minima
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;
pulse_head1_we <= (others => m.pulse_threshold_neg);
pulse_commit <= m.pulse_threshold_neg;

framer_full <= framer_free < m.size;
cleared <= clear_address < m.peak_address;

framing:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      start <= FALSE;
      commit_frame <= FALSE;
    else
      
      start <= FALSE;
      commit_frame <= FALSE;
      dump <= FALSE;
      overflow <= FALSE;
      frame_we <= (others => FALSE);
      address <= m.peak_address;
      frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
      
      if m.pulse_threshold_neg then
        dumped <= FALSE;
      end if;
      
      case m.eflags.event_type.detection is
      when PEAK_DETECTION_D =>
        
        if m.peak_start and m.valid_peak then
          if framer_full then
            overflow <= TRUE;
            started <= FALSE;
          else
            start <= TRUE;
            started <= TRUE;
          end if;
        end if;
        
        if peak_commit and started then 
          started <= FALSE;
          if m.armed and m.above_pulse_threshold then
            commit_frame <= TRUE; -- can't be full if started 
          else
            dump <= TRUE;
          end if;
        end if;
        
        frame_word <= to_streambus(peak,ENDIAN);
        if unaryOr(peak_we) and started then
          frame_we <= peak_we;
        end if; 
        
      when AREA_DETECTION_D =>
        
        if m.pulse_start and m.valid_peak then
          if framer_full then
            overflow <= TRUE;
            started <= FALSE;
          else
            start <= TRUE;
            started <= TRUE;
          end if;
        end if;
        
        if area_commit and started then 
          started <= FALSE;
          if m.has_armed and m.above_area_threshold then
            commit_frame <= TRUE; 
          else
            dump <= TRUE;
          end if;
        end if;
        
        frame_word <= to_streambus(area,ENDIAN);
        if unaryOr(area_we) and started then
          frame_we <= area_we;
        end if; 
        
      when PULSE_DETECTION_D =>
        
        if m.pulse_start and m.valid_peak then
          --dumped <= FALSE; -- FIXME clear at pulse end?
          clear_last <= TRUE;
          clear_address <= m.last_address; 
          if framer_full then
            overflow <= TRUE;
            started <= FALSE;
          else
            start <= TRUE;
            started <= TRUE;
          end if;
        end if;
        
        
        --FIXME need to check all cleared;
        if pulse_commit and started and not dumped then 
          started <= FALSE;
          if m.has_armed and m.above_area_threshold then
            if framer_full then
              dump <= TRUE;
              overflow <= TRUE;
              dumped <= TRUE;
            else
              commit_frame <= TRUE; 
            end if;
          else
            dump <= TRUE;
            dumped <= TRUE;
          end if;
        end if;
        
        --FIXME check what happens if max = pulse_threshold
        if not dumped then
          
          if unaryOr(pulse_peak_we) and not m.eflags.peak_overflow then
            if framer_full then 
              dump <= started;
              dumped <= TRUE;
              overflow <= TRUE;
            else
              frame_word <= to_streambus(pulse_peak,m.last_peak,ENDIAN);
              frame_we <= pulse_peak_we;
            end if;
          elsif pulse_head0_we(0) then
            if framer_full then
              dump <= started;
              dumped <= TRUE;
              overflow <= TRUE;
            else
              address <= (others => '0');
              frame_word <= to_streambus(pulse,0,ENDIAN);
              frame_we <= pulse_head0_we;
            end if;
          elsif pulse_head1_we(0) then
            if framer_full then
              dump <= started;
              dumped <= TRUE;
              overflow <= TRUE;
            else
              address <= (0 => '1', others => '0');
              frame_word <= to_streambus(pulse,1,ENDIAN);
              frame_we <= pulse_head1_we;
            end if;
            -- FIXME this could be done before started
          elsif not cleared then
            if not framer_full then
              address <= clear_address;
              frame_word.data <= (others => '-');
              frame_word.last <= (0 => clear_last,others => FALSE);
              clear_last <= FALSE;
              frame_word.discard <= (others => FALSE);
              frame_we <= (others => TRUE);
              clear_address <= clear_address-1;
            end if;
          end if; 
        end if;
      when TRACE_DETECTION_D =>
        null;
      end case;
    end if;
  end if;
end process framing;
commit <= commit_frame;

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
