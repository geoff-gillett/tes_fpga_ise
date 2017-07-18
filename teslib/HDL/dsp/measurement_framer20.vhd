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

--FIXME mux full errors????
entity measurement_framer20 is
generic(
  WIDTH:natural:=16;
  ADDRESS_BITS:integer:=11;
  DP_ADDRESS_BITS:integer:=11; 
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
end entity measurement_framer20;

architecture RTL of measurement_framer20 is

--  
constant CHUNKS:integer:=BUS_CHUNKS;
constant DEPTH:integer:=3;

type write_buffer is array (DEPTH-1 downto 0) of streambus_t;
signal queue:write_buffer;

signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse,first_pulse:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal aux_word_reg:streambus_t;
signal this_pulse_trace_header,first_pulse_trace_header:trace_detection_t;
signal tflags:trace_flags_t;

attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full:signal is "no";

signal framer_free:unsigned(ADDRESS_BITS downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
--signal next_free:signed(ADDRESS_BITS+1 downto 0);
signal frame_length,length:unsigned(ADDRESS_BITS downto 0):=(others => '0');
--
signal pulse_valid:boolean;
signal pulse_overflow:boolean;
signal frame_word:streambus_t;
signal frame_address:unsigned(ADDRESS_BITS-1 downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame,commit_reg,start_reg,dump_reg:boolean; 
signal commit_int,start_int,dump_int,error_int,overflow_int:boolean; 

signal aux_address:unsigned(ADDRESS_BITS-1 downto 0);
signal last_peak_address:unsigned(ADDRESS_BITS-1 downto 0);
signal area_overflow:boolean;
signal pulse_stamped:boolean:=FALSE;

signal pre_detection:detection_d;
-- trace signals
signal trace_reg:std_logic_vector(BUS_DATABITS-1 downto 16);
signal trace_chunk,trace_chunk_debug:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal acc_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal stride_count,next_stride_count:unsigned(TRACE_STRIDE_BITS-1 downto 0);
signal trace_address,trace_start_address:unsigned(ADDRESS_BITS-1 downto 0);
signal trace_count,trace_count_init:unsigned(TRACE_LENGTH_BITS-1 downto 0);
signal next_trace_count:unsigned(TRACE_LENGTH_BITS-1 downto 0);
signal last_trace_count:boolean;
signal trace_start:boolean;
signal committing:boolean;
signal overflow_reg,error_reg:boolean;
signal enable_reg:boolean;
--signal can_q_trace,can_q_pulse,can_q_single:boolean;
signal trace_last:boolean;

--FSMs
attribute fsm_encoding:string;
type FSMstate is (IDLE,FIRSTPULSE,TRACING,WAITPULSEDONE,AVERAGE,HOLD);
signal state:FSMstate;
type wrChunkState is (STORE0,STORE1,STORE2,WRITE);
signal wr_chunk_state:wrChunkState; 
type rdChunkState is (IDLE,WAIT_TRACE,READ3,READ2,READ1,READ0);
signal rd_chunk_state:rdChunkState;
type traceFSMstate is (IDLE,CAPTURE,DONE);
signal t_state:traceFSMstate;
type queueFSMstate is (
  IDLE,AUX_WORD,SINGLE_WORD_EVENT,WORD0,WORD1,LAST_PEAK_WORD,DONE
);
signal q_state:queueFSMstate;
type strideFSMstate is (INIT,IDLE,CAPTURE);
signal s_state:strideFSMstate;
type accumFSMstate is (IDLE,WAITING,ACCUM,SEND,STOPED);
signal a_state:accumFSMstate;
type DPstate is (IDLE,DPWAIT,DONE);
signal dp_state:DPstate;
attribute fsm_encoding of wr_chunk_state:signal is "one-hot";
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
-- TRACE_DETECTION and (SINGLE_TRACE or DOT_PRODUCT)
signal mux_enable:boolean;
signal mux_wr_en:boolean;
signal start_average,average_last:boolean;

signal accum_count,next_accum_count:unsigned(ACCUMULATE_N downto 0);
signal last_accum_count:boolean;
signal pending:signed(3 downto 0):=(others => '0');
signal stop:boolean;
signal dp_sample:signed(WIDTH-1 downto 0);
signal rd_trace_start:boolean;
signal dp_trace_last,rd_trace_last:boolean;
signal dp_start:boolean;
signal dot_product:signed(47 downto 0);
signal dp_valid:boolean;
signal accumulate_done:boolean;
signal multipeak,multipulse:boolean;
--signal dp_sample_valid:boolean;
signal dp_trace_start:boolean;
signal start_accumulating:boolean;
signal dp_detection:boolean;
signal trace_done:boolean;

signal dp_address:unsigned(ADDRESS_BITS-1 downto 0);
-- TRACE_DETECTION and not DOT_PRODUCT
signal trace_wr_en:boolean;
signal inc_accum:boolean;
signal trace_reset:boolean;

-- TRACE_DETECTION_D and AVERAGE_TRACE_D
signal average_detection:boolean;
signal zero_stride:boolean;
signal trace_full:boolean;
signal trace_overflow:boolean;
signal eflags_reg,eflags:detection_flags_t;
signal dp_length:unsigned(ADDRESS_BITS downto 0);
signal dp_dump:boolean; --,dp_write:boolean;

-- the free space required to start the event
signal size:unsigned(PEAK_COUNT_BITS downto 0);
-- the free space required to start a new event while the previous event is 
-- committing.
signal size2:unsigned(ADDRESS_BITS downto 0);

-- when true, the current pulse has this detection type.
signal trace_detection,area_detection,pulse_detection,peak_detection:boolean;
-- trace_type=DOT_PRODUCT_D no trace
signal dp_only:boolean;
-- TRACE_DETECTION_D and SINGLE_TRACE_D
signal single_trace_detection:boolean;
signal trace_chunks:unsigned(DP_ADDRESS_BITS downto 0);
signal space_available,space_available2:boolean;
-- the event queue can be written 
signal q_can_write,q_ready:boolean;
signal q_aux,q_single,q_header,q_pulse:boolean;
signal q_length:unsigned(ADDRESS_BITS downto 0);
signal commit_average:boolean;
signal started:boolean;

function to_streambus(v:std_logic_vector;last:boolean;endian:string) 
return streambus_t is
variable s:streambus_t;
begin
  s.data:=set_endianness(v,endian);
  s.last:=(0 => last, others => FALSE);
  s.discard:=(others => FALSE);
  return s;
end function;

type average_trace_detection_t is 
record
	size:unsigned(SIZE_BITS-1 downto 0);
	flags:detection_flags_t;
	trace_flags:trace_flags_t;
	multipulses:unsigned(31 downto 0);
	multipeaks:unsigned(31 downto 0);
end record;

signal average_trace_header:average_trace_detection_t;

function to_streambus(
  t:average_trace_detection_t;w:natural range 0 to 1;
	endianness:string
) return streambus_t is
	variable sb:streambus_t;
begin
	case w is
	when 0 =>
  	sb.data(63 downto 48) := set_endianness(t.size,endianness);
		sb.data(47 downto 32) := to_std_logic(t.trace_flags);
		sb.data(31 downto 16) := to_std_logic(t.flags); 
		sb.data(15 downto 0) := (others => '-');
	when 1 =>
		sb.data(63 downto 32) := set_endianness(t.multipulses,endianness);
		sb.data(31 downto 0) := set_endianness(t.multipeaks,endianness);
	when others =>
		assert FALSE report 
		             "bad word number in average_trace_detection_t to_streambus"	
						 		 severity FAILURE;
	end case;
  sb.discard := (others => FALSE);
  sb.last := (others => FALSE);
  return sb;
end function;

--------------------------------------------------------------------------------
-- debugging
--------------------------------------------------------------------------------
constant DEBUG:string:="TRUE";
attribute MARK_DEBUG:string;
attribute mark_debug of pending:signal is "FALSE";
attribute mark_debug of enable_reg:signal is "FALSE";

begin
debugGen:if DEBUG="TRUE" generate
debugPending:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      pending <= (others => '0');
    else
      -- simulation checks on framing
      if commit_frame then
        assert frame_length <= framer_free report "BAD commit" severity FAILURE;
      end if;
      if unaryOR(frame_we) then
        assert frame_address < framer_free report "BAD write" severity FAILURE;
      end if;
      --counter to track pending MUX starts 
      if start_int and not (commit_int or dump_int) and state/=HOLD then
        pending <= pending + 1;
      end if;
      if (commit_int or dump_int) and (not start_int) and state/=HOLD then
        pending <= pending - 1;
      end if;
      
   assert (pending >= 0 and pending <= 2) report "out of sync" severity FAILURE;
        
    end if;
  end if;
end process debugPending;
end generate;

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
eflags.event_type <= eflags_reg.event_type;
eflags.timing <= eflags_reg.timing;                             
eflags.height <= eflags_reg.height;                             
eflags.cfd_rel2min <= eflags_reg.cfd_rel2min;                             
eflags.channel <= eflags_reg.channel;                             
eflags.new_window <= eflags_reg.new_window;                             
eflags.peak_number <= m.eflags.peak_number;                             
eflags.has_peak <= m.eflags.has_peak;                             
                                      
pulse.size <= resize(length & "000",CHUNK_DATABITS);
pulse.flags <= eflags;
pulse.length <= m.pulse_length;
pulse.offset <= m.time_offset;
pulse.area <= m.pulse_area;
pulse.threshold <= m.timing_threshold; --FIXME 

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


average_trace_header.size <= resize(length & "000",CHUNK_DATABITS);
average_trace_header.flags <= eflags_reg;
--average_trace_header.trace_flags <= atflags;
average_trace_header.trace_flags.offset <= tflags.offset;
average_trace_header.trace_flags.stride <= tflags.stride;
average_trace_header.trace_flags.trace_length <= tflags.trace_length;
--atflags.multipeak <= multipeak;
--atflags.multipulse <= multipulse;
average_trace_header.trace_flags.trace_signal <= tflags.trace_signal;
average_trace_header.trace_flags.trace_type <= AVERAGE_TRACE_D;



--when trace shorter than pulse need to use current pulse data
this_pulse_trace_header.size <= resize(length & "000",CHUNK_DATABITS);
this_pulse_trace_header.flags <= eflags; 
this_pulse_trace_header.trace_flags <= tflags;
this_pulse_trace_header.length <= m.pulse_length;
this_pulse_trace_header.offset <= m.time_offset;
this_pulse_trace_header.area <= m.pulse_area;


--used when trace longer than pulse use stored pulse data
first_pulse_trace_header.size <= resize(length & "000",CHUNK_DATABITS);
first_pulse_trace_header.flags <= first_pulse.flags;
first_pulse_trace_header.trace_flags <= tflags;
first_pulse_trace_header.length <= first_pulse.length;
first_pulse_trace_header.offset <= first_pulse.offset;
first_pulse_trace_header.area <= first_pulse.area;

pulse_peak.minima <= m.min_value;
pulse_peak.timestamp <= m.peak_time;
pulse_peak.rise_time <= m.rise_time;
pulse_peak.height <= m.height;

peak.height <= m.height;
peak.minima <= m.min_value;
peak.flags <= eflags;

area.flags <= eflags;
area.area <= m.pulse_area;


pre_detection <= m.pre_eflags.event_type.detection;
  
--pre_pulse_start <= pre_detection/=PEAK_DETECTION_D and m.pre_pulse_start;  

--can_q_single <= q_state=IDLE;
--can_q_trace <= q_state=IDLE;
--can_q_pulse <= q_state=IDLE;

--pre_full <= free < resize(m.pre_size,ADDRESS_BITS+1);

--full <= free <= length;
--mux_wr_en <= mux_enable and enable_reg;

--trace_start <= trace_start_reg and enable_reg and t_state=IDLE;
trace_chunk_debug <= set_endianness(trace_chunk,ENDIAN);

--MUX registers now MUX signals are one clk later FIXME check for issues.
muxOutput:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      commit_int <= FALSE;
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
    else
      commit_int <= commit_reg and mux_wr_en;
--      start_int <= start_reg and mux_wr_en;
      start_int <= start_reg and mux_wr_en;
      dump_int <= dump_reg and mux_wr_en;
      overflow_int <= overflow_reg and mux_wr_en;
      error_int <= error_reg and mux_wr_en;
    end if;
  end if;
end process muxOutput;

--------------------------------------------------------------------------------
-- Framer control
-- trace and DP have priority access over queue
-- trace and DP writes should be mutually exclusive FIXME needs checking
--------------------------------------------------------------------------------
--FIXME simplify or register these control signals
q_can_write <= not (s_state=CAPTURE and wr_chunk_state=WRITE and trace_wr_en) 
               and not (dp_detection and dp_valid);
               
--FIXME this underestimates, also ready when in a  last word state and 
q_ready <= q_state=IDLE and not (q_aux or q_single or q_header or q_pulse);

framerControl:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      frame_word.discard <= (others => FALSE);
      frame_we <= (others => FALSE);
      commit_frame <= FALSE;
      commit_reg <= FALSE;
      q_state <= IDLE;
      s_state <= IDLE;
      wr_chunk_state <= STORE0;
      t_state <= IDLE;
      trace_overflow <= FALSE;
    else
      frame_we <= (others => FALSE);
      commit_frame <= FALSE;
      commit_reg <= FALSE;
      trace_overflow <= FALSE;
    
--------------------------------------------------------------------------------
-- Traces
--------------------------------------------------------------------------------
      
      -- trace done signal
      if trace_last and not trace_full then
        trace_done <= TRUE;
      elsif trace_start or trace_overflow then
        trace_done <= FALSE;
      end if;
      
      --------------------------------------------------------------------------
      --MUX for trace chunk
      --------------------------------------------------------------------------
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
      
      --------------------------------------------------------------------------
      --trace start
      --------------------------------------------------------------------------
      if state=AVERAGE then
        trace_start <= start_average;
      else
        --FIXME replace trace_started with t_state=IDLE ???
        if TRACE_FROM_STAMP then
          trace_start <= m.pre_stamp_pulse and  
                         (enable_reg or (m.pre_pulse_start and enable)); 
        end if;
        if not TRACE_FROM_STAMP then
          trace_start <= m.pre_pulse_start and enable; 
        end if;
      end if;
      
      --------------------------------------------------------------------------
      --trace stride FSM --FIXME need to check this actually works
      --------------------------------------------------------------------------
      trace_last <= FALSE;
      case s_state is 
        
      when INIT => 
--        next_stride_count <= tflags.stride-1;
--        stride_count <= (others => '0');
        if trace_start then
           s_state <= CAPTURE; 
        end if;
        
      when IDLE =>
--        if trace_start then
--          next_stride_count <= tflags.stride-1;
--          stride_count <= (others => '0');
--        end if;
        if stride_count=0 or zero_stride or trace_start then
          s_state <= CAPTURE;
          next_stride_count <= tflags.stride-1;
          stride_count <= tflags.stride;
          if wr_chunk_state=WRITE then --FIXME????
            trace_last <= last_trace_count and trace_detection;
          end if;
        else 
          next_stride_count <= next_stride_count-1;
          stride_count <= next_stride_count;
        end if;
        
      when CAPTURE =>
        if trace_last then
          s_state <= INIT;
        elsif not zero_stride then
          s_state <= IDLE;
          next_stride_count <= next_stride_count-1;
          stride_count <= next_stride_count;
        elsif wr_chunk_state=STORE2 then --FIXME ???
          trace_last <= last_trace_count and zero_stride and trace_detection;
        end if;
      end case;
       
      --------------------------------------------------------------------------
       --wr_chunk FSM gathers samples into a bus word
      --------------------------------------------------------------------------
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
      
      -- TODO check that dp_valid cannot clash with this trace write.
      -- dp_valid is 5 clks after wr_trace_last, and the next possible
      -- trace write should be 1 clk after that.  
      when WRITE => 
        --write to framer
        trace_full <= free <= trace_address;
        if s_state=CAPTURE then 
          trace_last <= FALSE;
          if trace_full and trace_wr_en then 
            wr_chunk_state <= STORE0;
            t_state <= IDLE;
            s_state <= INIT;
            trace_overflow <= trace_detection;
          else --if trace_wr_en then --4th chunk captured
            -- wait in this state?
            wr_chunk_state <= STORE0;
            frame_we <= (others => trace_wr_en);
            frame_word.data(63 downto 16) <= trace_reg(63 downto 16);
            frame_word.data(15 downto 0) <= trace_chunk;
            frame_word.last <= (0 => last_trace_count, others => FALSE);
            frame_word.discard(0) <= average_detection;
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
        
      --------------------------------------------------------------------------
      --trace control FSM
      --------------------------------------------------------------------------
      case t_state is
      when IDLE | DONE =>
        
        if average_detection and state/=AVERAGE then --FIXME
          trace_address <= (others => '0');
        else
          trace_address <= trace_start_address;
        end if;
        
        trace_count <= trace_count_init;
        next_trace_count <= trace_count_init-1;
        last_trace_count <= FALSE;
        wr_chunk_state <= STORE0; 
        -- FIXME remember to replace these in main.
  --      tflags.multipulse <= FALSE; --FIXME main FSM
  --      tflags.multipeak <= FALSE; --FIXME main FSM
        
        if trace_start and state/=HOLD then
          t_state <= CAPTURE; 
        end if;
        
        
      when CAPTURE =>
          if trace_last then
            t_state <= DONE;
          end if;
      end case;
      
      if trace_reset then 
        if trace_start then
          wr_chunk_state <= STORE0; 
          if average_detection and state/=AVERAGE then --FIXME
            trace_address <= (others => '0');
          else
            trace_address <= trace_start_address;
          end if;
          trace_count <= trace_count_init;
          next_trace_count <= trace_count_init-1;
          last_trace_count <= FALSE;
          t_state <= CAPTURE;
        else
          t_state <= IDLE;
        end if;
      end if;
    
--------------------------------------------------------------------------------
-- event writing queue
--------------------------------------------------------------------------------
      case q_state is 
      when IDLE =>
        if q_aux then
          q_state <= AUX_WORD;
        elsif q_single then
          q_state <= SINGLE_WORD_EVENT;
        elsif q_header then
          q_state <= WORD1;
        elsif q_pulse then
          q_state <= LAST_PEAK_WORD;
        end if;
        
      when AUX_WORD => 
        -- pulse_peak, dot_product
        if q_can_write then 
          frame_word <= aux_word_reg;
          frame_address <= aux_address;
          frame_we <= (others => TRUE);
          q_state <= IDLE; 
        end if;
        
      when SINGLE_WORD_EVENT => 
        if q_can_write then 
          frame_word <= queue(0);
          frame_address <= to_unsigned(0,ADDRESS_BITS);
          frame_length <= (0 => '1', others => '0');
          frame_we <= (others => TRUE);
          commit_frame <= TRUE;
          commit_reg <= TRUE;
          q_state <= IDLE;
        end if;

      when WORD0 => 
        if q_can_write then 
          frame_word <= queue(0);
          frame_we <= (others => TRUE);
          frame_address <= to_unsigned(0,ADDRESS_BITS);
          frame_length <= q_length;
          if dp_detection then
            commit_frame <= dp_state=DONE;
            commit_reg <= dp_state=DONE;
          else
            commit_frame <= TRUE; 
            commit_reg <= mux_enable; 
          end if;
          
          if dp_detection then
--            if dp_state=DONE then
--              q_state <= IDLE;
--            else
            q_state <= DONE;
--            end if;
          else
            q_state <= IDLE;
          end if;
        end if;
        
      when WORD1 =>
        if q_can_write then 
          frame_word <= queue(1);
          frame_we <= (others => TRUE);
          frame_address <= to_unsigned(1,ADDRESS_BITS);
          q_state <= WORD0;
        end if;
        
      when LAST_PEAK_WORD =>
        if q_can_write then 
          frame_word <= queue(2);
          frame_we <= (others => TRUE);
          frame_address <= last_peak_address;
          q_state <= WORD1;
        end if;
        
      when DONE =>
        if dp_state=DONE or dp_valid then
          q_state <= IDLE;
        end if;
      end case;
      
--------------------------------------------------------------------------------
-- Average trace captures to the framer two allow dumping
-- framer output is routed to the accumulator
--------------------------------------------------------------------------------
      if average_detection and (a_state=ACCUM or a_state=WAITING) then
        --commit for averaging if not a multipulse
        commit_frame <= commit_average;
        frame_length <= resize(tflags.trace_length,ADDRESS_BITS+1);
      end if;
      
--------------------------------------------------------------------------------
-- dot product FSM
-- dp_valid 5 clocks after trace_last
--------------------------------------------------------------------------------
      case dp_state is 
      when IDLE =>
        dp_length <= length;
        --FIXME state/=IDLE ??
        if dp_detection and trace_last and state/=IDLE then 
          dp_state <= DPWAIT;
        end if;

      when DPWAIT =>
        if dp_dump then
          dp_state <= IDLE;
        elsif dp_valid then  
          if q_state=DONE then
            dp_state <= IDLE;
          else
            dp_state <= DONE;
          end if;
          --safe to assume that trace not writing??? 5 clocks should be enough
          --FIXME What about queue state? make a specific state for DP?
          frame_word 
            <= to_streambus(resize(dot_product,BUS_DATABITS),dp_only,ENDIAN);
          frame_address <= dp_address;
          frame_length <= dp_length;
          frame_we <= (others => TRUE); 
          commit_frame <= q_state=DONE;
          commit_reg <= q_state=DONE;
        end if;
        
      when DONE =>
        if q_state=DONE  then --or (
--             q_state=WORD0 and not (wr_chunk_state=WRITE and s_state=CAPTURE)
--           ) then 
          dp_state <= IDLE;
        end if;
      end case;
      
--------------------------------------------------------------------------------
    end if; 
  end if;
end process framerControl;


main:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      
      start_reg <= FALSE;
      started <= FALSE;
      dump_reg <= FALSE;
      overflow_reg <= FALSE;
      error_reg <= FALSE;
      pulse_valid <= FALSE;
      pulse_overflow <= FALSE;
      area_overflow <= FALSE;
      enable_reg <= FALSE;
      
--      q_state <= IDLE;
      state <= IDLE;
--      t_state <= IDLE;
--      wr_chunk_state <= STORE0;
      
      mux_enable <= FALSE;
      mux_wr_en <= FALSE;
      multipulse <= FALSE;
      multipeak <= FALSE;
      
      trace_start_address <= (others => '-');
      trace_reset <= FALSE;
      
      average_trace_header.trace_flags.multipulse <= FALSE;
      average_trace_header.trace_flags.multipeak <= FALSE;
      average_trace_header.multipeaks <= (others => '0');
      average_trace_header.multipulses <= (others => '0');
      tflags.multipulse <= FALSE; -- FIXME need to reset at trace start as well
      tflags.multipeak <= FALSE;
    
      q_single <= FALSE;
      q_pulse <= FALSE;
      q_header <= FALSE;
      q_aux <= FALSE;
      inc_accum <= FALSE;
      commit_average <= FALSE;
      space_available <= TRUE;
      space_available2 <= TRUE;
    else
      q_single <= FALSE;
      q_pulse <= FALSE;
      q_header <= FALSE;
      q_aux <= FALSE;
      inc_accum <= FALSE;
      
      start_reg <= FALSE;
      dump_reg <= FALSE;
      overflow_reg <= FALSE;
      error_reg <= FALSE;
--      inc_accum <= FALSE;
      dp_start <= FALSE;
      dp_dump <= FALSE;
--      dp_write <= FALSE;
--      trace_overflow <= FALSE;
      trace_reset <= FALSE;
      commit_average <= FALSE;
      
      -- capture register settings when pulse FSM is idle and a new pulse starts
      -- TODO consider if there is an issue when registers change upstream
      -- on a new pulse even when this FSM is not idle
      if m.pre_pulse_start and (state=IDLE or state=HOLD) then 
        enable_reg <= enable; 
                              
        tflags.trace_length <= m.pre_tflags.trace_length;
        tflags.stride <= m.pre_tflags.stride;
        tflags.trace_signal <= m.pre_tflags.trace_signal;
        tflags.trace_type <= m.pre_tflags.trace_type;
        zero_stride <= m.pre_tflags.stride=0; 
        
        eflags_reg <= m.pre_eflags;
         
        trace_detection <= pre_detection=TRACE_DETECTION_D;
        area_detection <= pre_detection=AREA_DETECTION_D;
        pulse_detection <= pre_detection=PULSE_DETECTION_D;
        peak_detection <= pre_detection=PEAK_DETECTION_D;

        single_trace_detection <= pre_detection=TRACE_DETECTION_D and
                                  m.pre_tflags.trace_type=SINGLE_TRACE_D;

        average_detection <= m.pre_tflags.trace_type=AVERAGE_TRACE_D and 
                             pre_detection=TRACE_DETECTION_D;
                                   
        dp_detection <= (m.pre_tflags.trace_type=DOT_PRODUCT_D or 
                         m.pre_tflags.trace_type=DOT_PRODUCT_TRACE_D) and
                         pre_detection=TRACE_DETECTION_D;
                         
        dp_only <=  m.pre_tflags.trace_type=DOT_PRODUCT_D and
                    pre_detection=TRACE_DETECTION_D;
                                                         
        trace_wr_en <= pre_detection=TRACE_DETECTION_D and
                       m.pre_tflags.trace_type/=DOT_PRODUCT_D;
                       
        mux_enable <= (pre_detection/=TRACE_DETECTION_D or 
                      (
                        pre_detection=TRACE_DETECTION_D and 
                        m.pre_tflags.trace_type/=AVERAGE_TRACE_D
                      )) and enable;
                      
        mux_wr_en <= (pre_detection/=TRACE_DETECTION_D or 
                      (
                        pre_detection=TRACE_DETECTION_D and 
                        m.pre_tflags.trace_type/=AVERAGE_TRACE_D
                      )) and enable;
                     
        trace_count_init <= m.pre_tflags.trace_length-1;
        
        dp_address <= resize(m.dp_address, ADDRESS_BITS);
        
        
        -- length is the frame length to be committed
        -- size is the free space required to *start* a new event

        if m.pre_eflags.event_type.detection=TRACE_DETECTION_D then
          tflags.offset <= resize(m.pre_size,PEAK_COUNT_BITS);
          trace_start_address <= resize(m.pre_size,ADDRESS_BITS);

          dp_start <= m.pre_tflags.trace_type=DOT_PRODUCT_D or
                      m.pre_tflags.trace_type=DOT_PRODUCT_TRACE_D;
          
        end if;
        
        length <= resize(m.pre_frame_length,ADDRESS_BITS+1);
        size <= m.pre_size;
        size2 <= resize(m.pre_size2,ADDRESS_BITS+1);
        
        if not committing then
          free <= framer_free;
        end if;
        space_available <= m.pre_size <= free;
        space_available2 <= m.pre_size2 <= free;
          
      else 
      
        space_available <= size <= free;
        space_available2 <= size2 <= free;
        if not committing then -- FIXME 
          -- free space can only decrease here.
            free <= framer_free;
        end if; 
      end if;
      
      -- SINGLE_TRACE_D and DOT_PRODUCT_D move through same FSM states
      -- But DOT_PRODUCT_D does not write trace words to the framer.
      -- AVERAGE_TRACE_D dumps immediately on second pulse or peak
      
      if commit_frame or dump_reg or error_reg then
        committing <= FALSE;
      end if;
      
      if a_state=IDLE then
        accum_count <= (ACCUMULATE_N => '0', others => '1');
        next_accum_count <= to_unsigned(2**ACCUMULATE_N-2,ACCUMULATE_N+1);
        last_accum_count <= ACCUMULATE_N=0;
      elsif inc_accum and not last_accum_count then
        accum_count <= next_accum_count;
        next_accum_count <= next_accum_count-1;
        last_accum_count <= next_accum_count=0;
      end if;
      
      -- pulse FSM
      case state is 
      when IDLE =>
        
        pulse_stamped <= FALSE;
        if m.pulse_start and not peak_detection and enable_reg then 
          if space_available then
            state <= FIRSTPULSE;
            tflags.multipulse <= FALSE;
            tflags.multipeak <= FALSE;
          else
            overflow_reg <= TRUE;
          end if;
        end if;
        
      when FIRSTPULSE =>
     
        if trace_overflow or (trace_last and trace_full) then
          overflow_reg <= TRUE;
          dump_reg <= pulse_stamped or m.stamp_pulse;
          pulse_stamped <= FALSE;
          dp_dump <= TRUE;
          state <= IDLE;
          
        elsif m.pulse_threshold_neg then
          -- pulse ending ok to restart pulse
          
          if not m.above_area_threshold then
            --dump the pulse that is ending
            trace_reset <= TRUE;
            dump_reg <= pulse_stamped or m.stamp_pulse; 
            pulse_stamped <= FALSE;
            dp_dump <= TRUE;
            -- if pre_pulse_start space will be free as previous pulse was 
            -- dumped.
            if not m.pulse_start then 
              state <= IDLE; 
            end if;
            
          else
            -- End of valid pulse (pulse_threshold_neg).
            -- Could also have pre_pulse_start and/or trace_last. 
            -- Can't have pulse_start as pre_pulse_start should have been 
            -- handled in the previous clock cycle.
            
            --Store the first_pulse for use in trace_detections
            first_pulse <= pulse; 
            --------------------------------------------------------------------
            -- next state logic for valid pulse_threshold_neg (FIRSTPULSE)
            -- handles MUX logic except queue errors.
            --------------------------------------------------------------------
            if m.pulse_start then -- new pulse starting while this one ending. 
              if trace_detection then
                if average_detection then
                  average_trace_header.trace_flags.multipulse <= TRUE;
                  average_trace_header.multipulses 
                    <= average_trace_header.multipulses+1;
                  tflags.multipulse <= TRUE;
                  -- multiple pulses in trace, don't include either pulse in 
                  -- the average.
                  state <= IDLE; 
                  trace_reset <= TRUE;
--                  t_state <= IDLE; -- restart the trace
--                  trace_started <= FALSE;
--                  dump_int <= pulse_stamped; 
--                  error_int <= TRUE;
                else
                  if trace_last then -- 
                    -- May have queue error handled in output block.
                    state <= IDLE; -- New pulse and trace.
--                    t_state <= IDLE;
--                    inc_accum <= TRUE;
                  else
                    -- End of first pulse, continue single_trace_D.
                    state <= TRACING; 
                  end if;
                end if;
              else -- not TRACE_DETECTION_D
                if q_ready then
                  -- ending pulse not dumped but not yet committed, 
                  -- check space for two events
--                  if free < size2 then
                  if not space_available2 then
                    state <= IDLE;  
                    overflow_reg <= TRUE; --overflow for NEW pulse
                  end if;
                end if;
              end if;
            else -- no new pulse.
              if trace_detection then
                if trace_last then 
                  if average_detection then
                    commit_average <= TRUE;
                    if last_accum_count then
                      state <= AVERAGE;
                    else
                      state <= IDLE; -- all done.
                      inc_accum <= TRUE;
                    end if;
                  end if;
                else
                  state <= TRACING; -- end of first pulse, tracing.
                end if;
              else -- not tracing
                if q_ready then 
                  --if there is a new pulse check for space
                  if m.pulse_start and not space_available2 then
                    -- new pulse wont start no need for dump 
                    overflow_reg <= TRUE; 
                  end if;
                  state <= IDLE;
                else
                  state <= IDLE;  -- queue error dump this pulse 
                  error_reg <= TRUE;
                  -- anyn m.pulse_stamp belongs to the new pulse
                  dump_reg <= pulse_stamped;
                  pulse_stamped <= FALSE;
                  dp_dump <= TRUE;
                end if;
              end if;       
            end if;
              
            --------------------------------------------------------------------
            -- output logic for valid pulse_threshold_neg (FIRSTPULSE)
            --------------------------------------------------------------------

            if trace_detection then
              if trace_last and not trace_full then
                -- dump if SINGLE_TRACE_D
                if not average_detection then 
                  if q_ready then 
                    -- commit the trace
                    queue(0) <= to_streambus(this_pulse_trace_header,0,ENDIAN); 
                    queue(1) <= to_streambus(this_pulse_trace_header,1,ENDIAN);
                    q_length <= length;
                    committing <= TRUE;
                    free <= framer_free - length;
                    space_available <= size2 <= framer_free;
                    space_available2 <= size2 <= framer_free;
                    q_header <= TRUE;
                  else
                    error_reg <= TRUE;
                    dump_reg <= pulse_stamped;
                    pulse_stamped <= FALSE;
                  end if;
                end if;
              end if;
              
            else 
              -- not trace_detection 
              if q_ready then 
               
                --FIXME add ready test 
                if area_detection then
                  q_single <= TRUE; -- assumption here that q is idle
                  queue(0) <= to_streambus(area,ENDIAN);
                end if;
                
                if pulse_detection then
                  queue(0) <= to_streambus(pulse,0,ENDIAN);
                  queue(1) <= to_streambus(pulse,1,ENDIAN);
                  -- write last 
                  queue(2) <= to_streambus(pulse_peak,TRUE,ENDIAN);
                  last_peak_address <= resize(m.last_peak_address,ADDRESS_BITS);
                  q_pulse <= TRUE;
                end if;
                
                q_length <= length;
                committing <= TRUE;
                free <= framer_free - length;
                space_available <= size2 <= framer_free;
                space_available2 <= size2 <= framer_free;
                
              end if;
            end if;
          end if;
        else -- not pulse_threshold_neg
          if trace_detection and trace_last then
              if trace_full then
                state <= IDLE; --FIXME 
              else
                state <= WAITPULSEDONE;
              end if;
          end if;
        end if;
        ------------------------------------------------------------------------
        -- end output valid pulse_threshold_neg
        ------------------------------------------------------------------------
        
      when TRACING =>  -- pulse has ended
        
        ------------------------------------------------------------------------
        -- next state logic (TRACING)
        ------------------------------------------------------------------------
        if trace_overflow or (trace_last and trace_full) then
          state <= IDLE;
          overflow_reg <= TRUE;
          dump_reg <= pulse_stamped; 
          pulse_stamped <= FALSE;
          dp_dump <= TRUE;
          
        elsif trace_last or trace_done then
          -- end of trace
          if average_detection then 
            if m.pulse_start then
--              error_int <= TRUE;
              trace_reset <= TRUE;
              average_trace_header.trace_flags.multipulse <= TRUE;
              average_trace_header.multipulses 
                <= average_trace_header.multipulses+1;
              state <= IDLE;
            elsif last_accum_count then
              state <= AVERAGE;
              commit_average <= TRUE;
            else
              state <= IDLE;
              inc_accum <= TRUE;
              commit_average <= TRUE;
            end if;
          else -- not averaging
            if m.pulse_start then 
              -- make sure twice the space is free for new pulse
              if not space_available2 then 
                --second pulse overflows
                state <= IDLE;
                overflow_reg <= TRUE;
--                t_state <= IDLE;
              else
                state <= FIRSTPULSE; --new pulse
--                t_state <= IDLE;
              end if;
            else
--              t_state <= IDLE;
              state <= IDLE; -- all done
            end if;
          end if;
          
        else
          --still tracing
          if m.pulse_start then 
            tflags.multipulse <= TRUE;
            if average_detection then
            -- multipulse dump
              average_trace_header.trace_flags.multipulse <= TRUE;
              average_trace_header.multipulses 
                <= average_trace_header.multipulses+1;
              state <= FIRSTPULSE;
--              error_int <= TRUE;
              trace_reset <= TRUE;
            end if;
          end if;
        end if;
        
        ------------------------------------------------------------------------
        -- output logic (TRACING)
        ------------------------------------------------------------------------
        if not trace_overflow then
          if (trace_last and not trace_full) or trace_done then
--            if average_detection then 
--              if not m.pulse_start then
--                commit_frame <= TRUE; 
--                inc_accum <= TRUE; 
--                frame_length <= length; 
----                free <= next_free;
----                free <= framer_free - length;
--              end if;
--            else -- not averaging 
            if not average_detection then -- trace pulse or dp
              if q_ready then
--                dp_write <= TRUE;
                queue(0) <= to_streambus(first_pulse_trace_header,0,ENDIAN); 
                queue(1) <= to_streambus(first_pulse_trace_header,1,ENDIAN);
                q_length <= length;
--                commit_pulse <= not dp_detection; --because dp will commit
                committing <= TRUE;
                free <= framer_free - length;
                space_available <= size2 <= framer_free;
                space_available2 <= size2 <= framer_free;
--                q_state <= WORD1;
                q_header <= TRUE;
              else  
                error_reg <= TRUE;
                dump_reg <= pulse_stamped;
                pulse_stamped <= FALSE;
                dp_dump <= TRUE;
              end if;
            end if;
          end if;
        end if;
        
      when WAITPULSEDONE =>
        -- must have a TRACE_DETECTION_D pulse with completed trace.
        if m.pulse_threshold_neg then
          if not m.above_area_threshold then
            --dump the pulse that is ending
--            t_state <= IDLE;
            trace_reset <= TRUE;
--            trace_started <= FALSE;
            dump_reg <= pulse_stamped; 
            pulse_stamped <= FALSE;
            dp_dump <= TRUE;
            if m.pulse_start then 
              -- space will be free for new pulse as current one was dumped.
              state <= FIRSTPULSE;
            else
              state <= IDLE; 
            end if;
          else
            -- valid pulse_threshold_neg, could also have pre_pulse_start.
            -- must have a TRACE_DETECTION_D pulse with completed trace.
            
            --------------------------------------------------------------------
            -- next state & mux logic for valid pulse_threshold_neg 
            -- (WAITPULSEDONE)
            --------------------------------------------------------------------
            if m.pulse_start then -- new pulse starts as this one ends
              if q_ready then
                if single_trace_detection then
                  if not space_available2 then
                    state <= IDLE;
                    overflow_reg <= TRUE; -- overflow the new pulse;
                  else
                    state <= FIRSTPULSE;
                  end if;
                elsif average_detection then 
                  commit_average <= TRUE;
                  if last_accum_count then 
                  -- ending pulse will be committed, and was the last required 
                  -- for the average.
                    state <= AVERAGE; 
                  else
                    inc_accum <= TRUE;
                  end if; 
                elsif not space_available2 then
                  -- ending pulse will be committed, check space for two events.
                  state <= IDLE;  
                  overflow_reg <= TRUE; --overflow the NEW pulse.
                else
                  state <= FIRSTPULSE; --all good
                end if;
              else
                -- ending pulse dumped, no need to check space for new one.
                state <= FIRSTPULSE;
              end if;
            else  -- not pre_pulse start
              if average_detection then
                commit_average <= TRUE;
                if last_accum_count then
                  state <= AVERAGE;
                else 
                  state <= IDLE;
                  inc_accum <= TRUE;
                end if;
              else
                state <= IDLE;
              end if;
            end if;

            --------------------------------------------------------------------
            -- other output logic for valid pulse_threshold_neg (WAITPULSEDONE)
            -- mux logic for queue errors also lives here
            --------------------------------------------------------------------
--            if average_detection then 
--              commit_frame <= TRUE;-- FIXME need some signal to send to capture
--              free <= framer_free - length;
--              space_available <= size2 <= framer_free;
--              space_available2 <= size2 <= framer_free;
--              frame_length <= length;
--              inc_accum <= TRUE;
----              free <= next_free;
----              free <= framer_free - length;
            if not average_detection then
              if q_ready then
--                dp_write <= TRUE; 
                queue(0) <= to_streambus(this_pulse_trace_header,0,ENDIAN); 
                queue(1) <= to_streambus(this_pulse_trace_header,1,ENDIAN);
                q_length <= length;
                -- will commit when dp_valid
--                commit_pulse <= not dp_detection; -- because dp will commit
                committing <= TRUE;
                free <= framer_free - length;
                space_available <= size2 <= framer_free;
                space_available2 <= size2 <= framer_free;
--                q_state <= WORD1;
                q_header <= TRUE;
              else
                error_reg <= TRUE;
                dump_reg <= pulse_stamped;
                pulse_stamped <= FALSE;
              end if;
            end if;
            
            -- END of valid pulse_threshold_neg (WAITPULSEDONE) block
          
          end if;
        end if;
        
      when AVERAGE =>
        if trace_last then --FIXME trace_full?
          queue(0) <= to_streambus(average_trace_header,0,ENDIAN); 
          queue(1) <= to_streambus(average_trace_header,1,ENDIAN); 
          q_length <= length;
          committing <= TRUE;
          free <= framer_free - length;
          space_available <= size2 <= framer_free;
          space_available2 <= size2 <= framer_free;
          start_reg <= TRUE;
          mux_wr_en <= TRUE;
          q_header <= TRUE;
--          q_state <= WORD0; --FIXME
          state <= HOLD;
          average_trace_header.trace_flags.multipeak <= FALSE;
          average_trace_header.trace_flags.multipulse <= FALSE;
          average_trace_header.multipulses <= (others => '0'); 
          average_trace_header.multipeaks <= (others => '0'); 
        end if;
        
      when HOLD =>
        if m.pre_pulse_start and not average_detection then
          state <= IDLE;
        end if;
        
      end case;
     
      --FIXME now that the queue is controlled by registered signals 
      --there is one clock where its ready signal is false
      --but a transaction is pending, this can lock it up
      --this framer needs major refactoring, a couple of error conditions could
      --be removed, perhaps separate the peak writing from the queue.
      if m.peak_stop then --and enable_reg then 
        if (state=FIRSTPULSE or state=WAITPULSEDONE) and not area_detection then 
          if m.eflags.has_peak and average_detection then --FIXME check
            average_trace_header.trace_flags.multipeak <= TRUE;
            average_trace_header.multipeaks 
              <= average_trace_header.multipeaks+1;
--            q_state <= IDLE;
--            t_state <= IDLE;
            
            trace_reset <= TRUE;
            state <= IDLE;
            pulse_stamped <= FALSE;
          elsif not q_ready then 
                --s_state=CAPTURE)) or q_state/=IDLE then 
            -- queue error 
            error_reg <= TRUE;
            trace_reset <= TRUE;
--            q_state <= IDLE; --FIXME should the queue be reset?
--            t_state <= IDLE;
            state <= IDLE;
            dump_reg <= pulse_stamped and mux_enable;
            pulse_stamped <= FALSE;
          else
            tflags.multipeak <= m.eflags.has_peak;
            aux_word_reg <= to_streambus(pulse_peak,FALSE,ENDIAN);--?? last?
            aux_address <= resize(m.peak_address,ADDRESS_BITS);
            q_aux <= not average_detection;
--            pulse_peak_valid <= mux_enable;
          end if;
        elsif peak_detection then
          if not space_available then
            overflow_reg <= TRUE;
--            q_state <= IDLE;
            state <= IDLE;
            dump_reg <= TRUE; --FIXME check that it is always stamped
--            peak_stamped <= FALSE;
          else
            queue(0) <= to_streambus(peak,ENDIAN);
            q_single <= TRUE;
            q_length <= length;
--            q_state <= SINGLE_WORD_EVENT;
            committing <= TRUE;
            free <= framer_free - length;
            space_available <= size2 <= framer_free;
            space_available2 <= size2 <= framer_free;
          end if;
        end if;
      end if;
      
      -- time stamping
      if peak_detection and m.stamp_peak and enable_reg then
        if mux_full then
          error_reg <= TRUE;
--          peak_stamped <= FALSE;
        else
          start_reg <= mux_enable;  
        end if;
        --FIXME think about this
      elsif (state=FIRSTPULSE or state=WAITPULSEDONE) and m.stamp_pulse and 
            enable_reg then
        if mux_full then
          error_reg <= TRUE;
          pulse_stamped <= FALSE;
        else
          start_reg <= mux_enable;  
          pulse_stamped <= mux_enable;
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
  rd_trace_start,trace_start,rd_trace_last,acc_chunk,trace_chunk,trace_last 
)
begin
  reg_stream <= stream_int;
  if a_state=WAITING then
    dp_sample <= (others => '-');
