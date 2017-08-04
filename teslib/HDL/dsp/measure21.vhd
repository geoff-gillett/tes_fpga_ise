library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

library dsp;
use dsp.types.all;

use work.types.all;
use work.registers21.all;
use work.events21.all;
use work.measurements21.all;

entity measure21 is
generic(
  CF_WIDTH:natural:=18;
  CF_FRAC:natural:=17;
  WIDTH:natural:=16;
  FRAC:natural:=3;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  TIME_WIDTH:natural:=16;
  CFD_DELAY:natural:=1026;
  ADDRESS_BITS:natural:=MEASUREMENT_FRAMER_ADDRESS_BITS
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  event_enable:in boolean;
  registers:in capture_registers_t;
  raw:in signed(WIDTH-1 downto 0);
  s:in signed(WIDTH-1 downto 0);
  f:in signed(WIDTH-1 downto 0);
  
  measurements:out measurements_t
);
end entity measure21;

architecture RTL of measure21 is

constant RAW_DELAY:natural:=1026;

-- pipelines to sync signals
signal cfd_error_cfd:boolean;
signal s_cfd,f_cfd:signed(WIDTH-1 downto 0);
signal raw_d:std_logic_vector(WIDTH-1 downto 0);

signal m:measurements_t;

signal pre_pulse_time_n,pulse_length_n,rise_time_n:unsigned(16 downto 0);

--------------------------------------------------------------------------------
-- pipeline signals
--------------------------------------------------------------------------------
constant XLAT:natural:=1; -- crossing latency
constant ALAT:natural:=5; --accumulate and round latency
constant ELAT:natural:=1; --extrema latency
constant DEPTH:integer:=ALAT+XLAT;--5; --main pipeline depth

--type pipe is array (1 to DEPTH) of signed(WIDTH-1 downto 0);
signal cfd_low_p_pipe,cfd_high_p_pipe:boolean_vector(1 to DEPTH);
signal max_slope_p_pipe:boolean_vector(1 to DEPTH);
signal s_t_p_pipe:boolean_vector(1 to DEPTH);
signal min_pipe,max_pipe:boolean_vector(1 to DEPTH);
signal will_cross_pipe,will_arm_pipe:boolean_vector(1 to DEPTH);
--signal pulse_t_pos_pipe,pulse_t_neg_pipe:boolean_vector(1 to DEPTH);
signal above_pipe,armed_pipe:boolean_vector(1 to DEPTH);
signal cfd_error_pipe,cfd_overrun_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
signal rise_start_pipe,first_rise_pipe,pulse_start_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
--------------------------------------------------------------------------------

signal pulse_area:signed(AREA_WIDTH-1 downto 0);

--signal p_threshold:signed(WIDTH-1 downto 0);
signal valid_rise:boolean;
signal rise_number_n:unsigned(PEAK_COUNT_BITS downto 0);
signal cfd_low_threshold,cfd_high_threshold:signed(WIDTH-1 downto 0);
signal max_slope_threshold:signed(WIDTH-1 downto 0);
signal max_cfd,min_cfd:boolean;
signal will_cross_cfd:boolean;
signal will_arm_cfd:boolean;
signal armed_cfd:boolean;
signal s_t_p_cfd:boolean;
signal above_cfd:boolean;
signal p_t_p_cfd:boolean;
signal p_t_n_cfd:boolean;
signal filtered_area:signed(AREA_WIDTH-1 downto 0);
signal f_extrema:signed(WIDTH-1 downto 0);
signal slope_area:signed(AREA_WIDTH-1 downto 0);
signal s_extrema:signed(WIDTH-1 downto 0);
signal rise_address_n:unsigned(PEAK_COUNT_BITS downto 0);
--signal pre_stamp_peak,pre_stamp_pulse:boolean;

