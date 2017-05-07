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
use work.functions.all;

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
constant DEPTH:integer:=4;

type write_buffer is array (DEPTH-1 downto 0) of streambus_t;
signal queue:write_buffer;
--signal queue_full:boolean;

signal stream_int:streambus_t;
signal valid_int,ready_int:boolean;

signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal trace:trace_detection_t;
signal tflags:trace_flags_t;

signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
--signal framer_full:boolean;

attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full:signal is "no";

signal free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0):=(others => '0');
--
signal pulse_valid,pulse_peak_valid,pulse_commit:boolean;
signal pulse_overflow:boolean;
signal frame_word:streambus_t;
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame,start_int,dump_int:boolean;
constant MUX_DEPTH:natural:=2;
signal commit_pipe,start_pipe,dump_pipe:boolean_vector(1 to MUX_DEPTH)
       :=(others => FALSE);
signal error_pipe,overflow_pipe:boolean_vector(1 to MUX_DEPTH)
       :=(others => FALSE);


signal peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal area_overflow:boolean;
signal pulse_start:boolean;
signal peak_stamped,pulse_stamped:boolean:=FALSE;
signal last_peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);

signal pre_detection,detection:detection_d;

-- TRACE control registers implemented as constants
constant trace_length:unsigned(FRAMER_ADDRESS_BITS downto 0)
         :=to_unsigned(512,FRAMER_ADDRESS_BITS+1);
constant TRACE_STRIDE_BITS:integer:=5;
constant trace_stride:unsigned(TRACE_STRIDE_BITS-1 downto 0):=(others => '0');
-- trace signals
signal trace_reg:std_logic_vector(BUS_DATABITS-1 downto 16);
--signal trace_valid:boolean;
signal trace_chunk:signed(CHUNK_DATABITS-1 downto 0);
signal stride_count:unsigned(TRACE_STRIDE_BITS-1 downto 0);
--signal trace_started:boolean;
signal trace_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal trace_count:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal trace_size:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal trace_start:boolean;
signal wr_trace_valid,wr_trace,store_trace,trace_done:boolean;
signal commiting:boolean;
signal overflow_int,error_int:boolean;
--signal stamp_error:boolean;
--signal trace_overflow,single_overflow,trace_overflow_valid,trace_done:boolean;
signal tracing:boolean;
signal enable_reg:boolean;
signal commit_trace:boolean;
signal can_q_trace,can_q_pulse,can_q_single:boolean;
signal can_write_trace:boolean;



--FSMs
type pulseFSMstate is (IDLE_S,STARTED_S); --,DUMP_S,ERROR_S,AREADUMP_S,END_S);
signal p_state:pulseFSMstate;
type traceFSMstate is (IDLE_S,PULSE_S,TRACE_S,WAITPULSE_S);
signal t_state:traceFSMstate;
type traceChunkState is (STORE0,STORE1,STORE2,WRITE);
signal trace_chunk_state:traceChunkState;

type queueFSMstate is (
  IDLE_S,SINGLE_S,PULSE0_S,PULSE1_S,PULSELAST_S,TRACE0_S,TRACE1_S
);
signal q_state:queueFSMstate;

--debugging
--signal flags:std_logic_vector(7 downto 0);
--signal pending:signed(3 downto 0):=(others => '0');
--signal head:boolean;
--
--attribute keep:string;
----attribute MARK_DEBUG:string;
--
--constant DEBUG:string:="FALSE";
--
--attribute keep of pending:signal is DEBUG;
--attribute keep of flags:signal is DEBUG;
--attribute keep of head:signal is DEBUG;

--attribute MARK_DEBUG of framer_full:signal is DEBUG;
--attribute MARK_DEBUG of framer_free:signal is DEBUG;
--attribute MARK_DEBUG of commit_frame:signal is DEBUG;
--attribute MARK_DEBUG of frame_we:signal is DEBUG;
--attribute MARK_DEBUG of frame_address:signal is DEBUG;
--attribute MARK_DEBUG of frame_length:signal is DEBUG;

begin
m <= measurements;
commit <= commit_frame;
start <= start_int;
dump <= dump_int;
overflow <= overflow_int;
error <= error_int;

-- timing threshold to the header in reserved spot
-- reserved is traces flags or timing threshold
-----------------  pulse event - 16 byte header --------------------------------
--  | size | threshold  |   flags  |   time   |  wr_en @ pulse end
--  |       area        |  length  |  offset  |        @ pulse end -1
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | minima | rise | time |                  @ maxima
--
--  | height | low1 |  low2  | time | -- use this for pulse2
                                      -- low2 is @ time
