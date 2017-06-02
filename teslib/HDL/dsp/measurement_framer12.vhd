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
  DP_ADDRESS_BITS:integer:=11; -- sets max trace length
  ACCUMULATOR_WIDTH:natural:=36;
  ACCUMULATE_N:natural:=18;
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
signal pulse,first_pulse:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal pulse_peak_word,dp_word,dp_word_reg:streambus_t;
--signal dot_product_word_valid:boolean;
signal trace_ends_first,trace_ends_last,average_trace:trace_detection_t;
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
signal pre_pulse_start:boolean;
signal peak_stamped,pulse_stamped:boolean:=FALSE;

signal pre_detection,detection:detection_d;
signal full,pre_full:boolean;

-- TRACE control registers implemented as constants

--constant TRACE_CHUNK_LENGTH_BITS:natural:=ceilLog2(TRACE_CHUNKS+1);
--constant trace_chunk_len:unsigned(TRACE_CHUNK_LENGTH_BITS-1 downto 0)
----         :=to_unsigned((268/16)+1,FRAMER_ADDRESS_BITS+1);
--         :=to_unsigned(TRACE_CHUNKS,TRACE_CHUNK_LENGTH_BITS);
--constant TRACE_STRIDE_BITS:integer:=5;
--constant trace_stride:unsigned(TRACE_STRIDE_BITS-1 downto 0)
--         :=(others => '0');
-- trace signals
signal trace_reg:std_logic_vector(BUS_DATABITS-1 downto 16);
signal trace_chunk,trace_chunk_debug:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal acc_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal stride_count:unsigned(TRACE_STRIDE_BITS-1 downto 0);
signal trace_address,trace_start_address:unsigned(ADDRESS_BITS-1 downto 0);
signal trace_count,trace_count_init:unsigned(TRACE_LENGTH_BITS-1 downto 0);
signal next_trace_count:unsigned(TRACE_LENGTH_BITS-1 downto 0);
signal last_trace_count:boolean;
signal trace_start:boolean;
signal commiting:boolean;
signal overflow_int,error_int:boolean;
signal enable_reg:boolean;
signal can_q_trace,can_q_pulse,can_q_single:boolean;
signal wr_trace_last:boolean;

--FSMs
attribute fsm_encoding:string;
type FSMstate is (IDLE,FIRSTPULSE,TRACING,WAITPULSEDONE,AVERAGE,HOLD);
signal state:FSMstate;
type wrChunkState is (STORE0,STORE1,STORE2,WRITE);
signal wr_chunk_state:wrChunkState; 
type rdChunkState is (IDLE,WAIT_TRACE,READ3,READ2,READ1,READ0);
signal rd_chunk_state:rdChunkState;
type traceFSMstate is (IDLE,CAPTURE);
signal t_state:traceFSMstate;
type queueFSMstate is (IDLE,SINGLE,WORD0,WORD1);
signal q_state:queueFSMstate;
type strideFSMstate is (INIT,IDLE,CAPTURE);
signal s_state:strideFSMstate;
type accumFSMstate is (IDLE,WAITING,ACCUM,SEND,STOPED);
signal a_state:accumFSMstate;
type DPstate is (IDLE,DPWAIT,WRITE,WAITPULSEDONE);
signal dp_state:DPstate;
attribute fsm_encoding of s_state:signal is "one-hot";
attribute fsm_encoding of t_state:signal is "one-hot";
attribute fsm_encoding of q_state:signal is "one-hot";
attribute fsm_encoding of dp_state:signal is "one-hot";

signal acc_ready:boolean;
signal wait_valid,wait_ready:boolean;
signal stream_int:streambus_t;
signal valid_int:boolean;
signal ready_int:boolean;
signal reg_stream:streambus_t;
signal reg_ready:boolean;
signal reg_valid:boolean;
signal average_sample:signed(WIDTH-1 downto 0);
signal mux_wr_en:boolean;
signal start_average,average_last:boolean;

signal accum_count,next_accum_count:unsigned(ACCUMULATE_N downto 0);
signal last_accum_count:boolean;
signal pending:signed(3 downto 0):=(others => '0');
signal stop:boolean;
signal dp_sample:signed(WIDTH-1 downto 0);
signal rd_trace_start:boolean;
signal dp_trace_last,rd_trace_last:boolean;
signal dot_product_go:boolean;
signal dot_product:signed(47 downto 0);
signal dp_valid:boolean;
signal accumulate_done:boolean;
signal multipeak,multipulse:boolean;
signal dp_sample_valid : boolean;
signal dp_trace_start:boolean;
signal start_accumulating:boolean;
signal dp_detection:boolean;
signal trace_done:boolean;

