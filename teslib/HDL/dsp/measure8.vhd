library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

library dsp;
use dsp.types.all;

use work.types.all;
use work.registers.all;
use work.events.all;
use work.measurements.all;

entity measure8 is
generic(
  CHANNEL:natural:=0;
  CF_WIDTH:natural:=18;
  CF_FRAC:natural:=17;
  WIDTH:natural:=16;
  FRAC:natural:=3;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  TIME_WIDTH:natural:=16;
  SIZE_WIDTH:natural:=16;
  CFD_DELAY:natural:=1026;
  STRICT_CROSSING:boolean:=TRUE;
  ADDRESS_BITS:natural:=MEASUREMENT_FRAMER_ADDRESS_BITS
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  registers:in capture_registers_t;
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  measurements:out measurements_t
);
end entity measure8;

architecture RTL of measure8 is

-- pipelines to sync signals
signal cfd_error_cfd,cfd_valid_cfd:boolean;
signal slope_cfd,filtered_cfd:signed(WIDTH-1 downto 0);
signal m:measurements_t;

signal filtered_x:signed(WIDTH-1 downto 0);
signal pulse_time_n,pulse_length_n,rise_time_n:unsigned(16 downto 0);

--------------------------------------------------------------------------------
-- pipeline signals
--------------------------------------------------------------------------------
constant XLAT:natural:=2; -- crossing latency
constant ALAT:natural:=5; --accumulator latency
constant ELAT:natural:=1; --extrema latency
constant DEPTH:integer:=ALAT+XLAT;--5; --main pipeline depth

--type pipe is array (1 to DEPTH) of signed(WIDTH-1 downto 0);
signal cfd_low_pos_pipe,cfd_high_pos_pipe:boolean_vector(1 to DEPTH);
signal max_slope_pipe:boolean_vector(1 to DEPTH);
signal slope_t_pos_pipe:boolean_vector(1 to DEPTH);
signal min_pipe,max_pipe:boolean_vector(1 to DEPTH);
signal will_go_above_pipe,will_arm_pipe:boolean_vector(1 to DEPTH);
signal pulse_t_pos_pipe,pulse_t_neg_pipe:boolean_vector(1 to DEPTH);
signal above_pipe,armed_pipe:boolean_vector(1 to DEPTH);
signal cfd_error_pipe,cfd_valid_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
signal valid_peak_pipe,first_peak_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
--------------------------------------------------------------------------------

signal pulse_area:signed(AREA_WIDTH-1 downto 0);

signal constant_fraction:signed(CF_WIDTH-1 downto 0);
signal slope_threshold:signed(WIDTH-1 downto 0);
signal pulse_threshold:signed(WIDTH-1 downto 0);
signal valid_peak:boolean;
signal peak_number_n:unsigned(PEAK_COUNT_BITS downto 0);
signal cfd_low_threshold,cfd_high_threshold:signed(WIDTH-1 downto 0);
signal max_slope_threshold:signed(WIDTH-1 downto 0);
signal max_cfd,min_cfd:boolean;
signal will_go_above_cfd:boolean;
signal will_arm_cfd:boolean;
signal overrun_cfd:boolean;
signal armed_cfd:boolean;
signal slope_threshold_pos_cfd:boolean;
signal above_pulse_threshold_cfd:boolean;
signal pulse_threshold_pos_cfd:boolean;
signal pulse_threshold_neg_cfd:boolean;
signal cfd_low_pos_x:boolean;
signal cfd_low_neg_x:boolean;
signal cfd_high_pos_x:boolean;
signal cfd_high_neg_x:boolean;
signal slope_x:signed(WIDTH-1 downto 0);
signal max_slope_x:boolean;
signal filtered_area:signed(AREA_WIDTH-1 downto 0);
signal filtered_extrema:signed(WIDTH-1 downto 0);
signal area_threshold:signed(AREA_WIDTH-1 downto 0);
signal slope_area:signed(AREA_WIDTH-1 downto 0);
signal slope_extrema:signed(WIDTH-1 downto 0);
signal peak_address_n,max_peaks,pre_max_peaks:unsigned(PEAK_COUNT_BITS downto 0);
signal pre_stamp_peak,pre_stamp_pulse:boolean;

