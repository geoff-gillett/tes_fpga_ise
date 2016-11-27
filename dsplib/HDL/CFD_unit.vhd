library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

entity CFD_unit is
generic(
  WIDTH:integer:=18;
  CFD_DELAY:integer:=1020
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  
  raw:in signed(WIDTH-1 downto 0);
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  constant_fraction:in signed(WIDTH-1 downto 0);
  --rel2min:in boolean;
  slope_threshold:in signed(WIDTH-1 downto 0);
  pulse_threshold:in signed(WIDTH-1 downto 0);
  
  low_rising:out boolean; 
  low_falling:out boolean; 
  high_rising:out boolean; 
  high_falling:out boolean;
  max_slope:out boolean; 
  cfd_error:out boolean;
  
  raw_out:out signed(WIDTH-1 downto 0);
  slope_out:out signed(WIDTH-1 downto 0);
  filtered_out:out signed(WIDTH-1 downto 0);
  max:out boolean;
  min:out boolean;
  valid_peak:out boolean -- max following min crosses both thresholds
);
end entity CFD_unit;

architecture RTL of CFD_unit is
  
--constant RAW_CFD_DELAY:integer:=256;
constant DEPTH:integer:=8;

component cf_queue
port (
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(53 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(53 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;

type pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

-- pipelines to sync signals
signal f_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal s_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal s_out_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal slope_neg_p,slope_pos_p:boolean_vector(1 to DEPTH):=(others => FALSE);
signal slope_pos_thresh_p:boolean_vector(1 to DEPTH):=(others => FALSE);

signal slope_pos,slope_neg:boolean;
signal raw_d,filtered_d,filtered_d_reg,slope_d
       :std_logic_vector(WIDTH-1 downto 0);

signal cf_data,q_dout:std_logic_vector(3*WIDTH-1 downto 0);
signal cf_int:signed(WIDTH-1 downto 0):=(others => '0');
signal cfd_low_threshold,cfd_high_threshold:signed(WIDTH-1 downto 0)
       :=(others => '0');
signal q_full,q_empty:std_logic;
signal q_rd_en,q_wr_en:std_logic:='0';

--minimum sig value
signal p:signed(WIDTH-1 downto 0);
signal cfd_low_i,cfd_high_i:signed(WIDTH-1 downto 0);
signal min_cfd:boolean;
signal max_cfd:boolean;

type CFDstate is (BOOT_S,WAIT_S,INIT_S,IDLE_S,ARMED_S,ERROR_S);
signal cfd_state:CFDstate;
constant INIT_COUNT_BITS:integer:=ceilLog2(CFD_DELAY-9);
signal init_count:unsigned(INIT_COUNT_BITS-1 downto 0);

signal slope_cfd:signed(WIDTH-1 downto 0);
signal slope_pos_thresh:boolean;
signal slope_neg_thresh:boolean;

signal slope_i:signed(WIDTH-1 downto 0);
signal armed,above:boolean;
signal slope_threshold_int:signed(WIDTH-1 downto 0);
signal pulse_threshold_int:signed(WIDTH-1 downto 0);
signal valid_peak_int:boolean;
signal q_reset:std_logic:='0';
signal q_error,cfd_error_int:boolean:=FALSE;

signal min_p,max_p,valid_peak_p:boolean_vector(1 to DEPTH);
signal max_slope_int,max_slope_threshold:signed(WIDTH-1 downto 0);
--signal flags,flags_d:std_logic_vector(7 downto 0);

begin

--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
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
  pos => slope_pos,
  neg => slope_neg
);

slopeTxing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => slope,
  signal_out => slope_i,
  threshold => slope_threshold_int,
  pos => slope_pos_thresh,
  neg => slope_neg_thresh
);

cfCalc:entity work.constant_fraction
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  min => (others => '0'),
  cf => cf_int,
  sig => f_pipe(1), --FIXME is this the right latency?
  p => p -- constant fraction of the rise above minimum
);