signal dp_address:unsigned(ADDRESS_BITS-1 downto 0);
signal commit_pulse:boolean;
signal trace_wr_en:boolean;
signal inc_accum:boolean;
--signal pulse_wr_en:boolean;
signal averaging:boolean;
signal zero_stride:boolean;
signal trace_full:boolean;
signal trace_overflow:boolean;
signal eflags:detection_flags_t;
signal dp_length:unsigned(ADDRESS_BITS downto 0);
signal dp_before_pulse:boolean;
signal dp_dump,dp_write:boolean;
-- size of the event part (not including any trace)
-- DEPENDS on PEAK_COUNT_BITS FIXME change to 3 bits to minimise comparator.
constant SIZE_BITS:natural:=5; 
signal size:unsigned(SIZE_BITS-1 downto 0);
signal trace_detection,area_detection,pulse_detection:boolean;

function to_streambus(v:std_logic_vector;last:boolean;endian:string) 
return streambus_t is
variable s:streambus_t;
begin
  s.data:=set_endianness(v,endian);
  s.last:=(0 => last, others => FALSE);
  s.discard:=(others => FALSE);
  return s;
end function;

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
pulse.size <= resize(length,CHUNK_DATABITS);
pulse.flags <= eflags;
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
--tflags.offset <= offset;
--tflags.stride <= trace_stride;
--tflags.trace_signal <= trace_signal;
--tflags.trace_type <= trace_type;

--flags for the average trace
atflags.offset <= tflags.offset;
atflags.stride <= tflags.stride;
atflags.multipeak <= multipeak;
atflags.multipulse <= multipulse;
atflags.trace_signal <= tflags.trace_signal;
atflags.trace_type <= AVERAGE_TRACE_D;

--when trace shorter than pulse need to use current pulse data
trace_ends_first.size <= resize(length,CHUNK_DATABITS);
trace_ends_first.flags <= eflags; 
trace_ends_first.trace_flags <= tflags;
trace_ends_first.length <= m.pulse_length;
trace_ends_first.offset <= m.time_offset;
trace_ends_first.area <= m.pulse_area;

--used for AVERAGE_TRACE_D
average_trace.size <= resize(length+1,CHUNK_DATABITS);
average_trace.flags <= eflags;
average_trace.trace_flags <= atflags;

--used when trace longer than pulse use stored pulse data
trace_ends_last.size <= resize(length,CHUNK_DATABITS);
trace_ends_last.flags <= first_pulse.flags;
trace_ends_last.trace_flags <= tflags;
trace_ends_last.length <= first_pulse.length;
trace_ends_last.offset <= first_pulse.offset;
trace_ends_last.area <= first_pulse.area;

pulse_peak.minima <= m.min_value;
pulse_peak.timestamp <= m.peak_time;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.height <= m.height;

peak.height <= m.height;
peak.minima <= m.min_value;
peak.flags <= eflags;

area.flags <= eflags;
area.area <= m.pulse_area;

dp_word <= to_streambus(resize(dot_product,BUS_DATABITS),TRUE,ENDIAN);

pre_detection <= m.pre_eflags.event_type.detection;
detection <= m.eflags.event_type.detection;
  
pre_pulse_start <= pre_detection/=PEAK_DETECTION_D and m.pre_pulse_start;  

can_q_single <= q_state=IDLE;
can_q_trace <= q_state=IDLE;
can_q_pulse <= q_state=IDLE;

pre_full <= free < resize(m.pre_size,ADDRESS_BITS+1);

full <= free <= length;

trace_chunk_debug <= set_endianness(trace_chunk,ENDIAN);
traceSignalMux:process(clk)
begin
  if rising_edge(clk) then
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

--dot_product_word.last <= (0 => TRUE, others => FALSE);

--trace_last <= s_state=CAPTURE and last_trace_count and 
--              (wr_chunk_state=WRITE and can_write_trace); 
              
