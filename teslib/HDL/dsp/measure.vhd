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
  AREA_FRAC:integer:=1
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  registers:in channel_registers_t;
  --constant_fraction:in unsigned(16 downto 0);
  
  raw:in signed(WIDTH-1 downto 0);
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  measurements:out measurement_t
);
end entity measure;

architecture RTL of measure is

constant RAW_CFD_DELAY:integer:=196;
constant RAW_FIR_DELAY:integer:=91;
constant DEPTH:integer:=10;

component cf_queue
port (
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(35 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(35 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;

type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

-- pipelines to sync signals
signal f_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal s_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal max_pipe,min_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);

signal min,max:boolean;
signal raw_measurement,filtered_d,slope_d:std_logic_vector(WIDTH-1 downto 0);

signal thresholds,q_dout:std_logic_vector(2*WIDTH-1 downto 0);
signal cf_int:signed(WIDTH-1 downto 0):=(others => '0');
signal cfd_low_threshold,cfd_high_threshold:signed(WIDTH-1 downto 0)
       :=(others => '0');
signal q_full,q_empty:std_logic;
signal q_rd_en,q_wr_en:std_logic:='0';

--minimum sig value
signal min_in:signed(WIDTH-1 downto 0):=(others => '0');
signal min_out:signed(WIDTH-1 downto 0):=(others => '0');
signal p:signed(WIDTH-1 downto 0);
signal cfd_low,cfd_high:signed(WIDTH-1 downto 0);
signal min_cfd:boolean;
signal max_cfd:boolean;

type CFDstate is (CFD_IDLE_S,CFD_ARMED_S,CFD_ERROR_S);
signal cfd_state:CFDstate;
signal slope_cfd:signed(WIDTH-1 downto 0);
signal slope_pos_thresh_xing:boolean;
signal cfd_low_xing,cfd_high_thresh_xing:boolean;
signal slope_threshold:signed(WIDTH-1 downto 0);
signal slope_measurement:signed(WIDTH-1 downto 0);
signal filtered_measurement:signed(WIDTH-1 downto 0);

signal m:measurement_t;
signal start_int:boolean;

begin

--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
  
inputPipelines:process(clk)
begin
  if rising_edge(clk) then
    if reset1='1' then
      f_pipe <= (others => (others => '0'));
      s_pipe <= (others => (others => '0'));
      max_pipe <= (others => FALSE);
      min_pipe <= (others => FALSE);
    else
      f_pipe <= filtered & f_pipe(1 to DEPTH-1);
      s_pipe <= slope & s_pipe(1 to DEPTH-1);
      max_pipe <= max & max_pipe(1 to DEPTH-1);
      min_pipe <= min & min_pipe(1 to DEPTH-1);
    end if;
  end if;
end process inputPipelines;
  
--latency 3
slope0xing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => slope,
  signal_out => open,
  threshold => (others => '0'),
  pos => open,
  neg => open,
  pos_closest => min,
  neg_closest => max
);

cfCalc:entity work.constant_fraction
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset2,
  min => min_in,
  cf => cf_int,
  sig => f_pipe(4),
  p => p -- constant fraction of the rise above minimum
);

cfReg:process(clk)
begin
  if rising_edge(clk) then
    
    if min then
      min_in <= f_pipe(3);   --minima into cf pipeline
      cf_int <= signed('0' & registers.capture.constant_fraction);
    end if; 
          
    if min_pipe(4) then
      min_out <= f_pipe(7); --minima at output of cf pipeline
    end if;
    
    cfd_low <= p + min_out;
    cfd_high <= f_pipe(8) - p;

  end if;
end process cfReg;

-- low & high thresholds for queue
--------------------------------------------------------------------------------
-- CFD delays
--------------------------------------------------------------------------------
-- queue thresholds at max
-- if full there is a problem 
-- need to make queue deep enough in relation to cf_delay so that it can never 
-- fill up

assert q_full='0' 
report "Threshold queue full" severity ERROR;

thresholds <= std_logic_vector(cfd_low) & std_logic_vector(cfd_high);
q_wr_en <= '1' when max_pipe(6) else '0';
threshold_queue:cf_queue
port map (
  clk => clk,
  srst => reset1,
  din => thresholds,
  wr_en => q_wr_en,
  rd_en => q_rd_en,
  dout => q_dout,
  full => q_full,
  empty => q_empty
);

