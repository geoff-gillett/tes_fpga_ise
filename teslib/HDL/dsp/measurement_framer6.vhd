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
  
constant CHUNKS:integer:=4;
 
signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal pulse_peak2:pulse_peak2_t;

--signal height_mux:signal_t;
signal overflow_int:boolean;
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);

signal framer_full:boolean;

signal mux_full_reg:boolean;
attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full_reg:signal is "no";

signal dump_int:boolean;
signal error_int:boolean;
signal start_int:boolean;
signal filtered_reg:signal_t;

type FSMstate is (IDLE_S,PEAK_S,AREA_S,PULSE_S,PULSE2_S,LAST_S,COMMIT_S);
signal state,nextstate:FSMstate;

signal free_after_commit:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal pulse_commit,pulse_dump:boolean;
signal word,word_reg,word_reg2:streambus_t;
signal address,address_reg:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal address_reg2:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal length,length_reg,length_reg2:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal we,we_reg,we_reg2:boolean_vector(CHUNKS-1 downto 0);
signal commit_int:boolean;
signal commit_reg,commit_reg2,dump_reg,dump_reg2:boolean;
signal height_valid_reg,start_reg:boolean;
signal dump_pulse,dump_pulse_reg,commit_pulse,commit_pulse_reg:boolean;

signal height_valid:boolean;

signal size:unsigned(CHUNK_DATABITS-1 downto 0);
signal threshold:signed(CHUNK_DATABITS-1 downto 0);
signal offset:unsigned(CHUNK_DATABITS-1 downto 0);
signal flags:detection_flags_t;
signal minima:signed(CHUNK_DATABITS-1 downto 0);
signal timestamp:unsigned(CHUNK_DATABITS-1 downto 0);
signal low1,low2:signed(CHUNK_DATABITS-1 downto 0);
signal pulse_area:signed(2*CHUNK_DATABITS-1 downto 0);
signal pulse_length:unsigned(CHUNK_DATABITS-1 downto 0);
  
begin
m <= measurements;
overflow <= overflow_int;
error <= error_int;
commit <= commit_reg;
start <= start_reg;
dump <= dump_reg;

-- need to mark last peak 
-- flags and pulse_peak clash

capture:process(clk)
begin
  if rising_edge(clk) then

    if m.pulse_start then
      size <= m.size;
      threshold <= resize(m.timing_threshold,CHUNK_DATABITS);
    end if; 
    
    if m.stamp_pulse then
      offset <= m.pulse_time;
    end if;
    
    if m.height_valid then
      -- write peak
      flags <= m.eflags;
    end if;
    
    if m.peak_start then
      minima <= m.minima;
    end if;
    
    if m.stamp_peak then
      timestamp <= m.pulse_time;
      low1 <= filtered_reg;
      low2 <= m.filtered.sample;
    end if;
    
    if m.pulse_threshold_neg then
      -- mark last? -- what about area threshold dump.
      pulse_area <= m.pulse_area;
      pulse_length <= m.pulse_length;
      if m.above_area_threshold then
        pulse_commit <= TRUE;
        pulse_dump  <= FALSE;
      else
        pulse_commit <= FALSE;
        pulse_dump  <= TRUE;
      end if;
    end if;
    
  end if;
end process capture;

peak.height <= m.height;
peak.minima <= minima;
peak.flags <= m.eflags;

area.flags <= flags;
area.area <= m.pulse_area;

pulse.flags <= flags;
pulse.threshold <= threshold;
pulse.size <= size;
pulse.area <= pulse_area;
pulse.length <= pulse_length;
pulse.offset <= offset;

pulse_peak.height <= m.height;
pulse_peak.minima <= minima;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.timestamp <= timestamp; -- FIXME issue if stamp at height valid

pulse_peak2.height <= m.height;
pulse_peak2.low1 <= low1;
pulse_peak2.low2 <= low2;
pulse_peak2.timestamp <= timestamp; -- FIXME issue if stamp at height valid

fsmNextstate:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= IDLE_S;
    else
      state <= nextstate;
    end if;
  end if;
end process fsmNextstate;