main:process(clk)
variable space_for_trace:boolean;
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
      area_overflow <= FALSE;
      enable_reg <= FALSE;
      
      q_state <= IDLE;
      state <= IDLE;
      t_state <= IDLE;
      wr_chunk_state <= STORE0;
      
      mux_wr_en <= FALSE;
      frame_word.discard <= (others => FALSE);
      multipulse <= FALSE;
      multipeak <= FALSE;
      
      last_trace_count <= FALSE;
      
      trace_start_address <= (others => '-');
    else
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      commit_frame <= FALSE;
      commit_int <= FALSE;
      frame_we <= (others => FALSE);
      trace_start <= FALSE;
      space_for_trace:=free > trace_address;
      inc_accum <= FALSE;
      dot_product_go <= FALSE;
      dp_dump <= FALSE;
      dp_write <= FALSE;
      
      -- capture register settings when pulse FSM is idle and a new pulse starts
      -- TODO consider if there is an issue when registers change upstream
      -- on a new pulse even when this FSM is not idle
      if m.pre_pulse_start and state=IDLE then 
        enable_reg <= enable; 
                              
        tflags.trace_length <= m.pre_tflags.trace_length;
        tflags.stride <= m.pre_tflags.stride;
        zero_stride <= m.pre_tflags.stride=0; 
        tflags.trace_signal <= m.pre_tflags.trace_signal;
        tflags.trace_type <= m.pre_tflags.trace_type;
        
        eflags <= m.pre_eflags;
         
        dp_detection <= m.pre_tflags.trace_type=DOT_PRODUCT_D;
        
        trace_detection <= pre_detection=TRACE_DETECTION_D;
        area_detection <= pre_detection=AREA_DETECTION_D;
        pulse_detection <= pre_detection=PULSE_DETECTION_D;
        
        trace_wr_en <= pre_detection=TRACE_DETECTION_D and
                       m.pre_tflags.trace_type/=DOT_PRODUCT_D;
        
        mux_wr_en <= pre_detection=TRACE_DETECTION_D and 
                     (
                       m.pre_tflags.trace_type=SINGLE_TRACE_D or 
                       m.pre_tflags.trace_type=DOT_PRODUCT_D
                     );
              
        averaging <= m.pre_tflags.trace_type=AVERAGE_TRACE_D and 
                     pre_detection=TRACE_DETECTION_D;
                     
        trace_count_init <= m.pre_tflags.trace_length-1;
        
        dp_address <= resize(m.pre_size, ADDRESS_BITS);
        
        
        case m.pre_eflags.event_type.detection is
        when PEAK_DETECTION_D | AREA_DETECTION_D | PULSE_DETECTION_D =>
          length <= resize(m.pre_size,ADDRESS_BITS+1);
           
        when TRACE_DETECTION_D => 
          case m.pre_tflags.trace_type is
          when SINGLE_TRACE_D =>
            length 
              <= resize(m.pre_size,ADDRESS_BITS+1) + m.pre_tflags.trace_length;
            size <= resize(m.pre_size,SIZE_BITS);
            tflags.offset <= resize(m.pre_size,PEAK_COUNT_BITS);
            trace_start_address <= resize(m.pre_size,ADDRESS_BITS);
              
          when AVERAGE_TRACE_D =>
            length <= resize(m.pre_tflags.trace_length,ADDRESS_BITS+1);
            size <= resize(m.pre_size+1,SIZE_BITS);
            tflags.offset <= to_unsigned(1,PEAK_COUNT_BITS);
            trace_start_address <= to_unsigned(0,ADDRESS_BITS);
            
          when DOT_PRODUCT_D => 
            length <= resize(m.pre_size+1,ADDRESS_BITS+1);
            size <= resize(m.pre_size+1,SIZE_BITS);
            tflags.offset <= resize(m.pre_size,PEAK_COUNT_BITS);
            trace_start_address <= (others => '-'); 
            dot_product_go <= TRUE;
            
          when DOT_PRODUCT_TRACE_D =>
            trace_start_address <= (others => '-'); --resize(m.size+1,ADDRESS_BITS); --FIXME ??
            
          end case;
        end case;
      end if;
      
      -- event writing queue
      if not (s_state=CAPTURE and wr_chunk_state=WRITE) then 
        if pulse_peak_valid then
          frame_word <= pulse_peak_word;
          frame_address <= peak_address;
          frame_we <= (others => TRUE);
          pulse_peak_valid <= FALSE; 
        else
          case q_state is 
          when IDLE =>
            null;
          when SINGLE => 
            frame_word <= queue(0);
            frame_address <= to_unsigned(0,ADDRESS_BITS);
            frame_we <= (others => TRUE);
            commit_frame <= TRUE;
            commit_int <= TRUE;
            q_state <= IDLE;
          when WORD0 =>
            frame_word <= queue(0);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(0,ADDRESS_BITS);
            commit_frame <= commit_pulse;
            commit_int <= mux_wr_en and commit_pulse;
            q_state <= IDLE;
          when WORD1 =>
            frame_word <= queue(1);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,ADDRESS_BITS);
            q_state <= WORD0;
          end case;
        end if;
      end if;
      
      --trace stride FSM --FIXME need to check this actually works
      case s_state is 
      when INIT => 
        if trace_start then
           s_state <= CAPTURE; -- 
        end if;
        
      when IDLE =>
        if stride_count=0 or trace_start then
          s_state <= CAPTURE;
          if wr_chunk_state=WRITE then
            wr_trace_last <= last_trace_count;
            if last_trace_count then
              trace_done <= TRUE;
            end if;
          end if;
        else 
          stride_count <= stride_count-1;
        end if;
        
      when CAPTURE =>
        stride_count <= tflags.stride;
        if wr_trace_last then
          s_state <= INIT;
        elsif not zero_stride then
          s_state <= IDLE;
        elsif wr_chunk_state=STORE2 then
          wr_trace_last <= last_trace_count and zero_stride;
          if last_trace_count then
            trace_done <= zero_stride;
          end if;
        end if;
      end case;
     
     --wr_chunk FSM gathers samples into a bus word
