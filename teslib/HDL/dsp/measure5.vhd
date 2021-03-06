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

entity measure5 is
generic(
  CHANNEL:natural:=0;
  WIDTH:natural:=18;
  FRAC:natural:=3;
  WIDTH_OUT:natural:=16;
  FRAC_OUT:natural:=3;
  SLOPE_FRAC:natural:=8;
  SLOPE_FRAC_OUT:natural:=8;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  TIME_WIDTH:natural:=16;
  SIZE_WIDTH:natural:=16;
  CFD_DELAY:natural:=1026;
  STRICT_CROSSING:boolean:=TRUE
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  registers:in capture_registers_t;
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  measurements:out measurements_t
);
end entity measure5;

architecture RTL of measure5 is

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
constant RLAT:natural:=3; --round latency
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
--signal valid_peak_p:boolean_vector(1 to DEPTH);
--------------------------------------------------------------------------------

signal pulse_area:signed(AREA_WIDTH-1 downto 0);

signal constant_fraction:signed(WIDTH-1 downto 0);
signal slope_threshold:signed(WIDTH-1 downto 0);
signal pulse_threshold:signed(WIDTH-1 downto 0);
signal valid_peak:boolean;
signal peak_number_n:unsigned(PEAK_COUNT_BITS downto 0);
--new
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
signal filtered_extrema:signed(WIDTH_OUT-1 downto 0);
signal area_threshold:signed(AREA_WIDTH-1 downto 0);
signal slope_area:signed(AREA_WIDTH-1 downto 0);
signal slope_extrema:signed(WIDTH_OUT-1 downto 0);
--signal enabled:boolean;
signal peak_address_n,max_peaks:unsigned(PEAK_COUNT_BITS downto 0);
signal pre_stamp_peak,pre_stamp_pulse:boolean;

type long_pipe is array(1 to DEPTH) of signed(WIDTH-1 downto 0);
type pipe is array(1 to DEPTH) of signed(WIDTH_OUT-1 downto 0);
signal high_pipe,low_pipe,filtered_long_pipe,slope_long_pipe:long_pipe;
signal filtered_pipe,slope_pipe:pipe;
signal peak_started,pulse_started:boolean;
signal above_area_threshold:boolean;
signal filtered_0_pos_x,filtered_0_neg_x,filtered_0xing,slope_0xing:boolean;
signal filtered_0_pos_pipe:boolean_vector(1 to DEPTH);
signal filtered_0_neg_pipe:boolean_vector(1 to DEPTH);
signal filtered_rounded,slope_rounded:signed(WIDTH_OUT-1 downto 0);
signal pulse_start:boolean;
signal slope_area_m1:signed(AREA_WIDTH-1 downto 0);
signal slope_zero_xing : boolean;
signal filtered_zero_xing : boolean;
signal pulse_length:unsigned(TIME_WIDTH-1 downto 0);
signal time_offset:unsigned(TIME_WIDTH-1 downto 0);
signal height_valid:boolean;
signal height:signed(WIDTH_OUT-1 downto 0);
signal flags:detection_flags_t;
signal rise_time,pulse_time:unsigned(TIME_WIDTH-1 downto 0);
signal stamp_peak,stamp_pulse:boolean;
signal peak_address:unsigned(PEAK_COUNT_BITS downto 0);
signal last_peak:boolean;
signal valid_peak0,valid_peak1,valid_peak2:boolean;
signal height_thresh_out,timing_thresh_out:signed(WIDTH-1 downto 0);
signal size,pre_size,pre2_size:unsigned(SIZE_WIDTH-1 downto 0);
signal last_peak_address:unsigned(PEAK_COUNT_BITS downto 0);
signal peak_start:boolean;
signal pulse_t_xing:boolean;
signal pre_pulse_start,pre_peak_start:boolean;
signal reg:capture_registers_t;
signal minima:signed(WIDTH_OUT-1 downto 0);
signal cfd_high_thresh_rounded:signed(WIDTH_OUT-1 downto 0);

constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of valid_peak:signal is DEBUG;

begin
measurements <= m;
constant_fraction <= signed('0' & registers.constant_fraction);
slope_threshold <= signed('0' & registers.slope_threshold);
pulse_threshold <= signed('0' & registers.pulse_threshold);

