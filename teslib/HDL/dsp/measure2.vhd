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

entity measure2 is
generic(
  CHANNEL:natural:=0;
  WIDTH:natural:=18;
  FRAC:natural:=3;
  WIDTH_OUT:natural:=16;
  FRAC_OUT:natural:=1;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  CFD_DELAY:natural:=1026;
  FRAMER_ADDRESS_BITS:integer:=MEASUREMENT_FRAMER_ADDRESS_BITS
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  enable:in boolean;
  
  registers:in capture_registers_t;
  
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  measurements:out measurements_t
);
end entity measure2;

architecture RTL of measure2 is

-- pipelines to sync signals
signal cfd_error_cfd,cfd_valid_cfd:boolean;
signal slope_cfd,filtered_cfd:signed(WIDTH-1 downto 0);
signal m:measurements_t;

--signal slope_pos_Txing,slope_neg_Txing:boolean;
--signal pulse_pos_Txing,pulse_neg_Txing:boolean;
signal filtered_x:signed(WIDTH-1 downto 0);
--signal filtered_reg,filtered_reg2:signed(WIDTH-1 downto 0);
--signal filtered_reg3,slope_reg:signed(WIDTH-1 downto 0);
--signal slope_pos_0xing_cfd,slope_neg_0xing_cfd:boolean;
signal pulse_time_n,pulse_length_n,rise_time_n:unsigned(16 downto 0);

constant DEPTH:integer:=5;
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

signal pulse_area:signed(AREA_WIDTH-1 downto 0);
--signal first_peak:boolean;

signal constant_fraction:signed(WIDTH-1 downto 0);
signal slope_threshold:signed(WIDTH-1 downto 0);
signal pulse_threshold:signed(WIDTH-1 downto 0);
--signal valid_peak:boolean;
signal peak_number_n,peak_number:unsigned(PEAK_COUNT_BITS downto 0);
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
signal filtered_out : signed(WIDTH_OUT-1 downto 0);
signal filtered_pos_0xing : boolean;
signal filtered_neg_0xing : boolean;
signal filtered_zero_xing : boolean;
signal filtered_area : signed(AREA_WIDTH-1 downto 0);
signal filtered_extrema : signed(WIDTH_OUT-1 downto 0);
signal area_threshold : signed(AREA_WIDTH-1 downto 0);
signal slope_out : signed(WIDTH_OUT-1 downto 0);
signal slope_pos_0xing : boolean;
signal slope_neg_0xing : boolean;
signal slope_zero_xing : boolean;
signal slope_area : signed(AREA_WIDTH-1 downto 0);
signal slope_extrema : signed(WIDTH_OUT-1 downto 0);
signal enabled:boolean;
signal peak_address_n:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal stamp_peak,stamp_pulse:boolean;
--signal rise_time:unsigned(TIME_BITS-1 downto 0);
signal first_peak : boolean;

begin
measurements <= m;
constant_fraction <= signed('0' & registers.constant_fraction);
slope_threshold <= signed('0' & registers.slope_threshold);
pulse_threshold <= signed('0' & registers.pulse_threshold);

CFD:entity dsp.CFD
generic map(
  WIDTH => WIDTH,
  DELAY => CFD_DELAY
)
port map(
  clk => clk,
  reset => reset,
  slope => slope,
  filtered => filtered,
  constant_fraction => constant_fraction,
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

enbabledP:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      enabled <= FALSE;
      first_peak <= FALSE;
    else
      if min_cfd then
        enabled <= enable;
      end if;
      if min_cfd and not above_pulse_threshold_cfd then
        first_peak <= TRUE;
      elsif max_cfd then
        first_peak <= FALSE;
      end if;
    end if;
  end if;
end process enbabledP;

pulseArea:entity dsp.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => pulse_t_pos_pipe(1),
  sig => filtered_x,  
  area => pulse_area
);