type long_pipe is array(1 to DEPTH) of signed(WIDTH-1 downto 0);
type pipe is array(1 to DEPTH) of signed(WIDTH-1 downto 0);
signal high_pipe,low_pipe,filtered_long_pipe,slope_long_pipe:long_pipe;
signal filtered_pipe,slope_pipe:pipe;
signal peak_stamped,pulse_stamped:boolean:=FALSE;
signal above_area_threshold:boolean;
signal filtered_0_pos_x,filtered_0_neg_x,filtered_0xing,slope_0xing:boolean;
signal filtered_0_pos_pipe:boolean_vector(1 to DEPTH);
signal filtered_0_neg_pipe:boolean_vector(1 to DEPTH);
signal pulse_start:boolean;
signal slope_area_m1:signed(AREA_WIDTH-1 downto 0);
signal slope_zero_xing : boolean;
signal filtered_zero_xing : boolean;
signal pulse_length:unsigned(TIME_WIDTH-1 downto 0);
signal height_valid:boolean;
signal height:signed(WIDTH-1 downto 0);
signal flags,pre_flags:detection_flags_t;
signal pre_tflags,tflags:trace_flags_t;
signal rise_time,pulse_time:unsigned(TIME_WIDTH-1 downto 0);
signal stamp_peak,stamp_pulse:boolean;
signal peak_address:unsigned(PEAK_COUNT_BITS downto 0);
signal last_peak:boolean;
signal valid_peak0,valid_peak1,valid_peak2:boolean;
signal height_thresh_out,timing_thresh_out:signed(WIDTH-1 downto 0);
signal size,pre_size,pre2_size:unsigned(PEAK_COUNT_BITS downto 0);
signal pre_frame_length:unsigned(ADDRESS_BITS downto 0);
signal pre_size2:unsigned(ADDRESS_BITS downto 0);
signal pre2_detection:detection_d;
signal pre2_trace_type:trace_type_d;

signal last_peak_address:unsigned(PEAK_COUNT_BITS downto 0);
signal peak_start:boolean;
signal pulse_t_xing:boolean;
signal pre_pulse_start,pre_peak_start:boolean;
signal minima:signed(WIDTH-1 downto 0);



constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of valid_peak:signal is DEBUG;

begin
measurements <= m;
constant_fraction <= signed('0' & registers.constant_fraction);
slope_threshold <= signed('0' & registers.slope_threshold);
pulse_threshold <= signed('0' & registers.pulse_threshold);

CFD:entity dsp.CFD8
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  DELAY => CFD_DELAY,
  STRICT_CROSSING => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  slope => slope,
  filtered => filtered,
  constant_fraction => constant_fraction,
  rel2min => registers.cfd_rel2min,
  slope_threshold => slope_threshold,
  pulse_threshold => pulse_threshold,
  cfd_low_threshold => cfd_low_threshold,
  cfd_high_threshold => cfd_high_threshold,
  max => max_cfd,
  min => min_cfd,
  max_slope => max_slope_threshold,
  will_go_above_pulse_threshold => will_go_above_cfd,
  will_arm => will_arm_cfd,
  overrun => overrun_cfd,
  slope_out => slope_cfd,
  slope_threshold_pos => slope_threshold_pos_cfd,
  armed => armed_cfd,
  above_pulse_threshold => above_pulse_threshold_cfd,
  filtered_out => filtered_cfd,
  pulse_threshold_pos => pulse_threshold_pos_cfd,
  pulse_threshold_neg => pulse_threshold_neg_cfd,
  cfd_error => cfd_error_cfd,
  cfd_valid => cfd_valid_cfd
);

pulse_t_xing <= pulse_t_pos_pipe(XLAT) or pulse_t_neg_pipe(XLAT);
pulseArea:entity dsp.area_acc3
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => pulse_t_xing,
  sig => filtered_x,  
  signal_threshold => pulse_threshold,
  area_threshold => area_threshold,
  area => pulse_area,
  above_area_threshold => above_area_threshold
);

cfdLowXing:entity dsp.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_cfd,
  threshold => cfd_low_threshold,
  signal_out => filtered_x,
  pos => cfd_low_pos_x,
  neg => cfd_low_neg_x
);

cfdHighXing:entity dsp.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_cfd,
  threshold => cfd_high_threshold,
  signal_out => open,
  pos => cfd_high_pos_x,
  neg => cfd_high_neg_x
);

