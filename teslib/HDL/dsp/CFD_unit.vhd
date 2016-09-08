library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

entity CFD_unit is
generic(
  WIDTH:integer:=18;
  CFD_DELAY:integer:=1027
);
port (
  clk:in std_logic;
  reset1:in std_logic;
  reset2:in std_logic;
  
  raw:in signed(WIDTH-1 downto 0);
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  constant_fraction:in unsigned(16 downto 0);
  rel2min:in boolean;
  
  cfd_low:out boolean;
  cfd_high:out boolean;
  cfd_error:out boolean;
  
  raw_out:out signed(WIDTH-1 downto 0);
  slope_out:out signed(WIDTH-1 downto 0);
  filtered_out:out signed(WIDTH-1 downto 0)
);
end entity CFD_unit;

architecture RTL of CFD_unit is
  
--constant RAW_CFD_DELAY:integer:=256;
constant DEPTH:integer:=8;

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
--signal s_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal s_out_pipe:pipe(1 to 4):=(others => (others => '0'));
signal max_pipe,min_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);

signal min,max:boolean;
signal raw_d,filtered_d,filtered_d_reg,slope_d
       :std_logic_vector(WIDTH-1 downto 0);

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
signal cfd_low_int,cfd_high_int:signed(WIDTH-1 downto 0);
signal min_cfd:boolean;
signal max_cfd:boolean;

type CFDstate is (CFD_IDLE_S,CFD_ARMED_S,CFD_ERROR_S);
signal cfd_state:CFDstate;
signal slope_cfd:signed(WIDTH-1 downto 0);
signal rel2min_reg:boolean;

begin

--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
  
inputPipelines:process(clk)
begin
  if rising_edge(clk) then
    if reset1='1' then
      f_pipe <= (others => (others => '0'));
      --s_pipe <= (others => (others => '0'));
      max_pipe <= (others => FALSE);
      min_pipe <= (others => FALSE);
    else
      f_pipe <= filtered & f_pipe(1 to DEPTH-1);
      --s_pipe <= slope & s_pipe(1 to DEPTH-1);
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
  pos => min,
  neg => max
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
    if reset1='1' then
      rel2min_reg <= FALSE;
    else
    
      if min then
        if rel2min then
          min_in <= f_pipe(3);   --minima into cf pipeline
        else
          min_in <= (others => '0');
        end if;
        cf_int <= signed('0' & constant_fraction);
        rel2min_reg <= rel2min; --FIXME add pipe
      end if; 
            
      if min_pipe(4) then
        if rel2min_reg then
          min_out <= f_pipe(7); --minima at output of cf pipeline
        else 
          min_out <= (others => '0');
        end if;
      end if;
      
      cfd_low_int <= p + min_out;
      cfd_high_int <= f_pipe(8) - p;

    end if;
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

thresholds <= std_logic_vector(cfd_low_int) & std_logic_vector(cfd_high_int);
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
  pos => open,
  neg => open,
  pos_closest => min_cfd,
  neg_closest => max_cfd
);

CFDreg:process (clk) is
begin
  if rising_edge(clk) then
    if reset1 = '1' then
      q_rd_en <= '0';
      filtered_d_reg <= (others => '0');
      s_out_pipe <= (others => (others => '0'));
    else
      s_out_pipe <= slope_cfd & s_out_pipe(1 to 3);
      q_rd_en <= '0';
      filtered_d_reg <= filtered_d;
      
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
cfd_error <= cfd_state=CFD_ERROR_S;
slope_out <= s_out_pipe(4);


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
  pos => open,
  neg => open,
  pos_closest => cfd_low,
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
  pos => open,
  neg => open,
  pos_closest => cfd_high,
  neg_closest => open
);

end architecture RTL;
