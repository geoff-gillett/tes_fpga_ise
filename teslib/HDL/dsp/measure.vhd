library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

use work.registers.all;
use work.measurements.all;

entity measure is
generic(
  WIDTH:integer:=18;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1;
  PEAK_COUNT_BITS:integer:=4;
  CFD_DELAY:integer:=256
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  --rel2min:in boolean; -- don't use set FALSE
  slope_threshold:in unsigned(16 downto 0);
  pulse_threshold:in unsigned(16 downto 0);
  area_threshold:in unsigned(30 downto 0);
  constant_fraction:in unsigned(16 downto 0);
  
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

signal peak_state:peak_state_t;

signal slope_pos_Txing,slope_neg_Txing:boolean;
signal pulse_pos_Txing,pulse_neg_Txing:boolean;
signal slope_x,filtered_x:signed(WIDTH-1 downto 0);
signal filtered_reg,filtered_m:signed(WIDTH-1 downto 0);
signal pulse_area_m:signed(31 downto 0);
signal slope_pos_0xing,slope_neg_0xing:boolean;
signal slope_threshold_s,pulse_threshold_s:signed(WIDTH-1 downto 0);
signal area_threshold_s:signed(31 downto 0);
signal above_area_threshold:boolean;
signal pulse_time,peak_time,pulse_length:unsigned(16 downto 0);
signal pulse_start:boolean;

constant DEPTH:integer:=7;
type pipe is array (1 to DEPTH) of signed(WIDTH-1 downto 0);
signal raw_p:pipe;
signal cfd_low_p:boolean_vector(1 to DEPTH);
signal cfd_high_p:boolean_vector(1 to DEPTH);
signal slope_pos_Txing_p,slope_neg_Txing_p:boolean_vector(1 to DEPTH);
signal slope_pos_0xing_p,slope_neg_0xing_p:boolean_vector(1 to DEPTH);
signal pulse_pos_Txing_p,pulse_neg_Txing_p:boolean_vector(1 to DEPTH);
signal a_pulse_thresh_p:boolean_vector(1 to DEPTH);

signal pulse_area:signed(AREA_WIDTH-1 downto 0);
signal peak_count:unsigned(PEAK_COUNT_BITS downto 0);

begin
measurements <= m;

CFD:entity work.CFD_unit
generic map(
  WIDTH => WIDTH,
  CFD_DELAY => CFD_DELAY
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  raw => raw,
  slope => slope,
  filtered => filtered,
  constant_fraction => constant_fraction,
  rel2min => FALSE,
  cfd_low => cfd_low,
  cfd_high => cfd_high,
  cfd_error => cfd_error,
  raw_out => raw_cfd,
  slope_out => slope_cfd,
  filtered_out => filtered_cfd
);  

slope0xing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => slope_cfd,
  threshold => (others => '0'),
  signal_out => slope_x,
  pos => slope_pos_0xing,
  neg => slope_neg_0xing
);

slope_threshold_s <= signed('0' & slope_threshold);
slopeTxing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => slope_cfd,
  threshold => slope_threshold_s,
  signal_out => open,
  pos => slope_pos_Txing,
  neg => slope_neg_Txing
);

pulse_threshold_s <= signed('0' & pulse_threshold);
pulseTxing:entity work.threshold_xing
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

-- timing for peak event can only be minimum, cfd_low or slope_threshold
-- timing for area and pulse can be pulse_threshold
-- The issue is with pulse_event pTimes need negative values
-- cfd_low can happen before pulse_threshold 
-- solution replace sThresh slot in pulse_event with oTime (offset) to be 
-- subtracted from rTime to get the time of the starting minima.

-- TODO add rel2min code to subtract off minimum

