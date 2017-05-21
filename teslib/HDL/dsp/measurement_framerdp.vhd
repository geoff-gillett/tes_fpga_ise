library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

library dsp;

use work.types.all;
use work.measurements.all;
use work.events.all;
use work.registers.all;
use work.functions.all;

entity measurement_framerdp is
generic(
  WIDTH:natural:=16;
  ACCUMULATOR_WIDTH:natural:=36;
  FRAMER_ADDRESS_BITS:natural:=11;
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
end entity measurement_framerdp;

architecture RTL of measurement_framerdp is

--  
constant CHUNKS:integer:=BUS_CHUNKS;
constant DEPTH:integer:=4;

type write_buffer is array (DEPTH-1 downto 0) of streambus_t;
signal queue:write_buffer;
--signal queue_full:boolean;

signal stream_int:streambus_t;
signal reg_stream:streambus_t;
signal valid_int,reg_valid:boolean;
signal ready_int,acc_ready,reg_ready:boolean;

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
--signal peak_time:unsigned(CHUNK_DATABITS-1 downto 0);

signal pulse_valid,single_valid,pulse_peak_valid,pulse_commit:boolean;
signal pulse_overflow:boolean;
signal frame_word:streambus_t;
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame,start_int,dump_int:boolean;
signal single_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal area_overflow:boolean;
signal pulse_start:boolean;
--signal last_peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);

signal pre_detection,detection:detection_d;

-- TRACE control registers implemented as constants
constant ACC_COUNT_BITS:natural:=ACCUMULATOR_WIDTH-WIDTH;
constant TRACE_LENGTH_BITS:natural:=FRAMER_ADDRESS_BITS+1;

constant trace_length:unsigned(TRACE_LENGTH_BITS-1 downto 0)
         :=to_unsigned(24,TRACE_LENGTH_BITS);
constant TRACE_STRIDE_BITS:integer:=5;
constant trace_stride:unsigned(TRACE_STRIDE_BITS-1 downto 0):=(others => '0');
constant accumulate_n:unsigned(ceillog2(ACC_COUNT_BITS)-1 downto 0)
         :=(2 => '1',others => '0');

constant acc_count_init:unsigned(ACC_COUNT_BITS-1 downto 0)
         :=to_unsigned(2**to_integer(accumulate_n)-1, ACC_COUNT_BITS);        
         
-- trace signals
signal trace_wr_reg:std_logic_vector(BUS_DATABITS-1 downto 16);
--signal trace_valid:boolean;
signal trace_chunk:signed(CHUNK_DATABITS-1 downto 0);
signal stride_count:unsigned(TRACE_STRIDE_BITS-1 downto 0);
--signal trace_started:boolean;
signal trace_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal trace_wr_count,acc_trace_count:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal trace_size:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal trace_start:boolean;
signal wr_trace_valid,wr_trace:boolean;
signal single_commit:boolean;
signal peak_start:boolean;
signal commiting:boolean;
signal q_empty:boolean;
signal overflow_int,error_int:boolean;
--signal stamp_error:boolean;
--signal trace_overflow,single_overflow,trace_overflow_valid,trace_done:boolean;
signal tracing:boolean;
signal enable_reg:boolean;
signal commit_trace:boolean;
signal can_q_trace,can_q_pulse:boolean;
signal can_write_trace:boolean;

-- dot product signals
         
signal acc_sample:signed(WIDTH-1 downto 0);
signal accumulate:boolean;
signal write_acc:boolean;
signal acc_wr_address,acc_address:unsigned(TRACE_LENGTH_BITS-1 downto 0);
--signal acc_rd_address:unsigned(TRACE_LENGTH_BITS-1 downto 0);
signal acc_data:signed(WIDTH-1 downto 0);
signal acc_count:unsigned(ACC_COUNT_BITS-1 downto 0);
signal first_trace:boolean;

