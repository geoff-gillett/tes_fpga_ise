library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--TODO can configurations be used here?
library dsp;
use dsp.crossing;

use work.registers.all;

entity CFD is
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
  max:out boolean; --s falling zero crossing
  min:out boolean; --s zero rising crossing  
  s_0_x:out boolean; --s zero crossing
  s_t_p:out boolean; --s rising slope_threshold crossing
  f_0_n:out boolean; --f falling zero crossing
  f_0_p:out boolean; --f rising zero crossing
  f_0_x:out boolean; --f zero crossing
  p_t_p:out boolean; --f rising pulse_threshold crossing
  p_t_n:out boolean; --f falling pulse_threshold crossing
  p_t_x:out boolean; --f pulse_threshold crossing
  
  armed:out boolean; --s has crossed slope_threshold resets at max
  above:out boolean; --f is above pulse_threshold
  --true min to max of a rise that will_arm and will_cross
  valid_rise:out boolean; --true max to min of a valid rise
  first_rise:out boolean; --true min to max when min <= pulse_threshold
  rise_start:out boolean; --minima of a valid rise
  pulse_start:out boolean; --min of valid first rise
  
  cfd_low:out signed(WIDTH-1 downto 0); --changes at minima
  cfd_high:out signed(WIDTH-1 downto 0); --changes at minima
  max_slope:out signed(WIDTH-1 downto 0); -- changes at minima
  
  will_cross:out boolean; --changes at minima
  will_arm:out boolean; --changes at minima
  
--  -- crossings of calculated thresholds by output signals
--  cfd_low_p:out boolean; --f crossing cfd_low_threshold
--  cfd_high_p:out boolean; --f crossing cfd_high_threshold
--  max_slope_p:out boolean; --s = cfd_high_threshold (first occurrence after min)
  
  cfd_valid:out boolean; -- max to min -- no error or overrun
  cfd_error:out boolean; -- flag at min
  cfd_overrun:out boolean --cfd failure due to long rise time true max to min
);
end entity CFD;

architecture RTL of CFD is

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

signal reg,reg_d:capture_registers_t;

signal started:boolean;
signal slope_0_p,slope_0_n:boolean;
signal cf_int:signed(CF_WIDTH-1 downto 0):=(others => '0');
signal p:signed(WIDTH-1 downto 0);
signal slope_threshold_int:signed(WIDTH-1 downto 0);
signal p_thresh_i:signed(WIDTH-1 downto 0);
signal p_thresh_d:std_logic_vector(WIDTH-1 downto 0);
signal max_slope_i,max_slope_d:signed(WIDTH-1 downto 0);

type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

signal filtered_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal minima_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal s_0_n_pipe,s_0_p_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
signal s_t_p_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal p_t_p_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal p_t_n_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal first_rise_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal armed_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal above_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal slope_0x,filtered_0x:signed(WIDTH-1 downto 0);
signal delay_counter:natural range 0 to DELAY;
signal overrun_i,armed_i,above_i:boolean;
signal overrun_d,armed_d:boolean;
signal cf_low_i,cf_high_i:signed(WIDTH-1 downto 0);

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

signal first_rise_i:boolean;
signal filtered_int,filtered_0x_reg:signed(WIDTH-1 downto 0);
signal slope_int,slope_0x_reg:signed(WIDTH-1 downto 0);

signal s_t_p_i,p_t_p_i:boolean;
signal rel2min_i,rel2min_d:boolean;
signal minima,cf_min:signed(WIDTH-1 downto 0);

signal cfd_low_t_d,cfd_high_t_d:signed(WIDTH-1 downto 0);
signal will_cross_d,will_arm_d:boolean;
signal p_t_n_i:boolean;
signal pending:integer;
signal first_rise_d:boolean;
signal cf_error_i:boolean;
signal cfd_error_d:boolean;
signal cf_error_d:boolean;
signal max_int:boolean;

--DEBUGING
--constant DEBUG:boolean:=FALSE;
--signal wr_count,rd_count:unsigned(WIDTH-1 downto 0);
--signal CFD_valid:boolean;
--signal CFD_error:boolean;

begin
--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
--FIXME check underflow when min-max less than FWFT? 

--LAT 0 is at input
slope0xing:entity crossing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => s,
  threshold => (others => '0'),
  signal_out => slope_0x, --lat 0
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
  else
    filtered_0x <= f;
    if slope_0_p then
      started <= TRUE;
      reg <= registers; --capture the register settings each minima
    end if;
    slope_0x_reg <= slope_0x; --lat 1
    filtered_0x_reg <= filtered_0x; --lat 1
  end if;
end if;
end process thresholding;
p_thresh_i <= signed('0' & reg.pulse_threshold); -- used for pulse area in meas
slope_threshold_int <= signed('0' & reg.slope_threshold); --input stage only
cf_int <= signed('0' & reg.constant_fraction); --input stage only
rel2min_i <= reg.cfd_rel2min; -- used for height in meas

slopeTxing:entity crossing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_0x_reg, 
  threshold => slope_threshold_int, 
  signal_out => slope_int, --lat 2
  pos => s_t_p_i, --lat 2
  neg => open,
  above => open
);

