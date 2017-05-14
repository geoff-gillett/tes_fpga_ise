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

signal m:measurements_t;
signal peak:peak_detection_t;
signal area:area_detection_t;
signal pulse,pulse_reg:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal pulse_peak_word:streambus_t;
signal trace,pulse_reg_trace:trace_detection_t;
signal tflags:trace_flags_t;

signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
--signal framer_full:boolean;

attribute equivalent_register_removal:string;
attribute equivalent_register_removal of mux_full:signal is "no";

signal free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0):=(others => '0');
--
signal pulse_valid,pulse_peak_valid:boolean;
signal pulse_overflow:boolean;
signal frame_word:streambus_t;
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame,start_int,dump_int,just_started:boolean;

signal peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal area_overflow:boolean;
signal pulse_start:boolean;
signal peak_stamped,pulse_stamped:boolean:=FALSE;

signal pre_detection,detection:detection_d;
signal full,pre_full:boolean;

-- TRACE control registers implemented as constants
constant trace_length:unsigned(FRAMER_ADDRESS_BITS downto 0)
         :=to_unsigned(512,FRAMER_ADDRESS_BITS+1);
constant TRACE_STRIDE_BITS:integer:=5;
constant trace_stride:unsigned(TRACE_STRIDE_BITS-1 downto 0):=(others => '0');
-- trace signals
signal trace_reg:std_logic_vector(BUS_DATABITS-1 downto 16);
--signal trace_valid:boolean;
signal trace_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal stride_count:unsigned(TRACE_STRIDE_BITS-1 downto 0);
--signal trace_started:boolean;
signal trace_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal trace_count:unsigned(FRAMER_ADDRESS_BITS downto 0);
--signal trace_size:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal trace_start:boolean;
signal stride_wr:boolean;
signal commiting:boolean;
signal overflow_int,error_int:boolean;
--signal stamp_error:boolean;
--signal trace_overflow,single_overflow,trace_overflow_valid,trace_done:boolean;
--signal tracing:boolean;
signal trace_wr:boolean;
signal enable_reg:boolean;
--signal trace_done:boolean;
signal can_q_trace,can_q_pulse,can_q_single:boolean;
signal can_write_trace:boolean;
signal multipeak,multipulse:boolean;

--FSMs
--type pulseFSMstate is (IDLE_S,STARTED_S); --,DUMP_S,ERROR_S,AREADUMP_S,END_S);
--signal p_state:pulseFSMstate;
type traceFSMstate is (IDLE,FIRSTPULSE,TRACING,WAITPULSEDONE);
signal t_state:traceFSMstate;
type traceChunkState is (STORE0,STORE1,STORE2,WRITE,DONE);
signal trace_chunk_state:traceChunkState;

type queueFSMstate is (IDLE,SINGLE,WORD0,WORD1);
signal q_state:queueFSMstate;

--debugging
--signal flags:std_logic_vector(7 downto 0);
signal pending:signed(3 downto 0):=(others => '0');
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
tflags.trace_signal <= FILTERED_TRACE_D;
tflags.trace_type <= SINGLE_TRACE_D;
tflags.stride <= trace_stride;

trace.size <= resize(frame_length,CHUNK_DATABITS);
trace.flags <= m.eflags;
trace.trace_flags <= tflags;
trace.length <= m.pulse_length;
trace.offset <= m.time_offset;
trace.area <= m.pulse_area;

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

trace_start 
  <= m.pre_pulse_start and pre_detection=TRACE_DETECTION_D and enable_reg;
  
pulse_start 
  <= pre_detection/=PEAK_DETECTION_D and m.pre_pulse_start and enable_reg;  

--tracing <= (t_state=FIRSTPULSE or t_state=TRACING);
--wr_trace <= stride_count=0 and trace_chunk_state=WRITE;
--wr_trace_valid <= tracing and wr_trace;
--trace_last_wr <= stride_wr and trace_chunk_state=WRITE and trace_last_address;

can_q_single <= q_state=IDLE;
can_q_trace <= q_state=IDLE;
can_q_pulse <= q_state=IDLE;

pre_full <= free < resize(m.pre_size,FRAMER_ADDRESS_BITS+1);
full <= free < resize(m.size,FRAMER_ADDRESS_BITS+1);
trace_chunk <= set_endianness(m.filtered.sample,ENDIAN);