rawDelay:entity work.sdp_bram_delay
generic map(
  DELAY => RAW_CFD_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(raw),
  delayed => raw_measurement
);

fiteredDelay:entity work.sdp_bram_delay
generic map(
  DELAY => RAW_CFD_DELAY-RAW_FIR_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(filtered),
  delayed => filtered_d
);

slopeDelay:entity work.sdp_bram_delay
generic map(
  DELAY => RAW_CFD_DELAY-RAW_FIR_DELAY-3,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(slope),
  delayed => slope_d
);

cfdSlope0xing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => signed(slope_d),
  signal_out => slope_cfd,
  threshold => (others => '0'),
  pos => open,
  neg => open,
  pos_closest => min_cfd,
  neg_closest => max_cfd
);

slope_threshold <= signed('0' & registers.capture.slope_threshold);
SlopeThreshXing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => signed(slope_cfd),
  signal_out => slope_measurement,
  threshold => slope_threshold,
  pos => open,
  neg => open,
  pos_closest => slope_pos_thresh_xing,
  neg_closest => open
);

CFDreg:process (clk) is
begin
  if rising_edge(clk) then
    if reset1 = '1' then
      q_rd_en <= '0';
    else
      q_rd_en <= '0';
      
      case cfd_state is 
        
      when CFD_IDLE_S =>
        
        if min_cfd then
          if q_empty='1' then
            cfd_state <= CFD_ERROR_S;
            cfd_low_threshold <= signed(filtered_d);
            cfd_high_threshold <= signed(filtered_d);
          else
            cfd_state <= CFD_ARMED_S;
            cfd_low_threshold <= signed(q_dout(2*WIDTH-1 downto WIDTH));
            cfd_high_threshold <= signed(q_dout(WIDTH-1 downto 0));
          end if;
        end if;
            
      when CFD_ARMED_S | CFD_ERROR_S =>
        if max_cfd then
          cfd_state <= CFD_IDLE_S;
          q_rd_en <= '1';
        end if;         
        
      end case;
    end if;
  end if;
end process CFDreg;

cfdLowThreshXing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => signed(filtered_d),
  signal_out => filtered_measurement,
  threshold => cfd_low_threshold,
  pos => open,
  neg => open,
  pos_closest => cfd_low_xing,
  neg_closest => open
);

cfdHighThreshXing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => signed(filtered_d),
  signal_out => open,
  threshold => cfd_high_threshold,
  pos => open,
  neg => open,
  pos_closest => cfd_high_thresh_xing,
  neg_closest => open
);
--------------------------------------------------------------------------------
-- Measurement
--------------------------------------------------------------------------------

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
  signal_in => filtered_measurement,
  threshold => (others => '0'),
  signal_out => m.filtered.sample,
  pos => m.filtered.pos_0xing,
  neg => m.filtered.neg_0xing,
  xing_time => m.filtered.xing_time,
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
  reset => reset1,
  signal_in => slope_measurement,
  threshold => (others => '0'),
  signal_out => m.slope.sample,
  pos => m.slope.pos_0xing,
  neg => m.slope.neg_0xing,
  xing_time => m.slope.xing_time,
  area => m.slope.area,
  extrema => m.slope.extrema
);


startStop:process
begin
  case registers.capture.timing is
  when PULSE_THRESH_TIMING_D =>
    start_int <=  m.filtered.pos_threshxing;
  when SLOPE_THRESH_TIMING_D =>
    start_int <= m.slope.pos_threshxing;
  when CFD_LOW_TIMING_D =>
    start_int <= cfd_low_xing;
    null;
  when RISE_START_TIMING_D =>
    start_int <= 
    null;
  end case;
  
end process startStop;



pulseMeasurement:process(clk)
begin
  if rising_edge(clk) then
    if reset1 = '1' then
      
    else
    end if;
  end if;
end process pulseMeasurement;

--slopeMeas:entity work.signal_measurement2
--generic map(
--  WIDTH => WIDTH,
--  FRAC => FRAC,
--  AREA_WIDTH => AREA_WIDTH,
--  AREA_FRAC => AREA_FRAC
--)
--port map(
--  clk => clk,
--  reset => reset2,
--  signal_in => signed(slope_cfd),
--  threshold => signed('0' & registers.capture.slope_threshold),
--  signal_out => open,
--  pos => slope_pos,
--  neg => slope_neg,
--  time => slope_time,
--  area => area,
--  extrema => extrema
--);

end architecture RTL;