filteredTxing:entity crossing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_0x_reg,
  threshold => p_thresh_i, 
  signal_out => filtered_int, --lat 2
  pos => p_t_p_i,
  neg => p_t_n_i,
  above => above_i --lat 2
);

pipeline:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      armed_i <= FALSE;
      first_rise_i <= FALSE;
      delay_counter <= 0;
      pending <= 0;
    else
      
      --counter to track queue pending  
      if q_wr_en='1' and q_rd_en='0' then
        pending <= pending + 1;
      end if;
      if q_rd_en ='1' and q_wr_en='0' then
        pending <= pending - 1;
      end if;
      -- s_0_x LAT 0
      s_0_n_pipe <= (slope_0_n and started) & s_0_n_pipe(1 to DEPTH-1);
      s_0_p_pipe <= slope_0_p & s_0_p_pipe(1 to DEPTH-1);
      above_pipe(3 to DEPTH) <= above_i & above_pipe(3 to DEPTH-1);
      
      if s_0_p_pipe(2) and not above_i then
        first_rise_i <= TRUE; --lat 3
      elsif s_0_n_pipe(3) then
        first_rise_i <= FALSE;
      end if; 
      first_rise_pipe(4 to DEPTH) 
        <= first_rise_i & first_rise_pipe(4 to DEPTH-1);
      
      p_t_p_pipe(3 to DEPTH) <= p_t_p_i & p_t_p_pipe(3 to DEPTH-1);
      p_t_n_pipe(3 to DEPTH) <= p_t_n_i & p_t_n_pipe(3 to DEPTH-1);
      s_t_p_pipe(3 to DEPTH) <= s_t_p_i & s_t_p_pipe(3 to DEPTH-1);
      
      filtered_pipe(3 to DEPTH) <= filtered_int & filtered_pipe(3 to DEPTH-1);
      slope_pipe(3 to DEPTH) <= slope_int & slope_pipe(3 to DEPTH-1);
      
      if s_t_p_i then
        armed_i <= TRUE; -- lat 3
      elsif s_0_n_pipe(3) then
        armed_i <= FALSE;
      end if; 
      armed_pipe(4 to DEPTH) <= armed_i & armed_pipe(4 to DEPTH-1);
      
      -- need first peak
      if s_0_p_pipe(3) then
        minima <= filtered_pipe(3); --lat 4
        if rel2min_i or not first_rise_i then -- or not first peak
          cf_min <= filtered_pipe(3); --lat 4
        else
          cf_min <= (others => '0');
        end if;
      end if;
      minima_pipe(5 to DEPTH) <= minima & minima_pipe(5 to DEPTH-1);
      
      if s_0_p_pipe(DEPTH-1) then 
        delay_counter <= 0;
        overrun_i <= FALSE; --useable at DEPTH
      else
        if not overrun_i then
          overrun_i <= delay_counter = DELAY-4; --FWFT time = 4
          delay_counter <= delay_counter+1;
        end if;
      end if;
     
      if s_0_p_pipe(DEPTH-1) then
        max_slope_i <= slope_pipe(DEPTH-1);
      else
        if slope_pipe(DEPTH-1) > max_slope_i then
          max_slope_i <= slope_pipe(DEPTH-1);
        end if;
      end if;
      
      --p = cf * (filtered - minima) valid @DEPTH-1
      --NOTE:no rounding is done by the constant fraction entity but
      --truncation=rounding for the thresholds in valid rises as they are always 
      --positive
      cf_error_i <= FALSE;
      if first_rise_pipe(DEPTH-1) then
        cf_low_i <= p;
        cf_error_i <= p < minima_pipe(DEPTH-1);
      else
        cf_low_i <= p + minima_pipe(DEPTH-1);
      end if;
      cf_high_i <= filtered_pipe(DEPTH-1) - p; 
    end if;
  end if;
end process pipeline;

--latency 5
--cf*(sig-min)
cfCalc:entity dsp.constant_fraction
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC
 
)
port map(
  clk => clk,
  reset => reset,
  min => cf_min,
  cf => cf_int,
  sig => filtered_pipe(4), 
  p => p -- constant fraction of the rise above minimum
);

--------------------------------------------------------------------------------
-- input to delays and queue
--------------------------------------------------------------------------------
full_i <= q_full = '1';
flags_i <= FALSE & cf_error_i & 
           s_0_n_pipe(DEPTH) & s_0_p_pipe(DEPTH) & armed_pipe(DEPTH) & 
           above_pipe(DEPTH) & p_t_p_pipe(DEPTH) & p_t_n_pipe(DEPTH) & 
           s_t_p_pipe(DEPTH);
           