type pipe is array(1 to DEPTH) of signed(WIDTH-1 downto 0);
--signal high_pipe,low_pipe,filtered_long_pipe,slope_long_pipe:long_pipe;
signal f_pipe,s_pipe,high_pipe,low_pipe:pipe;
signal rise_timestamped,pulse_timestamped:boolean:=FALSE;
signal above_area_threshold:boolean;
signal f_0_x_a:boolean;
signal f_0_p_pipe,p_t_p_pipe:boolean_vector(1 to DEPTH);
signal f_0_n_pipe,p_t_n_pipe:boolean_vector(1 to DEPTH);
-- TRUE during a valid rise
signal rising_pipe:boolean_vector(1 to DEPTH);
signal pulse_length:unsigned(TIME_WIDTH-1 downto 0);
signal height_valid:boolean;
signal height:signed(WIDTH-1 downto 0);
--signal flags:detection_flags_t;
--signal tflags:trace_flags_t;
signal stamp_rise,stamp_pulse:boolean;
signal peak_address:unsigned(PEAK_COUNT_BITS downto 0);
signal last_peak:boolean;
signal pre_size2:unsigned(ADDRESS_BITS downto 0);
--signal pre2_detection:detection_d;
--signal pre2_trace_type:trace_type_d;

signal last_peak_address,dp_address:unsigned(PEAK_COUNT_BITS downto 0);
signal p_t_x_a:boolean;

signal f_0_n_cfd:boolean;
signal f_0_p_cfd:boolean;
signal rise_start_cfd:boolean;
signal pulse_start_cfd:boolean;
signal cfd_low_p:boolean;
signal cfd_high_p:boolean;
signal max_slope_p:boolean;
signal s_0_x_a:boolean;
signal cfd_overrun_cfd:boolean;
signal first_rise_cfd:boolean;
signal rising_cfd:boolean;
signal reg:capture_registers_t;

constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of valid_rise:signal is DEBUG;

begin
measurements <= m;

--raw is simply delayed
rawDelay:entity dsp.sdp_bram_delay
generic map(
  DELAY => RAW_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(raw),
  delayed => raw_d
);
m.raw <= signed(raw_d);

CFD:entity work.CFD21
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  DELAY => CFD_DELAY
)
port map(
  clk => clk,
  reset => reset,
  
  -- reg can only change 1 clk before a minima 
  registers => registers,
  registers_out => reg,
  
  s => s,
  f => f,
  
  
  s_out => s_cfd,
  f_out => f_cfd,
  
  max => max_cfd,
  min => min_cfd,
  s_t_p => s_t_p_cfd,
  p_t_p => p_t_p_cfd,
  p_t_n => p_t_n_cfd,
  f_0_n => f_0_n_cfd, 
  f_0_p => f_0_p_cfd, 
  first_rise => first_rise_cfd, 
  armed => armed_cfd,
  above => above_cfd,
  
  rise_start => rise_start_cfd,
  rising => rising_cfd,
  pulse_start => pulse_start_cfd,
  
  cfd_low_threshold => cfd_low_threshold,
  cfd_high_threshold => cfd_high_threshold,
  max_slope_threshold => max_slope_threshold,
  will_cross => will_cross_cfd,
  will_arm => will_arm_cfd,
  
  cfd_low_p => cfd_low_p,
  cfd_high_p => cfd_high_p,
  max_slope_p => max_slope_p,
  
  cfd_error => cfd_error_cfd,
  cfd_overrun => cfd_overrun_cfd
);

-- register changes at DEPTH-ALAT should not have significant 
-- effect on functionality, they will lead to a error in a single area 
-- measurement at the threshold register change.
pulseArea:entity dsp.area_acc21
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => p_t_x_a,
  sig => f_pipe(DEPTH-ALAT),  
  signal_threshold => signed('0' & reg.pulse_threshold),
  area_threshold => signed('0' & reg.area_threshold),
  area => m.pulse_area,
  above_area_threshold => m.above_area
);

filteredArea:entity dsp.area_acc21
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => f_0_x_a,
  sig => f_pipe(DEPTH-ALAT),
  signal_threshold => (others => '0'),
  area_threshold => (others => '0'),
  above_area_threshold => open,
  area => m.f_area
);

filteredExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  sig => f_pipe(DEPTH-ELAT),
  pos_0xing => f_0_p_pipe(DEPTH-ELAT),
  neg_0xing => f_0_n_pipe(DEPTH-ELAT),
  extrema => m.f_extrema
);