--FSMs
type pulseFSMstate is (IDLE_S,STARTED_S); --,DUMP_S,ERROR_S,AREADUMP_S,END_S);
signal p_state:pulseFSMstate;
type traceFSMstate is (IDLE_S,PULSE_S,TRACE_S,WAITPULSE_S);
signal t_state:traceFSMstate;
type traceWrState is (STORE0,STORE1,STORE2,WRITE);
signal chunk_wr_state:traceWrState;
type traceRdState is (IDLE_S,WAIT_TRACE,READ3,READ2,READ1,READ0);
signal chunk_acc_state:traceRdState;
type accumFSMstate is (IDLE_S,ACCUM_S,SEND_S,DOT_S);
signal a_state,a_nextstate:accumFSMstate;
type queueFSMstate is (
  IDLE_S,SINGLE_S,PULSE0_S,PULSE1_S,PULSELAST_S,TRACE0_S,TRACE1_S
);
signal q_state:queueFSMstate;

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
--flags <= stream_int.data(23 downto 16);
--stream <= stream_int;
--valid <= valid_int;
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

--FIXME register enable to change only at pulse_start?
trace_start <= m.pre_pulse_start and pre_detection=TRACE_DETECTION_D and 
               enable;
peak_start <= pre_detection=PEAK_DETECTION_D and m.pre_peak_start and 
              enable;

tracing <= (t_state=PULSE_S or t_state=TRACE_S);
wr_trace <= stride_count=0 and chunk_wr_state=WRITE;
wr_trace_valid <= tracing and wr_trace;
q_empty <= q_state=IDLE_S or (q_state=PULSELAST_S and not single_valid);

can_q_trace <= q_state=IDLE_S or (q_state=TRACE0_S and wr_trace_valid);
can_q_pulse <= q_state=IDLE_S and not (single_valid and wr_trace_valid);

trace_chunk <= m.filtered.sample;

pulse_start <= m.pre_pulse_start and enable;  


captureStart:process (clk) is
begin
  if rising_edge(clk) then
    if m.pre_pulse_start and t_state=IDLE_S then 
      enable_reg <= enable; --FIXME this is an issue when the thresholds change 
                            --downstream
      case m.pre_eflags.event_type.detection is
      when PEAK_DETECTION_D | AREA_DETECTION_D | PULSE_DETECTION_D =>
        frame_length <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1);
      when TRACE_DETECTION_D => 
        case tflags.trace_type is
        when SINGLE_TRACE_D =>
          frame_length <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1)+trace_length;
        when AVERAGE_TRACE_D =>
          frame_length <= trace_length;
        when DOT_PRODUCT_D =>  -- this should send the normal pulse + extra word
          frame_length <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1);
        end case;
      end case;
    end if;
  end if;
end process captureStart;

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
      single_valid <= FALSE; 
      pulse_overflow <= FALSE;
      trace_wr_count <= (others => '1');
      stride_count <= (others => '0');
      area_overflow <= FALSE;
--      enable_reg <= FALSE;
      
      q_state <= IDLE_S;
      p_state <= IDLE_S;
      t_state <= IDLE_S;