--      trace_overflow <= wr_chunk_state=WRITE and s_state=CAPTURE and 
--                        trace_wr_en and trace_full;

      --wr_trace_last <= FALSE;
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
        if s_state=CAPTURE then -- 3rd chunk valid
          wr_chunk_state <= WRITE;
          trace_full <= free <= trace_address;
        end if;
        
      when WRITE => 
        trace_full <= framer_free <= trace_address;
        if s_state=CAPTURE then 
          wr_trace_last <= FALSE;
          if trace_full and trace_wr_en then 
            wr_chunk_state <= STORE0;
            trace_overflow <= TRUE;
          else --if trace_wr_en then --4th chunk captured
            wr_chunk_state <= STORE0;
            frame_we <= (others => trace_wr_en);
            frame_word.data(63 downto 16) <= trace_reg(63 downto 16);
            frame_word.data(15 downto 0) <= trace_chunk;
            frame_word.last <= (0 => last_trace_count, others => FALSE);
            frame_word.discard(0) <= averaging;
            frame_address <= trace_address;
            if not last_trace_count then 
              trace_address <= trace_address+1;
            end if;
            trace_count <= next_trace_count;
            next_trace_count <= next_trace_count-1;
            last_trace_count <= next_trace_count=0;
          end if;
        end if;
      end case;
      
      --trace control FSM
      case t_state is
      when IDLE =>
        
        if a_state=SEND then
          trace_address <= trace_start_address+1;
        else
          trace_address <= trace_start_address;
        end if;
        
        trace_count <= trace_count_init;
        next_trace_count <= trace_count_init-1;
        last_trace_count <= FALSE;
        wr_chunk_state <= STORE0; 