--    dp_sample_valid <= FALSE;
    dp_trace_last <= FALSE;
    dp_trace_start <= FALSE;
    ready_int <= wait_ready;
    reg_valid <= wait_valid;
  elsif a_state=ACCUM then
    dp_sample <= signed(acc_chunk);
--    dp_sample_valid <= TRUE;
    dp_trace_last <= rd_trace_last;
    dp_trace_start <= rd_trace_start;
    ready_int <= acc_ready;
    reg_valid <= FALSE;
  else
    --calculating dot product or normal operation
    dp_sample <= signed(set_endianness(trace_chunk,ENDIAN));
--    dp_sample_valid <= s_state=CAPTURE;
    dp_trace_last <= trace_last;
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
      stop <= FALSE;
    else
      start_accumulating <= FALSE;
      stop <= FALSE;
      case a_state is 
      when IDLE =>
        wait_ready <= FALSE;
        wait_valid <= FALSE;
        if average_detection then
          a_state <= WAITING;
        elsif not dp_detection then
          stop <= TRUE;
        end if;
        
      when WAITING => 
        
        wait_ready <= FALSE;
        wait_valid <= FALSE;
        if not average_detection then
          stop <= TRUE;
          a_state <= IDLE;
        elsif valid_int and not wait_ready then --??
          if stream_int.discard(0) then
            a_state <= ACCUM;
            start_accumulating <= TRUE;
          else
            wait_ready <= TRUE;
            wait_valid <= TRUE;
          end if;
        end if;
        
      when ACCUM =>
        if not average_detection then
          stop <= TRUE;
          a_state <= IDLE;
        elsif accumulate_done then
          a_state <= SEND;
          rd_chunk_state <= IDLE;
        end if;
        
      when SEND =>
        if average_last then
          a_state <= STOPED;
        end if;
        
      when STOPED =>
        if not average_detection then
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

trace_chunks <= resize(tflags.trace_length,DP_ADDRESS_BITS+1);
dotproductDSP:entity work.dot_product20
generic map(
  ADDRESS_BITS => DP_ADDRESS_BITS,
  WIDTH => WIDTH,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH,
  STRIDE_BITS => TRACE_STRIDE_BITS,
  ACCUMULATE_N => ACCUMULATE_N
)
port map(
  clk => clk,
  reset => reset,
  stop => stop,
  trace_chunks => trace_chunks,
  trace_stride => tflags.stride,
  sample => dp_sample,
--  sample_valid => dp_sample_valid,
  trace_start => dp_trace_start,
  trace_last => dp_trace_last,
  accumulate_start => start_accumulating,
  accumulate_done => accumulate_done,
  dp_start => dp_start,
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