--      if DEBUG="TRUE" then
--        pending <= (others => '0');
--      end if;
      
      chunk_wr_state <= STORE0;
      
    else
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      commit_frame <= FALSE;
      frame_we <= (others => FALSE);
      
      
      if not commiting then
        free <= framer_free;
      end if; 

      -- queue to framer  
      if not wr_trace_valid then -- FIXME register
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
            q_state <= IDLE_S;
          when PULSE0_S =>
            frame_word <= queue(0);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
            commit_frame <= FALSE;
            q_state <= PULSE1_S;
          when PULSE1_S =>
            -- no free test since peak must already be written
            frame_word <= queue(1);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
            commit_frame <= FALSE;
            q_state <= PULSELAST_S;
          when PULSELAST_S =>
            frame_word <= queue(2);
            frame_word.last <= (0 => TRUE, others => FALSE);
            frame_we <= (0 => TRUE, others => FALSE);
            commit_frame <= TRUE;
            frame_address <= resize(m.last_peak_address,FRAMER_ADDRESS_BITS);
  --          frame_length <= resize(m.size,FRAMER_ADDRESS_BITS+1);
            if single_valid then
              q_state <= SINGLE_S;
            else
              q_state <= IDLE_S;
            end if;
          when TRACE0_S =>
  --          frame_length <= trace_size;
            frame_word <= queue(1);
            frame_address <= (others => '0');
            frame_word.last <= (others => FALSE);
            if commit_trace then 
              frame_we <= (others => TRUE);
              commit_trace <= FALSE;
              commit_frame <= TRUE;
              q_state <= IDLE_S;
            end if;
          when TRACE1_S =>
            frame_word <= queue(2);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
            q_state <= TRACE0_S;
          end case;
        end if;
      end if;
        
      --initialise new trace and count strides
      if trace_start then --FIXME handle double pulse
        if tflags.trace_type=SINGLE_TRACE_D then
          trace_address <= resize(m.pre_size,FRAMER_ADDRESS_BITS);
        else
          trace_address <= (others => '0');
        end if;
        stride_count <= trace_stride;
        trace_wr_count <= trace_length-1;
        chunk_wr_state <= STORE0;
        trace_size <= resize(m.pre_size,FRAMER_ADDRESS_BITS)+trace_length;
      elsif stride_count=0 then
        stride_count <= trace_stride;
      else 
        stride_count <= stride_count-1;
      end if;
      
      --gather trace words and write to framer
      if tracing and stride_count=0 then
        case chunk_wr_state is
        when STORE0 => 
          trace_wr_reg(63 downto 48) <= set_endianness(trace_chunk,ENDIAN);
          chunk_wr_state <= STORE1;
        when STORE1 => 
          trace_wr_reg(47 downto 32) <= set_endianness(trace_chunk,ENDIAN);
          chunk_wr_state <= STORE2;
        when STORE2 => 
          trace_wr_reg(31 downto 16) <= set_endianness(trace_chunk,ENDIAN);
          chunk_wr_state <= WRITE;
          can_write_trace <= free > trace_address;
        when WRITE => 
          if can_write_trace then
            chunk_wr_state <= STORE0;
            frame_we <= (others => TRUE);
            frame_word.data(63 downto 16) <= trace_wr_reg(63 downto 16);
            frame_word.data(15 downto 0) <= set_endianness(trace_chunk,ENDIAN);
            frame_word.last <= (0 => trace_wr_count=0, others => FALSE);
            if trace_wr_count=0 and p_state=IDLE_S then
              commit_trace <= TRUE;
              commiting <= TRUE;
              free <= framer_free - trace_size;
            end if;
            frame_address <= trace_address;
            if trace_wr_count /= 0 then
              trace_address <= trace_address+1;
              trace_wr_count <= trace_wr_count-1;
            end if;
          else
            dump_int <= m.pulse_stamped;
            p_state <= IDLE_S;
            t_state <= IDLE_S;
            q_state <= IDLE_S;
            overflow_int <= TRUE;
          end if;
        end case;
      end if;
      
      -- when accum 
      -- want to suppress starts
      -- want to dump multi pulse and more than one pk
      
      -- want to capture traces with certain number of peaks?
      
      case t_state is 
      when IDLE_S =>
        tflags.multipulse <= FALSE;
        if pulse_start then
          p_state <= STARTED_S;
          if pre_detection=TRACE_DETECTION_D then
            if tflags.trace_type=SINGLE_TRACE_D then
              t_state <= PULSE_S;
            else
              t_state <= TRACE_S;
            end if;
          end if;
        end if;
      when PULSE_S =>
        --FIXME what if both are true:
        if trace_wr_count=0 and chunk_wr_state=WRITE and stride_count=0 then
          t_state <= WAITPULSE_S;
          commiting <= TRUE;
          free <= framer_free - trace_size;
        end if;
        if m.pre_pulse_threshold_neg then 
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
        if trace_wr_count=0 and wr_trace then
          t_state <= IDLE_S;
        end if;
      when WAITPULSE_S =>
        if m.pre_pulse_threshold_neg then 
          if pulse_start then
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
        if m.pre_pulse_threshold_neg then
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
              null;
              p_state <= IDLE_S;
            elsif can_q_trace then
              queue(1) <= to_streambus(trace,0,ENDIAN);
              queue(2) <= to_streambus(trace,1,ENDIAN);
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
              dump_int <= TRUE;
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
            if free=0 then
              overflow_int <= TRUE;
              single_valid <= FALSE;
              dump_int <= TRUE;
            else 
              queue(0) <= to_streambus(area,ENDIAN);
              single_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
              single_valid <= TRUE;
              single_commit <= TRUE;
              commiting <= TRUE;
              free <= framer_free - 1;
            end if;
          else -- normal pulse
            if not pulse_start then
              p_state <= IDLE_S;
            end if;
            if free <= m.size then 
              overflow_int <= TRUE;
              dump_int <= TRUE;
            elsif not can_q_pulse then
              error_int <= TRUE;
              dump_int <= TRUE;
              p_state <= IDLE_S;
            else
              queue(0) <= to_streambus(pulse,0,ENDIAN);
              queue(1) <= to_streambus(pulse,1,ENDIAN);
              queue(2) <= to_streambus(pulse_peak,TRUE,ENDIAN);
              pulse_commit <= TRUE;
              commiting <= TRUE;
              free <= framer_free - resize(m.size,FRAMER_ADDRESS_BITS+1);
              q_state <= PULSE0_S;
            end if;
          end if;
        end if;
      end case;
      
      -- FIXME what if enabled between start and peak
      if m.peak_stop and enable_reg then 
        if p_state=STARTED_S then 
          -- free test performed at pulse_start
          if pulse_peak_valid then --FIXME
            error_int <= TRUE;
            q_state <= IDLE_S;
            t_state <= IDLE_S;
            p_state <= IDLE_S;
            dump_int <= m.pulse_stamped; --FIXME???
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
            dump_int <= TRUE;
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
        else
          start_int <= TRUE;  
        end if;
      elsif p_state=STARTED_S and m.stamp_pulse then
        if mux_full then
          error_int <= TRUE;
        else
          start_int <= TRUE;  
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
  stream => stream_int,
  valid => valid_int,
  ready => ready_int
);