cf_data(WIDTH-1 downto 0) <= std_logic_vector(cf_low_i);
cf_data(2*WIDTH-1 downto WIDTH) <= std_logic_vector(cf_high_i);
cf_data(3*WIDTH-1 downto 2*WIDTH) <= std_logic_vector(max_slope_i);
cf_data(4*WIDTH-1 downto 3*WIDTH) <= std_logic_vector(p_thresh_i);
cf_data(4*WIDTH) <= to_std_logic(overrun_i); 
cf_data(4*WIDTH+1) <= to_std_logic(armed_pipe(DEPTH)); 
cf_data(4*WIDTH+2) <= to_std_logic(above_pipe(DEPTH)); 
cf_data(4*WIDTH+3) <= to_std_logic(first_rise_pipe(DEPTH)); 
cf_data(4*WIDTH+4) <= to_std_logic(rel2min_i); 
cf_data(4*WIDTH+5) <= to_std_logic(cf_error_i); 
cf_data(71 downto 4*WIDTH+6) <= (others => '0'); 

q_reset <= reset;
q_wr_en <= to_std_logic(s_0_n_pipe(DEPTH));
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
cf_error_d <= to_boolean(flags_d(7)); -- filtered0_pos
max_d <= to_boolean(flags_d(6)); --slope0_neg
min_d <= to_boolean(flags_d(5)); --slope0_pos
armed_d <= to_boolean(flags_d(4));
above_pulse_threshold_d <= to_boolean(flags_d(3));
pulse_threshold_pos_d <= to_boolean(flags_d(2));
pulse_threshold_neg_d <= to_boolean(flags_d(1));
slope_threshold_pos_d <= to_boolean(flags_d(0));

cfd_low_t_d <= signed(q_dout(WIDTH-1 downto 0));
cfd_high_t_d <= signed(q_dout(2*WIDTH-1 downto WIDTH));
max_slope_d <= signed(q_dout(3*WIDTH-1 downto 2*WIDTH));
p_thresh_d <= q_dout(4*WIDTH-1 downto 3*WIDTH);
overrun_d <= to_boolean(q_dout(4*WIDTH));
will_arm_d <= to_boolean(q_dout(4*WIDTH+1));
will_cross_d <= to_boolean(q_dout(4*WIDTH+2));
first_rise_d <= to_boolean(q_dout(4*WIDTH+3));
rel2min_d <= to_boolean(q_dout(4*WIDTH+4));
cfd_error_d <= to_boolean(q_dout(4*WIDTH+5));


filtered0xing:entity crossing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(filtered_d),
  threshold => (others => '0'),
  signal_out => f_out,
  extrema => open,
  pos => f_0_p,
  neg => f_0_n,
  xing => f_0_x,
  above => open
);

--------------------------------------------------------------------------------
-- output registers
--------------------------------------------------------------------------------
max <= max_int;
registers_out <= reg_d;
outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    --full_d <= FALSE;
    cfd_valid <= FALSE;
    cfd_overrun <= FALSE;
    rise_start <= FALSE;
    valid_rise <= FALSE;
    pulse_start <= FALSE;
    will_arm <= FALSE;
    will_cross <= FALSE;
    q_rd_en <= '0';
  else
    s_out <= signed(slope_d);
    max_int <= max_d;
    min <= min_d;
    s_0_x <= min_d or max_d;
    armed <= armed_d;
    above <= above_pulse_threshold_d;
    p_t_p <= pulse_threshold_pos_d;
    p_t_n <= pulse_threshold_neg_d;
    p_t_x <= pulse_threshold_neg_d or pulse_threshold_pos_d;
    s_t_p <= slope_threshold_pos_d;
    
    rise_start <= FALSE;
    pulse_start <= FALSE;
    cfd_error <= FALSE;
    if not started then
      reg_d <= registers;
    end if;
    q_rd_en <= '0';
    if min_d and q_empty='0' and not overrun_d then
      will_arm <= will_arm_d;
      will_cross <= will_cross_d;
      rise_start <= will_arm_d and will_cross_d;
      cfd_low <= cfd_low_t_d;
      cfd_high <= cfd_high_t_d;
      max_slope <= max_slope_d;
      q_rd_en <= '1';
      cfd_error <= cfd_error_d;
      cfd_valid <= not cfd_error_d;
      first_rise <= first_rise_d;
      --recapture registers if pulse_start
      if will_arm_d and will_cross_d then
        if first_rise_d then
          if reg_d.timing=CFD_LOW_TIMING_D or reg_d.height=CFD_HIGH_D or 
             reg_d.height=CFD_HEIGHT_D then
            pulse_start <= not cfd_error_d;
            valid_rise <= not cfd_error_d;
          else
            pulse_start <= TRUE;
            valid_rise <= TRUE;
          end if;
          reg_d <= reg;
          reg_d.pulse_threshold <= unsigned(p_thresh_d(WIDTH-2 downto 0));
          reg_d.cfd_rel2min <= rel2min_d;
        else
          valid_rise <= TRUE;
        end if;
      end if;
    elsif max_int then 
      will_arm <= FALSE;
      will_cross <= FALSE;
      valid_rise <= FALSE;
      first_rise <= FALSE;
      cfd_valid <= FALSE;
    end if;
    
    cfd_overrun <= FALSE;
    if q_empty='0' and overrun_d and q_rd_en='0' then
      q_rd_en <= '1';
      cfd_overrun <= TRUE;
    end if;
      
  end if;
end if;
end process outputReg;

end architecture RTL;