slopeArea:entity dsp.area_acc21
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => s_0_x_a,
  sig => s_pipe(DEPTH-ALAT),
  signal_threshold => (others => '0'),
  area_threshold => (others => '0'),
  above_area_threshold => open,
  area => m.s_area
);

slopeExtrema:entity work.extrema
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  sig => s_pipe(DEPTH-ELAT),
  pos_0xing => min_pipe(DEPTH-ELAT),
  neg_0xing => max_pipe(DEPTH-ELAT),
  extrema => m.s_extrema
);

-- expose some pipelines for use by down stream entities.
m.pulse_start <= pulse_start_pipe(DEPTH-MEASUREMENT_DEPTH-1 to DEPTH);
m.rise_start <= rise_start_pipe(DEPTH-MEASUREMENT_DEPTH-1 to DEPTH);
m.p_t_p <= p_t_p_pipe(DEPTH-MEASUREMENT_DEPTH-1 to DEPTH);
m.p_t_n <= p_t_n_pipe(DEPTH-MEASUREMENT_DEPTH-1 to DEPTH);
m.min <= min_pipe(DEPTH-MEASUREMENT_DEPTH-1 to DEPTH);
m.max <= max_pipe(DEPTH-MEASUREMENT_DEPTH-1 to DEPTH);

m.f_0_p <= f_0_p_pipe(DEPTH);
m.f_0_n <= f_0_n_pipe(DEPTH);

