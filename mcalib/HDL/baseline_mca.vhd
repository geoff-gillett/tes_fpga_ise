--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: histogram_unit
-- Project Name: mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library mcalib;

entity baseline_mca is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:natural:=10;
  --width of counters and stream
  COUNTER_BITS:natural:=18;
  TIMECONSTANT_BITS:natural:=32
);
port(
  clk:in std_logic;
  reset:in std_logic;

  timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  
  -- count threshold before most frequent value is used in the average
  count_threshold:in unsigned(COUNTER_BITS-1 downto 0);
  --only include new bins in average not (new bin or new count)
  new_only:in boolean;
  
  sample:in signed(ADDRESS_BITS-1 downto 0);
  sample_valid:in boolean;
  
  estimate_f1:out signed(ADDRESS_BITS downto 0);
  new_estimate:out boolean
);
end entity baseline_mca;
--
architecture most_frequent of baseline_mca is
--------------------------------------------------------------------------------
-- shift register functions
type FSMstate is (INIT,BUFF0,BOTH0,BUFF1,BOTH1);
type CLRstate is (IDLE,BUFF0,BUFF1);
signal state,nextstate:FSMstate;
signal clr_state,clr_nextstate:CLRstate;
signal timer:unsigned(TIMECONSTANT_BITS-1 downto 0);
signal timeout:boolean;
signal address_to_clear:unsigned(ADDRESS_BITS-1 downto 0);
signal clear_done:boolean;
--
signal idle0,idle1:boolean;
signal swap0,swap1:boolean;
signal bin:unsigned(ADDRESS_BITS-1 downto 0);
signal bin_valid0,bin_valid1:boolean;
signal readable0,readable1:boolean;
signal clear0,clear1:boolean;
--
signal mf_bin0,mf_bin1:unsigned(ADDRESS_BITS-1 downto 0);
signal mf0,mf1:unsigned(ADDRESS_BITS-1 downto 0);

signal double_est:signed(ADDRESS_BITS downto 0);
signal new_est:boolean;
signal new_mf_bin0,new_mf_bin1:boolean;
signal mf_count0,mf_count1:unsigned(COUNTER_BITS-1 downto 0);
signal new_mf0,new_mf1,new0,new1,valid0,valid1:boolean;
signal initialised:boolean;
--signal bin_to_read:unsigned(ADDRESS_BITS-1 downto 0);
attribute equivalent_register_removal:string;
attribute equivalent_register_removal of timer:signal is "no";

begin
estimate_f1 <= double_est;  
new_estimate <= new_est;
bin <= unsigned(sample);

buffer0:entity work.mca_buffer3
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS => 64
)
port map(
  clk => clk,
  reset => reset,
  mca_idle => idle0,
  swap => swap0,
  bin => bin,
  bin_valid => bin_valid0,
  out_of_bounds => FALSE,
  most_frequent_bin => mf_bin0,
  new_most_frequent_bin => new_mf_bin0,
  most_frequent_count => mf_count0,
  new_most_frequent => new_mf0,
  total_in_bounds => open,
  readable => readable0,
  last_clear => clear_done,
  clear => clear0,
  bin_to_read => address_to_clear,
  count => open
);

buffer1:entity work.mca_buffer3
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS => 64
)
port map(
  clk => clk,
  reset => reset,
  mca_idle => idle1,
  swap => swap1,
  bin => bin,
  bin_valid => bin_valid1,
  out_of_bounds => FALSE,
  most_frequent_bin => mf_bin1,
  new_most_frequent_bin => new_mf_bin1,
  most_frequent_count => mf_count1,
  new_most_frequent => new_mf1,
  total_in_bounds => open,
  readable => readable1,
  last_clear => clear_done,
  clear => clear1,
  bin_to_read => address_to_clear,
  count => open
);

--------------------------------------------------------------------------------
-- FSM 
--------------------------------------------------------------------------------
FSMnextstate:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= INIT;
      clr_state <= IDLE;
    else
      state <= nextstate;
      clr_state <= clr_nextstate;
    end if;
  end if;
end process FSMnextstate;

