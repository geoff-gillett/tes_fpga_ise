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
  CFD_DELAY:natural:=1026
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  registers:in capture_registers_t;
  
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  measurements:out measurements_t
);
end entity measure2;

architecture RTL of measure2 is

-- pipelines to sync signals
signal cfd_low,cfd_high,cfd_error_cfd:boolean;
signal slope_cfd,filtered_cfd:signed(WIDTH-1 downto 0);
signal m:measurements_t;

signal slope_pos_Txing,slope_neg_Txing:boolean;
signal pulse_pos_Txing,pulse_neg_Txing:boolean;
signal filtered_x:signed(WIDTH-1 downto 0);
signal slope_pos_0xing_cfd,slope_neg_0xing_cfd:boolean;
signal area_threshold_s:signed(AREA_WIDTH-1 downto 0);
signal pulse_time_n,pulse_length_n,rise_time_n:unsigned(16 downto 0);

constant DEPTH:integer:=13;
--type pipe is array (1 to DEPTH) of signed(WIDTH-1 downto 0);
signal cfd_low_p,cfd_high_p,max_slope_p:boolean_vector(1 to DEPTH);
signal slope_pos_Txing_p,slope_neg_Txing_p:boolean_vector(1 to DEPTH);
signal slope_pos_0xing_p,slope_neg_0xing_p:boolean_vector(1 to DEPTH);
signal pulse_pos_Txing_p,pulse_neg_Txing_p:boolean_vector(1 to DEPTH);
signal valid_peak_p:boolean_vector(1 to DEPTH);
signal a_pulse_thresh_p:boolean_vector(1 to DEPTH);

signal pulse_area:signed(AREA_WIDTH-1 downto 0);
signal first_peak:boolean;

signal constant_fraction:signed(WIDTH-1 downto 0);
signal slope_threshold:signed(WIDTH-1 downto 0);
signal pulse_threshold:signed(WIDTH-1 downto 0);
signal valid_peak,max_slope_cfd:boolean;
signal peak_count_n,peak_count:unsigned(PEAK_COUNT_BITS downto 0);
--new
signal cfd_low_threshold,cfd_high_threshold:signed(WIDTH-1 downto 0);
signal max_slope_threshold:signed(WIDTH-1 downto 0);
signal max_cfd,min_cfd:boolean;
signal will_go_above:boolean;
signal will_arm_cfd:boolean;
signal overrun_cfd:boolean;
signal armed_cfd:boolean;
signal slope_threshold_pos_cfd:boolean;
signal above_pulse_threshold:boolean;
signal pulse_threshold_pos_cfd:boolean;
signal pulse_threshold_neg_cfd:boolean;
signal cfd_low_pos_x : boolean;
signal cfd_low_neg_x : boolean;
signal cfd_high_pos_x : boolean;
signal cfd_high_neg_x : boolean;
signal slope_x:signed(WIDTH-1 downto 0);
signal max_slope_x : boolean;
signal max_x,min_x : boolean;

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
  will_go_above_pulse_threshold => will_go_above,
  will_arm => will_arm_cfd,
  overrun => overrun_cfd,
  slope_out => slope_cfd,
  slope_threshold_pos => slope_threshold_pos_cfd,
  armed => armed_cfd,
  above_pulse_threshold => above_pulse_threshold,
  filtered_out => filtered_cfd,
  pulse_threshold_pos => pulse_threshold_pos_cfd,
  pulse_threshold_neg => pulse_threshold_neg_cfd,
  cfd_error => cfd_error_cfd
);

--latecy 4
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
  xing => pulse_threshold_pos_cfd,
  sig => filtered_cfd,  
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
      m.rise_time <= (others => '0');
      m.pulse_time <= (others => '0');
      m.pulse_length <= (others => '0');
      peak_count <= (others => '0');
      m.eflags.peak_overflow <= FALSE;
      m.eflags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
      m.stamp_peak <= FALSE;
      m.stamp_pulse <= FALSE;
      m.height_valid <= FALSE;
      
      pulse_time_n <= (0 => '1',others => '0');
      pulse_length_n <= (0 => '1',others => '0');
      rise_time_n <= (0 => '1',others => '0');
      
      first_peak <= TRUE;