filtered0xing:entity dsp.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_cfd,
  threshold => (others => '0'),
  signal_out => open,
  pos => filtered_0_pos_x,
  neg => filtered_0_neg_x
);
filtered_0xing <= filtered_0_pos_x or filtered_0_neg_x;

filteredArea:entity dsp.area_acc3
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => filtered_0xing,
  sig => filtered_x,
  signal_threshold => (others => '0'),
  area_threshold => (others => '0'),
  above_area_threshold => open,
  area => filtered_area
);

filteredExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  sig => filtered_pipe(DEPTH-ELAT),
  pos_0xing => filtered_0_pos_pipe(DEPTH-ELAT),
  neg_0xing => filtered_0_neg_pipe(DEPTH-ELAT),
  extrema => filtered_extrema
);

slopeArea:entity dsp.area_acc3
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => slope_0xing,
  sig => slope_long_pipe(XLAT-1),
  signal_threshold => (others => '0'),
  area_threshold => (others => '0'),
  above_area_threshold => open,
  area => slope_area_m1
);

slopeExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  sig => slope_pipe(DEPTH-ELAT),
  pos_0xing => min_pipe(DEPTH-ELAT),
  neg_0xing => max_pipe(DEPTH-ELAT),
  extrema => slope_extrema
);

maxSlopeXing:entity dsp.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => FALSE
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_cfd,
  threshold => max_slope_threshold,
  signal_out => slope_x,
  pos => max_slope_x,
  neg => open
);