pulseMeas:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then --FIXME are these resets needed
      m.valid_rise <= FALSE;
      m.pulse_stamped <= (others => FALSE);
      m.rise_stamped <= (others => FALSE);
    else
      --f and s zero crossings
      m.f_0 <= f_0_p_pipe(DEPTH-1) or f_0_n_pipe(DEPTH-1);
      m.s_0 <= min_pipe(DEPTH-1) or max_pipe(DEPTH-1);
      
      --crossing signals for area accumulators
      f_0_x_a <= f_0_p_pipe(DEPTH-ALAT-1) or f_0_n_pipe(DEPTH-ALAT-1);
      p_t_x_a <= p_t_p_pipe(DEPTH-ALAT-1) or p_t_n_pipe(DEPTH-ALAT-1);
      s_0_x_a <= min_pipe(DEPTH-ALAT-1) or max_pipe(DEPTH-ALAT-1);
      
      f_pipe(1 to DEPTH) <= f_cfd & f_pipe(1 to DEPTH-1);
      s_pipe(1 to DEPTH) <= s_cfd & s_pipe(1 to DEPTH-1);
      f_0_p_pipe(1 to DEPTH) <= f_0_p_cfd & f_0_p_pipe(1 to DEPTH-1);
      f_0_n_pipe(1 to DEPTH) <= f_0_n_cfd & f_0_n_pipe(1 to DEPTH-1);
      min_pipe <= min_cfd & min_pipe(1 to DEPTH-1);
      max_pipe <= max_cfd & max_pipe(1 to DEPTH-1);
      p_t_p_pipe(1 to DEPTH) <= p_t_p_cfd & p_t_p_pipe(1 to DEPTH-1);
      p_t_n_pipe(1 to DEPTH) <= p_t_n_cfd & p_t_n_pipe(1 to DEPTH-1);
      s_t_p_pipe(1 to DEPTH) <= s_t_p_cfd & s_t_p_pipe(1 to DEPTH-1);
      
      max_slope_p_pipe(1 to DEPTH) 
        <= max_slope_p & max_slope_p_pipe(1 to DEPTH-1);
      
      cfd_high_p_pipe(1 to DEPTH) <= cfd_high_p & cfd_high_p_pipe(1 to DEPTH-1);
      cfd_low_p_pipe(1 to DEPTH) <= cfd_low_p & cfd_low_p_pipe(1 to DEPTH-1);
        
      above_pipe <= above_cfd & above_pipe(1 to DEPTH-1);
      armed_pipe <= armed_cfd & armed_pipe(1 to DEPTH-1);
      
      rise_start_pipe(1 to DEPTH) 
        <= rise_start_cfd & rise_start_pipe(1 to DEPTH-1);
      
      rising_pipe(1 to DEPTH) <= rising_cfd & rising_pipe(1 to DEPTH-1);
        
      pulse_start_pipe(1 to DEPTH) 
        <= pulse_start_cfd & pulse_start_pipe(1 to DEPTH-1);
        
      will_cross_pipe 
        <= will_cross_cfd & will_cross_pipe(1 to DEPTH-1);
      will_arm_pipe 
        <= will_arm_cfd & will_arm_pipe(1 to DEPTH-1);
      
      cfd_error_pipe <= cfd_error_cfd & cfd_error_pipe(1 to DEPTH-1);
      cfd_overrun_pipe <= cfd_overrun_cfd & cfd_overrun_pipe(1 to DEPTH-1);
      first_rise_pipe <= first_rise_cfd & first_rise_pipe(1 to DEPTH-1);
      
      high_pipe <= cfd_high_threshold & high_pipe(1 to DEPTH-1);
      low_pipe <= cfd_low_threshold & low_pipe(1 to DEPTH-1);
      
      
      -- pre calculate sizes 
      if (pulse_start_pipe(DEPTH-3)) then 
        m.reg(PRE) <= reg; 
        m.enabled(PRE) <= event_enable;
        m.dp_address(PRE) <= (others => '-');
        
        -- size is the size of the event part
        case reg.detection is
        when PEAK_DETECTION_D | AREA_DETECTION_D => 
          m.size(PRE) <= (0 => '1', others => '0');
          
        when PULSE_DETECTION_D => 
          m.size(PRE) <= ('0' & reg.max_peaks) + 3; 
        when TRACE_DETECTION_D => 
          case reg.trace_type is
            when SINGLE_TRACE_D =>
              m.size(PRE) <= ('0' & reg.max_peaks) + 3; 
            when AVERAGE_TRACE_D =>
              m.size(PRE) <= to_unsigned(2,PEAK_COUNT_BITS+1); 
            when DOT_PRODUCT_D | DOT_PRODUCT_TRACE_D =>
              m.size(PRE) <= ('0' & reg.max_peaks) + 4; 
              m.dp_address(PRE) <= ('0' & reg.max_peaks) + 3; 
          end case;
        end case;
      end if;
          
      if (m.pulse_start(PRE2)) then 
        -- size2 is 2*size of event part
        m.size2(PRE) <= resize(m.size(PRE) & '0',ADDRESS_BITS+1); 
          
        case reg.detection is
        when PEAK_DETECTION_D | AREA_DETECTION_D | PULSE_DETECTION_D => 
          m.frame_length(PRE) <= resize(m.size(PRE),ADDRESS_BITS+1); 
          
        when TRACE_DETECTION_D => 

          case reg.trace_type is
            
            when SINGLE_TRACE_D | AVERAGE_TRACE_D | DOT_PRODUCT_TRACE_D =>
              m.frame_length(PRE) <= resize(
                                    reg.trace_length,ADDRESS_BITS+1
                                  )+m.size(PRE); 
                                  
              m.size2(PRE) <= resize(
                               reg.trace_length,ADDRESS_BITS+1
                             )+(m.size(PRE) & '0'); 
                                  
              
            when DOT_PRODUCT_D =>
              m.frame_length(PRE) <= resize(m.size(PRE),ADDRESS_BITS+1);
              
          end case;
        end case;
          
        --area_threshold <= signed('0' & registers.area_threshold);
        --pre_last_peak_address <= ('0' & registers.max_peaks)+2;

        m.rise_number <= (others => '0');
        rise_number_n <= (0 => '1',others => '0');
      end if;  
      
      if m.pulse_start(PRE) then 
        m.reg(NOW) <= m.reg(PRE);
        m.size(NOW) <= m.size(PRE);
        m.size2(NOW) <= m.size2(PRE);
        m.dp_address(NOW) <= m.dp_address(PRE);
        m.frame_length(NOW) <= m.frame_length(PRE);
        m.enabled(NOW) <= m.enabled(PRE);
        
        m.last_peak_address <= ('0' & reg.max_peaks)+2;
        
        rise_number_n <= (0 => '1',others => '0');
        m.last_rise <= reg.max_peaks=0;
        m.has_rise <= FALSE;
        
        m.rise_address <= (1 => '1', others => '0'); -- start at 2
        rise_address_n <= (1 downto 0 => '1', others => '0');
      end if;  
      
      if min_pipe(DEPTH-3) then
        m.minima(PRE2) <= f_pipe(DEPTH-3);
      end if;
      m.minima(PRE) <= m.minima(PRE2);
      m.minima(NOW) <= m.minima(PRE);
      
      if min_pipe(PRE) then
        if m.rise_number=1 then
          m.rise1 <= TRUE;  
        end if;
        if m.rise_number=2 then
          m.rise2 <= TRUE;  
        end if;
        if first_rise_pipe(DEPTH-1) then
          m.rise0 <= TRUE;  
        end if;
      end if;
      
      if m.rise_start(PRE) then
        m.valid_rise <= TRUE;
      end if;
      
      if m.max(NOW) then
        m.valid_rise <= FALSE;
        m.rise0 <= FALSE;
        m.rise1 <= FALSE;
        m.rise2 <= FALSE;
        
        if m.valid_rise then
          m.last_rise <= rise_number_n=m.reg(NOW).max_peaks; 
          if rise_number_n > m.reg(NOW).max_peaks then 
            m.rise_overflow <= TRUE;
          else
            m.rise_address <= rise_address_n;
            rise_address_n <= rise_address_n+1;
          end if;
          
          if rise_number_n(PEAK_COUNT_BITS)='0' then
            m.rise_number <= rise_number_n(PEAK_COUNT_BITS-1 downto 0);
            rise_number_n <= rise_number_n + 1;
            m.has_rise <= TRUE;
          else
            m.rise_number <= (others => '1');
          end if;
        end if;
      end if;
      
      case m.reg(NOW).timing is
      -- if pulse threshold is used for timing secondary peaks use cfd_low
      when PULSE_THRESH_TIMING_D =>
        -- no need to check if pulse stamped as dropping below threshold
        -- would be considered another pulse
        m.stamp_pulse(PRE) <= m.p_t_p(PRE2) and rising_pipe(DEPTH-2); 
             
        if first_rise_pipe(DEPTH-2) then
          
          m.stamp_rise(PRE) <= m.p_t_p(PRE2) and rising_pipe(DEPTH-2);

          if m.p_t_p(PRE2) and rising_pipe(DEPTH-2) then
            m.rise_stamped(PRE) <= TRUE;
            m.pulse_stamped(PRE) <= TRUE;
          end if;

        else
          m.stamp_rise(PRE) 
            <= cfd_low_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) and
               not m.rise_stamped(PRE);

          if cfd_low_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) then
            m.rise_stamped(PRE) <= TRUE;
          end if;
        end if;
        
      when SLOPE_THRESH_TIMING_D =>
        m.stamp_pulse(PRE)
          <= m.s_t_p(PRE2) and first_rise_pipe(DEPTH-2) and 
             rising_pipe(DEPTH-2) and not m.pulse_stamped(PRE);
             
        if m.s_t_p(PRE2) and first_rise_pipe(DEPTH-2) and 
           rising_pipe(DEPTH-2) then
          m.pulse_stamped(PRE) <= TRUE;
        end if;
                           
        m.pre_stamp_rise 
          <= m.s_t_p(PRE2) and rising_pipe(DEPTH-2) and not m.rise_stamped(PRE);

        if m.s_t_p(PRE2) and rising_pipe(DEPTH-2) then
          m.rise_stamped(PRE) <= TRUE;
        end if;
          
      --this will not fire a pulse start ????
      when CFD_LOW_TIMING_D =>
        m.stamp_rise(PRE) 
          <= cfd_low_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) and
             not m.rise_stamped(PRE);

        if cfd_low_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) then
          m.rise_stamped(PRE) <= TRUE;
        end if;
                          
        m.stamp_pulse(PRE) 
          <= cfd_low_p_pipe(DEPTH-2) and first_rise_pipe(DEPTH-2) and 
             rising_pipe(DEPTH-2) and not m.pulse_stamped(PRE);
        
        if cfd_low_p_pipe(DEPTH-2) and first_rise_pipe(DEPTH-2) and 
           rising_pipe(DEPTH-2) then
          m.pulse_stamped(PRE) <= TRUE;
        end if;
          
      when MAX_SLOPE_TIMING_D =>
        m.stamp_pulse(PRE)
          <= max_slope_p_pipe(DEPTH-2) and first_rise_pipe(DEPTH-2) and 
             rising_pipe(DEPTH-2) and not m.pulse_stamped(PRE);

        if max_slope_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) and 
           first_rise_pipe(DEPTH-2) then
          m.pulse_stamped(PRE) <= TRUE;
        end if;
                           
        m.stamp_rise(PRE) 
          <= max_slope_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) and
             not m.rise_stamped(PRE);

        if max_slope_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) then
          m.rise_stamped(PRE) <= TRUE;
        end if;
      end case;
      
      if m.max(PRE) then --FIXME what if threshold crossing @ max
        m.rise_stamped(PRE) <= FALSE;
        m.rise_stamped(NOW) <= m.rise_stamped(PRE);
      end if;
      
      if m.max(NOW) then --FIXME what if threshold crossing @ max
        m.rise_stamped(NOW) <= FALSE;
      end if;
      
      if m.p_t_n(PRE) then
        m.pulse_stamped(PRE) <= FALSE;
        m.pulse_stamped(NOW) <= m.pulse_stamped(PRE);
      end if;
      
      m.stamp_rise(NOW) <= m.stamp_rise(PRE);
      m.stamp_pulse(NOW) <= m.stamp_pulse(PRE);
      
      --time counters
      --pulse_time=0 each minima below pulse_threshold
      --pulse_length=0 each positive pulse_threshold crossing 
      --rise_time=0 each stamp_rise NOTE implies rise is valid
     
      --FIXME the pipelining is overkill
      if first_rise_pipe(DEPTH-2) and min_pipe(DEPTH-2) then 
        m.pulse_time(PRE) <= (others => '0');
        pre_pulse_time_n <= (0 => '1', others => '0'); 
      elsif pre_pulse_time_n(16)='1' then
        m.pulse_time(PRE) <= (others => '1');
      else
        pre_pulse_time_n <= pre_pulse_time_n + 1;
        m.pulse_time(PRE) <= pre_pulse_time_n(15 downto 0);
      end if;
      m.pulse_time(NOW) <= m.pulse_time(PRE);
      
      if m.stamp_rise(PRE2) then  
        m.rise_time(PRE) <= (others => '0');
        rise_time_n <= (0 => '1', others => '0');
      elsif rise_time_n(16)='1' then
        m.rise_time(PRE) <= (others => '1');
      else
        rise_time_n <= rise_time_n + 1;
        m.rise_time(PRE) <= rise_time_n(15 downto 0);
      end if;
      m.rise_time(NOW) <= m.rise_time(PRE);
      
      if m.p_t_p(PRE2) then
        m.pulse_length(PRE) <= (others => '0');
        pulse_length_n <= (0 => '1', others => '0');
      elsif pulse_length_n(16)='1' then
        m.pulse_length(PRE) <= (others => '1');
      else
        pulse_length_n <= pulse_length_n + 1;
        m.pulse_length(PRE) <= pulse_length_n(15 downto 0);
      end if;
    
      m.height_valid(PRE) <= FALSE;
      case m.reg(NOW).height is
      when PEAK_HEIGHT_D =>
        if m.reg(NOW).cfd_rel2min then
          m.height(PRE) <= f_pipe(DEPTH-2)-m.minima(PRE2); 
        else
          m.height(PRE) <= f_pipe(DEPTH-2); 
        end if;
        if max_pipe(DEPTH-2) and rising_pipe(DEPTH-2) then
          m.height_valid(PRE) <= TRUE;
        end if;
      when CFD_HEIGHT_D =>
        if m.reg(NOW).cfd_rel2min then
          m.height(PRE) <= high_pipe(DEPTH-2)-low_pipe(DEPTH-2); 
        else
          m.height(PRE) <= high_pipe(DEPTH-2); 
        end if;
        if cfd_high_p_pipe(DEPTH-2) and rising_pipe(DEPTH-2) then
          m.height_valid(PRE) <= TRUE;
        end if;
      when SLOPE_INTEGRAL_D =>
        m.height(PRE) <= resize(slope_area,16); --FIXME scale? and no pre so broken
        if max_pipe(DEPTH-2) and rising_pipe(DEPTH-2) then
          m.height_valid(PRE) <= TRUE;
        end if;
      when SLOPE_MAX_D => 
        m.height(PRE) <= s_pipe(DEPTH-2); 
        if max_slope_p_pipe(DEPTH-1) and rising_pipe(DEPTH-1) then
          m.height_valid(PRE) <= TRUE;
        end if;
      end case;
      