--        s_state <= INIT;
        
        if trace_start and state/=HOLD and enable_reg then
          t_state <= CAPTURE; 
        end if;
        
      when CAPTURE =>
        if trace_start then 
          wr_chunk_state <= STORE0; 
          trace_address <= trace_start_address;
          trace_count <= trace_count_init;
          next_trace_count <= trace_count_init-1;
          last_trace_count <= FALSE;
        elsif wr_trace_last or trace_overflow then
          t_state <= IDLE;
          wr_chunk_state <= STORE0; 
        end if;
         
      end case;
      
      -- SINGLE_TRACE_D and DOT_PRODUCT_D move through same FSM states
      -- But DOT_PRODUCT_D does not write trace words to the framer.
      -- AVERAGE_TRACE_D dumps immediately on second pulse or peak
      
      
      if not commiting then
        free <= framer_free;
      end if; 
      
      if commit_int or dump_int or error_int then
        commiting <= FALSE;
      end if;
      
      -- dot product valid 5 clks after trace last
      -- if trace_last before pulse done FSM could have transitioned to IDLE 
      -- trace_pulse_reg not written till trace_last so can assume 
      -- dot_product word always written after trace_pulse_reg?
      -- 
      -- case 1 trace shorter than pulse
      --   can write dp and pulse at same time
      --   will be WAITPULSEDONE *or* IDLE when dp_valid add WAITDP state?
      -- case 2 trace longer than pulse 
      --    write pulse when done 
      --    dp valid 5 clocks after trace_last would be nice to keep main fsm 
      --    running
      -- set commiting when trace_last
      
      -- if dp valid before end of pulse
      --    write it without committing
      
      -- dot product FSM dp is not valid till 5 clocks after trace_last
      --FIXME handle dumps
      case dp_state is 
      when IDLE =>
        dp_length <= length;
        if dp_detection and wr_trace_last then
          dp_before_pulse <= (state=FIRSTPULSE or state=WAITPULSEDONE) and 
                              not m.pulse_threshold_neg;
          dp_state <= DPWAIT;
        end if;
      when DPWAIT =>
        if dp_dump then
          dp_state <= IDLE;
        elsif dp_valid  then -- can happen before end of pulse need to store
          if dp_before_pulse then
            dp_state <= WAITPULSEDONE;
            dp_word_reg <= dp_word;
          else
            dp_state <= IDLE;
            frame_word <= dp_word;
            frame_address <= dp_address;
            frame_length <= dp_length;
            frame_we <= (others => TRUE); 
            commit_frame <= TRUE;
            commit_int <= TRUE;
          end if;
        end if;
      when WAITPULSEDONE =>
        if dp_dump then
          dp_state <= IDLE;
        elsif dp_write then --FIXME needs to be a clk later
          dp_state <= WRITE; 
        end if;  
      when WRITE =>
        if q_state=IDLE then --FIXME can this be earlier
          dp_state <= IDLE;
          frame_word <= dp_word_reg;
          frame_address <= dp_address;
          frame_length <= dp_length;
          frame_we <= (others => TRUE); 
          commit_frame <= TRUE;
          commit_int <= TRUE;
         end if;
      end case;
      
      --trace start
      if state=AVERAGE then
        trace_start <= start_average;
      else
        if TRACE_FROM_STAMP then 
          trace_start <= m.pre_stamp_pulse;
        end if;
        if not TRACE_FROM_STAMP then
          trace_start <= m.pre_pulse_start;
        end if;
      end if;
      if trace_start or trace_overflow then
        trace_done <= FALSE;
      end if;
        
      if a_state=IDLE then
        accum_count <= (ACCUMULATE_N => '0', others => '1');
        next_accum_count <= to_unsigned(2**ACCUMULATE_N-2,ACCUMULATE_N+1);
        last_accum_count <= ACCUMULATE_N=0;
--      elsif inc_accum and not last_accum_count then
      elsif wr_trace_last and averaging and not last_accum_count then
        accum_count <= next_accum_count;
        next_accum_count <= next_accum_count-1;
        last_accum_count <= next_accum_count=0;
      end if;
      
      -- pulse FSM
      case state is 
      when IDLE =>
        just_started <= TRUE;
        pulse_stamped <= FALSE;
        if pre_pulse_start and enable then 
          if size < free then
            state <= FIRSTPULSE;
            tflags.multipulse <= FALSE;
            tflags.multipeak <= FALSE;
          else
            overflow_int <= TRUE;
          end if;
        end if;
        
      when FIRSTPULSE =>
        just_started <= FALSE; --FIXME is this still needed? 
        
        if trace_overflow and trace_detection then
          t_state <= IDLE;
          overflow_int <= TRUE;
          dump_int <= pulse_stamped or m.stamp_pulse;
          dp_dump <= TRUE;
          
        elsif m.pulse_threshold_neg and not just_started then

          if not m.above_area_threshold then
            --dump the pulse that is ending
            t_state <= IDLE;
            dump_int <= pulse_stamped or m.stamp_pulse; 
            dp_dump <= TRUE;
            -- if pre_pulse_start space will be free as previous pulse was 
            -- dumped.
            if not pre_pulse_start then 
              state <= IDLE; 
            end if;
          else
            -- valid pulse_threshold_neg 
            -- could also be pre_pulse_start and/or trace_last 
            -- can't be pulse_start as pre_pulse_start should have been handled 
            -- last clock.
            
            --store the first_pulse for use in trace_detections
            first_pulse <= pulse; 
            
            --------------------------------------------------------------------
            -- next state logic for valid pulse_threshold_neg (FIRSTPULSE)
            --------------------------------------------------------------------
            if pre_pulse_start then -- new pulse will start next clock
              if trace_detection then
                if averaging then
                  -- multiple pulses in trace, dump and don't include in average.
                  multipulse <= TRUE;
                  state <= IDLE; 
                  t_state <= IDLE;
                else
                  if wr_trace_last then
                    -- may have queue error
                    state <= IDLE; -- new pulse and trace
                  else
                    -- no queueing
                    state <= TRACING; -- end of first pulse, continue tracing.
                  end if;
                end if;
              else -- not tracing
                -- a queue error will dump ending pulse
