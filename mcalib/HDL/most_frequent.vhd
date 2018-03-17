--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: histogram_unit
-- Project Name: channel
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

entity most_frequent is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:integer:=12;
  --width of counters and stream
  COUNTER_BITS:integer:=18;
  TIMECONSTANT_BITS:integer:=32
);
port(
  clk:in std_logic;
  reset:in std_logic;

  timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  
  -- count threshold before most frequent value is used in the average
  count_threshold:in unsigned(COUNTER_BITS-1 downto 0);
  sample:in std_logic_vector(ADDRESS_BITS-1 downto 0);
  sample_valid:in boolean;
  
  most_frequent_bin:out unsigned(ADDRESS_BITS-1 downto 0);
  new_most_frequent_bin:out boolean;
  most_frequent_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_most_frequent:out boolean
);
end entity most_frequent;
--
architecture MCA of most_frequent is
-- TODO modify clear so that smaller minimum time constants are possible
-- ie do partial clears threshold needs some thought
--------------------------------------------------------------------------------
-- shift register functions
type FSMstate is (INIT,BUFF0,BUFF1);
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
signal most_frequent_bin0,most_frequent_bin1:unsigned(ADDRESS_BITS-1 downto 0);
signal new_most_frequent_bin0:boolean;
signal new_most_frequent_bin1:boolean;
signal most_frequent_count0:unsigned(COUNTER_BITS-1 downto 0);
signal most_frequent_count1:unsigned(COUNTER_BITS-1 downto 0);
signal new_most_frequent0,new_most_frequent1:boolean;
signal readable0,readable1:boolean;
signal clear0,clear1:boolean;
--signal bin_to_read:unsigned(ADDRESS_BITS-1 downto 0);
attribute equivalent_register_removal:string;
attribute equivalent_register_removal of timer:signal is "no";

begin
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
  most_frequent_bin => most_frequent_bin0,
  new_most_frequent_bin => new_most_frequent_bin0,
  most_frequent_count => most_frequent_count0,
  new_most_frequent => new_most_frequent0,
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
  most_frequent_bin => most_frequent_bin1,
  new_most_frequent_bin => new_most_frequent_bin1,
  most_frequent_count => most_frequent_count1,
  new_most_frequent => new_most_frequent1,
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
    bin_valid0 <= sample_valid;
    bin_valid1 <= FALSE;
    if timeout and idle1 then
      nextstate <= BUFF1;
      clr_nextstate <= BUFF0;
      swap0 <= TRUE;
      swap1 <= TRUE;
    end if;
  when BUFF1 =>
    bin_valid1 <= sample_valid;
    bin_valid0 <= FALSE;
    if timeout and idle0 then
      clr_nextstate <= BUFF1;
      nextstate <= BUFF0;
      swap0 <= TRUE;
      swap1 <= TRUE;
    end if;
  end case;
  if clear_done then
    clr_nextstate <= IDLE;
  end if;
end process;

FSMoutput:process(clk)
begin
if rising_edge(clk) then
  case state is 
  when INIT =>
      most_frequent_bin <= (others => '-');
      new_most_frequent_bin <= FALSE;
      most_frequent_count <= (others => '-');
      new_most_frequent <= FALSE;
  when BUFF0 =>
    if most_frequent_count0 >= count_threshold then
      most_frequent_bin <= most_frequent_bin0;
      new_most_frequent_bin <= new_most_frequent_bin0;
      most_frequent_count <= most_frequent_count0;
      new_most_frequent <= new_most_frequent0;
    end if;
  when BUFF1 =>
    if most_frequent_count1 >= count_threshold then
      most_frequent_bin <= most_frequent_bin1;
      new_most_frequent_bin <= new_most_frequent_bin1;
      most_frequent_count <= most_frequent_count1;
      new_most_frequent <= new_most_frequent1;
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
      clear0 <= TRUE;
      clear1 <= FALSE;
    end if;
  when BUFF1 =>
    if readable1 then
      clear1 <= TRUE;
      clear0 <= FALSE;
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
    timeout <= timer >= timeconstant;
    if swap0 or swap1 then
      timer <= (others => '0');
    elsif not timer >= timeconstant  then
      timer <= timer+1;
    end if;
  end if;
end if;
end process timing;
end architecture MCA;
