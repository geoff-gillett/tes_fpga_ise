library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

library dsp;
use dsp.types.all;

library streamlib;
use streamlib.types.all;

use work.types.all;
use work.registers.all;
use work.events.all;
use work.measurements.all;

entity measure is
generic(
  CF_WIDTH:natural:=18;
  CF_FRAC:natural:=17;
  WIDTH:natural:=16;
  FRAC:natural:=3;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  RAW_DELAY:natural:=1026;
  TOWARDS_INF:boolean:=TRUE;
  AREA_ABOVE:boolean:=TRUE
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
end entity measure;

architecture RTL of measure is

-- pipelines to sync signals
signal cfd_error_cfd:boolean;
signal s_cfd,f_cfd:signed(WIDTH-1 downto 0);
signal raw_d:std_logic_vector(WIDTH-1 downto 0);

signal m:measurements_t;

signal pulse_time_n,pulse_length_n,rise_time_n:unsigned(16 downto 0);

--------------------------------------------------------------------------------
-- pipeline signals
--------------------------------------------------------------------------------
--accumulate and round latency the true latency of area_acc is 5
--but want area since the previous crossing which value is 1 clk before xing
constant ALAT:natural:=4; 
constant ELAT:natural:=1; --extrema latency
constant DEPTH:integer:=ALAT; --main pipeline depth

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
signal rise_start_pipe,first_rise_pipe,pulse_start_pipe:
       boolean_vector(1 to DEPTH):=(others => FALSE);
--------------------------------------------------------------------------------

--signal p_threshold:signed(WIDTH-1 downto 0);
signal valid_rise:boolean;
signal rise_number_n,rise_number_n2:unsigned(PEAK_COUNT_BITS downto 0);
signal cfd_low_cfd,cfd_high_cfd:signed(WIDTH-1 downto 0);
signal max_slope_cfd:signed(WIDTH-1 downto 0);
signal max_cfd,min_cfd:boolean;
signal will_cross_cfd:boolean;
signal will_arm_cfd:boolean;
signal armed_cfd:boolean;
signal s_t_p_cfd:boolean;
signal above_cfd:boolean;
signal p_t_p_cfd:boolean;
signal p_t_n_cfd:boolean;
signal rise_address_n:unsigned(PEAK_COUNT_BITS downto 0);
--signal pre_stamp_peak,pre_stamp_pulse:boolean;

type pipe is array(1 to DEPTH) of signed(WIDTH-1 downto 0);
--signal high_pipe,low_pipe,filtered_long_pipe,slope_long_pipe:long_pipe;
signal f_pipe,s_pipe,high_pipe,low_pipe,max_slope_pipe:pipe;
signal f_0_x_cfd:boolean;
signal f_0_p_pipe,p_t_p_pipe:boolean_vector(1 to DEPTH);
signal f_0_n_pipe,p_t_n_pipe:boolean_vector(1 to DEPTH);
-- TRUE during a valid rise
signal valid_rise_pipe,cfd_valid_pipe:boolean_vector(1 to DEPTH);
--rise_timer start no valid check or stamped check
signal stamp_rise_pre2:boolean;

signal p_t_x_cfd:boolean;
signal f_0_n_cfd:boolean;
signal f_0_p_cfd:boolean;
signal rise_start_cfd:boolean;
signal pulse_start_cfd:boolean;
signal cfd_low_p:boolean;
signal cfd_high_p:boolean;
signal max_slope_p:boolean;
signal s_0_x_cfd:boolean;
signal cfd_overrun_cfd:boolean;
signal first_rise_cfd:boolean;
signal rise_valid_cfd:boolean;
signal cfd_valid_cfd:boolean;
signal reg:capture_registers_t;

signal f_trace,s_trace,raw_trace,raw_sig:std_logic_vector(WIDTH-1 downto 0);

constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of valid_rise:signal is DEBUG;
signal cfd_low_armed,cfd_high_armed,max_slope_armed:boolean;

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
rawTrace:entity work.dynamic_RAM_delay2
generic map(
  DEPTH     => 2**10,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => raw_d,
  data_out => raw_sig,
  delay => to_integer(m.reg(PRE).trace_pre),
  delayed => raw_trace
);
m.raw <= signed(raw_sig);
m.raw_trace <= signed(raw_trace);

CFD:entity work.CFD
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  DELAY => RAW_DELAY-202 --203 --210
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
  s_0_x => s_0_x_cfd,
  s_t_p => s_t_p_cfd,
  p_t_p => p_t_p_cfd,
  p_t_n => p_t_n_cfd,
  p_t_x => p_t_x_cfd,
  f_0_n => f_0_n_cfd, 
  f_0_p => f_0_p_cfd, 
  f_0_x => f_0_x_cfd,
  first_rise => first_rise_cfd, 
  armed => armed_cfd,
  above => above_cfd,
  
  rise_start => rise_start_cfd,
  valid_rise => rise_valid_cfd,
  pulse_start => pulse_start_cfd,
  
  cfd_low => cfd_low_cfd,
  cfd_high => cfd_high_cfd,
  max_slope => max_slope_cfd,
  will_cross => will_cross_cfd,
  will_arm => will_arm_cfd,
  
--  cfd_low_p => cfd_low_p,
--  cfd_high_p => cfd_high_p,
--  max_slope_p => max_slope_p,
  
  cfd_valid => cfd_valid_cfd,
  cfd_error => cfd_error_cfd,
  cfd_overrun => cfd_overrun_cfd
);