pulseMeas:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then --FIXME are these resets needed
        valid_peak <= FALSE;
    else
      
      max_slope_pipe(1+XLAT to DEPTH) 
        <= max_slope_x & max_slope_pipe(1+XLAT to DEPTH-1);
      
      if low_pipe(XLAT) <= filtered_x and min_pipe(XLAT) then
        cfd_low_pos_pipe(1+XLAT to DEPTH) 
          <= TRUE  & cfd_low_pos_pipe(1+XLAT to DEPTH-1);
      else
        cfd_low_pos_pipe(1+XLAT to DEPTH) 
          <= cfd_low_pos_x & cfd_low_pos_pipe(1+XLAT to DEPTH-1);
      end if;
      
      cfd_high_pos_pipe(1+XLAT to DEPTH) 
        <= cfd_high_pos_x & cfd_high_pos_pipe(1+XLAT to DEPTH-1);
        
      filtered_0_pos_pipe(1+XLAT to DEPTH) 
        <= filtered_0_pos_x & filtered_0_pos_pipe(1+XLAT to DEPTH-1);
        
      filtered_0_neg_pipe(1+XLAT to DEPTH) 
        <= filtered_0_neg_x & filtered_0_neg_pipe(1+XLAT to DEPTH-1);
                                       
      filtered_long_pipe(1+XLAT to DEPTH) 
        <= filtered_x & filtered_long_pipe(1+XLAT to DEPTH-1);
        
      slope_long_pipe(1 to DEPTH) 
        <= slope_cfd & slope_long_pipe(1 to DEPTH-1);
        
      filtered_pipe(1 to DEPTH) 
        <= filtered_cfd & filtered_pipe(1 to DEPTH-1);
        
      slope_pipe(1 to DEPTH) 
        <= slope_cfd & slope_pipe(1 to DEPTH-1);
      
      slope_t_pos_pipe 
        <= slope_threshold_pos_cfd & slope_t_pos_pipe(1 to DEPTH-1);
                          
      min_pipe <= min_cfd & min_pipe(1 to DEPTH-1);
      max_pipe <= max_cfd & max_pipe(1 to DEPTH-1);
      
      above_pipe 
        <= above_pulse_threshold_cfd & above_pipe(1 to DEPTH-1);
      armed_pipe <= armed_cfd & armed_pipe(1 to DEPTH-1);
      
      if min_cfd then
        valid_peak <= will_arm_cfd and will_go_above_cfd and not cfd_error_cfd;
      elsif max_pipe(1) and above_pipe(1) then
        valid_peak <= FALSE;
      end if;
      
      valid_peak_pipe(2 to DEPTH) 
        <= valid_peak & valid_peak_pipe(2 to DEPTH-1);
        
      
      will_go_above_pipe 
        <= will_go_above_cfd & will_go_above_pipe(1 to DEPTH-1);
      will_arm_pipe 
        <= will_arm_cfd & will_arm_pipe(1 to DEPTH-1);
      
      pulse_t_pos_pipe 
        <= pulse_threshold_pos_cfd & pulse_t_pos_pipe(1 to DEPTH-1);
      pulse_t_neg_pipe 
        <= pulse_threshold_neg_cfd & pulse_t_neg_pipe(1 to DEPTH-1);
      
      cfd_error_pipe <= cfd_error_cfd & cfd_error_pipe(1 to DEPTH-1);
      cfd_valid_pipe <= cfd_valid_cfd & cfd_valid_pipe(1 to DEPTH-1);
      
      if (min_cfd and not above_pulse_threshold_cfd) then
        first_peak_pipe <= TRUE & first_peak_pipe(1 to DEPTH-1);
      elsif max_pipe(1) then
        first_peak_pipe <= FALSE & first_peak_pipe(1 to DEPTH-1);
      else
        first_peak_pipe <= first_peak_pipe(1) & first_peak_pipe(1 to DEPTH-1);
      end if;
      
      high_pipe <= cfd_high_threshold & high_pipe(1 to DEPTH-1);
      low_pipe <= cfd_low_threshold & low_pipe(1 to DEPTH-1);
      
      slope_0xing <= min_pipe(XLAT-1) or max_pipe(XLAT-1); 
      
      pre_pulse_start <= min_pipe(DEPTH-2) and not above_pipe(DEPTH-2) and 
                         valid_peak_pipe(DEPTH-2) and first_peak_pipe(DEPTH-2);
      pulse_start <= pre_pulse_start;
                       
      pre_peak_start <= min_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2); 
      
      peak_start <= pre_peak_start;
      
      if flags.timing=PULSE_THRESH_TIMING_D then
        timing_thresh_out <= pulse_threshold;
      else
        timing_thresh_out <= low_pipe(DEPTH-1);
      end if;
      height_thresh_out <= high_pipe(DEPTH-1);
      
      -- pre2
      if (min_pipe(DEPTH-3)) then 
        if first_peak_pipe(DEPTH-3) then 
          pre2_detection <= registers.detection;
          pre2_trace_type <= registers.trace_type;
          
          case registers.detection is
          when PEAK_DETECTION_D | AREA_DETECTION_D => 
            pre2_size <= (0 => '1', others => '0');
            
          when PULSE_DETECTION_D => 
            pre2_size <= '0' & registers.max_peaks + 3; 
          when TRACE_DETECTION_D => 
            case registers.trace_type is
              when SINGLE_TRACE_D =>
                pre2_size <= '0' & registers.max_peaks + 3; 
              when AVERAGE_TRACE_D =>
                pre2_size <= '0' & registers.max_peaks + 3; 
              when DOT_PRODUCT_D =>
                pre2_size <= '0' & registers.max_peaks + 4; 
              when DOT_PRODUCT_TRACE_D =>
                pre2_size <= '0' & registers.max_peaks + 4; 
            end case;
          end case;
          
        end if;
      end if;
          
      if (min_pipe(DEPTH-2)) then 
        if first_peak_pipe(DEPTH-2) then 
          
          pre_size <= pre2_size;
          
          case registers.detection is
          when PEAK_DETECTION_D | AREA_DETECTION_D | PULSE_DETECTION_D => 
            pre_frame_length <=resize(pre2_size,ADDRESS_BITS+1); 
            
          when TRACE_DETECTION_D => 

            case registers.trace_type is
              
              when SINGLE_TRACE_D =>
                pre_frame_length <= resize(
                                      registers.trace_length,ADDRESS_BITS+1
                                    )+pre2_size; 
                                    
                pre_size2 <= resize(
                                      registers.trace_length,ADDRESS_BITS+1
                                     )+(pre2_size & '0'); 
                                    
              when AVERAGE_TRACE_D =>
                pre_frame_length <= resize( 
                                      registers.trace_length,ADDRESS_BITS+1
                                    ); 
                                    
                pre_size2 <= resize(
                                      registers.trace_length,ADDRESS_BITS+1
                                     )+pre_size; 
                
              when DOT_PRODUCT_D =>
                pre_frame_length <= resize(pre2_size,ADDRESS_BITS+1);
                pre_size2 <= resize(pre2_size & '0',ADDRESS_BITS+1); 
                
              when DOT_PRODUCT_TRACE_D =>
                pre_frame_length <= resize(
                                      registers.trace_length,ADDRESS_BITS+1
                                    )+pre2_size; 
                pre_size2 <= resize(
                                      registers.trace_length,ADDRESS_BITS+1
                                     )+(pre2_size & '0'); 
            end case;
          end case;
          
          --area_threshold <= signed('0' & registers.area_threshold);
          pre_flags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
          pre_flags.event_type.detection <= registers.detection;
          pre_flags.event_type.tick <= FALSE;
          pre_flags.height <= registers.height;
          pre_flags.new_window <= FALSE;
          pre_flags.cfd_rel2min <= registers.cfd_rel2min;
          pre_flags.timing <= registers.timing;
          pre_max_peaks <= '0' & registers.max_peaks;
          --pre_last_peak_address <= ('0' & registers.max_peaks)+2;

          pre_flags.peak_number <= (others => '0');
          peak_number_n <= (0 => '1',others => '0');
          
          pre_tflags.trace_signal <= registers.trace_signal;
          pre_tflags.trace_type <= registers.trace_type;
          pre_tflags.stride <= registers.trace_stride;
          pre_tflags.trace_length <= registers.trace_length;

          --pre_tflags.offset <= registers.max_peaks + 3;
          
          
