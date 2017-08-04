library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--TODO can configurations be used here?
library dsp;
use dsp.crossing20;

use work.registers21.all;

entity CFD21 is
generic(
  WIDTH:integer:=16;
  CF_WIDTH:integer:=18;
  CF_FRAC:integer:=17;
  DELAY:integer:=1023
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  -- input signals
  s:in signed(WIDTH-1 downto 0);
  f:in signed(WIDTH-1 downto 0);
  
  -- control registers
  registers:in capture_registers_t;
  registers_out:out capture_registers_t;
 
  -- output signals
  s_out:out signed(WIDTH-1 downto 0);
  f_out:out signed(WIDTH-1 downto 0);
  
  -- crossings for output signals
  max:out boolean; --s zero falling crossing
  min:out boolean; --s zero rising crossing  
  s_t_p:out boolean; --s threshold rising crossing
  f_0_n:out boolean; --f zero falling crossing
  f_0_p:out boolean; --f 0 rising crossing
  p_t_p:out boolean; --f threshold rising crossing
  p_t_n:out boolean; --f threshold falling crossing
  
  armed:out boolean; --s has crossed slope_threshold reset at max
  above:out boolean; --f is above pulse_threshold
  first_rise:out boolean; --true min to max where min <= pulse_threshold
  rise_start:out boolean; --minima of a valid rise
  rising:out boolean; -- true min to max of a valid rise
  pulse_start:out boolean; --min of valid first rise
  
  cfd_low_threshold:out signed(WIDTH-1 downto 0); --changes at minima
  cfd_high_threshold:out signed(WIDTH-1 downto 0); --changes at minima
  max_slope_threshold:out signed(WIDTH-1 downto 0); -- changes at minima
  
  will_cross:out boolean; --changes at minima
  will_arm:out boolean; --changes at minima
  
  -- crossings of calculated thresholds by output signals
  cfd_low_p:out boolean; --f crossing cfd_low_threshold
  cfd_high_p:out boolean; --f crossing cfd_high_threshold
  max_slope_p:out boolean; --s = cfd_high_threshold (first occurrence after min)
  
  cfd_error:out boolean;
  cfd_overrun:out boolean --cfd failure due to long rise time
);
end entity CFD21;

architecture RTL of CFD21 is