pulse.size <= m.size;
pulse.flags <= m.eflags;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;
pulse.threshold <= m.timing_threshold;

-----------------  trace event - 16 byte header --------------------------------
--  | size |   tflags   |   flags  |   time   | *low thresh for pulse2
--  |       area        |  length  |  offset  |  
--  repeating 8 byte peak records (up to 16) for extra peaks.
--  | height | rise | minima | time |
--  | height | low1 |  low2  | time | -- use this for pulse2
tflags.offset <= m.offset;
tflags.trace_signal <= FILTERED_TRACE_D;
tflags.trace_type <= SINGLE_TRACE_D;
tflags.stride <= trace_stride;

trace.size <= resize(trace_size,CHUNK_DATABITS);
trace.flags <= m.eflags;
trace.trace_flags <= tflags;
trace.length <= m.pulse_length;
trace.offset <= m.time_offset;
trace.area <= m.pulse_area;

pulse_peak.minima <= m.min_value;
pulse_peak.timestamp <= m.peak_time;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.height <= m.height;

peak.height <= m.height;
peak.minima <= m.min_value;
peak.flags <= m.eflags;

area.flags <= m.eflags;
area.area <= m.pulse_area;

pre_detection <= m.pre_eflags.event_type.detection;
detection <= m.eflags.event_type.detection;

trace_start <= m.pre_pulse_start and pre_detection=TRACE_DETECTION_D and enable;
pulse_start 
  <= pre_detection/=PEAK_DETECTION_D and m.pre_pulse_start and enable;  

tracing <= (t_state=PULSE_S or t_state=TRACE_S);
wr_trace <= stride_count=0 and trace_chunk_state=WRITE;
wr_trace_valid <= tracing and wr_trace;

can_q_single <= q_state=IDLE_S;
can_q_trace <= q_state=IDLE_S;
can_q_pulse <= q_state=IDLE_S;