CFD:entity dsp.CFD2
generic map(
  WIDTH => WIDTH,
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

--enbabledP:process(clk)
--begin
--  if rising_edge(clk) then
--    if reset = '1' then
--      enabled <= FALSE;
--    else
--      if min_cfd then
--        enabled <= enable;
--      end if;
--    end if;
--  end if;
--end process enbabledP;

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

filteredRound:entity dsp.round2
generic map(
  WIDTH_IN => WIDTH,
  FRAC_IN => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT
)
port map(
  clk => clk,
  reset => reset,
  input => filtered_cfd,
  output_threshold => (others => '0'),
  output => filtered_rounded,
  above_threshold => open
);

highThreshRound:entity dsp.round2
generic map(
  WIDTH_IN => WIDTH,
  FRAC_IN => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT
)
port map(
  clk => clk,
  reset => reset,
  input => high_pipe(DEPTH-RLAT-1),
  output_threshold => (others => '0'),
  output => cfd_high_thresh_rounded,
  above_threshold => open
);

filteredExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH_OUT
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

slopeRound:entity dsp.round2
generic map(
  WIDTH_IN => WIDTH,
  FRAC_IN => SLOPE_FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => SLOPE_FRAC_OUT
)
port map(
  clk => clk,
  reset => reset,
  input => slope_cfd,
  output_threshold => (others => '0'),
  output => slope_rounded,
  above_threshold => open
);

slopeExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH_OUT
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
        
      filtered_pipe(1+RLAT to DEPTH) 
        <= filtered_rounded & filtered_pipe(1+RLAT to DEPTH-1);
        
      slope_pipe(1+RLAT to DEPTH) 
        <= slope_rounded & slope_pipe(1+RLAT to DEPTH-1);
      
      slope_t_pos_pipe 
        <= slope_threshold_pos_cfd & slope_t_pos_pipe(1 to DEPTH-1);
                          
      min_pipe <= min_cfd & min_pipe(1 to DEPTH-1);
      max_pipe <= max_cfd & max_pipe(1 to DEPTH-1);
      
      above_pipe 
        <= above_pulse_threshold_cfd & above_pipe(1 to DEPTH-1);
      armed_pipe <= armed_cfd & armed_pipe(1 to DEPTH-1);
      
      if min_cfd then
        valid_peak <= will_arm_cfd and will_go_above_cfd and not cfd_error_cfd;
      elsif max_pipe(1) then
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
      
      -- minima at start of pulse  
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
          
      --pre minima below pulse threshold 
      if (min_pipe(DEPTH-3) and not above_pipe(DEPTH-3)) then 
        reg <= registers;
        case registers.detection is
        when PEAK_DETECTION_D | AREA_DETECTION_D => 
          pre2_size <= (0 => '1', others => '0');
        when PULSE_DETECTION_D | TRACE_DETECTION_D => 
          pre2_size <= resize(registers.max_peaks + 3, 16); --max_peaks 0 -> 1 peak
        end case;
      end if;
      
      if (min_pipe(DEPTH-1) and not above_pipe(DEPTH-1)) then 
        area_threshold <= signed('0' & reg.area_threshold);
        flags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
        flags.event_type.detection <= reg.detection;
        flags.event_type.tick <= FALSE;
        flags.height <= reg.height;
        flags.new_window <= FALSE;
        flags.cfd_rel2min <= reg.cfd_rel2min;
        flags.timing <= reg.timing;
        max_peaks <= '0' & reg.max_peaks;
        last_peak_address <= ('0' & reg.max_peaks)+2;
        
      end if;  
       
      --minima (max) mutually exclusive)
      if min_pipe(DEPTH-1) then 
        
        minima <= filtered_pipe(DEPTH-1);
        
        if first_peak_pipe(DEPTH-1) then
          m.peak_overflow <= FALSE;
          flags.peak_number <= (others => '0');
          peak_number_n <= (0 => '1',others => '0');
          last_peak <= reg.max_peaks=0;
          --m.max_peaks <= registers.max_peaks;
          time_offset <= (others => '0'); 
          pre_size <= pre2_size;
          size <= pre_size;
          
          valid_peak0 <= valid_peak_pipe(DEPTH-1);
          
          peak_address <= (1 => '1', others => '0'); -- start at 2
          peak_address_n <= (1 downto 0 => '1', others => '0');
        else
          valid_peak1 <= flags.peak_number=1 and valid_peak_pipe(DEPTH-1);
          valid_peak2 <= flags.peak_number=2 and valid_peak_pipe(DEPTH-1);
        end if;
      end if;
      
      if max_pipe(DEPTH) then
        valid_peak0 <= FALSE;
        valid_peak1 <= FALSE;
        valid_peak2 <= FALSE;
      end if;
      
