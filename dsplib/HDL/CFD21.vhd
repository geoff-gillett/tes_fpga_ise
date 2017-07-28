library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

entity CFD21 is
generic(
  WIDTH:integer:=16;
  CF_WIDTH:integer:=18;
  CF_FRAC:integer:=17;
  DELAY:integer:=1023;
  STRICT_CROSSING:boolean:=TRUE
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  constant_fraction:in signed(CF_WIDTH-1 downto 0);
  slope_threshold:in signed(WIDTH-1 downto 0);
  pulse_threshold:in signed(WIDTH-1 downto 0);
  rel2min:in boolean;
 
  cfd_low_threshold:out signed(WIDTH-1 downto 0);
  cfd_high_threshold:out signed(WIDTH-1 downto 0);
  
  max:out boolean;
  min:out boolean;
  -- valid when min is true
  max_slope:out signed(WIDTH-1 downto 0); 
  will_go_above_pulse_threshold:out boolean;
  will_arm:out boolean;
  overrun:out boolean; --FIXME useful?
  
  slope_out:out signed(WIDTH-1 downto 0);
  slope_threshold_pos:out boolean;
  armed:out boolean;
  
  filtered_out:out signed(WIDTH-1 downto 0);
  pulse_threshold_pos:out boolean;
  pulse_threshold_neg:out boolean;
  above_pulse_threshold:out boolean;
  cfd_error:out boolean;
  cfd_valid:out boolean
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
constant DEPTH:integer:=11;

signal started:boolean;
signal slope_0_p,slope_0_n:boolean;
signal cf_int:signed(CF_WIDTH-1 downto 0):=(others => '0');
signal p:signed(WIDTH-1 downto 0);
--signal slope_t_p,slope_t_n:boolean;
signal slope_threshold_int:signed(WIDTH-1 downto 0);
signal pulse_threshold_int:signed(WIDTH-1 downto 0);
signal max_slope_i:signed(WIDTH-1 downto 0);
--signal pulse_t_p,pulse_t_n:boolean;
-- pipelines
type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

signal filtered_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal minima_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_0_n_pipe,slope_0_p_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
signal filtered_0_p_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
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
signal q_was_empty:boolean;

signal first_peak:boolean;
signal good_write:boolean;
signal read_d:boolean;
signal filtered_int,filtered_0x_reg:signed(WIDTH-1 downto 0);
signal slope_int,slope_0x_reg:signed(WIDTH-1 downto 0);

--DEBUGING
--constant DEBUG:boolean:=FALSE;
--signal wr_count,rd_count:unsigned(WIDTH-1 downto 0);
--signal CFD_valid:boolean;
--signal CFD_error:boolean;

signal slope_t_p,pulse_t_p:boolean;
signal rel2min_int:boolean;
signal minima:signed(WIDTH-1 downto 0);

signal cfd_low_threshold_d,cfd_high_threshold_d:signed(WIDTH-1 downto 0);
signal max_slope_d:signed(WIDTH-1 downto 0);
signal will_go_above_pulse_threshold_d,will_arm_d:boolean;
signal pulse_t_n:boolean;
signal pending:integer;


begin
--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
--FIXME make simpler lower latency crossing detector
slope0xing:entity work.crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope,
  threshold => (others => '0'),
  signal_out => slope_0x,
  pos => slope_0_p,  --LAT=0
  neg => slope_0_n,
  above => open
);

thresholding:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    started <= FALSE; 
    slope_threshold_int <= (WIDTH-1 => '0', others => '1');
    pulse_threshold_int <= (WIDTH-1 => '0', others => '1');
    cf_int <= (others => '0');
  else
    -- FIXME the thresholds changing could cause issues
    filtered_0x <= filtered;
    if slope_0_p then
      started <= TRUE;
      pulse_threshold_int <= pulse_threshold;
      slope_threshold_int <= slope_threshold;
      cf_int <= constant_fraction;
      rel2min_int <= rel2min;
    end if;
    slope_0x_reg <= slope_0x;
    filtered_0x_reg <= filtered_0x; --LAT 1
  end if;
end if;
end process thresholding;

