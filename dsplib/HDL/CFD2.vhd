library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

entity CFD2 is
generic(
  WIDTH:integer:=18;
  DELAY:integer:=1023;
  STRICT_CROSSING:boolean:=TRUE
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  constant_fraction:in signed(WIDTH-1 downto 0);
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
  above_pulse_threshold:out boolean;
  
  filtered_out:out signed(WIDTH-1 downto 0);
  pulse_threshold_pos:out boolean;
  pulse_threshold_neg:out boolean;
  cfd_error:out boolean;
  cfd_valid:out boolean
);
end entity CFD2;

architecture RTL of CFD2 is
  
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
constant DEPTH:integer:=7;

signal started:boolean;
signal slope_0_p,slope_0_n:boolean;
signal cf_int:signed(WIDTH-1 downto 0):=(others => '0');
signal p:signed(WIDTH-1 downto 0);
signal slope_t_p,slope_t_n:boolean;
signal slope_threshold_int:signed(WIDTH-1 downto 0);
signal pulse_threshold_int:signed(WIDTH-1 downto 0);
signal max_slope_i:signed(WIDTH-1 downto 0);
signal pulse_t_p,pulse_t_n:boolean;
-- pipelines
type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

signal filtered_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal minima_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_0_n_pipe,slope_0_p_pipe:boolean_vector(1 to DEPTH)
       :=(others => FALSE);
signal slope_t_p_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal pulse_t_p_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal pulse_t_n_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
--signal overrun_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal slope_x,filtered_x:signed(WIDTH-1 downto 0);
signal delay_counter:natural range 0 to DELAY;
signal overrun_i,armed_i,above_i:boolean;
signal overrun_d,armed_d,above_d:boolean;
signal cfd_low_i,cfd_high_i:signed(WIDTH-1 downto 0);

--------------------------------------------------------------------------------
-- Delay line and queue signals
--------------------------------------------------------------------------------
signal q_reset:std_logic;
signal cf_data:std_logic_vector(71 downto 0);
signal q_wr_en:std_logic;
signal q_rd_en:std_logic;
signal q_dout:std_logic_vector(71 downto 0);
signal q_full:std_logic;
signal q_empty:std_logic;
signal full_i,full_d:boolean;
signal flags_i:boolean_vector(8 downto 0);
signal flags_d,flags_i_s:std_logic_vector(8 downto 0);
signal filtered_d:std_logic_vector(WIDTH-1 downto 0);
signal slope_d:std_logic_vector(WIDTH-1 downto 0);
signal slope_t_p_d,pulse_t_p_d,pulse_t_n_d:boolean;
signal overran:boolean;
signal max_d,min_d,above_pulse_threshold_d,pulse_threshold_pos_d:boolean;
signal pulse_threshold_neg_d,slope_threshold_pos_d:boolean;
signal CFD_error_reg:boolean;
signal q_was_empty:boolean;

--DEBUGING
constant DEBUG:boolean:=FALSE;
signal wr_count,rd_count:unsigned(WIDTH-1 downto 0);
--signal CFD_valid:boolean;
--signal CFD_error:boolean;

begin

--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
slope0xing:entity work.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope,
  threshold => (others => '0'),
  signal_out => slope_x,
  pos => slope_0_p,
  neg => slope_0_n
);

slopeTxing:entity work.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope,
  threshold => slope_threshold_int,
  signal_out => open,
  pos => slope_t_p,
  neg => slope_t_n
);

pulseTxing:entity work.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered,
  threshold => pulse_threshold_int,
  signal_out => filtered_x,
  pos => pulse_t_p,
  neg => pulse_t_n
);

overrun_i <= delay_counter >= DELAY;
pipeline:process (clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      filtered_pipe <= (others => (others => '0'));
      slope_pipe <= (others => (others => '0'));
      slope_0_n_pipe <= (others => FALSE);
      slope_0_p_pipe <= (others => FALSE);
      slope_t_p_pipe <= (others => FALSE);
      pulse_t_p_pipe <= (others => FALSE);
      
      cf_int <= (others => '0');
      slope_threshold_int <= (WIDTH-1 => '0', others => '1');
      pulse_threshold_int <= (WIDTH-1 => '0', others => '1');
      
      armed_i <= FALSE;
      above_i <= FALSE;
      delay_counter <= 0;
      started <= FALSE;
      wr_count <= (others => '0');
    else
      filtered_pipe <= filtered_x & filtered_pipe(1 to DEPTH-1);
      slope_pipe <= slope_x & slope_pipe(1 to DEPTH-1);
      slope_0_n_pipe <= (slope_0_n and started) & slope_0_n_pipe(1 to DEPTH-1);
      slope_0_p_pipe <= slope_0_p & slope_0_p_pipe(1 to DEPTH-1);
      slope_t_p_pipe <= slope_t_p & slope_t_p_pipe(1 to DEPTH-1);
      pulse_t_p_pipe <= pulse_t_p & pulse_t_p_pipe(1 to DEPTH-1);
      pulse_t_n_pipe <= pulse_t_n & pulse_t_n_pipe(1 to DEPTH-1);
      
      if slope_0_p then
        if rel2min then
          minima_pipe <= filtered_x & minima_pipe(1 to DEPTH-1);
        else
          minima_pipe <= to_signed(0,width) & minima_pipe(1 to DEPTH-1);
        end if;
        cf_int <= constant_fraction;
        slope_threshold_int <= slope_threshold;
        pulse_threshold_int <= pulse_threshold;
        started <= TRUE;
      else
        minima_pipe <= minima_pipe(1) & minima_pipe(1 to DEPTH-1);
      end if;
      
      if slope_0_p_pipe(DEPTH) then
        delay_counter <= 1;
      else
        if not overrun_i then
          delay_counter <= delay_counter+1;
        end if;
      end if;
      
      if slope_t_p_pipe(6) then
        armed_i <= TRUE;
      elsif slope_0_n_pipe(7) then
        armed_i <= FALSE;
      end if; 
      
      above_i <= filtered_pipe(6) >= pulse_threshold_int;
      
      if slope_0_p_pipe(6) then
        max_slope_i <= slope_pipe(6);
      else
        if slope_pipe(5) > max_slope_i then
          max_slope_i <= slope_pipe(5);
        end if;
      end if;
      
      cfd_low_i <= p + minima_pipe(DEPTH-1);
      cfd_high_i <= filtered_pipe(DEPTH-1) - p; 
      
      if slope_0_n_pipe(DEPTH-1) then 
        q_wr_en <= '1';
        --if DEBUG then
          wr_count <= wr_count+1;
        --end if;
      else 
        q_wr_en <= '0';
      end if;
      
    end if;
  end if;
end process pipeline;

--latency 5?
cfCalc:entity work.constant_fraction2
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  min => minima_pipe(1),
  cf => cf_int,
  sig => filtered_pipe(1), 
  p => p -- constant fraction of the rise above minimum
);

