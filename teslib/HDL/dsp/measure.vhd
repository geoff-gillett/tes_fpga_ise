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

entity measure is
generic(
  CHANNEL:natural:=0;
  WIDTH:natural:=18;
  FRAC:natural:=3;
  WIDTH_OUT:natural:=16;
  FRAC_OUT:natural:=1;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  CFD_DELAY:natural:=1027
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  
  registers:in capture_registers_t;
  
  baseline:in signed(WIDTH-1 downto 0);
  raw:in signed(WIDTH-1 downto 0);
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  measurements:out measurements_t
);
end entity measure;

architecture RTL of measure is

-- pipelines to sync signals
signal cfd_low,cfd_high,cfd_error:boolean;
signal slope_cfd,raw_cfd,filtered_cfd:signed(WIDTH-1 downto 0);
signal m:measurements_t;

signal slope_pos_Txing,slope_neg_Txing:boolean;
signal pulse_pos_Txing,pulse_neg_Txing:boolean;
signal slope_x,filtered_x:signed(WIDTH-1 downto 0);
signal filtered_reg,filtered_reg2,filtered_m:signed(WIDTH-1 downto 0);
signal slope_pos_0xing_cfd,slope_neg_0xing_cfd:boolean;
signal slope_threshold_s,pulse_threshold_s:signed(WIDTH-1 downto 0);
signal area_threshold_s:signed(AREA_WIDTH-1 downto 0);
signal pulse_t_n,pulse_l_n,rise_t_n:unsigned(16 downto 0);

constant DEPTH:integer:=12;
type pipe is array (1 to DEPTH) of signed(WIDTH-1 downto 0);
signal raw_p:pipe;
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


constant DEBUG:string:="FALSE";
attribute MARK_DEBUG:string;
attribute MARK_DEBUG of peak_count:signal is DEBUG;

begin
measurements <= m;
constant_fraction <= signed('0' & registers.constant_fraction);
slope_threshold <= signed('0' & registers.slope_threshold);
pulse_threshold <= signed('0' & registers.pulse_threshold);

CFD:entity dsp.CFD_unit
generic map(
  WIDTH => WIDTH,
  CFD_DELAY => CFD_DELAY
)
port map(
  clk => clk,
  reset1 => reset1,
  raw => raw,
  slope => slope,
  filtered => filtered,
  constant_fraction => constant_fraction,
  slope_threshold => slope_threshold,
  pulse_threshold => pulse_threshold,
  low_rising => cfd_low,
  low_falling => open,
  high_rising => cfd_high,
  high_falling => open,
  max_slope => max_slope_cfd,
  cfd_error => cfd_error,
  raw_out => raw_cfd,
  slope_out => slope_cfd,
  filtered_out => filtered_cfd,
  max => slope_neg_0xing_cfd,
  min => slope_pos_0xing_cfd,
  valid_peak => valid_peak
);

slopeTxing:entity dsp.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => slope_cfd,
  threshold => slope_threshold_s,
  signal_out => slope_x,
  pos => slope_pos_Txing,
  neg => slope_neg_Txing
);

pulseTxing:entity dsp.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => filtered_cfd,
  threshold => pulse_threshold_s,
  signal_out => filtered_x,
  pos => pulse_pos_Txing,
  neg => pulse_neg_Txing
);

pulseArea:entity dsp.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset1,
  xing => pulse_pos_Txing_p(3),
  sig => filtered_m,  
  area => pulse_area
);

