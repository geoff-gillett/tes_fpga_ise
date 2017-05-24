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

entity measurement_framer12 is
generic(
  WIDTH:natural:=16;
  ADDRESS_BITS:integer:=11;
  ACCUMULATOR_WIDTH:natural:=36;
  ACCUMULATE_N:natural:=18;
  TRACE_CHUNKS:natural:=512;
  TRACE_FROM_STAMP:boolean:=TRUE;
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
end entity measurement_framer12;

architecture RTL of measurement_framer12 is

--  
constant CHUNKS:integer:=BUS_CHUNKS;
constant DEPTH:integer:=3;

type write_buffer is array (DEPTH-1 downto 0) of streambus_t;
signal queue:write_buffer;
--signal queue_full:boolean;

signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse,pulse_reg:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal pulse_peak_word:streambus_t;
signal trace,pulse_reg_trace,average_trace:trace_detection_t;
signal tflags,atflags:trace_flags_t;

--signal framer_full:boolean;

attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full:signal is "no";

signal framer_free:unsigned(ADDRESS_BITS downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
signal frame_length,length:unsigned(ADDRESS_BITS downto 0):=(others => '0');
--
signal pulse_valid,pulse_peak_valid:boolean;
signal pulse_overflow:boolean;
signal frame_word:streambus_t;
signal frame_address:unsigned(ADDRESS_BITS-1 downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame,commit_int,start_int,dump_int,just_started:boolean;

signal peak_address:unsigned(ADDRESS_BITS-1 downto 0);
signal area_overflow:boolean;
signal pulse_start:boolean;
signal peak_stamped,pulse_stamped:boolean:=FALSE;

signal pre_detection,detection:detection_d;
signal full,pre_full:boolean;

-- TRACE control registers implemented as constants

constant TRACE_CHUNK_LENGTH_BITS:natural:=ceilLog2(TRACE_CHUNKS+1);
constant trace_chunk_len:unsigned(TRACE_CHUNK_LENGTH_BITS-1 downto 0)
--         :=to_unsigned((268/16)+1,FRAMER_ADDRESS_BITS+1);
         :=to_unsigned(TRACE_CHUNKS,TRACE_CHUNK_LENGTH_BITS);
constant TRACE_STRIDE_BITS:integer:=5;
constant trace_stride:unsigned(TRACE_STRIDE_BITS-1 downto 0)
         :=(others => '0');
-- trace signals
signal trace_reg:std_logic_vector(BUS_DATABITS-1 downto 16);
--signal trace_valid:boolean;
signal trace_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal acc_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal stride_count:unsigned(TRACE_STRIDE_BITS-1 downto 0);
--signal trace_started:boolean;
signal trace_address:unsigned(ADDRESS_BITS-1 downto 0);
signal trace_count:unsigned(TRACE_CHUNK_LENGTH_BITS-1 downto 0);
signal next_trace_count:unsigned(TRACE_CHUNK_LENGTH_BITS-1 downto 0);
signal last_trace_count:boolean;
--signal trace_size:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal start_trace:boolean;
--signal trace_wr_en:boolean;
signal commiting:boolean;
signal overflow_int,error_int:boolean;
--signal stamp_error:boolean;
--signal trace_overflow,single_overflow,trace_overflow_valid,trace_done:boolean;
--signal tracing:boolean;
--signal trace_writing:boolean;
signal enable_reg:boolean;
--signal trace_done:boolean;
signal can_q_trace,can_q_pulse,can_q_single:boolean;
signal can_write_trace:boolean;
signal trace_last:boolean;

--FSMs
--type pulseFSMstate is (IDLE_S,STARTED_S); --,DUMP_S,ERROR_S,AREADUMP_S,END_S);
--signal p_state:pulseFSMstate;
type FSMstate is (IDLE,FIRSTPULSE,TRACING,WAITPULSEDONE,AVERAGE,HOLD);
signal state:FSMstate;
type wrChunkState is (STORE0,STORE1,STORE2,WRITE,DOTPRODUCT);
signal wr_chunk_state:wrChunkState; 
type rdChunkState is (IDLE,WAIT_TRACE,READ3,READ2,READ1,READ0);
signal rd_chunk_state:rdChunkState;
type traceFSMstate is (IDLE,CAPTURE,DONE);
signal t_state:traceFSMstate;
type queueFSMstate is (IDLE,SINGLE,WORD0,WORD1);
signal q_state:queueFSMstate;
type strideFSMstate is (INIT,IDLE,CAPTURE);
signal s_state:strideFSMstate;
type accumFSMstate is (IDLE,WAITING,ACCUM,SEND,STOPED);
signal a_state:accumFSMstate;

signal acc_ready:boolean;
signal wait_valid,wait_ready:boolean;
signal stream_int:streambus_t;
signal valid_int:boolean;
signal ready_int:boolean;
signal reg_stream:streambus_t;
signal reg_ready:boolean;
signal reg_valid:boolean;
signal average_sample:signed(WIDTH-1 downto 0);
signal mux_trace:boolean;
signal start_average,average_last:boolean;

--debugging
--signal flags:std_logic_vector(7 downto 0);
signal accum_count,next_accum_count:unsigned(ACCUMULATE_N downto 0);
signal last_accum_count:boolean;
signal pending:signed(3 downto 0):=(others => '0');
signal stop:boolean;
signal dp_sample:signed(WIDTH-1 downto 0);
signal dp_trace_start:boolean;
signal dp_trace_last,accum_trace_last:boolean;
signal accumulate:boolean;
signal dot_product_go:boolean;
signal dot_product:signed(47 downto 0);
signal dot_product_valid:boolean;
signal accumulate_done:boolean;
signal multipeak,multipulse:boolean;
signal dp_sample_valid : boolean;
signal dp_trace_go:boolean;
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
  
debugPending:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      pending <= (others => '0');
    else
      if start_int and not (commit_int or dump_int) then
        pending <= pending + 1;
      end if;
      if (commit_int or dump_int) and not start_int then
        pending <= pending - 1;
      end if;
    end if;
  end if;
end process debugPending;

m <= measurements;
commit <= commit_int;
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
pulse.size <= resize(frame_length,CHUNK_DATABITS);
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
tflags.stride <= trace_stride;

atflags.offset <= (0 => '1', others => '0');
atflags.stride <= trace_stride;
atflags.multipeak <= multipeak;
atflags.multipulse <= multipeak;
atflags.trace_signal <= tflags.trace_signal;
atflags.trace_type <= AVERAGE_TRACE_D;

trace.size <= resize(frame_length,CHUNK_DATABITS);
trace.flags <= m.eflags;
trace.trace_flags <= tflags;
trace.length <= m.pulse_length;
trace.offset <= m.time_offset;
trace.area <= m.pulse_area;

average_trace.size <= resize(frame_length,CHUNK_DATABITS);
average_trace.flags <= m.eflags;
average_trace.trace_flags <= atflags;

pulse_reg_trace.size <= resize(frame_length,CHUNK_DATABITS);
pulse_reg_trace.flags <= pulse_reg.flags;
pulse_reg_trace.trace_flags <= tflags;
pulse_reg_trace.length <= pulse_reg.length;
pulse_reg_trace.offset <= pulse_reg.offset;
pulse_reg_trace.area <= pulse_reg.area;

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
  
pulse_start <= pre_detection/=PEAK_DETECTION_D and m.pre_pulse_start;  

can_q_single <= q_state=IDLE;
can_q_trace <= q_state=IDLE;
can_q_pulse <= q_state=IDLE;

pre_full <= free < resize(m.pre_size,ADDRESS_BITS+1);
full <= free < resize(m.size,ADDRESS_BITS+1);

traceSignalMux:process(clk)
begin
  if rising_edge(clk) then
    --TODO add average send
    if state=AVERAGE then
      trace_chunk <= set_endianness(average_sample,ENDIAN);
    else
      case tflags.trace_signal is
      when NO_TRACE_D =>
        trace_chunk <= set_endianness(m.filtered.sample,ENDIAN);
      when RAW_TRACE_D =>
        trace_chunk <= set_endianness(m.raw.sample,ENDIAN);
      when FILTERED_TRACE_D =>
        trace_chunk <= set_endianness(m.filtered.sample,ENDIAN);
      when SLOPE_TRACE_D =>
        trace_chunk <= set_endianness(m.slope.sample,ENDIAN);
      end case;
    end if;
  end if;
end process traceSignalMux;

trace_last <= s_state=CAPTURE and last_trace_count and 
              ((wr_chunk_state=WRITE and can_write_trace) or
              wr_chunk_state=DOTPRODUCT);
              
main:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      
      start_int <= FALSE;
      dump_int <= FALSE;
      commit_int <= FALSE;
      commit_frame <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      pulse_valid <= FALSE;
      pulse_peak_valid <= FALSE;
      pulse_overflow <= FALSE;
      stride_count <= (others => '0');
      area_overflow <= FALSE;
      enable_reg <= FALSE;
      
      q_state <= IDLE;
      state <= IDLE;
      t_state <= IDLE;
      wr_chunk_state <= STORE0;
      
      start_trace <= FALSE;
      mux_trace <= FALSE;
      frame_word.discard <= (others => FALSE);
      multipulse <= FALSE;
      multipeak <= FALSE;
      
      last_trace_count <= FALSE;
      dot_product_go <= FALSE;
      
    else
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      commit_frame <= FALSE;
      commit_int <= FALSE;
      frame_we <= (others => FALSE);
      start_trace <= FALSE;
      dot_product_go <= FALSE;
      
      -- event writing
      if not (s_state=CAPTURE and wr_chunk_state=WRITE) then 
        if pulse_peak_valid then
          frame_word <= pulse_peak_word;
          frame_address <= peak_address;
          frame_we <= (others => TRUE);
          pulse_peak_valid <= FALSE; 
        else
          case q_state is 
          when IDLE =>
            frame_we <= (others => FALSE);
          when SINGLE => 
            frame_word <= queue(0);
            frame_address <= to_unsigned(0,ADDRESS_BITS);
            frame_we <= (others => TRUE);
            commit_frame <= TRUE;
            commit_int <= mux_trace;
            q_state <= IDLE;
          when WORD0 =>
            frame_word <= queue(0);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(0,ADDRESS_BITS);
            commit_frame <= TRUE;
            commit_int <= mux_trace or a_state=STOPED;
            q_state <= IDLE;
          when WORD1 =>
            frame_word <= queue(1);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,ADDRESS_BITS);
            q_state <= WORD0;
          end case;
        end if;
      end if;
      
      --trace stride FSM
      case s_state is 
      when INIT =>
        if start_trace then
          s_state <= CAPTURE;
        end if;
      when IDLE =>
        if stride_count=0 or start_trace then
          s_state <= CAPTURE;
        else 
          stride_count <= stride_count-1;
        end if;
      when CAPTURE =>
        stride_count <= trace_stride;
        if not start_trace then
          if trace_last then
            s_state <= INIT;
          elsif trace_stride/=0 then
            s_state <= IDLE;
          end if;
        end if;
      end case;
      
      --trace control FSM
      case t_state is
      when IDLE =>
        
        trace_count <= trace_chunk_len-1;
        next_trace_count <= trace_chunk_len-2;
        last_trace_count <= FALSE;
        if tflags.trace_type=SINGLE_TRACE_D then
          trace_address <= resize(m.size,ADDRESS_BITS);
        elsif state=AVERAGE then
          trace_address <= to_unsigned(1,ADDRESS_BITS);
        else
          trace_address <= to_unsigned(0,ADDRESS_BITS);
        end if;
        
        if start_trace then
          if tflags.trace_type=DOT_PRODUCT_D then
            t_state <= CAPTURE; 
            wr_chunk_state <= DOTPRODUCT; 
          elsif state/=HOLD then 
            t_state <= CAPTURE; 
            wr_chunk_state <= STORE0; 
          end if; 
        end if;
        
      when CAPTURE =>
          
          -- capture trace samples into a bus word
        case wr_chunk_state is
        when STORE0 => 
          trace_reg(63 downto 48) <= trace_chunk;
          if s_state=CAPTURE then
            wr_chunk_state <= STORE1;
          end if;
          
        when STORE1 => 
          trace_reg(47 downto 32) <= trace_chunk;
          if s_state=CAPTURE then
            wr_chunk_state <= STORE2;
          end if;
          
        when STORE2 => 
          trace_reg(31 downto 16) <= trace_chunk;
          if s_state=CAPTURE then
            wr_chunk_state <= WRITE;
            can_write_trace <= free > trace_address;
          end if;
          
        when WRITE => 
          if not can_write_trace then
            t_state <= IDLE;
          elsif s_state=CAPTURE then
            wr_chunk_state <= STORE0;
            frame_we <= (others => TRUE);
            frame_word.data(63 downto 16) <= trace_reg(63 downto 16);
            frame_word.data(15 downto 0) <= trace_chunk;
            frame_word.last <= (0 => last_trace_count, others => FALSE);
            frame_word.discard(0) <= not mux_trace;
            frame_address <= trace_address;
            if last_trace_count then
              -- FIXME needs to be state based
              commit_frame <= a_state=ACCUM or a_state=WAITING;
              frame_length <= length;
            else
              trace_address <= trace_address+1;
              trace_count <= next_trace_count;
              next_trace_count <= next_trace_count-1;
              last_trace_count <= next_trace_count=0;
            end if;
          end if;
        
        when DOTPRODUCT => 
          if s_state=CAPTURE then
            if not last_trace_count then
              trace_count <= next_trace_count;
              next_trace_count <= next_trace_count-1;
              last_trace_count <= next_trace_count=0;
            else
              t_state <= IDLE;
            end if;
          end if;
        end case;
        
      when DONE =>
        null;
      end case;
      
      -- SINGLE_TRACE_D and DOT_PRODUCT_D move through same FSM states
      -- But DOT_PRODUCT_D does not write trace words to the framer.
      -- AVERAGE_TRACE_D dumps immediately on second pulse or peak
      
      if m.pre_pulse_start and state=IDLE then 
        --FIXME this is an issue when the thresholds change downstream while 
        --capturing a trace, as they can span multiple pulse_starts.
        --A work-around is to disable before register changes then re-enable.
        enable_reg <= enable; 
                              
        tflags.trace_signal <= m.trace_signal;
        tflags.trace_type <= m.trace_type;
        mux_trace <= (pre_detection=TRACE_DETECTION_D and 
                     m.trace_type=SINGLE_TRACE_D);
        
        case m.pre_eflags.event_type.detection is
        when PEAK_DETECTION_D | AREA_DETECTION_D | PULSE_DETECTION_D =>
          length <= resize(m.pre_size,ADDRESS_BITS+1);
          
        when TRACE_DETECTION_D => 
          case m.trace_type is
            
          when SINGLE_TRACE_D =>
            length 
              <= resize(m.pre_size,ADDRESS_BITS+1)+trace_chunk_len;
              
          when AVERAGE_TRACE_D =>
            length <= resize(trace_chunk_len,ADDRESS_BITS+1);
            
          when DOT_PRODUCT_D => 
            length <= resize(m.pre_size,ADDRESS_BITS+1)+1;
            dot_product_go <= TRUE;
          end case;
        end case;
      end if;
      
      if not commiting then
        free <= framer_free;
      end if; 

      -- queue to framer 
        
      --initialise new trace and count strides
      --gather trace words and write to framer
      --FIXME combine into 0ne FSM
      
      case state is 
      when IDLE =>
        just_started <= TRUE;
        pulse_stamped <= FALSE;
        if pulse_start and enable then 
          if free >= resize(m.pre_size,ADDRESS_BITS+1) then
            if TRACE_FROM_STAMP then
              start_trace 
                <= m.pre_stamp_pulse and pre_detection=TRACE_DETECTION_D;
            else 
              start_trace <= pulse_start and pre_detection=TRACE_DETECTION_D;
            end if;
            state <= FIRSTPULSE;
            tflags.multipulse <= FALSE;
            tflags.multipeak <= FALSE;
          else
            overflow_int <= TRUE;
          end if;
        end if;
        
      when FIRSTPULSE =>
        just_started <= FALSE; 
        
        if TRACE_FROM_STAMP then
          start_trace <= m.pre_stamp_pulse and detection=TRACE_DETECTION_D;
        end if; 
        
        if m.pulse_threshold_neg and not just_started then
          
          if not m.above_area_threshold then
            -- under area threshold -- dump 
            dump_int <= pulse_stamped and mux_trace;
            t_state <= IDLE;
            wr_chunk_state <= STORE0;
            if m.pulse_start and detection/=PEAK_DETECTION_D then 
              pulse_stamped <= m.stamp_pulse;
              tflags.multipulse <= FALSE;
              tflags.multipeak <= FALSE;
            else
              state <= IDLE;
            end if;
            
          else
            -- valid end of pulse 
            if detection=TRACE_DETECTION_D then
              
              pulse_reg <= pulse;
              state <= TRACING;
              if (m.pulse_start and t_state=CAPTURE) then
--                 (m.peak_start and m.eflags.peak_number/=0) then
                if tflags.trace_type=AVERAGE_TRACE_D and not trace_last then
                  --valid multi-pulse trace -- dump
--                  dump_int <= pulse_stamped and mux_trace; 
                  pulse_stamped <= FALSE;
                  state <= IDLE;
                  t_state <= IDLE;
                  multipulse <= TRUE;
                else
                  tflags.multipulse <= m.pulse_start;
                end if;
              end if;
            
            elsif detection=AREA_DETECTION_D then
              if m.pulse_start then
                if full then
                  pulse_stamped <= FALSE;
                  overflow_int <= TRUE;
                  state <= IDLE;
                else
                  pulse_stamped <= m.stamp_pulse;
                  just_started <= TRUE;
                end if;
              else
                state <= IDLE;
              end if;
              
              q_state <= SINGLE;
              queue(0) <= to_streambus(area,ENDIAN);
              frame_length <= length;
              commiting <= TRUE;
              free <= framer_free - frame_length;
                
            else -- must be normal pulse
              
              if m.pulse_start and detection=PULSE_DETECTION_D then
                if full then
                  pulse_stamped <= FALSE;
                  overflow_int <= TRUE;
                  state <= IDLE;
                else
                  pulse_stamped <= m.stamp_pulse;
                  just_started <= TRUE;
                end if;
              else
                state <= IDLE;
              end if;
              
              if q_state=IDLE then 
                queue(0) <= to_streambus(pulse,0,ENDIAN);
                queue(1) <= to_streambus(pulse,1,ENDIAN);
                frame_length <= length;
                pulse_peak_word <= to_streambus(pulse_peak,TRUE,ENDIAN);
                pulse_peak_valid <= TRUE;
                peak_address <= resize(m.last_peak_address,ADDRESS_BITS);
                commiting <= TRUE;
                free <= framer_free - frame_length;
                q_state <= WORD1;
              else
                error_int <= TRUE;
                dump_int <= pulse_stamped;
              end if;
              
            end if;
          end if;
        else
          if detection=TRACE_DETECTION_D and (t_state=DONE or trace_last) then
            --FIXME
            -- trace is complete before pulse end
            t_state <= IDLE;
            if mux_trace or wr_chunk_state=DOTPRODUCT then
              state <= WAITPULSEDONE;
            elsif a_state=ACCUM and last_accum_count then
              state <= AVERAGE;
            end if;
          elsif (m.pulse_start and not just_started) then
--                (m.peak_start and m.eflags.peak_number/=0) then
            if tflags.trace_type=AVERAGE_TRACE_D then
--              dump_int <= pulse_stamped; 
              pulse_stamped <= FALSE;
              state <= IDLE;
              t_state <= IDLE;
              multipulse <= TRUE;
            else
              tflags.multipulse <= m.pulse_start;
            end if;
          end if; 
        end if;
        
      when TRACING =>  -- pulse has ended
        if trace_last then
          t_state <= IDLE;
          if a_state=ACCUM and last_accum_count then
            state <= AVERAGE;
          else
            state <= IDLE;
          end if;
          if mux_trace then
            if q_state=IDLE then
              queue(0) <= to_streambus(pulse_reg_trace,0,ENDIAN); 
              queue(1) <= to_streambus(pulse_reg_trace,1,ENDIAN);
              frame_length <= length;
              commiting <= TRUE;
              free <= framer_free - frame_length;
              q_state <= WORD1;
            else  
              error_int <= TRUE;
              dump_int <= pulse_stamped;
            end if;
          end if;
        else
          if m.pulse_start then
            if tflags.trace_type=AVERAGE_TRACE_D then
--              dump_int <= pulse_stamped and mux_trace; 
              multipulse <= TRUE;
              pulse_stamped <= FALSE;
              state <= IDLE;
              t_state <= IDLE;
            else
              tflags.multipulse <= m.pulse_start;
              tflags.multipeak <= m.peak_start;
            end if;
          end if;
        end if;
        
      when WAITPULSEDONE =>
        --can't be accumulating trace 
        if TRACE_FROM_STAMP then
          start_trace <= m.pre_stamp_pulse and detection=TRACE_DETECTION_D;
        end if; 
        if m.pulse_threshold_neg then 
          if not m.above_area_threshold then
            dump_int <= pulse_stamped;
          else
            if q_state=IDLE then
              queue(0) <= to_streambus(trace,0,ENDIAN); 
              queue(1) <= to_streambus(trace,1,ENDIAN);
              frame_length <= length;
              commiting <= TRUE;
              free <= framer_free - frame_length;
              q_state <= WORD1;
            else  
              error_int <= TRUE;
              dump_int <= pulse_stamped;
            end if;
          end if;
          
          --FIXME not sure this will work if not TRACE_FROM_STAMP
--          if m.pulse_start and detection=TRACE_DETECTION_D then
          if pulse_start and pre_detection=TRACE_DETECTION_D and enable then
            if full then
              pulse_stamped <= FALSE;
              overflow_int <= TRUE;
              state <= IDLE;
              t_state <= IDLE;
            else
              pulse_stamped <= m.stamp_pulse;
              just_started <= TRUE;
              tflags.multipulse <= FALSE;
              tflags.multipeak <= FALSE;
              state <= FIRSTPULSE;
              t_state <= IDLE;
              if not TRACE_FROM_STAMP then
                start_trace <= TRUE;
              end if;
            end if;
          else
            t_state <= IDLE;
            state <= IDLE;
          end if;
        else
          if m.pulse_start then
            tflags.multipulse <= TRUE;
          end if;
          if m.peak_start then  
              tflags.multipeak <= TRUE;
          end if;
        end if;
        
      when AVERAGE =>
        start_trace <= start_average;
        if trace_last then
            queue(0) <= to_streambus(average_trace,0,ENDIAN); 
            frame_length <= length+1;
            commiting <= TRUE;
            start_int <= TRUE;
            free <= framer_free - frame_length - 1;
            q_state <= WORD0;
            state <= HOLD;
            multipeak <= FALSE;
            multipulse <= FALSE;
            mux_trace <= FALSE;
            t_state <= IDLE;
        end if;
        
      when HOLD =>
        if pulse_start and m.trace_type/=AVERAGE_TRACE_D then
          state <= IDLE;
        end if;
        
      end case;
     
      -- peak recording 
      if m.peak_stop and enable_reg then 
        if state=FIRSTPULSE or state=WAITPULSEDONE then 
          if m.eflags.peak_number/=0 and not mux_trace then
--            dump_int <= m.pulse_stamped and mux_trace;
            multipeak <= TRUE;
            if tflags.trace_type=AVERAGE_TRACE_D then
              q_state <= IDLE;
              state <= IDLE;
              pulse_stamped <= FALSE;
            end if;
          elsif pulse_peak_valid and wr_chunk_state=WRITE then
            error_int <= TRUE;
            q_state <= IDLE;
            state <= IDLE;
            dump_int <= m.pulse_stamped and mux_trace;
            pulse_stamped <= FALSE;
          else
            pulse_peak_word <= to_streambus(pulse_peak,FALSE,ENDIAN);
            peak_address <= resize(m.peak_address,ADDRESS_BITS);
            pulse_peak_valid <= mux_trace;
          end if;
        elsif m.eflags.event_type.detection=PEAK_DETECTION_D then
          if free=0 then
            overflow_int <= TRUE;
            q_state <= IDLE;
            state <= IDLE;
            dump_int <= TRUE; --FIXME check that it is always stamped
            peak_stamped <= FALSE;
          else
            queue(0) <= to_streambus(peak,ENDIAN);
            frame_length <= length;
            q_state <= SINGLE;
            commiting <= TRUE;
            free <= framer_free-1;
          end if;
        end if;
      end if;
      
      -- time stamping
      if m.eflags.event_type.detection=PEAK_DETECTION_D and m.stamp_peak and 
         enable_reg then
        if mux_full then
          error_int <= TRUE;
          peak_stamped <= FALSE;
        else
          start_int <= TRUE;  
          peak_stamped <= TRUE;
        end if;
      elsif (state=FIRSTPULSE or state=WAITPULSEDONE) and m.stamp_pulse and 
            enable_reg then
        if mux_full then
          error_int <= TRUE;
          pulse_stamped <= FALSE;
        else
          start_int <= mux_trace or wr_chunk_state=DOTPRODUCT;  
          pulse_stamped <= TRUE;
        end if;
      end if; 
        
      if commit_int or dump_int or error_int then
        commiting <= FALSE;
      end if;
        
    end if;
  end if;
end process main;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
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
  ready => ready_int
);