cfReg:process(clk)
begin
  if rising_edge(clk) then
    if reset1='1' then
      cf_int <= (others => '0');
      f_pipe <= (others => (others => '0'));
      s_pipe <= (others => (others => '0'));
      slope_neg_p <= (others => FALSE);
      slope_pos_p <= (others => FALSE);
      slope_pos_thresh_p <= (others => FALSE);
      cf_int <= (others => '0');
      slope_threshold_int <= (WIDTH-1 => '0', others => '1');
      pulse_threshold_int <= (WIDTH-1 => '0', others => '1');
      q_error <= FALSE;
    else
      
      f_pipe <= filtered & f_pipe(1 to DEPTH-1);
      s_pipe <= slope & s_pipe(1 to DEPTH-1);
      slope_neg_p <= slope_neg & slope_neg_p(1 to DEPTH-1);
      slope_pos_p <= slope_pos & slope_pos_p(1 to DEPTH-1);
      slope_pos_thresh_p 
        <= slope_pos_Thresh & slope_pos_thresh_p(1 to DEPTH-1);
            
      
      -- slope_i = s_pipe(4)
      if slope_pos then --s_pipe(4)
        cf_int <= constant_fraction;
        slope_threshold_int <= slope_threshold;
        pulse_threshold_int <= pulse_threshold;
      end if; 
      
      if slope_pos_thresh_p(1) then
        armed <= TRUE; -- aligned to pipe(6)
      elsif slope_neg_p(2) then
        armed <= FALSE;
      end if;
      
      if slope_pos_p(1) then
        max_slope_int <= s_pipe(5);
      else
        if s_pipe(5) > max_slope_int then
          max_slope_int <= s_pipe(5);
        end if;
      end if;
      
      above <= f_pipe(5) >= pulse_threshold_int; -- aligned to pipe(6)
      
      cfd_low_i <= p;
      cfd_high_i <= f_pipe(5) - p; -- Correct latency 
      
      --FIXME need a reset signal to be sent to end of delay 
      q_error <= FALSE;
      q_wr_en <= '0';
      --FIXME this is bullshit
      if slope_neg_p(1) and 
         (cfd_state/=BOOT_S or cfd_state/=INIT_S or cfd_state/=WAIT_S) then
        if q_full='0' then
          q_wr_en <= '1';
          q_error <= FALSE;
        else
          q_wr_en <= '0';
          q_error <= TRUE;
        end if;
      end if;
     
    end if;
  end if;
end process cfReg;

--------------------------------------------------------------------------------
-- CFD delays
--------------------------------------------------------------------------------
-- queue  at max
-- if full there is a problem 
-- need to make queue deep enough in relation to cf_delay so that it can never 
-- fill up

assert q_full='0' 
report "Threshold queue full" severity ERROR;

-- can safely remove MSBs as all values will be positive
cf_data(WIDTH-2 downto 0) <= std_logic_vector(cfd_low_i(WIDTH-2 downto 0));
cf_data(WIDTH-1) <= to_std_logic(armed);
cf_data(2*WIDTH-2 downto WIDTH) 
  <= std_logic_vector(cfd_high_i(WIDTH-2 downto 0));
cf_data(2*WIDTH-1) <= to_std_logic(above);
cf_data(3*WIDTH-1 downto 2*WIDTH) <= std_logic_vector(max_slope_int);

q_reset <= '1' when cfd_state=BOOT_S else '0';
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

-- FIXME add a delay for flags
-- Need a ready flag, 

--flagDelay:entity work.sdp_bram_delay
--generic map(
--  DELAY => CFD_DELAY,
--  WIDTH => 8
--)
--port map(
--  clk => clk,
--  input => std_logic_vector(flags),
--  delayed => flags_d
--);

rawDelay:entity work.sdp_bram_delay
generic map(
  DELAY => CFD_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(raw),
  delayed => raw_d
);
raw_out <= signed(raw_d);