fsmTransition:process(
  state,m.eflags.event_type.detection,m.peak_start,m.pulse_start,m.height_valid,
  m.pulse_threshold_neg,peak,area,m.pre_pulse_threshold_neg, 
  m.above_area_threshold, m.peak_address,pulse,pulse_peak,pulse_peak2, 
  height_valid_reg,m.last_peak_address,m.size,framer_full,mux_full_reg, 
  commit_pulse_reg,dump_pulse_reg,m.peak_overflow,enable
)
begin
  nextstate <= state;
  commit_pulse <= FALSE;
  dump_pulse <= FALSE;
  commit_int <= FALSE;
  dump_int <= FALSE;
  we <= (others => FALSE);
  address <= (others => '0');
  word.data <= (others => '-');
  word.last <= (others => FALSE);
  word.discard <= (others => FALSE);
  overflow_int <= FALSE;
  start_int <= FALSE;
  
  case state is 
  when IDLE_S =>
    
    case m.eflags.event_type.detection is
    when PEAK_DETECTION_D =>
      length <= (0 => '1', others => '0');
      if m.peak_start and enable then
        if (mux_full_reg or framer_full) then
          overflow_int <= TRUE;
        else
          start_int <= TRUE;
          nextstate <= PEAK_S;
        end if;
      end if;
      
    when AREA_DETECTION_D =>
      length <= (0 => '1', others => '0');
      if m.pulse_start and enable then
        if (mux_full_reg or framer_full) then
          overflow_int <= TRUE;
        else
          start_int <= TRUE;
          nextstate <= AREA_S;
        end if;
      end if;
      
    when PULSE_DETECTION_D =>
      length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
      if m.pulse_start and enable then
        word <= to_streambus(pulse,0,ENDIAN);
        we <= (others => TRUE); 
        if (mux_full_reg or framer_full) then
          overflow_int <= TRUE;
        else
          start_int <= TRUE;
          nextstate <= PULSE_S;   
        end if;
      end if;
      
    when PULSE2_DETECTION_D =>
      length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
      if m.pulse_start and enable then
        word <= to_streambus(pulse,0,ENDIAN);
        we <= (others => TRUE); 
        if (mux_full_reg or framer_full) then
          overflow_int <= TRUE;
        else
          start_int <= TRUE;
          nextstate <= PULSE2_S;   
        end if;
      end if;
    end case;  
    
    
  when PEAK_S =>
    word <= to_streambus(peak,ENDIAN);
    length <= (0 => '1',others => '0');
    we <= (others => m.height_valid);
    commit_int <= m.height_valid;
    if m.height_valid then
      nextstate <= IDLE_S;
    end if;

  when AREA_S =>
    word <= to_streambus(area,ENDIAN);
    length <= (0 => '1',others => '0');
    we <= (others => m.pulse_threshold_neg);
    if m.pulse_threshold_neg then
      nextstate <= IDLE_S;
      if m.above_area_threshold then
        dump_int <= FALSE;
        commit_int <= TRUE;
      else
        dump_int <= TRUE;
        commit_int <= FALSE;
      end if;
    end if;
    
  when PULSE_S =>
    -- next 
    word <= to_streambus(pulse_peak,FALSE,ENDIAN);
    we <= (others => (m.height_valid and not m.peak_overflow));
    address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
    length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
    if height_valid_reg then
      word <= to_streambus(pulse,0,ENDIAN); -- write flags
      we <= (others => TRUE);
      address <= (others => '0');
    end if;
    if m.pre_pulse_threshold_neg then
      nextstate <= LAST_S;
    end if;
    
  when PULSE2_S =>
    word <= to_streambus(pulse_peak2,FALSE,ENDIAN);
    we <= (others => (m.height_valid and not m.peak_overflow));
    address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
    length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
    if height_valid_reg then
      word <= to_streambus(pulse,0,ENDIAN);
      we <= (others => TRUE);
      address <= (others => '0');
    end if;
    if m.pre_pulse_threshold_neg then
      nextstate <= LAST_S;
    end if;
    
  when LAST_S =>
    -- @ neg thresh xing
    if m.above_area_threshold then
      dump_pulse <= FALSE;
      commit_pulse <= TRUE;
    else
      dump_pulse <= TRUE;
      commit_pulse <= FALSE;
    end if;
    if m.eflags.event_type.detection = PULSE_DETECTION_D then
      word <= to_streambus(pulse_peak,TRUE,ENDIAN);
    elsif m.eflags.event_type.detection = PULSE_DETECTION_D then
      word <= to_streambus(pulse_peak2,TRUE,ENDIAN);
    end if;
    address <= resize(m.last_peak_address,FRAMER_ADDRESS_BITS);
    we <= (0 => m.above_area_threshold, others => FALSE);
    nextstate <= COMMIT_S;
    
  when COMMIT_S =>
    -- clk after neg thresh xing
    word <= to_streambus(pulse,1,ENDIAN);
    address <= (0 => '1', others => '0');
    we <= (others => TRUE);
    commit_int <= commit_pulse_reg;
    dump_int <= dump_pulse_reg;
    nextstate <= IDLE_S;  -- FIXME check for new starts 
  end case;
end process fsmTransition;

fsmOutput:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      we_reg <= (others => FALSE);
      address_reg <= (others => '-');
      commit_reg  <= FALSE;
      dump_reg <= FALSE;
      commit_pulse_reg <= FALSE;
      dump_pulse_reg <= FALSE;
      height_valid_reg <= FALSE;
      word_reg.data <= (others => '-');
      word_reg.last <= (others => FALSE);
      word_reg.discard <= (others => FALSE);
      start_reg <= FALSE;
      length_reg <= (others => '-');
    else
      we_reg <= we;
      we_reg2 <= we_reg;
      address_reg <= address;
      address_reg2 <= address_reg;
      commit_reg <= commit_int;
      commit_reg2 <= commit_reg;
      dump_reg <= dump_int;
      dump_reg2 <= dump_reg;
      length_reg <= length;
      length_reg2 <= length_reg;
      word_reg <= word;
      word_reg2 <= word_reg;
      
      commit_pulse_reg <= commit_pulse;
      dump_pulse_reg <= dump_pulse;
      height_valid_reg <= m.height_valid;
      filtered_reg <= m.filtered.sample;
      start_reg <= start_int;
      
      height_valid <= m.height_valid;
      
      mux_full_reg <= mux_full;
      
      --FIXME this needs twice the free space 
      -- also this maybe cause of jamming
      free_after_commit <= framer_free - length_reg;
--      if commit_reg then -- problem if commit_reg and pulse/peak start
        framer_full <= free_after_commit < m.pre_size; --needs to be next size
--      else
--        framer_full <= framer_free < m.size; -- size changes at minima
--      end if;
    end if;
  end if;
end process fsmOutput;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => CHUNKS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => word_reg,
  address => address_reg,
  chunk_we => we_reg,
  length => length_reg,
  commit => commit_reg,
  free => framer_free,
  stream => stream,
  valid => valid,
  ready => ready
);

end architecture RTL;