--                if q_state/=IDLE then 
--                  if free < size then --must be space as previous pulse dumped
--                    state <= IDLE;  --overflow for NEW pulse 
--                  end if;
--                else
                if q_state=IDLE then
                  -- ending pulse not dumped but not yet commited, 
                  -- check space for two events
                  if free < size & '0' then
                    state <= IDLE;  --overflow for NEW pulse
                  end if;
                end if;
              end if;
            else -- not pre_pulse start
              if trace_detection then
                if wr_trace_last then
                  state <= IDLE; 
                else
                  state <= TRACING; -- end of first pulse, continue tracing.
                end if;
              else -- not tracing
                if q_state/=IDLE then 
                  state <= IDLE;  --queue error dump ending pulse 
                end if;
              end if;       
            end if;
              
              
            --------------------------------------------------------------------
            -- output logic for valid pulse_threshold_neg (FIRSTPULSE)
            --------------------------------------------------------------------

            if trace_detection then
              if wr_trace_last then
                -- TODO test pre_pulse_start here
                -- dump if SINGLE_TRACE_D
                if averaging then
                  commit_frame <= TRUE;
                  frame_length <= length;
                elsif q_state=IDLE then 
                  dp_write <= TRUE;
                  queue(0) <= to_streambus(trace_ends_first,0,ENDIAN); 
                  queue(1) <= to_streambus(trace_ends_first,1,ENDIAN);
                  frame_length <= length;
                  -- will commit when dp_valid
                  commit_pulse <= not dp_detection; 
                  commiting <= TRUE;
                  free <= framer_free - length;
                  q_state <= WORD1;
                  -- can skip space check if pre_pulse_start, handled by 
                  -- trace_overflow, pulse_peak cannot occur before tracing?
                  -- FIXME can happen before first trace word is written, 
                  -- which takes 6 clocks. Add check at pulse peak write?
                else  
                  error_int <= TRUE;
                  --FIXME consider effect of m.stamp_pulse
                  dump_int <= pulse_stamped; 
                  dp_dump <= TRUE;
                end if;
              elsif pre_pulse_start and averaging then 
                multipulse <= TRUE; --dump due to multiple pulses
              end if;
              
            else 
              -- not trace_detection 
              if q_state=IDLE then 
                
                if area_detection then
                  q_state <= SINGLE; -- assumption here that q is idle
                  queue(0) <= to_streambus(area,ENDIAN);
                end if;
                
                if pulse_detection then
                  queue(0) <= to_streambus(pulse,0,ENDIAN);
                  queue(1) <= to_streambus(pulse,1,ENDIAN);
                  -- write last 
                  pulse_peak_word <= to_streambus(pulse_peak,TRUE,ENDIAN);
                  pulse_peak_valid <= TRUE;
                  peak_address <= resize(m.last_peak_address,ADDRESS_BITS);
                  commit_pulse <= TRUE;
                  q_state <= WORD1;
                end if;
                
                frame_length <= length;
                free <= framer_free - length;
                commiting <= TRUE;
                
                -- if a new pulse is starting, check for space for two events 
                -- as previous pulse not committed yet.
                if pre_pulse_start and free < size & '0' then
                  -- new pulse wont start no need for dump 
                  overflow_int <= TRUE; 
                  dp_dump <= TRUE;
                end if;
                
              else -- queue error
                error_int <= TRUE;
                dump_int <= pulse_stamped;
                dp_dump <= TRUE;
              end if;
            end if;
          end if;
        else -- not end of pulse
          if wr_trace_last then
            state <= WAITPULSEDONE;
          end if;
        end if;
        -- output valid pulse_threshold_neg
        
      when TRACING =>  -- pulse has ended
        
        ------------------------------------------------------------------------
        -- next state logic (TRACING)
        ------------------------------------------------------------------------
        if trace_overflow then
          state <= IDLE;
        elsif wr_trace_last or trace_done then
          if last_accum_count and averaging then
            state <= AVERAGE;
          else
            if pre_pulse_start then 
              -- trace_last 1 clk before new pulse
              -- make sure twice the space is free for new pulse
              if (free < size & '0') and not averaging then 
                --second pulse overflows
                state <= IDLE;
--                t_state <= IDLE;
              else
                state <= FIRSTPULSE;
--                t_state <= IDLE;
              end if;
            else