-- register changes at DEPTH-ALAT should not have significant 
-- effect on functionality, they will lead to a error in a single area 
-- measurement at the threshold register change.
pulseArea:entity dsp.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  AREA_ABOVE => AREA_ABOVE,
  TOWARDS_INF => TOWARDS_INF
)
port map(
  clk => clk,
  reset => reset,
  xing => p_t_x_cfd,
  sig => f_cfd,  
  signal_threshold => signed('0' & reg.pulse_threshold),
  area_threshold => signed('0' & reg.area_threshold),
  area => m.pulse_area, -- effectively lat 4
  above_area_threshold => m.above_area 
);

filteredArea:entity dsp.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  AREA_ABOVE => AREA_ABOVE,
  TOWARDS_INF => TOWARDS_INF
)
port map(
  clk => clk,
  reset => reset,
  xing => f_0_x_cfd,
  sig => f_cfd,
  signal_threshold => (others => '0'),
  area_threshold => (others => '0'),
  above_area_threshold => open,
  area => m.f_area --effectively lat 4
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

slopeArea:entity dsp.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  AREA_ABOVE => AREA_ABOVE,
  TOWARDS_INF => TOWARDS_INF
)
port map(
  clk => clk,
  reset => reset,
  xing => s_0_x_cfd,
  sig => s_cfd,
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

--------------------------------------------------------------------------------
--level detectors for calculated thresholds 
--true first time in rise that sig >= thresh 
--------------------------------------------------------------------------------
cfdLowp:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      cfd_low_p <= FALSE;
      cfd_low_armed <= FALSE;
    else
      if min_cfd then
        cfd_low_armed <= TRUE;
      end if;
      if f_cfd >= cfd_low_cfd then
        cfd_low_p <= (cfd_low_armed or min_cfd) and cfd_valid_cfd;
        cfd_low_armed <= FALSE;
      end if;
    end if;
  end if;
end process cfdLowp;

cfdHighp:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      cfd_high_p <= FALSE;
      cfd_high_armed <= FALSE;
    else
      if min_cfd then
        cfd_high_armed <= TRUE;
      end if;
      if f_cfd >= cfd_high_cfd then
        cfd_high_p <= (cfd_high_armed or min_cfd) and cfd_valid_cfd;
        cfd_high_armed <= FALSE;
      end if;
    end if;
  end if;
end process cfdHighp;

maxSlope:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      max_slope_p <= FALSE;
      max_slope_armed <= FALSE;
    else
      if min_cfd then
        max_slope_armed <= TRUE;
      end if;
      if f_cfd >= max_slope_cfd then
        max_slope_p <= (max_slope_armed or min_cfd) and cfd_valid_cfd;
        max_slope_armed <= FALSE;
      end if;
    end if;
  end if;
end process maxSlope;

-- expose some pipelines for use by down stream entities.
m.pulse_start <= pulse_start_pipe(DEPTH-3 to DEPTH);
m.rise_start <= rise_start_pipe(DEPTH-1 to DEPTH);

m.f <= f_pipe(DEPTH);
m.f_0_p <= f_0_p_pipe(DEPTH);
m.f_0_n <= f_0_n_pipe(DEPTH);
m.p_t_p <= p_t_p_pipe(DEPTH-2 to DEPTH);
m.p_t_n <= p_t_n_pipe(DEPTH-2 to DEPTH);

m.s <= s_pipe(DEPTH);
m.min <= min_pipe(DEPTH-2 to DEPTH);
m.max <= max_pipe(DEPTH-2 to DEPTH);

m.valid_rise <= valid_rise_pipe(DEPTH);

m.armed <= armed_pipe(DEPTH);
m.will_arm <= will_arm_pipe(DEPTH);
m.above <= above_pipe(DEPTH);
m.will_cross <= will_cross_pipe(DEPTH);

m.cfd_high <= high_pipe(DEPTH);
m.cfd_low <= low_pipe(DEPTH);
m.max_slope <= max_slope_pipe(DEPTH);
m.cfd_high_p <= cfd_high_p_pipe(DEPTH);
m.cfd_low_p <= cfd_low_p_pipe(DEPTH);
m.max_slope_p <= max_slope_p_pipe(DEPTH);
m.cfd_valid <= cfd_valid_pipe(DEPTH);

pulseMeas:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then 
      null;
    else
      --f and s zero crossings
      m.f_0 <= f_0_p_pipe(DEPTH-1) or f_0_n_pipe(DEPTH-1);
      m.s_0 <= min_pipe(DEPTH-1) or max_pipe(DEPTH-1);
      
      
      f_pipe <= f_cfd & f_pipe(1 to DEPTH-1);
      s_pipe <= s_cfd & s_pipe(1 to DEPTH-1);
      f_0_p_pipe <= f_0_p_cfd & f_0_p_pipe(1 to DEPTH-1);
      f_0_n_pipe <= f_0_n_cfd & f_0_n_pipe(1 to DEPTH-1);
      min_pipe <= min_cfd & min_pipe(1 to DEPTH-1);
      max_pipe <= max_cfd & max_pipe(1 to DEPTH-1);
      p_t_p_pipe <= p_t_p_cfd & p_t_p_pipe(1 to DEPTH-1);
      p_t_n_pipe <= p_t_n_cfd & p_t_n_pipe(1 to DEPTH-1);
      s_t_p_pipe <= s_t_p_cfd & s_t_p_pipe(1 to DEPTH-1);
      
      high_pipe <= cfd_high_cfd & high_pipe(1 to DEPTH-1);
      low_pipe <= cfd_low_cfd & low_pipe(1 to DEPTH-1);
      max_slope_pipe <= max_slope_cfd & max_slope_pipe(1 to DEPTH-1);
      
      max_slope_p_pipe(2 to DEPTH) 
        <= max_slope_p & max_slope_p_pipe(2 to DEPTH-1);
      cfd_high_p_pipe(2 to DEPTH) 
        <= cfd_high_p & cfd_high_p_pipe(2 to DEPTH-1);
      cfd_low_p_pipe(2 to DEPTH) 
        <= cfd_low_p & cfd_low_p_pipe(2 to DEPTH-1);
        
      above_pipe <= above_cfd & above_pipe(1 to DEPTH-1);
      armed_pipe <= armed_cfd & armed_pipe(1 to DEPTH-1);
      will_cross_pipe <= will_cross_cfd & will_cross_pipe(1 to DEPTH-1);
      will_arm_pipe <= will_arm_cfd & will_arm_pipe(1 to DEPTH-1);
      
      rise_start_pipe <= rise_start_cfd & rise_start_pipe(1 to DEPTH-1);
      valid_rise_pipe <= rise_valid_cfd & valid_rise_pipe(1 to DEPTH-1);
      pulse_start_pipe <= pulse_start_cfd & pulse_start_pipe(1 to DEPTH-1);
        
      cfd_valid_pipe <= cfd_valid_cfd & cfd_valid_pipe(1 to DEPTH-1);
      cfd_error_pipe <= cfd_error_cfd & cfd_error_pipe(1 to DEPTH-1);
      cfd_overrun_pipe <= cfd_overrun_cfd & cfd_overrun_pipe(1 to DEPTH-1);
      first_rise_pipe <= first_rise_cfd & first_rise_pipe(1 to DEPTH-1);
      
      if pulse_start_cfd then 
        m.reg(PRE) <= reg; 
        m.enabled(PRE) <= event_enable;
        m.has_pulse(PRE) <= reg.detection=PULSE_DETECTION_D or (
                              reg.detection=TRACE_DETECTION_D and (
                                reg.trace_type=SINGLE_TRACE_D or 
                                reg.trace_type=DOT_PRODUCT_TRACE_D
                              )
                            );
        m.has_trace(PRE) <= m.reg(PRE).detection=TRACE_DETECTION_D and (
                              m.reg(PRE).trace_type=SINGLE_TRACE_D or 
                              m.reg(PRE).trace_type=DOT_PRODUCT_TRACE_D
                            );
      end if;
          
      if m.pulse_start(PRE2) then
        rise_number_n2 <= (1 => '1', others => '0');
        rise_number_n <= (0 => '1', others => '0');
        m.rise_number <= (others => '0');
      end if;
          
      if m.pulse_start(PRE) then 
        m.reg(NOW) <= m.reg(PRE);
        m.enabled(NOW) <= m.enabled(PRE);
        m.has_pulse(NOW) <= m.has_pulse(PRE);
        m.has_trace(NOW) <= m.has_trace(PRE);
        
        
        m.last_peak_address <= reg.max_peaks+2;
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
      
      if m.min(PRE) then
        if rise_number_n=1 then
          m.rise1 <= TRUE;  
        end if;
        if rise_number_n=2 then
          m.rise2 <= TRUE;  
        end if;
        if first_rise_pipe(DEPTH-1) then
          m.rise0 <= TRUE;  
        end if;
      end if;
      
      if m.max(NOW) then
        m.rise0 <= FALSE;
        m.rise1 <= FALSE;
        m.rise2 <= FALSE;
        m.has_rise <= TRUE;
        if rise_number_n2(PEAK_COUNT_BITS)='0' then
          rise_number_n <= rise_number_n2;
          rise_number_n2 <= rise_number_n2 + 1;
        else
          rise_number_n <= (others => '1');
        end if;
        m.rise_number <= rise_number_n(PEAK_COUNT_BITS-1 downto 0);
        if m.valid_rise then
          m.last_rise <= rise_number_n >= m.reg(NOW).max_peaks; 
          if rise_number_n > m.reg(NOW).max_peaks then 
            m.rise_overflow <= m.has_rise;
          end if;
          if not m.last_rise then
            m.rise_address <= rise_address_n(PEAK_COUNT_BITS-1 downto 0);
            rise_address_n <= rise_address_n + 1;
          end if;
        end if;
      end if;
      
      case m.reg(NOW).timing is
      -- if pulse threshold is used for timing secondary peaks use cfd_low
      when PULSE_THRESH_TIMING_D =>
        if first_rise_pipe(DEPTH-3) then
          stamp_rise_pre2 <= p_t_p_pipe(DEPTH-3);
        else
          stamp_rise_pre2 <= cfd_low_p_pipe(DEPTH-3);
        end if;
        
      when SLOPE_THRESH_TIMING_D =>
        stamp_rise_pre2 <= s_t_p_pipe(DEPTH-3);
        
      when CFD_LOW_TIMING_D =>
        stamp_rise_pre2 <= cfd_low_p_pipe(DEPTH-3);

      when MAX_SLOPE_TIMING_D =>
        stamp_rise_pre2 <= max_slope_p_pipe(DEPTH-3);
        
      end case;
      
      -- rise and pulse stamping
      m.stamp_rise(PRE) <= FALSE;
      m.stamp_pulse(PRE) <= FALSE;
      if stamp_rise_pre2 then
        if first_rise_pipe(DEPTH-2) and valid_rise_pipe(DEPTH-2) then
          m.stamp_pulse(PRE) <= not m.pulse_stamped(PRE);
          m.pulse_stamped(PRE) <= TRUE;
        end if;
        
        if valid_rise_pipe(DEPTH-2) then
          m.stamp_rise(PRE) <= not m.rise_stamped(PRE);
          m.rise_stamped(PRE) <= TRUE;
        end if;
      end if;
      m.stamp_pulse(NOW) <= m.stamp_pulse(PRE);
      m.stamp_rise(NOW) <= m.stamp_rise(PRE);
      
      if m.max(PRE) then 
        m.rise_stamped(PRE) <= FALSE;
        m.rise_stamped(NOW) <= m.rise_stamped(PRE);
      end if;
      
      if m.max(NOW) then --FIXME what if threshold crossing @ max
        m.rise_stamped(NOW) <= m.stamp_rise(PRE);
      end if;
      
      if m.stamp_pulse(PRE) then
        m.pulse_stamped(PRE) <= stamp_rise_pre2 and first_rise_pipe(DEPTH-1) and
                                valid_rise_pipe(DEPTH-1);
        m.pulse_stamped(NOW) <= m.pulse_stamped(PRE);
      end if;
      
      if m.p_t_n(NOW) then
        m.pulse_stamped(NOW) <= FALSE;
      end if;
      
      if m.stamp_rise(PRE) then
        m.rise_timestamp <= m.pulse_timer(PRE);
      end if;
      if m.stamp_pulse(PRE) then
        if m.has_trace(PRE) then
          m.time_offset <= resize(m.reg(PRE).trace_pre,CHUNK_DATABITS);
          m.pulse_timer(PRE) <= resize(m.reg(PRE).trace_pre,CHUNK_DATABITS);
          pulse_time_n <= resize(m.reg(PRE).trace_pre+1,CHUNK_DATABITS+1);
        else
          m.time_offset <= m.pulse_timer(PRE);
        end if;
      end if;
      
      m.stamp_pulse(NOW) <= m.stamp_pulse(PRE);
      m.stamp_rise(NOW) <= m.stamp_rise(PRE);
      
      --time counters
      --pulse_time=0 or trace_pre @ each minima below pulse_threshold
      --  initialised to trace_pre if has_trace
      --pulse_length=0 each positive pulse_threshold crossing 
      --rise_time=0 each stamp_rise NOTE implies rise is valid
     
      if first_rise_pipe(DEPTH-2) and m.min(PRE2) then 
        -- NOTE has_trace(PRE) is at same latency as reg(PRE)
        if not m.has_trace(PRE) then  
          m.pulse_timer(PRE) <= (0 => '0', others => '0');
          pulse_time_n <= (0 => '1', others => '0'); 
        else
        end if;
      elsif pulse_time_n(16)='1' then
        m.pulse_timer(PRE) <= (others => '1');
      else
        pulse_time_n <= pulse_time_n + 1;
        m.pulse_timer(PRE) <= pulse_time_n(15 downto 0);
      end if;
      m.pulse_timer(NOW) <= m.pulse_timer(PRE);
      
      if stamp_rise_pre2 then  
        m.rise_timer(PRE) <= (0 => '0', others => '0');
        rise_time_n <= (0 => '1', others => '0');
      elsif rise_time_n(16)='1' then
        m.rise_timer(PRE) <= (others => '1');
      else
        rise_time_n <= rise_time_n + 1;
        m.rise_timer(PRE) <= rise_time_n(15 downto 0);
      end if;
      m.rise_timer(NOW) <= m.rise_timer(PRE);
      
      if m.p_t_p(PRE2) then
        m.pulse_length_timer(PRE) <= (0 => '0', others => '0');
        pulse_length_n <= (0 => '1', others => '0');
      elsif pulse_length_n(16)='1' then
        m.pulse_length_timer(PRE) <= (others => '1');
      else
        pulse_length_n <= pulse_length_n + 1;
        m.pulse_length_timer(PRE) <= pulse_length_n(15 downto 0);
      end if;
      m.pulse_length_timer(NOW) <= m.pulse_length_timer(PRE);
      
      if m.p_t_n(PRE) then
        m.pulse_length <= m.pulse_length_timer(PRE);
      end if;
      
      m.height_valid(PRE) <= FALSE;
      case m.reg(NOW).height is
      when PEAK_HEIGHT_D =>
        if m.reg(NOW).cfd_rel2min then
          m.height(PRE) <= f_pipe(DEPTH-2)-m.minima(PRE2); 
        else
          m.height(PRE) <= f_pipe(DEPTH-2); 
        end if;
        m.height_valid(PRE) <= max_pipe(DEPTH-2) and valid_rise_pipe(DEPTH-2);
      when CFD_HIGH_D =>
        if m.reg(NOW).cfd_rel2min then
          m.height(PRE) <= high_pipe(DEPTH-2)-m.minima(PRE2); 
        else
          m.height(PRE) <= high_pipe(DEPTH-2); 
        end if;
        m.height_valid(PRE) 
          <= cfd_high_p_pipe(DEPTH-2) and valid_rise_pipe(DEPTH-2);
      when CFD_HEIGHT_D =>
        m.height(PRE) <= high_pipe(DEPTH-2)-low_pipe(DEPTH-2); 
        m.height_valid(PRE) 
          <= cfd_high_p_pipe(DEPTH-2) and valid_rise_pipe(DEPTH-2);
      when MAX_SLOPE_D => 
        m.height(PRE) <= max_slope_pipe(DEPTH-2); 
        m.height_valid(PRE) 
          <= max_slope_p_pipe(DEPTH-2) and valid_rise_pipe(DEPTH-2);
      end case;
      m.height(NOW) <= m.height(PRE);
      m.height_valid(NOW) <= m.height_valid(PRE);
      if m.height_valid(PRE) then
        m.peak_height <= m.height(PRE);
      end if;
      
      m.rise_stop(PRE) <= max_pipe(DEPTH-2) and valid_rise_pipe(DEPTH-2);
      m.rise_stop(NOW) <= m.rise_stop(PRE);
      
    end if;
  end if;
end process pulseMeas;

fTrace:entity work.dynamic_RAM_delay2
generic map(
  DEPTH     => 2**10,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => std_logic_vector(f_cfd),
  data_out => open,
  delay => to_integer(m.reg(PRE).trace_pre),
  delayed => f_trace
);
m.f_trace <= signed(f_trace);
sTrace:entity work.dynamic_RAM_delay2
generic map(
  DEPTH     => 2**10,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => std_logic_vector(s_cfd),
  data_out => open,
  delay => to_integer(m.reg(PRE).trace_pre),
  delayed => s_trace
);
m.s_trace <= signed(s_trace);

end architecture RTL;