trace_chunk <= m.filtered.sample;
capture:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      pulse_valid <= FALSE;
      pulse_peak_valid <= FALSE;
      frame_length <= (0 => '1', others => '0');
      pulse_overflow <= FALSE;
      trace_address <= (others => '0');
      trace_count <= (others => '1');
      stride_count <= (others => '0');
      area_overflow <= FALSE;
      
      q_state <= IDLE_S;
      p_state <= IDLE_S;
      t_state <= IDLE_S;
      
      trace_chunk_state <= STORE0;
      
    else
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      commit_frame <= FALSE;
      frame_we <= (others => FALSE);
      
      if m.pre_pulse_start and t_state=IDLE_S then 
        enable_reg <= enable;
        case m.pre_eflags.event_type.detection is
        when PEAK_DETECTION_D | AREA_DETECTION_D | PULSE_DETECTION_D =>
          frame_length <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1);
        when TRACE_DETECTION_D => 
          case tflags.trace_type is
          when SINGLE_TRACE_D =>
            frame_length 
              <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1)+trace_length;
          when AVERAGE_TRACE_D =>
            frame_length <= trace_length;
          when DOT_PRODUCT_D =>
            frame_length <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1);
          end case;
        end case;
      end if;
      
      if not commiting then
        free <= framer_free;
      end if; 

     
      -- queue to framer 
      if not (store_trace and trace_chunk_state=WRITE) then -- FIXME register
        if pulse_peak_valid then
          frame_word <= queue(3);
          frame_address <= peak_address;
          frame_we <= (others => TRUE);
          commit_frame <= FALSE;
          pulse_peak_valid <= FALSE; 
        else
          case q_state is 
          when IDLE_S =>
          when SINGLE_S => 
            frame_word <= queue(0);
            frame_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
            frame_we <= (others => TRUE);
            commit_frame <= TRUE;
            pulse_stamped <= FALSE;
            q_state <= IDLE_S;
          when PULSE0_S =>
            frame_word <= queue(0);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
            q_state <= PULSE1_S;
          when PULSE1_S =>
            -- no free test since peak must already be written
            frame_word <= queue(1);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
            q_state <= PULSELAST_S;
          when PULSELAST_S =>
            frame_word <= queue(2);
            frame_word.last <= (0 => TRUE, others => FALSE);
            frame_we <= (0 => TRUE, others => FALSE);
            commit_frame <= TRUE;
            frame_address <= resize(m.last_peak_address,FRAMER_ADDRESS_BITS);
            q_state <= IDLE_S;
          when TRACE0_S =>
            frame_length <= trace_size;
            frame_word <= queue(0);
            frame_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
            frame_we <= (others => TRUE);
            if commit_trace then 
              commit_trace <= FALSE;
              commit_frame <= TRUE;
              pulse_stamped <= FALSE;
              q_state <= IDLE_S;
            end if;
          when TRACE1_S =>
            frame_word <= queue(1);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
            q_state <= TRACE0_S;
          end case;
        end if;
      end if;
        
      --initialise new trace and count strides
      if trace_start then --FIXME handle double pulse
        stride_count <= (others => '0');
        trace_count <= trace_length-1;
        if tflags.trace_type=SINGLE_TRACE_D then
          trace_address <= resize(m.pre_size,FRAMER_ADDRESS_BITS);
        else
          trace_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
        end if;
        trace_chunk_state <= STORE0;
        trace_size <= resize(m.pre_size,FRAMER_ADDRESS_BITS)+trace_length;
        store_trace <= TRUE; --FIXME assumes valid start
        trace_done <= FALSE;
      elsif stride_count=0 then
        stride_count <= trace_stride;
        store_trace <= t_state=PULSE_S or t_state=TRACE_S;
      else
        store_trace <= FALSE;
        stride_count <= stride_count-1;
      end if;
      
      --gather trace words and write to framer
      if store_trace then --FIXME register stride_count=0
        case trace_chunk_state is
        when STORE0 => 
          trace_reg(63 downto 48) <= set_endianness(trace_chunk,ENDIAN);
          trace_chunk_state <= STORE1;
        when STORE1 => 
          trace_reg(47 downto 32) <= set_endianness(trace_chunk,ENDIAN);
          trace_chunk_state <= STORE2;
        when STORE2 => 
          trace_reg(31 downto 16) <= set_endianness(trace_chunk,ENDIAN);
          trace_chunk_state <= WRITE;
          can_write_trace <= free > trace_address;
        when WRITE => 
          if can_write_trace then
            trace_chunk_state <= STORE0;
            frame_we <= (others => TRUE);
            frame_word.data(63 downto 16) <= trace_reg(63 downto 16);
            frame_word.data(15 downto 0) <= set_endianness(trace_chunk,ENDIAN);
            frame_word.last <= (0 => trace_count=0, others => FALSE);
            if trace_count=0 and p_state=IDLE_S then
              commit_trace <= TRUE;
              pulse_stamped <= FALSE;
              commiting <= TRUE;
              free <= framer_free - trace_size;
            end if;
            frame_address <= trace_address;
            frame_length <= trace_size;
            if trace_count /= 0 then
              trace_address <= trace_address+1;
              trace_count <= trace_count-1;
              trace_done <= trace_count=1;
            end if;
          else
            dump_int <= pulse_stamped;
            pulse_stamped <= FALSE;
            p_state <= IDLE_S;
            t_state <= IDLE_S;
            q_state <= IDLE_S;
            overflow_int <= TRUE;
          end if;
        end case;
      end if;
      
      case t_state is 
      when IDLE_S =>
        tflags.multipulse <= FALSE;
        if pulse_start then 
          if free >= resize(m.pre_size,FRAMER_ADDRESS_BITS+1) then
            p_state <= STARTED_S;
            if pre_detection=TRACE_DETECTION_D then
              t_state <= PULSE_S;
            end if;
          else
            overflow_int <= TRUE;
          end if;
        end if;
      when PULSE_S =>
        --FIXME what if both are true:
        if trace_done and trace_chunk_state=WRITE and store_trace then
          t_state <= WAITPULSE_S;
          commiting <= TRUE;
          free <= framer_free - trace_size;
        end if;
        if m.pulse_threshold_neg then 
          if m.above_area_threshold then
            t_state <= TRACE_S;
          else
            if not pulse_start then
              t_state <= IDLE_S;
            end if;
          end if;
        end if;
      when TRACE_S =>
        if pulse_start then
          tflags.multipulse <= TRUE;
        end if;
        if trace_done and trace_chunk_state=WRITE and store_trace then
          t_state <= IDLE_S;
        end if;
      when WAITPULSE_S =>
        if m.pulse_threshold_neg then 
          if trace_start then
            tflags.multipulse <= FALSE;
            t_state <= PULSE_S;
          else
            t_state <= IDLE_S;
          end if;
        end if;
      end case;
      
      case p_state is 
      when IDLE_S =>
      when STARTED_S =>
        if m.pulse_threshold_neg then
          if t_state=IDLE_S then
            pulse_stamped <= FALSE;
          end if;
          if not m.above_area_threshold then
            dump_int <= TRUE;
            if pulse_start then
              t_state <= PULSE_S;
            else
              t_state <= IDLE_S;
              p_state <= IDLE_S;
            end if;
          elsif t_state=PULSE_S or t_state=WAITPULSE_S then
            --no free test as a trace word will have failed if not enough free
            if tflags.trace_type/=SINGLE_TRACE_D then
              p_state <= IDLE_S;
            elsif can_q_trace then
              queue(0) <= to_streambus(trace,0,ENDIAN);
              queue(1) <= to_streambus(trace,1,ENDIAN);
              q_state <= TRACE1_S;
              p_state <= IDLE_S;
              if t_state=WAITPULSE_S then
                commit_trace <= TRUE; 
                if pulse_start then
                  p_state <= STARTED_S;
                end if;
              end if;
            else
              error_int <= TRUE;
              dump_int <= pulse_stamped;
              if pulse_start then
                p_state <= STARTED_S;
                if pre_detection=TRACE_DETECTION_D then
                  t_state <= PULSE_S;
                end if;
              else
                p_state <= IDLE_S;
                t_state <= IDLE_S;
              end if;
            end if;
          elsif m.eflags.event_type.detection=AREA_DETECTION_D then
            if not pulse_start then
              p_state <= IDLE_S;
            end if;
            q_state <= SINGLE_S;
            queue(0) <= to_streambus(area,ENDIAN);
            commiting <= TRUE;
            free <= framer_free - 1;
          else -- normal pulse
            if not pulse_start then
              p_state <= IDLE_S;
            end if;
            if not can_q_pulse then
              error_int <= TRUE;
              dump_int <= TRUE;
              p_state <= IDLE_S;
              
            else
              queue(0) <= to_streambus(pulse,0,ENDIAN);
              queue(1) <= to_streambus(pulse,1,ENDIAN);
              queue(2) <= to_streambus(pulse_peak,TRUE,ENDIAN);
              last_peak_address 
                <= resize(m.last_peak_address,FRAMER_ADDRESS_BITS);
              pulse_commit <= TRUE;
              commiting <= TRUE;
              free <= framer_free - resize(m.size,FRAMER_ADDRESS_BITS+1);
              q_state <= PULSE0_S;
            end if;
          end if;
        end if;
      end case;
      
      -- FIXME what if enabled between start and peak
      --FIXME will break when commit then peak_stop