--              t_state <= IDLE;
              state <= IDLE;
            end if;
          end if;
        else
          --still tracing
          if m.pulse_start then
            if averaging then
              -- multipulse dump
              state <= IDLE;
              t_state <= IDLE;
            end if;
          end if;
        end if;
        
        ------------------------------------------------------------------------
        -- output logic (TRACING)
        ------------------------------------------------------------------------
        if trace_overflow then
          overflow_int <= TRUE;
          dump_int <= pulse_stamped;
          dp_dump <= TRUE;
        elsif wr_trace_last or trace_done then
          if averaging then 
            commit_frame <= TRUE; 
--            inc_accum <= TRUE; --FIXME can 
            frame_length <= length;
          else 
            if q_state=IDLE then
              dp_write <= TRUE;
--              queue(0) <= to_streambus(trace_pulse,0,ENDIAN); 
--              queue(1) <= to_streambus(trace_pulse,1,ENDIAN);
              queue(0) <= to_streambus(trace_ends_last,0,ENDIAN); 
              queue(1) <= to_streambus(trace_ends_last,1,ENDIAN);
              frame_length <= length;
              commit_pulse <= not dp_detection;
              commiting <= TRUE;
              free <= framer_free - length;
              q_state <= WORD1;
            else  
              error_int <= TRUE;
              dump_int <= pulse_stamped;
              dp_dump <= TRUE;
            end if;
          end if;
          if pre_pulse_start then
            --check space for 2 events
            if (free < length(ADDRESS_BITS-1 downto 0) & '0') and 
                trace_wr_en and not averaging then 
              state <= IDLE;
              overflow_int <= TRUE;
            else
              state <= FIRSTPULSE;
              just_started <= TRUE;
              tflags.multipulse <= FALSE;
              tflags.multipeak <= FALSE;
            end if;
          end if;
        else
          if m.pulse_start then
            --multipulse dump
            if averaging then
              multipulse <= TRUE;
              pulse_stamped <= FALSE;
              tflags.multipulse <= TRUE;
            end if;
          end if;
        end if;
        
      when WAITPULSEDONE =>
        --FIXME assure this state can only be reached when TRACE_DETECTION_D 
       
        ------------------------------------------------------------------------
        --next state logic (WAITPULSEDONE)
        ------------------------------------------------------------------------
        if m.pulse_threshold_neg then 
          --this will use the old register settings so enable_reg must be true.
          if pre_pulse_start then 
            -- make sure twice the space is free in case the last pulse  
            -- committed.
            if (free <= size & '0') and not averaging then 
              state <= IDLE; -- dump this new pulse
              t_state <= IDLE;
            else
              t_state <= IDLE;
              if averaging and last_accum_count and 
                 m.above_area_threshold then
                state <= AVERAGE;
              else
                state <= FIRSTPULSE;
              end if;
            end if;
          else
            t_state <= IDLE;
            if averaging and last_accum_count and 
               m.above_area_threshold then
              state <= AVERAGE;
            else
              state <= IDLE;
            end if;
          end if;
        end if;
        
        ------------------------------------------------------------------------
        --output logic
        ------------------------------------------------------------------------
        if m.pulse_threshold_neg then 
          if not m.above_area_threshold then
            dump_int <= pulse_stamped or m.stamp_pulse;
            dp_dump <= TRUE;
          else
            --this will use the old register settings so enable_reg must be true.
            if pre_pulse_start then --and detection=TRACE_DETECTION_D then
              -- make sure twice the space is free in case the block above 
              -- committed.
              if free <= resize(m.size & '0',ADDRESS_BITS+1) then 
                pulse_stamped <= FALSE;
                overflow_int <= TRUE;
                dp_dump <= TRUE;
              else
                pulse_stamped <= m.stamp_pulse;
                just_started <= TRUE;
                tflags.multipulse <= FALSE;
                tflags.multipeak <= FALSE;
              end if;
            end if;
            if not averaging then
              if q_state=IDLE then
                dp_write <= TRUE;
                queue(0) <= to_streambus(trace_ends_first,0,ENDIAN); 
                queue(1) <= to_streambus(trace_ends_first,1,ENDIAN);
                frame_length <= length;
                commit_pulse <= not dp_detection;  --FIXME commit_int?
                commiting <= TRUE;
                free <= framer_free - length;
                q_state <= WORD1;
              else  
                error_int <= TRUE;
                dump_int <= pulse_stamped;
                dp_dump <= TRUE;
              end if;
            else
              commit_frame <= TRUE;
              frame_length <= length;