cfdLowXing:entity dsp.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => FALSE
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
  STRICT => FALSE
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
--      m.rise_time <= (others => '0');
--      m.pulse_time <= (others => '0');
--      m.pulse_length <= (others => '0');
--      peak_count <= (others => '0');
--      m.eflags.peak_overflow <= FALSE;
--      m.eflags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
--      m.stamp_peak <= FALSE;
--      m.stamp_pulse <= FALSE;
--      m.height_valid <= FALSE;
--      
--      pulse_time_n <= (0 => '1',others => '0');
--      pulse_length_n <= (0 => '1',others => '0');
--      rise_time_n <= (0 => '1',others => '0');

    else
      
      max_slope_pipe(2 to DEPTH) <= max_slope_x & max_slope_pipe(2 to DEPTH-1);
      cfd_low_pos_pipe(2 to DEPTH) <= cfd_low_pos_x & 
                                      cfd_low_pos_pipe(2 to DEPTH-1);
      cfd_high_pos_pipe(2 to DEPTH) <= cfd_high_pos_x & 
                                       cfd_high_pos_pipe(2 to DEPTH-1);
                                       
      --valid_peak_p <= valid_peak & valid_peak_p(1 to DEPTH-1);
      
      slope_t_pos_pipe <= slope_threshold_pos_cfd & 
                          slope_t_pos_pipe(1 to DEPTH-1);
      min_pipe <= min_cfd & min_pipe(1 to DEPTH-1);
      max_pipe <= max_cfd & max_pipe(1 to DEPTH-1);
      
      above_pipe <= above_pulse_threshold_cfd &
                    above_pipe(1 to DEPTH-1);
      armed_pipe <= armed_cfd & armed_pipe(1 to DEPTH-1);
      
      valid_peak_pipe(2 to DEPTH) <= (will_arm_pipe(1) and will_go_above_pipe(1) 
                                      and enabled and not cfd_error_pipe(1)) & 
                                      valid_peak_pipe(2 to DEPTH-1);
      
      will_go_above_pipe <= will_go_above_cfd &
                            will_go_above_pipe(1 to DEPTH-1);
      will_arm_pipe <= will_arm_cfd & will_arm_pipe(1 to DEPTH-1);
      
      pulse_t_pos_pipe <= pulse_threshold_pos_cfd & 
                          pulse_t_pos_pipe(1 to DEPTH-1);
      pulse_t_neg_pipe <= pulse_threshold_neg_cfd & 
                          pulse_t_neg_pipe(1 to DEPTH-1);
      
      cfd_error_pipe <= cfd_error_cfd & cfd_error_pipe(1 to DEPTH-1);
      cfd_valid_pipe <= cfd_valid_cfd & cfd_valid_pipe(1 to DEPTH-1);
      
      first_peak_pipe(2 to DEPTH) <= first_peak & first_peak_pipe(2 to DEPTH-1);
      
--      filtered_reg <= filtered_x;
--      filtered_reg2 <= filtered_reg;
--      filtered_reg3 <= filtered_reg2;
      --slope_reg <= slope_x;
     
      --peak_number_n <= peak_number + 1;
      
      -- minima at start of pulse  
      m.pulse_start <= min_pipe(DEPTH) and not above_pipe(DEPTH) and enabled and
                       valid_peak_pipe(DEPTH) and first_peak_pipe(DEPTH);
      m.peak_start <= min_pipe(DEPTH) and enabled and valid_peak_pipe(DEPTH); 
     
      
        
      
      --valid_peak <= will_arm_pipe(DEPTH-1) and will_go_above_pipe(DEPTH-1) and 
                    --enabled and not cfd_error_pipe(DEPTH-1);
      
      -- k1 clk before a minima which is below threshold
      if (min_pipe(DEPTH-1) and not above_pipe(DEPTH-1)) then 
        area_threshold <= signed('0' &registers.area_threshold);
        --m.last_peak <= FALSE;
        --m.time_offset <= (others => '0');
        -- m.rise_time <= (others => '0');
        -- m.pulse_time <= (others => '0');
        -- m.pulse_length <= (others => '0');
