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

entity measurement_framer8 is
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
end entity measurement_framer8;

architecture RTL of measurement_framer8 is

--  
constant CHUNKS:integer:=BUS_CHUNKS;
constant DEPTH:integer:=3;

type write_buffer is array (DEPTH-1 downto 0) of streambus_t;
signal queue:write_buffer;
--signal queue_full:boolean;

signal stream_int:streambus_t;
signal valid_int:boolean;

signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal pulse_peak:pulse_peak_t;

signal framer_free,event_size:unsigned(FRAMER_ADDRESS_BITS downto 0);
--signal framer_full:boolean;

attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full:signal is "no";

signal free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0):=(others => '0');

signal offset:unsigned(CHUNK_DATABITS-1 downto 0);
signal minima:signed(CHUNK_DATABITS-1 downto 0);
--
signal peak_time:unsigned(CHUNK_DATABITS-1 downto 0);

signal pulse_valid,single_valid,pulse_peak_valid,pulse_commit:boolean;
signal pulse_overflow:boolean;
signal frame_word:streambus_t;
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame,commit_frame_reg,start_int,dump_int:boolean;
signal single_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal area_overflow,peak_overflow:boolean;
signal pulse_error,pulse_start:boolean;
signal last_peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal thresh:signed(CHUNK_DATABITS-1 downto 0);

signal detection:detection_d;

-- TRACE control registers implemented as constants
constant trace_length:unsigned(FRAMER_ADDRESS_BITS downto 0)
         :=to_unsigned(510,FRAMER_ADDRESS_BITS+1);
constant TRACE_STRIDE_BITS:integer:=5;
constant trace_stride:unsigned(TRACE_STRIDE_BITS-1 downto 0):=(others => '0');
-- trace signals
signal trace_word:streambus_t;
signal trace_reg:std_logic_vector(BUS_DATABITS-1 downto 16);
--signal trace_valid:boolean;
signal trace_chunk:signed(CHUNK_DATABITS-1 downto 0);
signal stride_count:unsigned(TRACE_STRIDE_BITS-1 downto 0);
--signal trace_started:boolean;
signal trace_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal trace_count:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal trace_size:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal trace_commit,trace_start:boolean;
signal wr_trace_word:boolean;
signal single_commit:boolean;
signal peak_start:boolean;
signal commiting:boolean;
signal q_empty:boolean;
signal overflow_int:boolean;

type trace_type_d is (SINGLE, AVERAGE, DOTPRODUCT);
constant NUM_TRACE_TYPE_D:integer:=trace_type_d'pos(trace_type_d'high)+1;
constant TRACE_TYPE_D_BITS:integer:=ceilLog2(NUM_TRACE_TYPE_D);