component cf_queue
port (
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(71 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(71 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;

--constant RAW_CFD_DELAY:integer:=256;
constant DEPTH:integer:=9;

signal reg:capture_registers_t;

signal started:boolean;
signal slope_0_p,slope_0_n:boolean;
signal cf_int:signed(CF_WIDTH-1 downto 0):=(others => '0');
signal p:signed(WIDTH-1 downto 0);
--signal slope_t_p,slope_t_n:boolean;
signal slope_threshold_int:signed(WIDTH-1 downto 0);
signal p_thresh_i:signed(WIDTH-1 downto 0);
signal p_thresh_d:std_logic_vector(WIDTH-1 downto 0);
signal max_slope_i,max_slope_d:signed(WIDTH-1 downto 0);
--signal pulse_t_p,pulse_t_n:boolean;
-- pipelines
type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

signal filtered_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal minima_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_0_n_pipe,slope_0_p_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
--signal filtered_0_p_pipe,filtered_0_n_pipe:boolean_vector(1 to DEPTH)
--       :=(others => FALSE);
signal slope_t_p_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal pulse_t_p_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal pulse_t_n_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal first_peak_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal armed_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal above_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
--signal overrun_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal slope_0x,filtered_0x:signed(WIDTH-1 downto 0);
signal delay_counter:natural range 0 to DELAY;
signal overrun_i,armed_i,above_i:boolean;
signal overrun_d,armed_d:boolean;
signal cfd_low_i,cfd_high_i:signed(WIDTH-1 downto 0);

--------------------------------------------------------------------------------
-- Delay line and queue signals
--------------------------------------------------------------------------------
signal q_reset:std_logic;
signal cf_data:std_logic_vector(71 downto 0);
signal q_wr_en:std_logic:='0';
signal q_rd_en:std_logic:='0';
signal q_dout:std_logic_vector(71 downto 0);
signal q_full:std_logic;
signal q_empty:std_logic;
signal full_i:boolean;
signal flags_i:boolean_vector(8 downto 0);
signal flags_d,flags_i_s:std_logic_vector(8 downto 0);
signal filtered_d:std_logic_vector(WIDTH-1 downto 0);
signal slope_d:std_logic_vector(WIDTH-1 downto 0);
signal max_d,min_d,above_pulse_threshold_d,pulse_threshold_pos_d:boolean;
signal pulse_threshold_neg_d,slope_threshold_pos_d:boolean;
--signal q_was_empty:boolean;

signal first_peak_i:boolean;
signal filtered_int,filtered_0x_reg:signed(WIDTH-1 downto 0);
signal slope_int,slope_0x_reg:signed(WIDTH-1 downto 0);

--DEBUGING
--constant DEBUG:boolean:=FALSE;
--signal wr_count,rd_count:unsigned(WIDTH-1 downto 0);
--signal CFD_valid:boolean;
--signal CFD_error:boolean;

signal slope_t_p,p_t_p_i:boolean;
signal rel2min_i,rel2min_d:boolean;
signal minima:signed(WIDTH-1 downto 0);

signal cfd_low_threshold_d,cfd_high_threshold_d:signed(WIDTH-1 downto 0);
signal will_cross_d,will_arm_d:boolean;
signal p_t_n_i:boolean;
signal pending:integer;
--signal valid_peak_i:boolean;
--signal valid_peak_reg:boolean;
signal first_peak_d:boolean;
signal max_slope_armed:boolean;
signal filtered_0_n_i,filtered_0_n_d:boolean;
signal filtered_0_p_i,filtered_0_p_d:boolean;
signal cfd_error_i:boolean;
signal cfd_error_d:boolean;


begin
--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
--FIXME check underflow when min-max less than FWFT? 

--LAT 0 is at input
slope0xing:entity crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => s,
  threshold => (others => '0'),
  signal_out => slope_0x, --lat 1
  pos => slope_0_p,  
  neg => slope_0_n,
  above => open
);

-- lat=2 captured registers 
thresholding:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    started <= FALSE; 
    slope_threshold_int <= (WIDTH-1 => '0', others => '1');
    p_thresh_i <= (WIDTH-1 => '0', others => '1');
    cf_int <= (others => '0');
  else
    filtered_0x <= f;
    if slope_0_p then
      started <= TRUE;
      reg <= registers; --capture the register settings each minima
    end if;
    slope_0x_reg <= slope_0x; --lat 2
    filtered_0x_reg <= filtered_0x; --lat 2
  end if;
end if;
end process thresholding;
p_thresh_i <= signed('0' & reg.pulse_threshold); -- used for pulse area in meas
slope_threshold_int <= signed('0' & reg.slope_threshold); --input stage only
cf_int <= signed('0' & reg.constant_fraction); --input stage only
rel2min_i <= reg.cfd_rel2min; -- used for height in meas

slopeTxing:entity crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_0x_reg, 
  threshold => slope_threshold_int, 
  signal_out => slope_int, --lat 3
  pos => slope_t_p,
  neg => open,
  above => open
);

filteredTxing:entity crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_0x_reg,
  threshold => p_thresh_i, 
  signal_out => filtered_int, --lat 3
  pos => p_t_p_i,
  neg => p_t_n_i,
  above => above_i --lat 3
);