--------------------------------------------------------------------------------
-- delays and queue
--------------------------------------------------------------------------------
full_i <= q_full = '1';
flags_i <= overrun_i & full_i & slope_0_n_pipe(DEPTH) & 
           slope_0_p_pipe(DEPTH) & armed_i & above_i & pulse_t_p_pipe(DEPTH) & 
           pulse_t_n_pipe(DEPTH) & slope_t_p_pipe(DEPTH);

cf_data(WIDTH-1 downto 0) <= std_logic_vector(cfd_low_i);
cf_data(2*WIDTH-1 downto WIDTH) <= std_logic_vector(cfd_high_i);
cf_data(3*WIDTH-1 downto 2*WIDTH) <= std_logic_vector(wr_count) when DEBUG
                                     else std_logic_vector(max_slope_i);
cf_data(3*WIDTH) <= to_std_logic(overrun_i); 
cf_data(3*WIDTH+1) <= to_std_logic(armed_i); 
cf_data(3*WIDTH+2) <= to_std_logic(above_i); 
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
  DELAY => DELAY-2,
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

--------------------------------------------------------------------------------
-- output registers
--------------------------------------------------------------------------------
outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    overrun_d <= FALSE;
    full_d <= FALSE;
    armed_d <= FALSE;
    above_d <= FALSE;
    pulse_t_p_d <= FALSE;
    pulse_t_n_d <= FALSE;
    slope_t_p_d <= FALSE;
    CFD_error_reg <= FALSE;
    CFD_error <= FALSE;
    CFD_valid <= FALSE;
    q_rd_en <= '0';
    --if DEBUG then 
      rd_count <= (others => '0');
    --end if;
  else
    overrun_d <= to_boolean(flags_d(8));
    overrun <= overrun_d;
    full_d <= to_boolean(flags_d(7)); -- how does this help?
    max_d <= to_boolean(flags_d(6));
    max <= max_d;
    min_d <= to_boolean(flags_d(5));
    min <= min_d;
    armed_d <= to_boolean(flags_d(4));
    armed <= armed_d;
    above_pulse_threshold_d <= to_boolean(flags_d(3));
    above_pulse_threshold <= above_pulse_threshold_d;
    pulse_threshold_pos_d <= to_boolean(flags_d(2));
    pulse_threshold_pos <= pulse_threshold_pos_d;
    pulse_threshold_neg_d <= to_boolean(flags_d(1));
    pulse_threshold_neg <= pulse_threshold_neg_d;
    slope_threshold_pos_d <= to_boolean(flags_d(0));
    slope_threshold_pos <= slope_threshold_pos_d;
    q_rd_en <= '0';
    
    if q_rd_en='1' then
      cfd_low_threshold <= signed(q_dout(WIDTH-1 downto 0));
      cfd_high_threshold <= signed(q_dout(2*WIDTH-1 downto WIDTH));
      max_slope <= signed(q_dout(3*WIDTH-1 downto 2*WIDTH));
      will_arm <= to_boolean(q_dout(3*WIDTH+1));
      will_go_above_pulse_threshold <= to_boolean(q_dout(3*WIDTH+2));
      overran <= to_boolean(q_dout(3*WIDTH));
    end if;
    
    -- read queue at min
    CFD_error_reg <= FALSE;
    q_was_empty <= q_empty='1';
    
    if started and ((flags_d(6)='1' and overran) or flags_d(5)='1' or 
       (min_d and q_was_empty)) then
      q_rd_en <= '1';
      --if DEBUG then
        rd_count <= rd_count+1;
      --end if;
    else
      q_rd_en <= '0';
    end if;
    
    if min_d and q_empty='1' and q_was_empty then
      CFD_error <= TRUE;
      CFD_valid <= FALSE;
    else
      CFD_error <= FALSE;
      if min_d then
        CFD_valid <= TRUE;
      end if;
    end if;
        
  end if;
end if;
end process outputReg;
slope_out <= signed(slope_d);
filtered_out <= signed(filtered_d);

end architecture RTL;