slopeTxing:entity work.crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_0x_reg,
  threshold => slope_threshold_int, --LAT 2
  signal_out => slope_int,
  pos => slope_t_p,
  neg => open,
  above => open
);

filteredTxing:entity work.crossing20
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_0x_reg,
  threshold => pulse_threshold_int, --LAT 2
  signal_out => filtered_int,
  pos => pulse_t_p,
  neg => pulse_t_n,
  above => above_i --LAT 2
);

overrun_i <= delay_counter >= DELAY-1;
pipeline:process (clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      slope_0_n_pipe <= (others => FALSE);
      slope_0_p_pipe <= (others => FALSE);
      filtered_0_p_pipe <= (others => FALSE);
      slope_t_p_pipe <= (others => FALSE);
      pulse_t_p_pipe <= (others => FALSE);
      armed_pipe <= (others => FALSE);
      above_pipe <= (others => FALSE);
      
      armed_i <= FALSE;
      first_peak <= TRUE;
      delay_counter <= 0;
      q_wr_en <= '0'; 
      good_write <= FALSE;
    else
      
      --counter to track queue pending  
      if q_wr_en='1' and q_rd_en='0' then
        pending <= pending + 1;
      end if;
      if q_rd_en ='1' and q_wr_en='0' then
        pending <= pending - 1;
      end if;
      slope_0_n_pipe <= (slope_0_n and started) & slope_0_n_pipe(1 to DEPTH-1);
      slope_0_p_pipe <= slope_0_p & slope_0_p_pipe(1 to DEPTH-1);
      
      above_pipe(3 to DEPTH) <= above_i & above_pipe(3 to DEPTH-1);
      
      if slope_0_p_pipe(2) and not above_i then
        first_peak <= TRUE; -- LAT 3
      elsif slope_0_n_pipe(3) and armed_i and above_pipe(3) then
        first_peak <= FALSE;
      end if; 
      first_peak_pipe(4 to DEPTH) <= first_peak & first_peak_pipe(4 to DEPTH-1);
      
      pulse_t_p_pipe(3 to DEPTH) <= pulse_t_p & pulse_t_p_pipe(3 to DEPTH-1);
      pulse_t_n_pipe(3 to DEPTH) <= pulse_t_n & pulse_t_n_pipe(3 to DEPTH-1);
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
        if rel2min_int or not first_peak then -- or not first peak
          minima <= filtered_pipe(3); --lat 4
        else
          minima <= (others => '0');
        end if;
        minima_pipe(4 to DEPTH) <= filtered_pipe(3) & minima_pipe(4 to DEPTH-1);
      else
        minima_pipe(4 to DEPTH) <= minima_pipe(4) & minima_pipe(4 to DEPTH-1);
      end if;
      
      if slope_0_p_pipe(DEPTH) then 
        delay_counter <= 1;
      else
        if not overrun_i then
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
      if first_peak_pipe(DEPTH-1) then
        -- the minima used in the calculation was zero
        if minima_pipe(DEPTH-1) > p then
          cfd_low_i <= minima_pipe(DEPTH-1);
        else
          cfd_low_i <= p;
        end if; 
      else
        cfd_low_i <= p + minima_pipe(DEPTH-1);
      end if;
      cfd_high_i <= filtered_pipe(DEPTH-1) - p; 
      
      if slope_0_n_pipe(DEPTH-1) then
        q_wr_en <=  to_std_logic(not overrun_i);
        overrun_d <= overrun_i; 
      else 
        q_wr_en <= '0';
        if min_d then
          overrun_d <= FALSE;
        end if;
      end if;
      
    end if;
  end if;
end process pipeline;

--latency 5?
--cf*(sig-min)
cfCalc:entity work.constant_fraction8
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
-- delays and queue
--------------------------------------------------------------------------------
full_i <= q_full = '1';
--FIXME good_write no longer used
flags_i <= overrun_i & good_write & slope_0_n_pipe(DEPTH) & 
           slope_0_p_pipe(DEPTH) & armed_pipe(DEPTH) & above_pipe(DEPTH) & 
           pulse_t_p_pipe(DEPTH) & pulse_t_n_pipe(DEPTH) & 
           slope_t_p_pipe(DEPTH);

cf_data(WIDTH-1 downto 0) <= std_logic_vector(cfd_low_i);
cf_data(2*WIDTH-1 downto WIDTH) <= std_logic_vector(cfd_high_i);
cf_data(3*WIDTH-1 downto 2*WIDTH) <= std_logic_vector(max_slope_i);
cf_data(3*WIDTH) <= to_std_logic(overrun_i); 
cf_data(3*WIDTH+1) <= to_std_logic(armed_pipe(DEPTH)); 
cf_data(3*WIDTH+2) <= to_std_logic(above_pipe(DEPTH)); 
cf_data(71 downto 3*WIDTH+3) <= (others => '0'); 

-- write queue at max read at delayed min
q_reset <= reset;

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
flagDelay:entity work.sdp_bram_delay
generic map(
  DELAY => DELAY-1,
  WIDTH => 9
)
port map(
  clk => clk,
  input => flags_i_s,
  delayed => flags_d
);

fiteredDelay:entity work.sdp_bram_delay
generic map(
  DELAY => DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(filtered_pipe(DEPTH)),
  delayed => filtered_d
);

slopeDelay:entity work.sdp_bram_delay
generic map(
  DELAY => DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(slope_pipe(DEPTH)),
  delayed => slope_d
);

--overrun_d <= to_boolean(flags_d(8));
read_d <= to_boolean(flags_d(7)); --FIXME not used
max_d <= to_boolean(flags_d(6));
min_d <= to_boolean(flags_d(5));
armed_d <= to_boolean(flags_d(4));
above_pulse_threshold_d <= to_boolean(flags_d(3));
pulse_threshold_pos_d <= to_boolean(flags_d(2));
pulse_threshold_neg_d <= to_boolean(flags_d(1));
slope_threshold_pos_d <= to_boolean(flags_d(0));

cfd_low_threshold_d <= signed(q_dout(WIDTH-1 downto 0));
cfd_high_threshold_d <= signed(q_dout(2*WIDTH-1 downto WIDTH));
max_slope_d <= signed(q_dout(3*WIDTH-1 downto 2*WIDTH));
will_arm_d <= to_boolean(q_dout(3*WIDTH+1));
will_go_above_pulse_threshold_d <= to_boolean(q_dout(3*WIDTH+2));
--------------------------------------------------------------------------------
-- output registers
--------------------------------------------------------------------------------
outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    --full_d <= FALSE;
    CFD_error <= FALSE;
    CFD_valid <= FALSE;
    q_rd_en <= '0';
    --if DEBUG then 
--      rd_count <= (others => '0');
    --end if;
  else
    overrun <= overrun_d;
    max <= max_d;
    min <= min_d;
    armed <= armed_d;
    above_pulse_threshold <= above_pulse_threshold_d;
    pulse_threshold_pos <= pulse_threshold_pos_d;
    pulse_threshold_neg <= pulse_threshold_neg_d;
    slope_threshold_pos <= slope_threshold_pos_d;
    
    -- read queue at min
    q_was_empty <= q_empty='1';
    
    --getting CFD errors with peak packets which are not expected, and the peak
    --event is not ignored with and peak height under pulse threshold an 
    --impossible value
    
    --started is true after the first minima is detected at the start of the
    --delay flags(6) is slope_0_n (maxima) flags(5) is slope_0_p min_d is 
    --slope_0_p registered
    if min_d and not overrun_d then
      q_rd_en <= '1'; -- read the queue 
      cfd_low_threshold <= cfd_low_threshold_d;
      cfd_high_threshold <= cfd_high_threshold_d;
      max_slope <= max_slope_d;
      will_arm <= will_arm_d;
      will_go_above_pulse_threshold <= will_go_above_pulse_threshold_d;
    else
      q_rd_en <= '0';
    end if;
    
    --min_d is slope_0_p
    if min_d then
      CFD_error <= overrun_d;
      CFD_valid <= not overrun_d;
    else
      CFD_error <= FALSE;
    end if;
        
  end if;
end if;
end process outputReg;
slope_out <= signed(slope_d);
filtered_out <= signed(filtered_d);

end architecture RTL;