traceFSMTransition:process(
  a_state, tflags.trace_type,trace_start,acc_count,acc_ready,reg_ready, 
  stream_int,valid_int
)
begin
  a_nextstate <= a_state;
  ready_int <= reg_ready;
  reg_stream <= stream_int;
  reg_valid <= valid_int;
  case a_state is 
  when IDLE_S =>
    if trace_start and tflags.trace_type=AVERAGE_TRACE_D then
      a_nextstate <= ACCUM_S;
    end if; 
  when ACCUM_S =>
    ready_int <= acc_ready;
    if acc_count=0 then
      a_nextstate <= SEND_S;
    end if;
  when SEND_S =>
      null;
  when DOT_S =>
      null;
  end case;
end process traceFSMTransition;

--read traces from framer and accumulate
accumFSM:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      a_state <= IDLE_S;
      chunk_acc_state <= IDLE_S;
      acc_ready <= FALSE;
    else
      a_state <= a_nextstate;
      case chunk_acc_state is 
      when IDLE_S =>
        first_trace <= TRUE;
        acc_ready <= FALSE;
        if a_state=ACCUM_S then
          chunk_acc_state <= READ3;
        end if;
      when WAIT_TRACE =>
        acc_count <= acc_count_init;
        acc_trace_count <= trace_length-1;
        acc_wr_address <= (others => '0');
        if valid_int then
          chunk_acc_state <= READ3;
        end if;
      when READ3 =>
        acc_sample <= signed(stream_int.data(63 downto 48));
        acc_wr_address <= acc_wr_address+1;
        chunk_acc_state <= READ2;
        acc_ready <= FALSE;
      when READ2 =>
        acc_sample <= signed(stream_int.data(47 downto 32));
        acc_wr_address <= acc_wr_address+1;
        chunk_acc_state <= READ1;
      when READ1 =>
        acc_sample <= signed(stream_int.data(31 downto 16));
        acc_wr_address <= acc_wr_address+1;
        chunk_acc_state <= READ0;
        acc_ready <= TRUE;
      when READ0 =>
        acc_sample <= signed(stream_int.data(15 downto 0));
        if valid_int then
          acc_ready <= FALSE;
          acc_wr_address <= acc_wr_address+1;
          if acc_trace_count=0 then
            if acc_count=0 then
              chunk_acc_state <= IDLE_S;
            else
              acc_count <= acc_count-1;
              chunk_acc_state <= WAIT_TRACE;
              first_trace <= FALSE;
            end if;
          else
            chunk_acc_state <= READ3; 
          end if;
        end if;
      end case;
    end if;
  end if;
end process accumFSM;

dotproduct:entity work.pulse_accumulator
generic map(
  ADDRESS_BITS => TRACE_LENGTH_BITS,
  WIDTH => WIDTH,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH
)
port map(
  clk => clk,
  reset => reset,
  accumulate_n => accumulate_n,
  sample => acc_sample,
  accumulate => accumulate,
  write => write_acc,
  address => acc_address,
  data => acc_data
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