function to_std_logic(t:trace_type_d;w:integer) return std_logic_vector is
begin
--	if w < TRACE_TYPE_D_BITS then
--		assert FALSE report "w to small to represent trace_type_d" severity ERROR;
--	end if;
	return to_std_logic(trace_type_d'pos(t),w);
end function;

--trace flags 
type trace_flags_t is record
  multipulse:boolean;
  trace_type:trace_type_d; --2 bits
end record;
signal trace_flags:trace_flags_t;

--FSMs
type pulseFSMstate is (IDLE_S,STARTED_S,STAMPED_S,DUMP_S,ERROR_S,END_S);
signal p_state,p_nextstate:pulseFSMstate;
type traceFSMstate is (IDLE_S,PULSE_S,TRACE_S,DUMP_S);
signal t_state,t_nextstate:traceFSMstate;
type traceChunkState is (STORE0,STORE1,STORE2,WRITE);
signal trace_chunk_state:traceChunkState;

type queueFSMstate is (IDLE_S,PULSE0_S,PULSE1_S,PULSELAST_S);
signal q_state,q_nextstate:queueFSMstate;

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
dump <= dump_int;

-- timing threshold to the header in reserved spot
-- reserved is traces flags or timing threshold
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

fsmNextstate:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      p_state <= IDLE_S;
      t_state <= IDLE_S;
      q_state <= IDLE_S;
    else
      p_state <= p_nextstate;
      t_state <= t_nextstate;
      q_state <= q_nextstate;
    end if;
  end if;
end process fsmNextstate;

detection <= m.pre_eflags.event_type.detection;
trace_start <= m.pre_pulse_start and detection=TRACE_DETECTION_D and 
               t_state=IDLE_S and enable;
               
pulse_start <= m.pre_pulse_start and enable and 
               (
                 detection=PULSE_DETECTION_D or detection=AREA_DETECTION_D or 
                 (detection=TRACE_DETECTION_D and t_state=IDLE_S)
               );

peak_start <= detection=PEAK_DETECTION_D and m.pre_peak_start;

overflow_int <= free <= resize(m.size,FRAMER_ADDRESS_BITS+1);

fsmTransition:process(
  p_state,t_state,m.pre_pulse_threshold_neg,pulse_start, 
  m.above_area_threshold,m.height_valid,q_empty,framer_free,trace_address, 
  trace_count,m.stamp_pulse,mux_full,stride_count,trace_chunk_state, 
  q_state,overflow_int,detection,enable,m.pre_pulse_start
)
begin
  
  t_nextstate <= t_state;
  p_nextstate <= p_state;
  q_nextstate <= q_state;
  
  case p_state is 
  when IDLE_S =>
    if pulse_start then
      p_nextstate <= STARTED_S;
    end if;
  when STARTED_S =>
    if m.stamp_pulse then
      if mux_full or overflow_int then
        p_nextstate <= ERROR_S;
      else
        p_nextstate <= STAMPED_S;
      end if;
    end if;
  when STAMPED_S =>
    if m.pre_pulse_threshold_neg then
      if not m.above_area_threshold then
        p_nextstate <= DUMP_S;
      elsif not q_empty then
        p_nextstate <= ERROR_S;
      else
        p_nextstate <= END_S;
      end if;
    elsif m.height_valid and not q_empty then
      p_nextstate <= ERROR_S;
    end if;
  when DUMP_S  => 
    p_nextstate <= IDLE_S;
  when ERROR_S => 
    p_nextstate <= IDLE_S;
  when END_S => 
    p_nextstate <= IDLE_S;
  end case;
  
  case t_state is 
  when IDLE_S =>
    if enable and m.pre_pulse_start and detection=TRACE_DETECTION_D then
      t_nextstate <= PULSE_S;
    end if;
  when PULSE_S =>
    if framer_free <= trace_address then
      t_nextstate <= DUMP_S;
    elsif m.pre_pulse_threshold_neg then
      if p_state=ERROR_S or p_state=DUMP_S then
        t_nextstate <= IDLE_S;
      elsif trace_count=0 and trace_chunk_state=WRITE and stride_count=0 then
        t_nextstate <= IDLE_S;
      else
        t_nextstate <= TRACE_S;
      end if;
    end if;
  when TRACE_S =>
    if framer_free <= trace_address then
      t_nextstate <= DUMP_S;
    elsif trace_count=0 and trace_chunk_state=WRITE and stride_count=0 then
      t_nextstate <= IDLE_S;
    end if;
  when DUMP_S => 
    t_nextstate <= IDLE_S;
  end case;
  
  case q_state is 
  when IDLE_S =>
    if p_state=END_S then
      q_nextstate <= PULSE0_S;
    end if;
  when PULSE0_S =>
    q_nextstate <= PULSE1_S;
  when PULSE1_S =>
    if t_state=TRACE_S then
      q_nextstate <= IDLE_S;
    else
      q_nextstate <= PULSELAST_S;
    end if;
  when PULSELAST_S =>
    q_nextstate <= IDLE_S;
  end case;
  
end process fsmTransition;

q_empty <= q_state=IDLE_S or (q_state=PULSELAST_S and not single_valid);
wr_trace_word <= (t_state=PULSE_S or t_state=TRACE_S) and stride_count=0 and 
                 trace_chunk_state=WRITE;

trace_chunk <= m.filtered.sample;
capture:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow <= FALSE;
      error <= FALSE;
      pulse_valid <= FALSE;
      pulse_peak_valid <= FALSE;
      pulse_error <= FALSE;
      single_valid <= FALSE; 
      frame_length <= (0 => '1', others => '0');
      pulse_overflow <= FALSE;
      area_overflow <= FALSE;
      if DEBUG="TRUE" then
        pending <= (others => '0');
      end if;
      
      trace_chunk_state <= STORE0;
      
    else
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow <= FALSE;
      error <= FALSE;
      commit_frame <= FALSE;
      frame_we <= (others => FALSE);
      
      if DEBUG="TRUE" then
        if ready and valid_int then
          head <= stream_int.last(0);
        end if;
      end if;
      
      if not commiting then
        free <= framer_free;
--        free <= framer_free - frame_length - 1;
--        if commit_frame then
--          commiting <= FALSE;
--        end if;
--      else
      end if; 

      if m.peak_start then -- fixme needed?
        minima <= m.minima;
        thresh  <= resize(m.timing_threshold,CHUNK_DATABITS);
      end if;
      
      if m.stamp_peak then
        peak_time <= m.pulse_time;
      end if;
      
      if m.pulse_start then
        if p_state=STARTED_S or p_state=STAMPED_S then
          last_peak_address <= resize(m.last_peak_address,FRAMER_ADDRESS_BITS);
          offset <= m.pulse_time;
          trace_flags.multipulse <= FALSE;
        else
          trace_flags.multipulse <= TRUE;
        end if;
      end if;
     
      -- write queue to framer 
      if not wr_trace_word then
        case q_state is 
        when IDLE_S =>
          if single_valid then
            frame_word <= queue(0);
            frame_address <= single_address;
            frame_we <= (others => TRUE);
            single_valid <= FALSE;
            commit_frame <= single_commit;
            frame_length <= to_unsigned(1,FRAMER_ADDRESS_BITS+1);
          end if;
        when PULSE0_S =>
            frame_word <= queue(0);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
        when PULSE1_S =>
            frame_word <= queue(1);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
        when PULSELAST_S =>
            frame_we <= (0 => TRUE, others => FALSE);
            commit_frame <= pulse_commit;
            frame_address <=  last_peak_address;
            frame_length <= event_size;
        end case;
      end if;
        
      
      if pulse_start then
        event_size <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1)+1; 
      elsif peak_start then
        event_size <= to_unsigned(1,FRAMER_ADDRESS_BITS+1); 
      end if;
      
      if trace_start or commit_frame then
        trace_address <= resize(m.pre_size,FRAMER_ADDRESS_BITS);
      end if;

      --initialise new trace and count strides
      if trace_start then
        stride_count <= trace_stride;
        trace_count <= trace_length;
        trace_address <= resize(m.pre_size,FRAMER_ADDRESS_BITS);
        trace_chunk_state <= STORE0;
        trace_size <= resize(m.pre_size,FRAMER_ADDRESS_BITS)+trace_length;
      elsif stride_count=0 then
        stride_count <= trace_stride;
      else 
        stride_count <= stride_count-1;
      end if;
      
      --gather trace words and write to framer
      if (t_state=PULSE_S or t_state=TRACE_S) and stride_count=0 then
        case trace_chunk_state is
        when STORE0 => 
          trace_reg(63 downto 48) <= to_std_logic(trace_chunk);
          trace_chunk_state <= STORE1;
        when STORE1 => 
          trace_reg(47 downto 32) <= to_std_logic(trace_chunk);
          trace_chunk_state <= STORE2;
        when STORE2 => 
          trace_reg(31 downto 16) <= to_std_logic(trace_chunk);
          trace_chunk_state <= WRITE;
        when WRITE => 
          if framer_free > trace_address then
            trace_chunk_state <= STORE0;
            frame_we <= (others => TRUE);
            frame_word.data(63 downto 16) <= trace_reg(63 downto 16);
            frame_word.data(15 downto 0) <= to_std_logic(trace_chunk);
            frame_word.last <= (0 => trace_count=0, others => FALSE);
            if trace_count=0 then
              commiting <= TRUE;
              commit_frame <= TRUE;
              free <= framer_free - trace_size;
            end if;
            frame_address <= trace_address;
            frame_length <= trace_size;
            if trace_count /= 0 then
              trace_address <= trace_address+1;
              trace_count <= trace_count-1;
            end if;
          end if;
        end case;
      end if;
      
      if p_state=END_S then
        if m.eflags.event_type.detection=AREA_DETECTION_D and free > 0 then
          queue(0) <= to_streambus(area,ENDIAN);
          single_valid <= TRUE;
          single_commit <= TRUE;
          commiting <= TRUE;
          free <= framer_free - 1;
          frame_length <= to_unsigned(1,FRAMER_ADDRESS_BITS+1);
        else
          queue(0) <= to_streambus(pulse,0,ENDIAN);
          queue(1) <= to_streambus(pulse,1,ENDIAN);
          queue(2) <= to_streambus(pulse_peak,t_state=IDLE_S,ENDIAN);
          frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
          if t_state=IDLE_S then
            pulse_commit <= TRUE;
            commiting <= TRUE;
            free <= framer_free - resize(m.size,FRAMER_ADDRESS_BITS+1);
          end if;
        end if;
      end if;
        
      if m.height_valid then 
        if (p_state=STARTED_S or p_state=STAMPED_S) then 
          queue(0) <= to_streambus(pulse_peak,FALSE,ENDIAN);
          single_address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
          single_valid <= TRUE;
          single_commit <= FALSE;
        elsif m.eflags.event_type.detection=PEAK_DETECTION_D then
          if free > 0 then
            queue(0) <= to_streambus(peak,ENDIAN);
            single_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
            single_valid <= TRUE;
            single_commit <= TRUE;
            frame_length <= to_unsigned(1,FRAMER_ADDRESS_BITS+1);
            commiting <= TRUE;
            free <= framer_free-1;
          else
            null; --overflow
          end if;
        end if;
      end if;
        
      if m.stamp_pulse and p_state/=IDLE_S and not overflow_int then -- not second pulse in trace
        start_int <= TRUE;
      end if;
      
      if commit_frame then
        commiting <= FALSE;
      end if;
        
        
--      if detection=PEAK_DETECTION_D then
--        frame_length <= (0 => '1', others => '0');
--        if m.height_valid and not peak_overflow then
--          queue(0) <= to_streambus(peak,ENDIAN);
--          single_valid <= TRUE;
--        end if;
        
--        if m.stamp_peak and enable then 
--          if not framer_full and not mux_full then
--            start_int <= TRUE;
--            peak_overflow <= FALSE;
--          else
--            peak_overflow <= TRUE;
--            overflow <= framer_full;
--            error <= mux_full;
--          end if;
--        end if;
--      end if;
        
--      if detection=AREA_DETECTION_D then
--        frame_length <= (0 => '1', others => '0');
--        if m.stamp_pulse and enable then 
--          if  framer_full and not mux_full then
--            start_int <= TRUE;
--            area_overflow <= FALSE;
--          else
--            overflow <= framer_full;
--            area_overflow <= TRUE;
--          end if;
--        end if;
--        
--        if m.pulse_threshold_neg and not area_overflow then
--          if m.above_area_threshold then
--            queue(0) <= to_streambus(area,ENDIAN);
--            single_valid <= TRUE;
--          else
--            dump_int <= TRUE;
--          end if;
--        end if;
--      end if;
        
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