--        pulse_time_n <= (0 => '1',others => '0');
--        pulse_length_n <= (0 => '1',others => '0');
        m.eflags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
        m.eflags.event_type.detection <= registers.detection;
        m.eflags.event_type.tick <= FALSE;
        m.eflags.height <= registers.height;
        m.eflags.new_window <= FALSE;
        m.eflags.peak_overflow <= FALSE;
        m.eflags.timing <= registers.timing;
      end if;  
      
      --minima (max) mutually exclusive)
      if first_peak_pipe(DEPTH) and min_pipe(DEPTH) then 
        m.eflags.peak_number <= (others => '0');
        peak_number_n <= (0 => '1',others => '0');
        m.eflags.peak_number <= (others => '0');
        m.last_peak <= registers.max_peaks=0;
        m.max_peaks <= registers.max_peaks;
        m.time_offset <= (others => '0'); --FIXME needed?
        if registers.detection=PULSE_DETECTION_D or 
           registers.detection=TRACE_DETECTION_D then
          m.size <= resize(registers.max_peaks + 3, 16); --max_peaks 0 -> 1 peak
          m.peak_address <= (1 => '1', others => '0'); -- start at 2
          peak_address_n <= (1 downto 0 => '1', others => '0');
          
--          m.last_address <= resize( -- FIXME used?
--            ('0' & registers.max_peaks)+2,MEASUREMENT_FRAMER_ADDRESS_BITS
--          );
        else
          m.peak_address <= (others => '0'); 
          m.size <= (0 => '1',others => '0');
        end if;
      end if;
      if max_pipe(DEPTH) then -- maxima
        if peak_number > ('0' & m.max_peaks) then 
          m.eflags.peak_overflow <= TRUE;
        else
          m.last_peak <= peak_number=('0' & m.max_peaks);
          peak_number_n <= peak_number_n + 1;
          m.eflags.peak_number <= peak_number_n(PEAK_COUNT_BITS-1 downto 0);
          if m.eflags.event_type.detection=PULSE_DETECTION_D or
            m.eflags.event_type.detection=TRACE_DETECTION_D then
            m.peak_address <= peak_address_n;
            peak_address_n <= peak_address_n+1;
          else
            m.peak_address <= (others => '0');
          end if;
        end if;
      end if;
     
    
      case m.eflags.timing is
      when PULSE_THRESH_TIMING_D =>
        stamp_pulse <= pulse_t_pos_pipe(DEPTH-1);
        if first_peak_pipe(DEPTH-1) then
          stamp_peak <= pulse_t_pos_pipe(DEPTH-1); 
        else
          stamp_peak <= cfd_low_pos_pipe(DEPTH-1);
        end if;
        
      when SLOPE_THRESH_TIMING_D =>
        
        stamp_pulse <= slope_t_pos_pipe(DEPTH-1);
        if first_peak_pipe(DEPTH-1) then
          stamp_peak <= slope_t_pos_pipe(DEPTH-1);
        else
          stamp_peak <= min_pipe(DEPTH-1);
        end if;
          
      --this will not fire a pulse start
      when CFD_LOW_TIMING_D =>
        stamp_peak <= cfd_low_pos_pipe(DEPTH-1);
        stamp_pulse <= cfd_low_pos_pipe(DEPTH-1) and first_peak_pipe(DEPTH-1);
        
      when SLOPE_MAX_TIMING_D =>
        stamp_pulse <= max_slope_pipe(DEPTH-1);
        stamp_peak <= max_slope_pipe(DEPTH-1);
      end case;
      m.stamp_pulse <= stamp_pulse and valid_peak_pipe(DEPTH);
      m.stamp_peak <= stamp_peak and valid_peak_pipe(DEPTH);
      
      if first_peak_pipe(DEPTH) and min_pipe(DEPTH) then
        m.pulse_time <= (others => '0');
        pulse_time_n <= (0 => '1', others => '0'); 
      elsif pulse_time_n(16)='1' then
        m.pulse_time <= (others => '1');
      else
        pulse_time_n <= pulse_time_n + 1;
        m.pulse_time <= pulse_time_n(15 downto 0);
      end if;
      
      if stamp_peak then  
        m.rise_time <= (others => '0');
        rise_time_n <= (0 => '1', others => '0');
      elsif rise_time_n(16)='1' then
        m.rise_time <= (others => '1');
      else
        rise_time_n <= rise_time_n + 1;
        m.rise_time <= rise_time_n(15 downto 0);
      end if;
      --m.rise_time <= rise_time;
    
      case m.eflags.height is
      when PEAK_HEIGHT_D =>
        m.height <= filtered_out; 
      when CFD_HEIGHT_D =>
        m.height <= filtered_out; 
      when SLOPE_INTEGRAL_D =>
        m.height <= resize(slope_area,16); --FIXME scale?
      when SLOPE_MAX_D =>
        m.height <= slope_extrema(15 downto 0); --FIXME why?
      end case;
    
      if m.eflags.height=CFD_HEIGHT_D then
        m.height_valid <= cfd_high_pos_pipe(DEPTH) and valid_peak_pipe(DEPTH);
      else
        m.height_valid <= max_pipe(DEPTH) and valid_peak_pipe(DEPTH);
      end if;
      
      if stamp_pulse then --FIXME will this be right?
        m.time_offset <= pulse_time_n(TIME_BITS-1 downto 0);
      end if;
    
      if pulse_t_pos_pipe(DEPTH) then
        m.pulse_length <= (others => '0');
        pulse_length_n <= (0 => '1', others => '0');
      else
        if pulse_length_n(TIME_BITS)='1' then
          m.pulse_length <= (others => '1');
        else
          pulse_length_n <= pulse_length_n + 1;
          m.pulse_length <= pulse_length_n(15 downto 0);
        end if;
      end if;
    
      m.pulse_area <= pulse_area;
      m.above_area_threshold <= pulse_area >= area_threshold;
      m.above_pulse_threshold <= above_pipe(DEPTH);

      m.valid_peak <= valid_peak_pipe(DEPTH);
      m.cfd_high <= cfd_high_pos_pipe(DEPTH);
      m.cfd_low <= cfd_low_pos_pipe(DEPTH);
      m.max_slope <= max_slope_pipe(DEPTH);
      --m.eflags.peak_number <= peak_number(PEAK_COUNT_BITS-1 downto 0);
      m.above_pulse_threshold <= above_pipe(DEPTH);
      m.armed <= armed_pipe(DEPTH);
      m.will_arm <= will_arm_pipe(DEPTH);
      m.will_go_above <= will_go_above_pipe(DEPTH);
      m.pulse_threshold_pos <= pulse_t_pos_pipe(DEPTH);
      m.pulse_threshold_neg <= pulse_t_neg_pipe(DEPTH);
      m.slope_threshold_pos <= slope_T_pos_pipe(DEPTH);
      m.cfd_error <= cfd_error_pipe(DEPTH);
      m.cfd_valid <= cfd_valid_pipe(DEPTH);
      
      m.filtered.sample <= filtered_out;
      m.filtered.pos_0xing <= filtered_pos_0xing;
      m.filtered.neg_0xing <= filtered_neg_0xing;
      m.filtered.zero_xing <= filtered_zero_xing;
      m.filtered.area <= filtered_area;
      m.filtered.extrema <= filtered_extrema;
      
      m.slope.sample <= slope_out;
      m.slope.pos_0xing <= slope_pos_0xing;
      m.slope.neg_0xing <= slope_neg_0xing;
      m.slope.zero_xing <= slope_zero_xing;
      m.slope.area <= slope_area;
      m.slope.extrema <= slope_extrema;
    end if;
  end if;
end process pulseMeas;

--m.slope_threshold_neg <= slope_neg_Txing_p(DEPTH);

--latency 7
filteredMeas:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
	WIDTH_OUT => WIDTH_OUT,
	FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  STRICT => TRUE
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_cfd,
  threshold => (others => '0'),
  signal_out => filtered_out,
  pos_xing => filtered_pos_0xing,
  neg_xing => filtered_neg_0xing,
  xing => filtered_zero_xing,
  area => filtered_area,
  extrema => filtered_extrema
);


slopeMeas:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
	WIDTH_OUT => WIDTH_OUT,
	FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  STRICT => TRUE
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_cfd,
  threshold => (others => '0'),
  signal_out => slope_out,
  pos_xing => slope_pos_0xing,
  neg_xing => slope_neg_0xing,
  xing => slope_zero_xing,
  area => slope_area,
  extrema => slope_extrema
);


end architecture RTL;