--          last_peak <= registers.max_peaks=0;
          
--          valid_peak0 <= valid_peak_pipe(DEPTH-1);
          
--          peak_address <= (1 => '1', others => '0'); -- start at 2
--          peak_address_n <= (1 downto 0 => '1', others => '0');
        end if;  
      end if;  
      
      if (min_pipe(DEPTH-1)) then 
        if first_peak_pipe(DEPTH-1) then 
          
          size <= pre_size; --FIXME remove
          
          area_threshold <= signed('0' & registers.area_threshold);
          flags <= pre_flags;
          tflags <= pre_tflags;
          max_peaks <= pre_max_peaks;
          last_peak_address <= pre_max_peaks+2;
          m.offset <= resize(pre_max_peaks+3,PEAK_COUNT_BITS);

          peak_number_n <= (0 => '1',others => '0');
          last_peak <= pre_max_peaks=0;
          
          valid_peak0 <= valid_peak_pipe(DEPTH-1);
          
          peak_address <= (1 => '1', others => '0'); -- start at 2
          peak_address_n <= (1 downto 0 => '1', others => '0');
          
        end if;  
        minima <= filtered_pipe(DEPTH-1);
      end if;  
      
      if max_pipe(DEPTH) then
        valid_peak0 <= FALSE;
        valid_peak1 <= FALSE;
        valid_peak2 <= FALSE;
      end if;
      
      if m.slope.neg_0xing and m.valid_peak then -- maxima