pipeline:process (clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      slope_0_n_pipe <= (others => FALSE);
      slope_0_p_pipe <= (others => FALSE);
      slope_t_p_pipe <= (others => FALSE);
      pulse_t_p_pipe <= (others => FALSE);
      armed_pipe <= (others => FALSE);
      above_pipe <= (others => FALSE);
      
      armed_i <= FALSE;
      first_peak_i <= FALSE;
      delay_counter <= 0;
--      q_wr_en <= '0'; 
      pending <= 0;
    else
      
      --counter to track queue pending  
      if q_wr_en='1' and q_rd_en='0' then
        pending <= pending + 1;
      end if;
      if q_rd_en ='1' and q_wr_en='0' then
        pending <= pending - 1;
      end if;
      --
      slope_0_n_pipe <= (slope_0_n and started) & slope_0_n_pipe(1 to DEPTH-1);
      slope_0_p_pipe <= slope_0_p & slope_0_p_pipe(1 to DEPTH-1);
      above_pipe(3 to DEPTH) <= above_i & above_pipe(3 to DEPTH-1);
      
      if slope_0_p_pipe(2) and not above_i then
        first_peak_i <= TRUE; -- LAT 3
      elsif slope_0_n_pipe(3) and armed_i and above_pipe(3) then
        first_peak_i <= FALSE;
      end if; 
      first_peak_pipe(3 to DEPTH) <= first_peak_i & first_peak_pipe(3 to DEPTH-1);
      
      pulse_t_p_pipe(3 to DEPTH) <= p_t_p_i & pulse_t_p_pipe(3 to DEPTH-1);
      pulse_t_n_pipe(3 to DEPTH) <= p_t_n_i & pulse_t_n_pipe(3 to DEPTH-1);
      slope_t_p_pipe(3 to DEPTH) <= slope_t_p & slope_t_p_pipe(3 to DEPTH-1);
      
      filtered_pipe(3 to DEPTH) <= filtered_int & filtered_pipe(3 to DEPTH-1);
      slope_pipe(3 to DEPTH) <= slope_int & slope_pipe(3 to DEPTH-1);
      
      if slope_t_p then
        armed_i <= TRUE; -- lat 3
      elsif slope_0_n_pipe(3) then
        armed_i <= FALSE;
      end if; 
      armed_pipe(4 to DEPTH) <= armed_i & armed_pipe(4 to DEPTH-1);
      
      -- need first peak
      if slope_0_p_pipe(3) then
        if rel2min_i or not first_peak_i then -- or not first peak
          minima <= filtered_pipe(3); --lat 4
        else
          minima <= (others => '0');
        end if;
        minima_pipe(4 to DEPTH) <= filtered_pipe(3) & minima_pipe(4 to DEPTH-1);
      else
        minima_pipe(4 to DEPTH) <= minima_pipe(4) & minima_pipe(4 to DEPTH-1);
      end if;
      
      if slope_0_p_pipe(DEPTH-1) then 
        delay_counter <= 0;
        overrun_i <= FALSE; --useable at DEPTH
      else
        if not overrun_i then
          overrun_i <= delay_counter = DELAY-4; --FWFT time = 4
          delay_counter <= delay_counter+1;
        end if;
      end if;
     
      -- FIXME 
      if slope_0_p_pipe(DEPTH-1) then
        max_slope_i <= slope_pipe(DEPTH-1);
      else
        if slope_pipe(DEPTH-1) > max_slope_i then
          max_slope_i <= slope_pipe(DEPTH-1);
        end if;
      end if;
      
      -- p = cf * (sig - minima) valid @DEPTH-1
      -- NOTE: truncation = rounding as the thresholds are always positive
      cfd_error_i <= FALSE;
      if first_peak_pipe(DEPTH-1) then
        -- the minima used in the calculation was 0
        if p > minima_pipe(DEPTH-1) then 
          -- good CFD 
          cfd_low_i <= p;
          cfd_error_i <= FALSE;  
        else
          cfd_low_i <= (others => '-');
          cfd_error_i <= TRUE;
        end if; 
      else
        cfd_low_i <= p + minima_pipe(DEPTH-1);
      end if;
      cfd_high_i <= filtered_pipe(DEPTH-1) - p; --
      
    end if;
  end if;
end process pipeline;

filtered0xing:entity crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_pipe(DEPTH-1),
  threshold => (others => '0'),
  signal_out => open,
  extrema => open,
  pos => filtered_0_p_i,
  neg => filtered_0_n_i,
  above => above
);