--      end if;
      
      --FIXME is rising needed?
      m.rise_stop(PRE) <= max_pipe(DEPTH-2) and rising_pipe(DEPTH-2);
      m.rise_stop(NOW) <= m.rise_stop(PRE);
      
    end if;
  end if;
end process pulseMeas;

m.rise_start <= rise_start_pipe(DEPTH-1 to DEPTH);
m.pulse_start <= pulse_start_pipe(DEPTH-1 to DEPTH);

m.valid_rise <= rising_pipe(DEPTH);
m.last_rise <= last_peak;

m.rise_address <= peak_address;
m.last_peak_address <= last_peak_address;
m.dp_address <= dp_address;

m.pre_pulse_start <= pre_pulse_start;
--m.pulse_time <= pulse_time;
m.stamp_peak <= stamp_rise;
m.stamp_pulse <= stamp_pulse;
m.pre_stamp_rise <= pre_stamp_peak;
m.pre_stamp_pulse <= pre_stamp_pulse;
--m.time_offset <= time_offset;
m.peak_stamped <= rise_timestamped;
m.pulse_stamped <= pulse_timestamped;
m.pulse_length <= pulse_length;

m.height <= height;
m.height_valid <= height_valid;
--m.rise_time <= rise_time;
m.min_value <= minima;