--      if height_valid then -- maxima
        last_peak <= peak_number_n=max_peaks; 
        if peak_number_n > max_peaks then 
          m.peak_overflow <= TRUE;
        else
          peak_address <= peak_address_n;
          peak_address_n <= peak_address_n+1;
        end if;
        
        if peak_number_n(PEAK_COUNT_BITS)='0' then
          flags.peak_number <= peak_number_n(PEAK_COUNT_BITS-1 downto 0);
          peak_number_n <= peak_number_n + 1;
        else
          flags.peak_number <= (others => '1');
        end if;
      end if;
    
      case flags.timing is
      -- if pulse threshold is used for timing secondary peaks use cfd_low
      when PULSE_THRESH_TIMING_D =>
        pre_stamp_pulse 
          <= pulse_t_pos_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2) and 
             not (pulse_stamped and not pulse_t_neg_pipe(DEPTH-1));
                           
        if first_peak_pipe(DEPTH-2) then
          
          pre_stamp_peak 
            <= pulse_t_pos_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2) and
               not (peak_stamped and not max_pipe(DEPTH-1));
        else
          pre_stamp_peak 
            <= cfd_low_pos_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2) and
               not (peak_stamped and not max_pipe(DEPTH-1));
        end if;
        
      when SLOPE_THRESH_TIMING_D =>
        
        pre_stamp_pulse 
          <= slope_t_pos_pipe(DEPTH-2) and first_peak_pipe(DEPTH-2) and 
             valid_peak_pipe(DEPTH-2) and 
             not (pulse_stamped and not pulse_t_neg_pipe(DEPTH-1));
                           
        pre_stamp_peak 
          <= slope_t_pos_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2) and
             not (peak_stamped and not max_pipe(DEPTH-1));
          
      --this will not fire a pulse start ????
      when CFD_LOW_TIMING_D =>
        pre_stamp_peak 
          <= cfd_low_pos_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2) and
             not (peak_stamped and not max_pipe(DEPTH-1));
                          
        pre_stamp_pulse 
          <= cfd_low_pos_pipe(DEPTH-2) and first_peak_pipe(DEPTH-2) and 
             valid_peak_pipe(DEPTH-2) and 
             not (pulse_stamped and not pulse_t_neg_pipe(DEPTH-1));
        
      when SLOPE_MAX_TIMING_D =>
        pre_stamp_pulse 
          <= max_slope_pipe(DEPTH-2) and first_peak_pipe(DEPTH-2) and 
             valid_peak_pipe(DEPTH-2) and 
             not (pulse_stamped and not pulse_t_neg_pipe(DEPTH-1));
                           
        pre_stamp_peak 
          <= max_slope_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2) and
             not (peak_stamped and not max_pipe(DEPTH-1));
      end case;
      
      if max_pipe(DEPTH) then
        peak_stamped <= FALSE;
      end if;
      if pulse_t_neg_pipe(DEPTH) then
        pulse_stamped <= FALSE;
      end if;
      if pre_stamp_peak then
        peak_stamped <= TRUE;
        m.peak_time <= pulse_time;
      end if;
      if pre_stamp_pulse then
        pulse_stamped <= TRUE;
        m.time_offset <= pulse_time;
      end if;
        
      stamp_peak <= pre_stamp_peak;
      stamp_pulse <= pre_stamp_pulse;
      
      if first_peak_pipe(DEPTH-2) and min_pipe(DEPTH-2) and 
         valid_peak_pipe(DEPTH-2) then
        pulse_time <= (others => '0');
        pulse_time_n <= (0 => '1', others => '0'); 
      elsif pulse_time_n(16)='1' then
        pulse_time <= (others => '1');
      else
        pulse_time_n <= pulse_time_n + 1;
        pulse_time <= pulse_time_n(15 downto 0);
      end if;
      m.pulse_time <= pulse_time;
      
      if pre_stamp_peak then  
        rise_time <= (others => '0');
        rise_time_n <= (0 => '1', others => '0');
      elsif rise_time_n(16)='1' then
        rise_time <= (others => '1');
      else
        rise_time_n <= rise_time_n + 1;
        rise_time <= rise_time_n(15 downto 0);
      end if;
    
      height_valid <= FALSE;
      case flags.height is
      when PEAK_HEIGHT_D =>
        if max_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1) then
          height_valid <= TRUE;
          m.rise_time <= rise_time;
          if flags.cfd_rel2min then
            height <= filtered_pipe(DEPTH-1)-minima; 
          else
            height <= filtered_pipe(DEPTH-1); 
          end if;
        end if;
      when CFD_HEIGHT_D =>
        --FIXME could do subtraction before rounding
        if cfd_high_pos_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1) then
          height_valid <= TRUE;
          m.rise_time <= rise_time;
          if flags.cfd_rel2min then
            height <= high_pipe(DEPTH-1)-minima; 
          else
            height <= high_pipe(DEPTH-1); 
          end if;
        end if;
        --FIXME should use the max 
      when SLOPE_INTEGRAL_D =>
        if max_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1) then
          height_valid <= TRUE;
          m.rise_time <= rise_time;
          height <= resize(slope_area_m1,16); --FIXME scale?
        end if;
      when SLOPE_MAX_D => 
        --FIXME use slope extrema then all heights valid at max
        if max_slope_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1) then
          height_valid <= TRUE;
          m.rise_time <= rise_time;
          height <= slope_pipe(DEPTH-1); 
        end if;
      end case;
      
      if pulse_t_pos_pipe(DEPTH-2) then
        pulse_length <= (others => '0');
        pulse_length_n <= (0 => '1', others => '0');
      else
        if pulse_length_n(TIME_WIDTH)='1' then
          pulse_length <= (others => '1');
        else
          pulse_length_n <= pulse_length_n + 1;
          pulse_length <= pulse_length_n(15 downto 0);
        end if;
      end if;
      