--      pulse_threshold_s <= (WIDTH-1 => '0', others => '1');
--      slope_threshold_s <= (WIDTH-1 => '0', others => '1');
--      area_threshold_s <= (AREA_WIDTH-1 => '0', others => '1');
      max_x <= FALSE;
      min_x <= FALSE;
      --pulse_threshold_pos_x <= pulse_threshold_pos_cfd;


    else
      max_x <= max_cfd;
      min_x <= min_cfd;
      
      max_slope_p <= max_slope_cfd & max_slope_p(1 to DEPTH-1);
      cfd_low_p <= cfd_low & cfd_low_p(1 to DEPTH-1);
      cfd_high_p <= cfd_high & cfd_high_p(1 to DEPTH-1);
      valid_peak_p <= valid_peak & valid_peak_p(1 to DEPTH-1);
      slope_pos_Txing_p <= slope_pos_Txing & slope_pos_Txing_p(1 to DEPTH-1);
      slope_neg_Txing_p <= slope_neg_Txing & slope_neg_Txing_p(1 to DEPTH-1);
      slope_pos_0xing_p <= slope_pos_0xing_cfd & slope_pos_0xing_p(1 to DEPTH-1);
      slope_neg_0xing_p <= slope_neg_0xing_cfd & slope_neg_0xing_p(1 to DEPTH-1);
      pulse_pos_Txing_p <= pulse_pos_Txing & pulse_pos_Txing_p(1 to DEPTH-1);
      pulse_neg_Txing_p <= pulse_neg_Txing & pulse_neg_Txing_p(1 to DEPTH-1);
      
      
     
      peak_count_n <= peak_count + 1;
      
      -- minima at start of pulse  
      m.pulse_start <= min_cfd and not above_pulse_threshold;
      m.peak_start <= min_cfd;
     
      -- pulse start
      if min_cfd and not above_pulse_threshold then
         
        first_peak <= TRUE;
        peak_count <= (others => '0');
        peak_count_n <= (0 => '1',others => '0');
        m.last_peak <= FALSE;
        m.time_offset <= (others => '0');
        -- m.rise_time <= (others => '0');
        -- m.pulse_time <= (others => '0');
        -- m.pulse_length <= (others => '0');
        pulse_time_n <= (0 => '1',others => '0');
        pulse_length_n <= (0 => '1',others => '0');
        m.eflags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
        m.eflags.event_type.detection <= registers.detection;
        m.eflags.event_type.tick <= FALSE;
        m.eflags.height <= registers.height;
        m.eflags.new_window <= FALSE;
        m.eflags.peak_overflow <= FALSE;
        m.eflags.timing <= registers.timing;
        m.last_peak <= registers.max_peaks=0;
        m.max_peaks <= registers.max_peaks;
        --pulse_threshold_s <= signed('0' & registers.pulse_threshold);
        --slope_threshold_s <= signed('0' & registers.slope_threshold);
        --area_threshold_s <= signed('0' & registers.area_threshold);
        
        if registers.detection=PULSE_DETECTION_D or 
           registers.detection=TRACE_DETECTION_D then
          m.size <= resize(registers.max_peaks + 3, 16);
          m.peak_address <= (1 => '1', others => '0'); 
          m.last_address <= resize(
            ('0' & registers.max_peaks)+2,MEASUREMENT_FRAMER_ADDRESS_BITS
          );
        else
          m.peak_address <= (others => '0');
          m.size <= (0 => '1',others => '0');
        end if;
        
      else
        
        -- maxima
        if max_cfd then
          if peak_count > ('0' & m.max_peaks) then 
            m.eflags.peak_overflow <= TRUE;
          else
            m.last_peak <= peak_count=('0' & m.max_peaks);
            peak_count <= peak_count_n;
            peak_count_n <= peak_count_n + 1;
            if m.eflags.event_type.detection=PULSE_DETECTION_D or
               m.eflags.event_type.detection=TRACE_DETECTION_D then
              m.peak_address <= resize(  --FIXME  use peak_addr_n minimise bits
                peak_count_n+2,MEASUREMENT_FRAMER_ADDRESS_BITS
              );
            else
              m.peak_address <= (others => '0');
            end if;
            first_peak <= FALSE;
          end if;
        end if;
        
        if pulse_time_n(16)='1' then
          m.pulse_time <= (others => '1');
        else
          pulse_time_n <= pulse_time_n + 1;
          m.pulse_time <= pulse_time_n(15 downto 0);
        end if;
        
      end if;
      
      if rise_time_n(16)='1' then
        m.rise_time <= (others => '1');
      else
        rise_time_n <= rise_time_n + 1;
        m.rise_time <= rise_time_n(15 downto 0);
      end if;
      
      case m.eflags.timing is
      when PULSE_THRESH_TIMING_D =>
        m.stamp_pulse <= pulse_threshold_pos_cfd and first_peak;
        if first_peak then
          m.stamp_peak <= pulse_threshold_pos_cfd; -- 
        else
          m.stamp_peak <= cfd_low;
        end if;
        
        
        if pulse_threshold_pos_cfd then
          rise_time_n <= (0 => '1',others => '0');
          m.rise_time <= (others => '0');
        end if;

      when SLOPE_THRESH_TIMING_D =>
        m.stamp_peak <= slope_pos_Txing_p(DEPTH-1);
        m.stamp_pulse 
          <= slope_pos_Txing_p(DEPTH-1) and first_peak;
        if slope_pos_Txing_p(DEPTH-1) then
          rise_time_n <= (0 => '1',others => '0');
          m.rise_time <= (others => '0');
        end if;

      --this will not fire a pulse start
      when CFD_LOW_TIMING_D =>
        m.stamp_peak <= cfd_low_p(DEPTH-1);
        m.stamp_pulse <= cfd_low_p(DEPTH-1) and first_peak;
        if cfd_low_p(DEPTH-1) then
          rise_time_n <= (0 => '1',others => '0');
          m.rise_time <= (others => '0');
        end if;
        
      when SLOPE_MAX_TIMING_D =>
        m.stamp_peak <= max_slope_p(DEPTH-1);
        m.stamp_pulse <= max_slope_p(DEPTH-1) and first_peak;
        if max_slope_p(DEPTH-1) then
          rise_time_n <= (0 => '1',others => '0');
          m.rise_time <= (others => '0');
        end if;
      end case;
      
      if m.eflags.height=CFD_HEIGHT_D then
        m.height_valid <= cfd_high_p(DEPTH-1);
      else
        m.height_valid <= slope_neg_0xing_p(DEPTH-1);
      end if;
      
      if m.stamp_pulse then
        m.time_offset <= m.pulse_time;
      end if;

      m.pulse_area <= pulse_area;
      m.above_area_threshold <= pulse_area >= area_threshold_s;
      
      if slope_pos_Txing_p(DEPTH-1) then
        m.armed <= TRUE;
        m.has_armed <= TRUE;
      elsif slope_neg_0xing_p(DEPTH) then
        m.armed <= FALSE;
      end if;
      
      if slope_pos_Txing_p(DEPTH-1) then
        m.has_armed <= TRUE;
      elsif pulse_neg_Txing_p(DEPTH) then
        m.has_armed <= FALSE;
      end if;
      
      if pulse_pos_Txing_p(DEPTH-1) then
        m.pulse_length <= (others => '0');
      else
        if pulse_length_n(16)='1' then
          m.pulse_length <= (others => '1');
        else
          pulse_length_n <= pulse_length_n + 1;
          m.pulse_length <= pulse_length_n(15 downto 0);
        end if;
      end if;
      
    end if;
  end if;