--latency 5?
--cf*(sig-min)
cfCalc:entity dsp.constant_fraction8
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC
 
)
port map(
  clk => clk,
  reset => reset,
  min => minima,
  cf => cf_int,
  sig => filtered_pipe(4), 
  p => p -- constant fraction of the rise above minimum
);

--------------------------------------------------------------------------------
-- input to delays and queue
--------------------------------------------------------------------------------
full_i <= q_full = '1';

flags_i <= filtered_0_n_i & filtered_0_p_i & 
           slope_0_n_pipe(DEPTH) & 
           slope_0_p_pipe(DEPTH) & armed_pipe(DEPTH) & above_pipe(DEPTH) & 
           pulse_t_p_pipe(DEPTH) & pulse_t_n_pipe(DEPTH) & 
           slope_t_p_pipe(DEPTH);
           
cf_data(WIDTH-1 downto 0) <= std_logic_vector(cfd_low_i);
cf_data(2*WIDTH-1 downto WIDTH) <= std_logic_vector(cfd_high_i);
cf_data(3*WIDTH-1 downto 2*WIDTH) <= std_logic_vector(max_slope_i);
cf_data(4*WIDTH-1 downto 3*WIDTH) <= std_logic_vector(p_thresh_i);
cf_data(4*WIDTH) <= to_std_logic(overrun_i); 
cf_data(4*WIDTH+1) <= to_std_logic(armed_pipe(DEPTH)); 
cf_data(4*WIDTH+2) <= to_std_logic(above_pipe(DEPTH)); 
cf_data(4*WIDTH+3) <= to_std_logic(first_peak_pipe(DEPTH)); 
cf_data(4*WIDTH+4) <= to_std_logic(cfd_error_i); 
cf_data(4*WIDTH+5) <= to_std_logic(rel2min_i); 
cf_data(71 downto 4*WIDTH+6) <= (others => '0'); 

q_reset <= reset;
q_wr_en <= to_std_logic(slope_0_n_pipe(DEPTH));
CFqueue:cf_queue
port map (
  clk => clk,
  srst => q_reset,
  din => cf_data,
  wr_en => q_wr_en,
  rd_en => q_rd_en,
  dout => q_dout,
  full => q_full,
  empty => q_empty
);

flags_i_s <= to_std_logic(flags_i);
flagDelay:entity dsp.sdp_bram_delay
generic map(
  DELAY => DELAY,
  WIDTH => 9
)
port map(
  clk => clk,
  input => flags_i_s,
  delayed => flags_d
);

fiteredDelay:entity dsp.sdp_bram_delay
generic map(
  DELAY => DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(filtered_pipe(DEPTH)),
  delayed => filtered_d
);

slopeDelay:entity dsp.sdp_bram_delay
generic map(
  DELAY => DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(slope_pipe(DEPTH)),
  delayed => slope_d
);

--------------------------------------------------------------------------------
-- output of queue and delays
--------------------------------------------------------------------------------

filtered_0_n_d <= to_boolean(flags_d(8)); --filtered0_neg
filtered_0_p_d <= to_boolean(flags_d(7)); -- filtered0_pos
max_d <= to_boolean(flags_d(6)); --slope0_neg
min_d <= to_boolean(flags_d(5)); --slope0_pos
armed_d <= to_boolean(flags_d(4));
above_pulse_threshold_d <= to_boolean(flags_d(3));
pulse_threshold_pos_d <= to_boolean(flags_d(2));
pulse_threshold_neg_d <= to_boolean(flags_d(1));
slope_threshold_pos_d <= to_boolean(flags_d(0));