debugPending:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      pending <= (others => '0');
    else
      if start_int and not (commit_frame or dump_int) then
        pending <= pending + 1;
      end if;
      if (commit_frame or dump_int) and not start_int then
        pending <= pending - 1;
      end if;
    end if;
  end if;
end process debugPending;


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
      pulse_overflow <= FALSE;
      trace_address <= (others => '0');
      trace_count <= (others => '1');
      stride_count <= (others => '0');
      area_overflow <= FALSE;
      
      q_state <= IDLE;
      t_state <= IDLE;
      
      trace_chunk_state <= DONE;
      
    else
      
      start_int <= FALSE;
      dump_int <= FALSE;
      overflow_int <= FALSE;
      error_int <= FALSE;
      commit_frame <= FALSE;
      frame_we <= (others => FALSE);
      
      if m.pre_pulse_start then
        if t_state=IDLE then
          enable_reg <= enable;
        end if;
      end if;
      
      
      if m.pre_pulse_start and t_state=IDLE then 
        case m.pre_eflags.event_type.detection is
        when PEAK_DETECTION_D | AREA_DETECTION_D | PULSE_DETECTION_D =>
          frame_length <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1);
        when TRACE_DETECTION_D => 
          case tflags.trace_type is
          when SINGLE_TRACE_D =>
            frame_length 
              <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1)+trace_length;
          when AVERAGE_TRACE_D => --FIXME accum state must be factor here
            frame_length 
              <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1)+trace_length;
--            frame_length <= trace_length;
          when DOT_PRODUCT_D => --FIXME
            frame_length <= resize(m.pre_size,FRAMER_ADDRESS_BITS+1);
          end case;
        end case;
      end if;
      
      if not commiting then
        free <= framer_free;
      end if; 

      -- queue to framer 
      if not (trace_wr) then 
        if pulse_peak_valid then
          frame_word <= pulse_peak_word;
          frame_address <= peak_address;
          frame_we <= (others => TRUE);
          commit_frame <= FALSE;
          pulse_peak_valid <= FALSE; 
        else
          case q_state is 
          when IDLE =>
            frame_we <= (others => FALSE);
          when SINGLE => 
            frame_word <= queue(0);
            frame_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
            frame_we <= (others => TRUE);
            commit_frame <= TRUE;
            q_state <= IDLE;
          when WORD0 =>
            frame_word <= queue(0);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
            commit_frame <= TRUE;
            q_state <= IDLE;
          when WORD1 =>
            frame_word <= queue(1);
            frame_we <= (others => TRUE);
            frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
            q_state <= WORD0;
          end case;
        end if;
      end if;
        
      --initialise new trace and count strides
      if pre_detection=TRACE_DETECTION_D or detection=TRACE_DETECTION_D then
        if trace_start and not pre_full and (t_state=IDLE or 
           (t_state=WAITPULSEDONE and m.pre_pulse_threshold_neg)) then 
          stride_count <= (others => '0');
          trace_count <= trace_length-1;
          if tflags.trace_type=SINGLE_TRACE_D then
            trace_address <= resize(m.pre_size,FRAMER_ADDRESS_BITS);
          else
            trace_address <= to_unsigned(0,FRAMER_ADDRESS_BITS);
          end if;
          trace_chunk_state <= STORE0;
          --trace_size <= resize(m.pre_size,FRAMER_ADDRESS_BITS)+trace_length;
          stride_wr <= TRUE; --FIXME assumes valid start
          trace_wr <= FALSE;
        elsif stride_count=0 then
          stride_count <= trace_stride;
          stride_wr <= trace_chunk_state/=DONE; 
          trace_wr <= trace_chunk_state=WRITE;
        else
          stride_wr <= FALSE;
          trace_wr <= FALSE;
          stride_count <= stride_count-1;
        end if;
      else
        stride_wr <= FALSE;
      end if;
      
      --gather trace words and write to framer
      if stride_wr then --FIXME register stride_count=0
        case trace_chunk_state is
        when STORE0 => 
          trace_reg(63 downto 48) <= trace_chunk;
          trace_chunk_state <= STORE1;
        when STORE1 => 
          trace_reg(47 downto 32) <= trace_chunk;
          trace_chunk_state <= STORE2;
        when STORE2 => 
          trace_reg(31 downto 16) <= trace_chunk;
          trace_chunk_state <= WRITE;
          can_write_trace <= free > trace_address;
        when WRITE => 
          if can_write_trace then
            trace_chunk_state <= STORE0;
            frame_we <= (others => TRUE);
            frame_word.data(63 downto 16) <= trace_reg(63 downto 16);
            frame_word.data(15 downto 0) <= trace_chunk;
            frame_word.last <= (0 => trace_count=0, others => FALSE);
            if trace_count=0 then --FIXME move
              trace_chunk_state <= DONE;
            end if;
            frame_address <= trace_address;
            if trace_count /= 0 then
              trace_address <= trace_address+1;
              trace_count <= trace_count-1;
            end if;
          else
            dump_int <= pulse_stamped;
            pulse_stamped <= FALSE;
            t_state <= IDLE;