--      if pulse_t_neg_pipe(DEPTH-1) then
--        m.pulse_length <= pulse_length;
--      end if;
      
--      m.minima <= min_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1);
      m.pre_peak_stop <= max_pipe(DEPTH-2) and valid_peak_pipe(DEPTH-2);
      m.peak_stop <= m.pre_peak_stop;
      filtered_zero_xing <= filtered_0_pos_pipe(DEPTH-1) or 
                            filtered_0_neg_pipe(DEPTH-1);
      slope_zero_xing <= min_pipe(DEPTH-1) or max_pipe(DEPTH-1);
      slope_area <= slope_area_m1;
      
    end if;
  end if;
end process pulseMeas;

--FIXME it would be useful in the framer to expose the pipes for some more 
--signals already done for starts
--a valid max an pre would help in the framer
m.pre_tflags <= pre_tflags;
m.tflags <= tflags;
--m.trace_signal <= registers.trace_signal;
--m.trace_type <= registers.trace_type;

m.valid_peak <= valid_peak_pipe(DEPTH);
m.valid_peak0 <= valid_peak0;
m.valid_peak1 <= valid_peak1;
m.valid_peak2 <= valid_peak2;

m.last_peak <= last_peak;
m.peak_address <= peak_address;
m.last_peak_address <= last_peak_address;

m.peak_start <= peak_start;
m.pre_peak_start <= pre_peak_start;
m.pulse_start <= pulse_start;
m.pre_pulse_start <= pre_pulse_start;
--m.pulse_time <= pulse_time;
m.stamp_peak <= stamp_peak;
m.stamp_pulse <= stamp_pulse;
m.pre_stamp_peak <= pre_stamp_peak;
m.pre_stamp_pulse <= pre_stamp_pulse;
--m.time_offset <= time_offset;
m.peak_stamped <= peak_stamped;
m.pulse_stamped <= pulse_stamped;
m.pulse_length <= pulse_length;

m.height <= height;
m.height_valid <= height_valid;
--m.rise_time <= rise_time;
m.min_value <= minima;

m.eflags <= flags;
m.pre_eflags <= pre_flags;
m.size <= size;
m.pre_size <= pre_size;
m.pre_frame_length <= pre_frame_length;
m.pre_size2 <= pre_size2;

--m.pre2_size <= pre2_size;
m.timing_threshold <= resize(timing_thresh_out,16);
--m.height_threshold <= height_thresh_out;
m.cfd_high <= cfd_high_pos_pipe(DEPTH);
m.cfd_high_threshold <= high_pipe(DEPTH);
m.cfd_low <= cfd_low_pos_pipe(DEPTH);
m.max_slope <= max_slope_pipe(DEPTH);
m.cfd_error <= cfd_error_pipe(DEPTH);
m.cfd_valid <= cfd_valid_pipe(DEPTH);

m.filtered_long <= filtered_long_pipe(DEPTH);
m.filtered.sample <= filtered_pipe(DEPTH);
m.filtered.pos_0xing <= filtered_0_pos_pipe(DEPTH);
m.filtered.neg_0xing <= filtered_0_neg_PIPE(DEPTH);
m.filtered.zero_xing <= filtered_zero_xing;
m.filtered.area <= filtered_area;
m.filtered.extrema <= filtered_extrema;
m.pulse_threshold_pos <= pulse_t_pos_pipe(DEPTH);
m.pulse_threshold_neg <= pulse_t_neg_pipe(DEPTH);
m.pre_pulse_threshold_neg <= pulse_t_neg_pipe(DEPTH-1);
--m.pulse_length <= pulse_length;
m.above_pulse_threshold <= above_pipe(DEPTH);
m.pulse_area <= pulse_area;
m.above_area_threshold <= above_area_threshold;
m.will_go_above <= will_go_above_pipe(DEPTH);

m.slope.sample <= slope_pipe(DEPTH);
m.slope.pos_0xing <= min_pipe(DEPTH);
m.slope.neg_0xing <= max_pipe(DEPTH);
m.slope.zero_xing <= slope_zero_xing;
m.slope_threshold_pos <= slope_T_pos_pipe(DEPTH);
m.slope.area <= slope_area;
m.slope.extrema <= slope_extrema;
m.armed <= armed_pipe(DEPTH);
m.will_arm <= will_arm_pipe(DEPTH);

end architecture RTL;