cfd_low_threshold_d <= signed(q_dout(WIDTH-1 downto 0));
cfd_high_threshold_d <= signed(q_dout(2*WIDTH-1 downto WIDTH));
max_slope_d <= signed(q_dout(3*WIDTH-1 downto 2*WIDTH));
p_thresh_d <= q_dout(4*WIDTH-1 downto 3*WIDTH);
overrun_d <= to_boolean(q_dout(4*WIDTH));
will_arm_d <= to_boolean(q_dout(4*WIDTH+1));
will_cross_d <= to_boolean(q_dout(4*WIDTH+2));
first_peak_d <= to_boolean(q_dout(4*WIDTH+3));
cfd_error_d <= to_boolean(q_dout(4*WIDTH+4));
rel2min_d <= to_boolean(q_dout(4*WIDTH+4));

--------------------------------------------------------------------------------
-- cfd and max slope crossings
--------------------------------------------------------------------------------
cfdLow:entity crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(filtered_d), 
  threshold => signed(cfd_low_threshold_d), 
  signal_out => f_out, 
  pos => cfd_low_p,
  neg => open,
  above => open
);

cfdHigh:entity crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(filtered_d), 
  threshold => signed(cfd_high_threshold_d), 
  signal_out => open, 
  pos => cfd_high_p,
  neg => open,
  above => open
);

maxSlope:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      max_slope_p <= FALSE;
      max_slope_armed <= FALSE;
      s_out <= (others => '0');
    else
      s_out <= signed(slope_d);
      if min_d then
        max_slope_armed <= TRUE;
      end if;
      if signed(slope_d) = max_slope_d then
        max_slope_p <= max_slope_armed;
        max_slope_armed <= FALSE;
      end if;
    end if;
  end if;
end process maxSlope;

--------------------------------------------------------------------------------
-- output registers
--------------------------------------------------------------------------------
outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    --full_d <= FALSE;
    cfd_overrun <= FALSE;
    rise_start <= FALSE;
    rising <= FALSE;
    pulse_start <= FALSE;
    will_arm <= FALSE;
    will_cross <= FALSE;
    q_rd_en <= '0';
  else
    max <= max_d;
    min <= min_d;
    armed <= armed_d;
    above <= above_pulse_threshold_d;
    first_rise <= first_peak_d;
    f_0_p <= filtered_0_p_d;
    f_0_n <= filtered_0_n_d;
    p_t_p <= pulse_threshold_pos_d;
    p_t_n <= pulse_threshold_neg_d;
    s_t_p <= slope_threshold_pos_d;
    
    rise_start <= FALSE;
    pulse_start <= FALSE;
    q_rd_en <= '0';
    if min_d and q_empty='0' and not overrun_d then
      will_arm <= will_arm_d;
      will_cross <= will_cross_d;
      rise_start <= will_arm_d and will_cross_d and not cfd_error_d;
      rising <= will_arm_d and will_cross_d and not cfd_error_d;
      pulse_start <= will_arm_d and will_cross_d and first_peak_d and 
                     not cfd_error_d;
      cfd_low_threshold <= cfd_low_threshold_d;
      cfd_high_threshold <= cfd_high_threshold_d;
      max_slope_threshold <= max_slope_d;
      q_rd_en <= '1';
      --recapture registers
      registers_out <= reg;
      registers_out.pulse_threshold <= unsigned(p_thresh_d(WIDTH-2 downto 0));
      registers_out.cfd_rel2min <= rel2min_d;
    elsif max_d then 
      will_arm <= FALSE;
      will_cross <= FALSE;
      rising <= FALSE;
    end if;
    
    cfd_error <= cfd_error_d;
    cfd_overrun <= FALSE;
    if min_d then
      cfd_overrun <= q_empty='1';
    end if;
    if q_empty='0' and overrun_d and q_rd_en='0' then
      q_rd_en <= '1';
    end if;
      
  end if;
end if;
end process outputReg;

end architecture RTL;