m.pre_eflags <= flags;
m.pre_eflags <= pre_flags;
m.size <= size;
m.pre_size <= pre_size;
m.pre_frame_length <= pre_frame_length;
m.pre_size2 <= pre_size2;

--m.pre2_size <= pre2_size;
m.timing_threshold <= resize(timing_thresh_out,16);
--m.height_threshold <= height_thresh_out;
m.cfd_high <= cfd_high_p_pipe(DEPTH);
m.cfd_high_threshold <= high_pipe(DEPTH);
m.cfd_low <= cfd_low_pos_pipe(DEPTH);
m.max_slope <= max_slope_pipe(DEPTH);
m.cfd_error <= cfd_error_pipe(DEPTH);
m.cfd_valid <= cfd_overrun_pipe(DEPTH);

m.filtered.sample <= f_pipe(DEPTH);
m.filtered.pos_0xing <= f_0_p_pipe(DEPTH);
m.filtered.neg_0xing <= f_0_n_pipe(DEPTH);
m.filtered.zero_xing <= filtered_zero_xing;
m.filtered.area <= filtered_area;
m.filtered.extrema <= f_extrema;
m.pulse_threshold_pos <= pulse_t_pos_pipe(DEPTH);
m.pulse_threshold_neg <= pulse_t_neg_pipe(DEPTH);
m.pre_pulse_threshold_neg <= pulse_t_neg_pipe(DEPTH-1);
--m.pulse_length <= pulse_length;
m.above_pulse_threshold <= above_pipe(DEPTH);
m.pulse_area <= pulse_area;
m.above_area_threshold <= above_area_threshold;
m.will_go_above <= will_cross_pipe(DEPTH);

m.slope.sample <= s_pipe(DEPTH);
m.slope.pos_0xing <= min_pipe(DEPTH);
m.slope.neg_0xing <= max_pipe(DEPTH);
m.slope.zero_xing <= slope_zero_xing;
m.slope_threshold_pos <= s_t_p_pipe(DEPTH);
m.slope.area <= slope_area;
m.slope.extrema <= s_extrema;
m.armed <= armed_pipe(DEPTH);
m.will_arm <= will_arm_pipe(DEPTH);

end architecture RTL;