end process pulseMeas;

m.valid_peak <= valid_peak_p(DEPTH);
m.cfd_high <= cfd_high_p(DEPTH);
m.cfd_low <= cfd_low_p(DEPTH);
m.max_slope <= max_slope_p(DEPTH);
m.eflags.peak_count <= peak_count(PEAK_COUNT_BITS-1 downto 0);
m.above_pulse_threshold <= a_pulse_thresh_p(DEPTH);
m.pulse_threshold_pos <= pulse_pos_Txing_p(DEPTH);
m.pulse_threshold_neg <= pulse_neg_Txing_p(DEPTH);
m.slope_threshold_pos <= slope_pos_Txing_p(DEPTH);
m.slope_threshold_neg <= slope_neg_Txing_p(DEPTH);

--latency 7
filteredMeas:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
	WIDTH_OUT => WIDTH_OUT,
	FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_cfd,
  threshold => (others => '0'),
  signal_out => m.filtered.sample,
  pos_xing => m.filtered.pos_0xing,
  neg_xing => m.filtered.neg_0xing,
  xing => m.filtered.zero_xing,
  area => m.filtered.area,
  extrema => m.filtered.extrema
);

slopeMeas:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
	WIDTH_OUT => WIDTH_OUT,
	FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_cfd,
  threshold => (others => '0'),
  signal_out => m.slope.sample,
  pos_xing => m.slope.pos_0xing,
  neg_xing => m.slope.neg_0xing,
  xing => m.slope.zero_xing,
  area => m.slope.area,
  extrema => m.slope.extrema
);

end architecture RTL;