--      if m.slope.neg_0xing and m.valid_peak then -- maxima
      if height_valid then -- maxima
        last_peak <= peak_number_n=max_peaks; --FIXME not used
        if peak_number_n > max_peaks then 
          m.peak_overflow <= TRUE;
          last_peak <= TRUE; -- FIXME not used
        else
          peak_address <= peak_address_n;
          peak_address_n <= peak_address_n+1;
        end if;
        
        if peak_number_n(PEAK_COUNT_BITS)='0' then
          flags.peak_number <= peak_number_n(PEAK_COUNT_BITS-1 downto 0);
          peak_number_n <= peak_number_n + 1;
        else
          flags.peak_number <= (others => '0');
        end if;
      end if;
    
      case flags.timing is
      -- if pulse threshold is used for timing secondary peaks use cfd_low
      when PULSE_THRESH_TIMING_D =>
        pre_stamp_pulse <= pulse_t_pos_pipe(DEPTH-2);
        if first_peak_pipe(DEPTH-2) then
          pre_stamp_peak <= pulse_t_pos_pipe(DEPTH-2); 
        else
          pre_stamp_peak <= cfd_low_pos_pipe(DEPTH-2);
        end if;
        
      when SLOPE_THRESH_TIMING_D =>
        
        pre_stamp_pulse <= slope_t_pos_pipe(DEPTH-2) and 
                           first_peak_pipe(DEPTH-2);
        --if first_peak_pipe(DEPTH-2) then
        pre_stamp_peak <= slope_t_pos_pipe(DEPTH-2);
        --else
          --pre_stamp_peak <= min_pipe(DEPTH-2);
        --end if;
          
      --this will not fire a pulse start
      when CFD_LOW_TIMING_D =>
        pre_stamp_peak <= cfd_low_pos_pipe(DEPTH-2);
        pre_stamp_pulse <= cfd_low_pos_pipe(DEPTH-2) and 
                           first_peak_pipe(DEPTH-2);
        
      when SLOPE_MAX_TIMING_D =>
        pre_stamp_pulse <= max_slope_pipe(DEPTH-2) and 
                           first_peak_pipe(DEPTH-2);
        pre_stamp_peak <= max_slope_pipe(DEPTH-2);
      end case;
      
      if pre_stamp_peak and valid_peak_pipe(DEPTH-1) then
        peak_started <= TRUE;
      end if;
      if max_pipe(DEPTH-1) then
        peak_started <= FALSE;
      end if;
      if pre_stamp_pulse and valid_peak_pipe(DEPTH-1) then
        pulse_started <= TRUE;
      end if;
      if max_pipe(DEPTH-1) then
        pulse_started <= FALSE;
      end if;
        
      stamp_peak 
        <= pre_stamp_peak and valid_peak_pipe(DEPTH-1) and not peak_started;
      stamp_pulse 
        <= pre_stamp_pulse and valid_peak_pipe(DEPTH-1) and not pulse_started;
      
      if first_peak_pipe(DEPTH-1) and min_pipe(DEPTH-1) then
        pulse_time <= (others => '0');
        pulse_time_n <= (0 => '1', others => '0'); 
      elsif pulse_time_n(16)='1' then
        pulse_time <= (others => '1');
      else
        pulse_time_n <= pulse_time_n + 1;
        pulse_time <= pulse_time_n(15 downto 0);
      end if;
      
      if pre_stamp_peak and not peak_started then  
        rise_time <= (others => '0');
        rise_time_n <= (0 => '1', others => '0');
      elsif rise_time_n(16)='1' then
        rise_time <= (others => '1');
      else
        rise_time_n <= rise_time_n + 1;
        rise_time <= rise_time_n(15 downto 0);
      end if;
      --m.rise_time <= rise_time;
    
      case flags.height is
      when PEAK_HEIGHT_D =>
        if flags.cfd_rel2min then
          height <= filtered_pipe(DEPTH-1)-minima; 
        else
          height <= filtered_pipe(DEPTH-1); 
        end if;
        height_valid <= max_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1);
      when CFD_HEIGHT_D =>
        --FIXME could do subtraction before rounding
        if flags.cfd_rel2min then
          height <= cfd_high_thresh_rounded-minima; 
        else
          height <= cfd_high_thresh_rounded; 
        end if;
        --FIXME should be able to use the max 
        height_valid <= cfd_high_pos_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1);
      when SLOPE_INTEGRAL_D =>
        height <= resize(slope_area_m1,16); --FIXME scale?
        height_valid <= max_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1);
      when SLOPE_MAX_D => 
        --FIXME use slope extrema then all heights valid at max
        height <= slope_pipe(DEPTH-1); 
        height_valid <= max_slope_pipe(DEPTH-1) and valid_peak_pipe(DEPTH-1);
      end case;
      
      if pre_stamp_pulse and not pulse_started then --FIXME will this be right?
        if min_pipe(DEPTH-1) and first_peak_pipe(DEPTH-1) then
          time_offset <= (others => '0');
        else
          time_offset <= pulse_time_n(TIME_WIDTH-1 downto 0);
        end if;
      end if;
    
      if pulse_t_pos_pipe(DEPTH-1) then
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
m.pulse_time <= pulse_time;
m.stamp_peak <= stamp_peak;
m.stamp_pulse <= stamp_pulse;
m.time_offset <= time_offset;

m.height <= height;
m.height_valid <= height_valid;
m.rise_time <= rise_time;
m.min_value <= minima;

m.eflags <= flags;
m.size <= size;
m.pre_size <= pre_size;
m.pre2_size <= pre2_size;
m.timing_threshold <= timing_thresh_out;
m.height_threshold <= height_thresh_out;
m.cfd_high <= cfd_high_pos_pipe(DEPTH);
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
m.pulse_length <= pulse_length;
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