pulseMeas:process(clk)
begin
  if rising_edge(clk) then
    if reset1 = '1' then --FIXME are these resets needed
      m.armed <= FALSE;
      m.rise_time <= (others => '0');
      m.pulse_time <= (others => '0');
      m.pulse_length <= (others => '0');
      peak_count <= (others => '0');
      m.eflags.peak_overflow <= FALSE;
      m.eflags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
      m.stamp_peak <= FALSE;
      m.stamp_pulse <= FALSE;
      m.height_valid <= FALSE;
      
      pulse_t_n <= (0 => '1',others => '0');
      pulse_l_n <= (0 => '1',others => '0');
      rise_t_n <= (0 => '1',others => '0');
      
      first_peak <= TRUE;
      pulse_threshold_s <= (WIDTH-1 => '0', others => '1');
      slope_threshold_s <= (WIDTH-1 => '0', others => '1');
      area_threshold_s <= (AREA_WIDTH-1 => '0', others => '1');
    else
      
      raw_p <= raw_cfd & raw_p(1 to DEPTH-1);
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
      
      filtered_reg <= filtered_x;
      filtered_reg2 <= filtered_reg;
      filtered_m <= filtered_reg2;
      
      a_pulse_thresh_p 
        <= (filtered_x >= pulse_threshold_s) & a_pulse_thresh_p(1 to DEPTH-1);
     
      --peak_count_n <= peak_count + 1; --FIXME why here
      
      m.pulse_area <= pulse_area; 
      m.above_area_threshold <= pulse_area >= area_threshold_s;
      
      -- minima at start of pulse  
      m.pulse_start <= slope_pos_0xing_p(DEPTH-1) and 
                       not a_pulse_thresh_p(DEPTH-1);
      m.peak_start <= slope_pos_0xing_p(DEPTH-1);
      
      -- pulse start
      if slope_pos_0xing_p(DEPTH-1) and not a_pulse_thresh_p(DEPTH-1) then
         
        first_peak <= TRUE;
        peak_count <= (others => '0');
        peak_count_n <= (0 => '1',others => '0');
        m.last_peak <= FALSE;
        m.time_offset <= (others => '0');
        -- m.rise_time <= (others => '0');
        -- m.pulse_time <= (others => '0');
        -- m.pulse_length <= (others => '0');
        pulse_t_n <= (0 => '1',others => '0');
        pulse_l_n <= (0 => '1',others => '0');
        m.eflags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
        m.eflags.event_type.detection <= registers.detection;
        m.eflags.event_type.tick <= FALSE;
        m.eflags.height <= registers.height;
        m.eflags.new_window <= FALSE;
        m.eflags.peak_overflow <= FALSE;
        m.eflags.timing <= registers.timing;
        m.last_peak <= registers.max_peaks=0;
        m.max_peaks <= registers.max_peaks;
        pulse_threshold_s <= signed('0' & registers.pulse_threshold);
        slope_threshold_s <= signed('0' & registers.slope_threshold);
        area_threshold_s <= signed('0' & registers.area_threshold);
        
        if registers.detection=PULSE_DETECTION_D or 
           registers.detection=TRACE_DETECTION_D then
          m.size <= resize(registers.max_peaks + 3, 16);
          m.peak_address <= (1 => '1', others => '0'); 
          m.last_address <= resize(
            ('0' & registers.max_peaks)+2,MEASUREMENT_FRAMER_ADDRESS_BITS
          );
        else
          m.last_address  <= (others => '0');
          m.peak_address <= (others => '0');
          m.size <= (0 => '1',others => '0');
        end if;
        
      else
        
        -- maxima
        if slope_neg_0xing_p(DEPTH-1) then
          if peak_count > ('0' & m.max_peaks) then 
            m.eflags.peak_overflow <= TRUE;
          else
            m.last_peak <= peak_count_n=('0' & m.max_peaks);
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
        
        if pulse_t_n(16)='1' then
          m.pulse_time <= (others => '1');
        else
          pulse_t_n <= pulse_t_n + 1;
          m.pulse_time <= pulse_t_n(15 downto 0);
        end if;
        
      end if;
      
      if rise_t_n(16)='1' then
        m.rise_time <= (others => '1');
      else
        rise_t_n <= rise_t_n + 1;
        m.rise_time <= rise_t_n(15 downto 0);
      end if;
      
      case m.eflags.timing is
      when PULSE_THRESH_TIMING_D =>
        m.stamp_peak <= pulse_pos_Txing_p(DEPTH-4);
        m.stamp_pulse
          <= pulse_pos_Txing_p(DEPTH-4) and first_peak;
        if pulse_pos_Txing_p(DEPTH-4) then
          rise_t_n <= (0 => '1',others => '0');
          m.rise_time <= (others => '0');
        end if;

      when SLOPE_THRESH_TIMING_D =>
        m.stamp_peak <= slope_pos_Txing_p(DEPTH-5);
        m.stamp_pulse 
          <= slope_pos_Txing_p(DEPTH-5) and first_peak;
        if slope_pos_Txing_p(DEPTH-5) then
          rise_t_n <= (0 => '1',others => '0');
          m.rise_time <= (others => '0');
        end if;

      --this will not fire a pulse start
      when CFD_LOW_TIMING_D =>
        m.stamp_peak <= cfd_low_p(DEPTH-1);
        m.stamp_pulse <= cfd_low_p(DEPTH-1) and first_peak;
        if cfd_low_p(DEPTH-1) then
          rise_t_n <= (0 => '1',others => '0');
          m.rise_time <= (others => '0');
        end if;
        
      when SLOPE_MAX_TIMING_D =>
        m.stamp_peak <= max_slope_p(DEPTH-1);
        m.stamp_pulse <= max_slope_p(DEPTH-1) and first_peak;
        if max_slope_p(DEPTH-1) then
          rise_t_n <= (0 => '1',others => '0');
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

      if slope_pos_Txing_p(DEPTH-1) then
        m.armed <= TRUE;
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
        pulse_l_n <= (0 => '1', others => '0');
      else
        if pulse_l_n(16)='1' then
          m.pulse_length <= (others => '1');
        else
          pulse_l_n <= pulse_l_n + 1;
          m.pulse_length <= pulse_l_n(15 downto 0);
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
m.above_pulse_threshold <= a_pulse_thresh_p(DEPTH-4);
m.pulse_threshold_pos <= pulse_pos_Txing_p(DEPTH-4);
m.pulse_threshold_neg <= pulse_neg_Txing_p(DEPTH-4);
m.slope_threshold_pos <= slope_pos_Txing_p(DEPTH-4);
m.slope_threshold_neg <= slope_neg_Txing_p(DEPTH-4);
m.baseline <= resize(baseline,SIGNAL_BITS);

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
  reset => reset1,
  signal_in => filtered_x,
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
  reset => reset1,
  signal_in => slope_x,
  threshold => (others => '0'),
  signal_out => m.slope.sample,
  pos_xing => m.slope.pos_0xing,
  neg_xing => m.slope.neg_0xing,
  xing => m.slope.zero_xing,
  area => m.slope.area,
  extrema => m.slope.extrema
);

rawMeas:entity work.signal_measurement
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
  reset => reset1,
  signal_in => raw_p(4),
  threshold => (others => '0'),
  signal_out => m.raw.sample,
  pos_xing => m.raw.pos_0xing,
  neg_xing => m.raw.neg_0xing,
  xing => m.raw.zero_xing,
  area => m.raw.area,
  extrema => m.raw.extrema
);

end architecture RTL;