--              inc_accum <= TRUE;
            end if;
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
        if wr_trace_last then
          queue(0) <= to_streambus(average_trace,0,ENDIAN); 
          frame_length <= length+1;
          commiting <= TRUE;
          start_int <= TRUE;
          free <= framer_free - length - 1;
          q_state <= WORD0;
          state <= HOLD;
          multipeak <= FALSE;
          multipulse <= FALSE;
          mux_wr_en <= TRUE;
        end if;
        
      when HOLD =>
        if pre_pulse_start and m.pre_tflags.trace_type/=AVERAGE_TRACE_D then
          state <= IDLE;
        end if;
        
      end case;
     
      -- peak recording 
      if m.peak_stop and enable_reg then 
        if state=FIRSTPULSE or state=WAITPULSEDONE then 
          if m.eflags.peak_number/=0 and averaging then --FIXME check
            multipeak <= TRUE;
            q_state <= IDLE;
            state <= IDLE;
            pulse_stamped <= FALSE;
          elsif pulse_peak_valid and wr_chunk_state=WRITE and 
                s_state=CAPTURE then
            error_int <= TRUE;
            q_state <= IDLE;
            state <= IDLE;
            dump_int <= m.pulse_stamped and mux_wr_en;
            pulse_stamped <= FALSE;
          else
            pulse_peak_word <= to_streambus(pulse_peak,FALSE,ENDIAN);--?? last?
            peak_address <= resize(m.peak_address,ADDRESS_BITS);
            pulse_peak_valid <= mux_wr_en;
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
      if detection=PEAK_DETECTION_D and m.stamp_peak and enable_reg then
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
          start_int <= mux_wr_en;  
          pulse_stamped <= mux_wr_en;
        end if;
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

internalStreamMux:process(
  a_state,acc_ready,reg_ready,stream_int,valid_int,wait_ready,wait_valid, 
  rd_trace_start,trace_start,rd_trace_last,acc_chunk,trace_chunk,wr_trace_last 
)
begin
  reg_stream <= stream_int;
  if a_state=WAITING then
    dp_sample <= (others => '-');
    dp_trace_last <= FALSE;
    dp_trace_start <= FALSE;
    ready_int <= wait_ready;
    reg_valid <= wait_valid;
  elsif a_state=ACCUM then
    dp_sample <= signed(acc_chunk);
    dp_trace_last <= rd_trace_last;
    dp_trace_start <= rd_trace_start;
    ready_int <= acc_ready;
    reg_valid <= FALSE;
  else
    --calculating dot product
    dp_sample <= signed(set_endianness(trace_chunk,ENDIAN));
    dp_trace_last <= wr_trace_last;
    dp_trace_start <= trace_start;
    ready_int <= reg_ready;
    reg_valid <= valid_int;
  end if;
end process internalStreamMux;

accumFSM:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      a_state <= IDLE;
      rd_chunk_state <= IDLE;
      acc_ready <= FALSE;
    else
      start_accumulating <= FALSE;
      case a_state is 
      when IDLE =>
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
            start_accumulating <= TRUE;
          else
            wait_ready <= TRUE;
            wait_valid <= TRUE;
          end if;
        end if;
        
      when ACCUM =>
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
      
      rd_trace_last <= FALSE;
      rd_trace_start <= FALSE;
      case rd_chunk_state is 
      when IDLE =>
        acc_ready <= FALSE;
        rd_trace_start <= FALSE;
        if a_state=ACCUM then
          rd_chunk_state <= WAIT_TRACE;
        end if;
      when WAIT_TRACE =>
        acc_ready <= FALSE;
        if valid_int then
          rd_chunk_state <= READ3;
          rd_trace_start <= TRUE;
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
          rd_trace_last <= TRUE;
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
  ADDRESS_BITS => DP_ADDRESS_BITS,
  WIDTH => WIDTH,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH,
  ACCUMULATE_N => ACCUMULATE_N
)
port map(
  clk => clk,
  reset => reset,
  stop => stop,
  trace_chunks => resize(length,DP_ADDRESS_BITS+1),
  sample => dp_sample,
  sample_valid => dp_sample_valid,
  trace_start => dp_trace_start,
  trace_last => dp_trace_last,
  accumulate_start => start_accumulating,
  accumulate_done => accumulate_done,
  dp_start => dot_product_go,
  average => average_sample,
  average_start => start_average,
  average_last => average_last,
  dot_product => dot_product,
  dot_product_valid => dp_valid
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