streamMux:process(
  a_state,acc_ready,reg_ready,stream_int,valid_int,wait_ready,wait_valid, 
  dp_trace_start,start_trace,accum_trace_last,trace_last, acc_chunk, trace_chunk 
)
begin
  dp_sample <= signed(acc_chunk);
  dp_trace_go <= dp_trace_start;
  dp_trace_last <= trace_last;
  if a_state=WAITING then
    ready_int <= wait_ready;
    reg_valid <= wait_valid;
  elsif a_state=ACCUM then
    dp_trace_last <= accum_trace_last;
    ready_int <= acc_ready;
    reg_valid <= FALSE;
  else
    dp_sample <= signed(set_endianness(trace_chunk,ENDIAN));
    dp_trace_go <= start_trace;
    ready_int <= reg_ready;
    reg_valid <= valid_int;
    reg_stream <= stream_int;
  end if;
end process streamMux;

accumFSM:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      a_state <= IDLE;
      rd_chunk_state <= IDLE;
      acc_ready <= FALSE;
      accumulate <= FALSE;
    else
      accumulate <= FALSE;
      case a_state is 
      when IDLE =>
        accum_count <= (ACCUMULATE_N => '0', others => '1');
        next_accum_count <= to_unsigned(2**ACCUMULATE_N-2,ACCUMULATE_N+1);
        last_accum_count <= ACCUMULATE_N=0;
        wait_ready <= FALSE;
        wait_valid <= FALSE;
        if tflags.trace_type=AVERAGE_TRACE_D and enable_reg then
          a_state <= WAITING;
        end if;
      when WAITING => 
        wait_ready <= FALSE;
        wait_valid <= FALSE;
        if valid_int and not wait_ready then
          if stream_int.discard(0) then
            a_state <= ACCUM;
            accumulate <= TRUE;
            accum_count <= next_accum_count;
            next_accum_count <= next_accum_count-1;
            last_accum_count <= next_accum_count=0;
          else
            wait_ready <= TRUE;
            wait_valid <= TRUE;
          end if;
        end if;
      when ACCUM =>
        --FIXME what if trace last and dumped, is that possible?
        if trace_last and not last_accum_count then
          accum_count <= next_accum_count;
          next_accum_count <= next_accum_count-1;
          last_accum_count <= next_accum_count=0;
        end if;
        if accumulate_done then
          a_state <= SEND;
          rd_chunk_state <= IDLE;
        end if;
      when SEND =>
        if average_last then
          a_state <= STOPED;
        end if;
      when STOPED =>
        if tflags.trace_type/=AVERAGE_TRACE_D and enable_reg then
          a_state <= IDLE;
        end if;
      end case;
      
      accum_trace_last <= FALSE;
      dp_trace_start <= FALSE;
      case rd_chunk_state is 
      when IDLE =>
        acc_ready <= FALSE;
        dp_trace_start <= FALSE;
        if a_state=ACCUM then
          rd_chunk_state <= WAIT_TRACE;
        end if;
      when WAIT_TRACE =>
        acc_ready <= FALSE;
        if valid_int then
          rd_chunk_state <= READ3;
          dp_trace_start <= TRUE;
        end if;
      when READ3 =>
        acc_chunk <= set_endianness(stream_int.data(63 downto 48),ENDIAN);
        acc_ready <= FALSE;
        rd_chunk_state <= READ2;
      when READ2 =>
        acc_chunk <= set_endianness(stream_int.data(47 downto 32),ENDIAN);
        acc_ready <= FALSE;
        rd_chunk_state <= READ1;
      when READ1 =>
        acc_chunk <= set_endianness(stream_int.data(31 downto 16),ENDIAN);
        rd_chunk_state <= READ0;
        acc_ready <= TRUE;
      when READ0 =>
        acc_chunk <= set_endianness(stream_int.data(15 downto 0),ENDIAN);
        acc_ready <= FALSE;
        if stream_int.last(0) then
          accum_trace_last <= TRUE;
          rd_chunk_state <= WAIT_TRACE;
        else
          rd_chunk_state <= READ3; 
        end if;
      end case;
    end if;
  end if;
end process accumFSM;

dotproductDSP:entity work.dot_product2
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  TRACE_CHUNKS => TRACE_CHUNKS,
  WIDTH => WIDTH,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH,
  ACCUMULATE_N => ACCUMULATE_N
)
port map(
  clk => clk,
  reset => reset,
  stop => stop,
  sample => dp_sample,
  sample_valid => dp_sample_valid,
  trace_start => dp_trace_go,
  trace_last => dp_trace_last,
  accumulate => accumulate,
  accumulate_done => accumulate_done,
  dp_start => dot_product_go,
  average => average_sample,
  average_start => start_average,
  average_last => average_last,
  dot_product => dot_product,
  dot_product_valid => dot_product_valid
);

outputReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => reg_stream,
  ready_out => reg_ready,
  valid_in => reg_valid,
  stream => stream,
  ready => ready,
  valid => valid
);
end architecture RTL;
