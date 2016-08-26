library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

entity measure is
generic(WIDTH:integer:=18);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  constant_fraction:in unsigned(16 downto 0);
  raw:in signed(WIDTH-1 downto 0);
  slope:in signed(WIDTH-1 downto 0);
  filtered:in signed(WIDTH-1 downto 0);
  
  raw_out:out signed(WIDTH-1 downto 0);
  filtered_out:out signed(WIDTH-1 downto 0);
  slope_out:out signed(WIDTH-1 downto 0)
);
end entity measure;

architecture RTL of measure is

constant RAW_CFD_DELAY:integer:=32;
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
signal s_pipe:pipe(1 to DEPTH):=(others => (others => '0'));
signal max_pipe,min_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);

signal min,max:boolean;
signal slope_cfin:signed(WIDTH-1 downto 0):=(others => '0');
signal raw_d,filtered_d,slope_d:std_logic_vector(WIDTH-1 downto 0);

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
signal min_cfd : boolean;
signal max_cfd : boolean;

begin

--------------------------------------------------------------------------------
-- Constant fraction calculation
--------------------------------------------------------------------------------
  
pipelines:process(clk)
begin
  if rising_edge(clk) then
    if reset='0' then
      f_pipe(1) <= filtered;
      f_pipe(2 to DEPTH) <= f_pipe(1 to DEPTH-1);
      s_pipe(1) <= slope_cfin;
      s_pipe(2 to DEPTH) <= s_pipe(1 to DEPTH-1);
      max_pipe(1) <= max;
      max_pipe(2 to DEPTH) <= max_pipe(1 to DEPTH-1);
      min_pipe(1) <= min;
      min_pipe(2 to DEPTH) <= min_pipe(1 to DEPTH-1);
    end if;
  end if;
end process pipelines;
  
slope0xing:entity work.closest0xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope,
  signal_out => open,
  pos_xing => min,
  neg_xing => max
);

cfCalc:entity work.constant_fraction
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  min => min_in,
  cf => cf_int,
  sig => f_pipe(1),
  p => p -- constant fraction of the rise above minimum
);

cfReg:process(clk)
begin
  if rising_edge(clk) then
    
    if min then
      min_in <= filtered;   --minima into cf pipeline
      cf_int <= signed('0' & constant_fraction);
    end if; 
          
    if min_pipe(4) then
      min_out <= f_pipe(4); --minima at output of cf pipeline
    end if;
    
    cfd_low <= p + min_out;
    cfd_high <= f_pipe(5) - p;

  end if;
end process cfReg;

-- low & high thresholds for queue
thresholds <= std_logic_vector(cfd_low) & std_logic_vector(cfd_high);
--------------------------------------------------------------------------------
-- CFD delays
--------------------------------------------------------------------------------
-- queue thresholds at max
-- if full there is a problem 
-- need to make queue deep enough in relation to cf_delay so that it can never 
-- fill up

assert q_full='0' 
report "Threshold queue full" severity ERROR;

q_wr_en <= '1' when max_pipe(7) else '0';
threshold_queue:cf_queue
port map (
  clk => clk,
  srst => reset,
  din => thresholds,
  wr_en => q_wr_en,
  rd_en => q_rd_en,
  dout => q_dout,
  full => q_full,
  empty => q_empty
);

cfd_low_threshold <= signed(q_dout(2*WIDTH-1 downto WIDTH));
cfd_high_threshold <= signed(q_dout(WIDTH-1 downto 0));

rawDelay:entity work.sdp_bram_delay
generic map(
  DELAY => RAW_CFD_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(raw),
  delayed => raw_d
);

fiteredDelay:entity work.sdp_bram_delay
generic map(
  DELAY => RAW_CFD_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(filtered),
  delayed => filtered_d
);

slopeDelay:entity work.sdp_bram_delay
generic map(
  DELAY => RAW_CFD_DELAY,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(slope),
  delayed => slope_d
);


--------------------------------------------------------------------------------
-- Measurement
--------------------------------------------------------------------------------

cfdSlope0xing:entity work.closest0xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(slope_d),
  signal_out => slope_cfin,
  pos_xing => min_cfd,
  neg_xing => max_cfd
);
end architecture RTL;