--            q_state <= IDLE;
            overflow_int <= TRUE;
            trace_chunk_state <= DONE;
          end if;
        when DONE =>
        end case;
      end if;
      
      case t_state is 
      when IDLE =>
        just_started <= TRUE;
        pulse_stamped <= FALSE;
        if pulse_start then 
          if free >= resize(m.pre_size,FRAMER_ADDRESS_BITS+1) then
            t_state <= FIRSTPULSE;
            tflags.multipulse <= FALSE;
            tflags.multipeak <= FALSE;
          else
            overflow_int <= TRUE;
          end if;
        end if;
        
      when FIRSTPULSE =>
        just_started <= FALSE; 
        if m.pulse_threshold_neg and not just_started then
          
          if not m.above_area_threshold then
            dump_int <= pulse_stamped;
            if m.pulse_start and detection/=PEAK_DETECTION_D then 
              pulse_stamped <= m.stamp_pulse;
              tflags.multipulse <= FALSE;
              tflags.multipeak <= FALSE;
            else
              t_state <= IDLE;
            end if;
            
          else
            
            if detection=TRACE_DETECTION_D then
              
              pulse_reg <= pulse;
              t_state <= TRACING;
              if m.pulse_start and not (trace_chunk_state=DONE) and 
                 (m.peak_start and m.eflags.peak_number/=0) then
                if tflags.trace_type=AVERAGE_TRACE_D then
                  dump_int <= pulse_stamped; 
                  pulse_stamped <= FALSE;
                  t_state <= IDLE;
                  trace_chunk_state <= DONE;
                else
                  tflags.multipulse <= m.pulse_start;
                  tflags.multipeak <= m.peak_start;
                end if;
              end if;
            
            elsif detection=AREA_DETECTION_D then
              if m.pulse_start then
                if full then
                  pulse_stamped <= FALSE;
                  overflow_int <= TRUE;
                  t_state <= IDLE;
                else
                  pulse_stamped <= m.stamp_pulse;
                  just_started <= TRUE;
                end if;
              else
                t_state <= IDLE;
              end if;
              
              q_state <= SINGLE;
              queue(0) <= to_streambus(area,ENDIAN);
              commiting <= TRUE;
              free <= framer_free - frame_length;
                
            else -- must be normal pulse
              
              if m.pulse_start and detection=PULSE_DETECTION_D then
                if full then
                  pulse_stamped <= FALSE;
                  overflow_int <= TRUE;
                  t_state <= IDLE;
                else
                  pulse_stamped <= m.stamp_pulse;
                  just_started <= TRUE;
                end if;
              else
                t_state <= IDLE;
              end if;
              
              if q_state=IDLE then 
                queue(0) <= to_streambus(pulse,0,ENDIAN);
                queue(1) <= to_streambus(pulse,1,ENDIAN);
                pulse_peak_word <= to_streambus(pulse_peak,TRUE,ENDIAN);
                pulse_peak_valid <= TRUE;
                peak_address <= resize(m.last_peak_address,FRAMER_ADDRESS_BITS);
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
          if detection=TRACE_DETECTION_D and trace_chunk_state=DONE then
            t_state <= WAITPULSEDONE;
          elsif (m.pulse_start and not just_started) or 
                (m.peak_start and m.eflags.peak_number/=0) then
            if tflags.trace_type=AVERAGE_TRACE_D then
              dump_int <= pulse_stamped; 
              pulse_stamped <= FALSE;
              t_state <= IDLE;
              trace_chunk_state <= DONE;
            else
              tflags.multipulse <= m.pulse_start;
              tflags.multipeak <= m.peak_start;
            end if;
          end if; 
        end if;
        
      when TRACING =>
        if trace_chunk_state=DONE then
          t_state <= IDLE;
          if q_state=IDLE then
            queue(0) <= to_streambus(pulse_reg_trace,0,ENDIAN); 
            queue(1) <= to_streambus(pulse_reg_trace,1,ENDIAN);
            commiting <= TRUE;
            free <= framer_free - frame_length;
            q_state <= WORD1;
          else  
            error_int <= TRUE;
            dump_int <= pulse_stamped;
          end if;
        else
          if m.pulse_start or (m.peak_start and m.eflags.peak_number/=0) then
            if tflags.trace_type=AVERAGE_TRACE_D then
              dump_int <= pulse_stamped; 
              pulse_stamped <= FALSE;
              t_state <= IDLE;
              trace_chunk_state <= DONE;
            else
              tflags.multipulse <= m.pulse_start;
              tflags.multipeak <= m.peak_start;
            end if;
          end if;
        end if;
        
      when WAITPULSEDONE =>
        if m.pulse_threshold_neg then 
          if not m.above_area_threshold then
            dump_int <= pulse_stamped;
          else
            if q_state=IDLE then
              queue(0) <= to_streambus(trace,0,ENDIAN); 
              queue(1) <= to_streambus(trace,1,ENDIAN);
              commiting <= TRUE;
              free <= framer_free - frame_length;
              q_state <= WORD1;
            else  
              error_int <= TRUE;
              dump_int <= pulse_stamped;
            end if;
          end if;
          
          if m.pulse_start and detection=TRACE_DETECTION_D then
            if full then
              pulse_stamped <= FALSE;
              overflow_int <= TRUE;
              t_state <= IDLE;
            else
              pulse_stamped <= m.stamp_pulse;
              just_started <= TRUE;
              tflags.multipulse <= FALSE;
              tflags.multipeak <= FALSE;
              t_state <= FIRSTPULSE;
            end if;
          else
            t_state <= IDLE;
          end if;
        else
          if m.pulse_start or (m.peak_start and m.eflags.peak_number/=0) then
            if tflags.trace_type=AVERAGE_TRACE_D then
              dump_int <= pulse_stamped; 
              pulse_stamped <= FALSE;
              t_state <= IDLE;
              trace_chunk_state <= DONE;
            else
              tflags.multipulse <= m.pulse_start;
              tflags.multipeak <= m.peak_start;
            end if;
          end if;
        end if;
        
      end case;
     
      -- peak recording 
      if m.peak_stop and enable_reg then 
        if t_state=FIRSTPULSE or t_state=WAITPULSEDONE then 
          if m.eflags.peak_number/=0 and tflags.trace_type=AVERAGE_TRACE_D then
            dump_int <= m.pulse_stamped;
            q_state <= IDLE;
            t_state <= IDLE;
            pulse_stamped <= FALSE;
          elsif pulse_peak_valid and stride_wr then
            error_int <= TRUE;
            q_state <= IDLE;
            t_state <= IDLE;
            dump_int <= m.pulse_stamped;
            pulse_stamped <= FALSE;
          else
            pulse_peak_word <= to_streambus(pulse_peak,FALSE,ENDIAN);
            peak_address <= resize(m.peak_address,FRAMER_ADDRESS_BITS);
            pulse_peak_valid <= TRUE;
          end if;
        elsif m.eflags.event_type.detection=PEAK_DETECTION_D then
          if free=0 then
            overflow_int <= TRUE;
            q_state <= IDLE;
            t_state <= IDLE;
            dump_int <= TRUE; --FIXME check that it is always stamped
            peak_stamped <= FALSE;
          else
            queue(0) <= to_streambus(peak,ENDIAN);
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
      elsif (t_state=FIRSTPULSE or t_state=WAITPULSEDONE) and m.stamp_pulse and 
            enable_reg then
        if mux_full then
          error_int <= TRUE;
          pulse_stamped <= FALSE;
        else
          start_int <= TRUE;  
          pulse_stamped <= TRUE;
        end if;
      end if; 
        
      if commit_frame or dump_int or error_int then
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