area_threshold_s <= signed('0' & area_threshold);
pulseMeas:process(clk)
begin
  if rising_edge(clk) then
    if reset1 = '1' then
      peak_state <= IDLE_S;
      pulse_time <= (others => '0');
      peak_time <= (others => '0');
      pulse_length <= (others => '0');
      peak_count <= (others => '0');
    else
      
      raw_p <= raw_cfd & raw_p(1 to DEPTH-1);
      cfd_low_p <= cfd_low & cfd_low_p(1 to DEPTH-1);
      cfd_high_p <= cfd_high & cfd_high_p(1 to DEPTH-1);
      slope_pos_Txing_p <= slope_pos_Txing & slope_pos_Txing_p(1 to DEPTH-1);
      slope_neg_Txing_p <= slope_neg_Txing & slope_neg_Txing_p(1 to DEPTH-1);
      slope_pos_0xing_p <= slope_pos_0xing & slope_pos_0xing_p(1 to DEPTH-1);
      slope_neg_0xing_p <= slope_neg_0xing & slope_neg_0xing_p(1 to DEPTH-1);
      pulse_pos_Txing_p <= pulse_pos_Txing & pulse_pos_Txing_p(1 to DEPTH-1);
      pulse_neg_Txing_p <= pulse_neg_Txing & pulse_neg_Txing_p(1 to DEPTH-1);
      
      filtered_reg <= filtered_x;
      filtered_m <= filtered_reg;
      --slope_m <= slope_x;
      
      a_pulse_thresh_p 
        <= (filtered_x >= pulse_threshold_s) & a_pulse_thresh_p(1 to DEPTH-1);
      
      pulse_start <= slope_pos_0xing_p(DEPTH-1) and 
                     not a_pulse_thresh_p(DEPTH-1);
                     
      if slope_pos_0xing_p(DEPTH-1) and not a_pulse_thresh_p(DEPTH-1) then
        pulse_time <= (others => '0');
        peak_count <= (others => '0');
      else
        
        if slope_neg_0xing_p(DEPTH) then
          if peak_count(PEAK_COUNT_BITS)='1' then
            peak_count <= (others => '1');
          else
            peak_count <= peak_count + 1;
          end if;
        end if;
        
        if pulse_time(16)='1' then
          pulse_time <= (others => '1');
        else
          pulse_time <= pulse_time + 1;
        end if;
        
      end if;
      
      --above_area_threshold <= pulse_area >= area_threshold_s;
      pulse_area_m <= pulse_area;
      
      if slope_pos_Txing_p(DEPTH-1) then
        peak_state <= ARMED_S;
      elsif slope_neg_0xing_p(DEPTH) then
        peak_state <= IDLE_S;
      end if;
      
      if pulse_pos_Txing_p(DEPTH-1) then
        pulse_length <= (others => '0');
      else
        if pulse_length(16)='1' then
          pulse_length <= (others => '1');
        else
          pulse_length <= pulse_length + 1;
        end if;
      end if;
      
      if slope_pos_0xing_p(DEPTH-1) then
        peak_time <= (others => '0');
      else
        if peak_time(16)='1' then
          peak_time <= (others => '1');
        else
          peak_time <= peak_time+1;
        end if;
      end if;
      
    end if;
  end if;
end process pulseMeas;

m.pulse_area <= pulse_area_m;
m.pulse_length <= pulse_length(15 downto 0);
m.pulse_time <= pulse_time(15 downto 0);
m.pulse_start <= pulse_start;
m.peak_time <= peak_time(15 downto 0);
m.peak_state <= peak_state;
m.peak_count <= peak_count(PEAK_COUNT_BITS-1 downto 0);
m.cfd_high <= cfd_high_p(DEPTH);
m.cfd_low <= cfd_low_p(DEPTH);
m.above_area_threshold <= above_area_threshold;
m.above_pulse_threshold <= a_pulse_thresh_p(DEPTH);
m.pulse_threshold_pos <= pulse_pos_Txing_p(DEPTH);
m.pulse_threshold_neg <= pulse_neg_Txing_p(DEPTH);
m.slope_threshold_pos <= slope_pos_Txing_p(DEPTH);
m.slope_threshold_neg <= slope_neg_Txing_p(DEPTH);

pulseArea:entity work.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset1,
  xing => pulse_pos_Txing_p(2),
  sig => filtered_m,
  area => pulse_area
);

filteredMeas:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
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

slopeMeas:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset2,
  signal_in => slope_x,
  threshold => (others => '0'),
  signal_out => m.slope.sample,
  pos_xing => m.slope.pos_0xing,
  neg_xing => m.slope.neg_0xing,
  xing => m.slope.zero_xing,
  area => m.slope.area,
  extrema => m.slope.extrema
);

rawMeas:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset2,
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