FsmTransition:process(
  state,idle1,timeout,idle0,sample_valid,clear_done,clr_state
)
begin
  nextstate <= state;
  clr_nextstate <= clr_state;
  swap0 <= FALSE;
  swap1 <= FALSE;
  case state is
  when INIT =>
    nextstate <= BUFF0;
    swap0 <= TRUE;
    bin_valid1 <= FALSE;
    bin_valid0 <= FALSE;
  when BUFF0 =>
    -- buffer0 active buff1 clearing
    bin_valid0 <= sample_valid;
    bin_valid1 <= FALSE;
    if timeout and idle1 then
      nextstate <= BOTH0;
      swap1 <= TRUE;
    end if;
  when BOTH0 =>
    -- both active buff0 will clear next 
    bin_valid0 <= sample_valid;
    bin_valid1 <= sample_valid;
    if timeout then
      nextstate <= BUFF1;
      clr_nextstate <= BUFF0;
      swap0 <= TRUE;
    end if;
  when BUFF1 =>
    -- buff1 only buff0 clearing
    bin_valid0 <= FALSE;
    bin_valid1 <= sample_valid;
    if timeout and idle0 then
      nextstate <= BOTH1;
      swap0 <= TRUE;
    end if;
  when BOTH1 =>
    -- both active buff1 will clear
    bin_valid0 <= sample_valid;
    bin_valid1 <= sample_valid;
    if timeout then
      nextstate <= BUFF0;
      clr_nextstate <= BUFF1;
      swap1 <= TRUE;
    end if;
  end case;
  if clear_done then
    clr_nextstate <= IDLE;
  end if;
end process;

newMfreg:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      new0 <= FALSE;
      new1 <= FALSE;
      valid0 <= FALSE;
      valid1 <= FALSE;
      mf0 <= (others => '-');
      mf1 <= (others => '-');
    else
      new0 <= FALSE;
      new1 <= FALSE;
      if mf_count0 >= count_threshold then
        valid0 <= TRUE;
        mf0 <= mf_bin0;
        if new_only then
          new0 <= new_mf_bin0;
        else
          new0 <= new_mf0;
        end if;
      end if;
      if mf_count1 >= count_threshold then
        mf1 <= mf_bin1;
        valid1 <= TRUE;
        if new_only then
          new1 <= new_mf_bin1;
        else
          new1 <= new_mf1;
        end if;
      end if;
    end if;
  end if;
end process newMfreg;

FSMoutput:process(clk)
begin
if rising_edge(clk) then
  new_est <= FALSE;
  case state is 
  when INIT =>
      double_est <= (others => '-');
      initialised <= FALSE;
  when BUFF0 =>
    if new0 then
      if valid1 then
        double_est <= resize(signed(mf0),ADDRESS_BITS+1)+signed(mf1);
      else
        double_est <= shift_left(resize(signed(mf0),ADDRESS_BITS+1),1);
      end if;
      new_est <= TRUE;
    end if;
  when BOTH0 => 
    if new0 or new1 then
      double_est <= resize(signed(mf0),ADDRESS_BITS+1)+signed(mf1);
      new_est <= valid0 and valid1;
    end if;
  when BUFF1 =>
    if new1 then
      double_est <= resize(signed(mf0),ADDRESS_BITS+1)+signed(mf1);
      new_est <= valid0 and valid1;
    end if;
  when BOTH1 => 
    if new0 or new1 then
      double_est <= resize(signed(mf0),ADDRESS_BITS+1)+signed(mf1);
      new_est <= valid0 and valid1;
    end if;
  end case;
end if;
end process FSMoutput;

clear_done <= address_to_clear=to_unsigned(2**ADDRESS_BITS-1,ADDRESS_BITS);
clearFSMaddr:process (clk) is
begin
  if rising_edge(clk) then
    case clr_state is 
    when IDLE =>
      address_to_clear <= (others => '0');
    when BUFF0 =>
      if readable0 then
        address_to_clear <= address_to_clear+1;
      end if;
    when BUFF1 =>
      if readable1 then
        address_to_clear <= address_to_clear+1;
      end if;
    end case;
  end if;
end process clearFSMaddr;

clearFSM:process(clr_state,readable0,readable1)
begin
  clear0 <= FALSE;
  clear1 <= FALSE;
  case clr_state is 
  when IDLE =>
    clear0 <= FALSE;
    clear1 <= FALSE;
  when BUFF0 =>
    if readable0 then
      clear1 <= FALSE;
      clear0 <= TRUE;
    end if;
  when BUFF1 =>
    if readable1 then
      clear0 <= FALSE;
      clear1 <= TRUE;
    end if;
  end case;
end process clearFSM;

--------------------------------------------------------------------------------
-- Time
--------------------------------------------------------------------------------
timing:process(clk)
begin
if rising_edge(clk) then
  if state=INIT then
    timer <= (others => '0');
  else
    timeout <= FALSE;
    if timer >= timeconstant then
      timeout <= TRUE;
    end if;
    if swap0 or swap1 then
      timer <= (others => '0');
      timeout <= FALSE;
    elsif not timeout  then
      timer <= timer+1;
    end if;
  end if;
end if;
end process timing;

end architecture most_frequent;