--      peak_full <= free <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
      if m.peak_stop and enable_reg then 
        if p_state=STARTED_S then 
          if pulse_peak_valid then
            error_int <= TRUE;
            q_state <= IDLE_S;
            t_state <= IDLE_S;
            p_state <= IDLE_S;
            dump_int <= m.pulse_stamped;
            pulse_stamped <= FALSE;
          else
            queue(3) <= to_streambus(pulse_peak,FALSE,ENDIAN);
            peak_address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
            pulse_peak_valid <= TRUE;
          end if;
        elsif m.eflags.event_type.detection=PEAK_DETECTION_D then
          if free=0 then
            overflow_int <= TRUE;
            q_state <= IDLE_S;
            t_state <= IDLE_S;
            p_state <= IDLE_S;
            dump_int <= TRUE; --FIXME check that it is always stamped
            peak_stamped <= FALSE;
          else
            queue(0) <= to_streambus(peak,ENDIAN);
            q_state <= SINGLE_S;
            commiting <= TRUE;
            free <= framer_free-1;
          end if;
        end if;
      end if;
        
      if m.eflags.event_type.detection=PEAK_DETECTION_D and m.stamp_peak and 
         enable_reg then
        if mux_full then
          error_int <= TRUE;
          peak_stamped <= FALSE;
        else
          start_int <= TRUE;  
          peak_stamped <= TRUE;
        end if;
      elsif p_state=STARTED_S and m.stamp_pulse and enable_reg then
        if mux_full then
          error_int <= TRUE;
          pulse_stamped <= FALSE;
        else
          start_int <= TRUE;  
          pulse_stamped <= TRUE;
        end if;
      end if; 
        
      if commit_frame or dump_int then
        commiting <= FALSE;
      end if;
        
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
  stream => stream,
  valid => valid,
  ready => ready
);


end architecture RTL;