fiteredDelay:entity work.sdp_bram_delay
generic map(
  DELAY => CFD_DELAY-5,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(filtered),
  delayed => filtered_d
);

slopeDelay:entity work.sdp_bram_delay
generic map(
  DELAY => CFD_DELAY-8,
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
  pos => min_cfd,
  neg => max_cfd,
  pos_closest => open,
  neg_closest => open
);

CFDFSM:process (clk) is
begin
  if rising_edge(clk) then
    if reset1 = '1' then
      q_rd_en <= '0';
      filtered_d_reg <= (others => '0');
      s_out_pipe <= (others => (others => '0'));
      cfd_state <= BOOT_S;
      cfd_error_int <= TRUE;
    else
      s_out_pipe <= slope_cfd & s_out_pipe(1 to DEPTH-1);
      filtered_d_reg <= filtered_d;
      
      min_p <= min_cfd & min_p(1 to DEPTH-1);
      max_p <= max_cfd & max_p(1 to DEPTH-1);
      valid_peak_p <= valid_peak_int & valid_peak_p(1 to DEPTH-1);
      
      case cfd_state is 
      when BOOT_S => 
        init_count <= to_unsigned(CFD_DELAY-10,INIT_COUNT_BITS); 
        cfd_state <= WAIT_S; 
        cfd_error_int <= TRUE;
      when WAIT_S =>  -- wait for min at start of delay
        if slope_pos then
          cfd_state <= INIT_S;
        end if;
      when INIT_S => -- wait for min to traverse delay
        if init_count=0 then
          cfd_state <= IDLE_S;
          cfd_error_int <= FALSE;
        else
          init_count <= init_count-1;
        end if;
      when IDLE_S => -- normal operation
        if q_error then
          cfd_state <= BOOT_S;
        elsif min_cfd then
          if q_empty='1' then
            cfd_state <= ERROR_S;
            cfd_low_threshold <= signed(filtered_d);
            cfd_high_threshold <= signed(filtered_d);
            max_slope_threshold <= signed(slope_cfd);
            valid_peak_int <= FALSE;
            cfd_error_int <= TRUE;
          else
            cfd_state <= ARMED_S;
            cfd_high_threshold <= signed('0' & q_dout(2*WIDTH-2 downto WIDTH));
            cfd_low_threshold <= signed('0' & q_dout(WIDTH-2 downto 0));
            max_slope_threshold <= signed(q_dout(3*WIDTH-1 downto 2*WIDTH));
            valid_peak_int <= (q_dout(2*WIDTH-1)='1' and q_dout(WIDTH-1)='1');
          end if;
        end if;
            
      --TODO check this works on error
      q_rd_en <= '0';
      when ARMED_S | ERROR_S =>
        if q_error then
          cfd_state <= BOOT_S;
        elsif max_cfd then
          cfd_error_int <= FALSE;
          cfd_state <= IDLE_S;
          q_rd_en <= '1';
        end if;         
        
      end case;
      valid_peak <= valid_peak_p(2) and not cfd_error_int;
    end if;
  end if;
end process CFDFSM;
cfd_error <= cfd_error_int;
--slope_out <= s_out_pipe(4); --FIXME can remove pipe?
max <= max_p(4);
min <= min_p(4);

slopeMax:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => signed(slope_cfd),
  signal_out => slope_out,
  threshold => max_slope_threshold,
  pos => max_slope,
  neg => open,
  pos_closest => open,
  neg_closest => open
);

cfdLowThreshXing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => signed(filtered_d_reg),
  signal_out => filtered_out,
  threshold => cfd_low_threshold,
  pos => low_rising,
  neg => low_falling,
  pos_closest => open,
  neg_closest => open
);

cfdHighThreshXing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  signal_in => signed(filtered_d_reg),
  signal_out => open,
  threshold => cfd_high_threshold,
  pos => high_rising,
  neg => high_falling,
  pos_closest => open,
  neg_closest => open
);

end architecture RTL;