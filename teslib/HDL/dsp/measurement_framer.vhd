library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.measurements.all;
use work.events.all;
use work.registers.all;

entity measurement_framer is
generic(
  WIDTH:integer:=18;
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
  
  m:in measurements_t
);
end entity measurement_framer;

architecture RTL of measurement_framer is
  
constant CHUNKS:integer:=4;
 
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal pulse_p:pulse_peak_t;

signal peak_we,area_we,pulse_p_we:boolean_vector(CHUNKS-1 downto 0);

--signal m_reg:measurements_t;

signal height:signed(WIDTH-1 downto 0);
signal peak_commit,area_commit,pulse_commit:boolean;

signal started:boolean;

signal frame_word:streambus_t;
signal frame_we:boolean_vector;
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal chunk_we:boolean_vector(CHUNKS-1 downto 0);
  
begin

height_mux:process(m.filtered.sample,m.slope.area(15 downto 0),
  m.slope.extrema(15 downto 0),m.eflags.height
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

--FIXME check we numbering
peak.height <= height; 
peak_we(0) <= m.height_valid; 
peak.rise_time <= m.rise_time;
peak_we(1) <= m.height_valid;
peak.flags <= m.eflags;
peak_we(2) <= m.slope.neg_0xing; 
peak_we(3) <= m.height_valid;
peak_commit <= m.slope.neg_0xing;

area.flags <= m.eflags;
area.area <= m.pulse_area;
area_we <= (others => m.pulse_threshold_neg);
--FIXME 
area_commit <= m.pulse_threshold_neg and m.armed and m.above_area_threshold;

pulse_p.height <= height;
pulse_p_we(0) <= m.height_valid;
pulse_p.minima <= m.filtered.sample;
pulse_p_we(1) <= m.slope.pos_0xing;
pulse_p.rise_time <= m.rise_time;
pulse_p_we(2) <= m.peak_start;
pulse_p_we(3) <= m.height_valid;

pulse.flags <= m.eflags;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;
pulse.size <= m.size;


-- TODO here need to minimise starts, add FSM to know when started
framing:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      
    else
      
      
      
      case m.eflags.event_type.detection is
      when PEAK_DETECTION_D =>
        frame_word <= to_streambus(peak,ENDIAN);
        frame_we <= peak_we;
        if framer_free > 0 then
           
        end if;
      when AREA_DETECTION_D =>
        null;
      when PULSE_DETECTION_D =>
        null;
      when TRACE_DETECTION_D =>
        null;
      end case;
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
  data => data,
  address => address,
  chunk_we => chunk_we,
  length => length,
  commit => commit,
  free => framer_free,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
