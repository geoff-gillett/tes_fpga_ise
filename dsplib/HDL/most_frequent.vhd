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
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library mcalib;

--! the distribution is collected in a MCA over 2**TIMECONSTANT clks
--! and the average of the maximum of of the last two distributions is the
--! baseline.
entity most_frequent is
generic(
  --The distributions are acquired over 2**TIMECONSTANT_BITS clks
  --number of bins (channels) = 2**ADDRESS_BITS
  SAMPLE_BITS:integer:=12;
  --width of counters and stream
  COUNTER_BITS:integer:=18;
  TIMECONSTANT_BITS:integer:=32
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  -- max count threshold
  threshold:in unsigned(COUNTER_BITS-1 downto 0);
  sample:in std_logic_vector(SAMPLE_BITS-1 downto 0);
  sample_valid:in boolean;
  --
  most_frequent:out std_logic_vector(SAMPLE_BITS-1 downto 0);
  new_value:out boolean
);
end entity most_frequent;
--
architecture MCA of most_frequent is
--------------------------------------------------------------------------------
constant MIN_TIMECONSTANT:integer:=2**SAMPLE_BITS+8;
--------------------------------------------------------------------------------
-- shift register functions
signal mca_ready:boolean;
type FSMstate is (INIT,WRITE,WAITREADABLE,CLEAR);
signal state,nextstate:FSMstate;
signal timer:unsigned(TIMECONSTANT_BITS-1 downto 0);
signal timeout:boolean;
signal readable:boolean;
signal most_frequent_int:unsigned(SAMPLE_BITS-1 downto 0);
signal max_count:unsigned(COUNTER_BITS-1 downto 0);
signal new_max:boolean;
signal address_to_clear:unsigned(SAMPLE_BITS-1 downto 0);
signal clear_mca:boolean;
signal clear_done:boolean;
--
begin
--
mca:entity mcalib.mca
generic map(
  ADDRESS_BITS => SAMPLE_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS => 1
)
port map(
  clk => clk,
  reset => reset,
  ready => mca_ready,
  bin => unsigned(sample),
  bin_valid => sample_valid,
  overflow => FALSE,
  swap_buffer => timeout,
  readable => readable,
  total => open,
  most_frequent => most_frequent_int,
  max_count => max_count,
  new_max => new_max,
  bin_to_read => address_to_clear,
  read_bin => clear_mca,
  count => open
);
clear_mca <= state=CLEAR;
clear_done <= address_to_clear=to_unsigned((2**SAMPLE_BITS)-1,SAMPLE_BITS);
clearAddress:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    address_to_clear <= (others => '0');
  else
    if clear_done then
      address_to_clear <= (others => '0');
    elsif state=CLEAR then
      address_to_clear <= address_to_clear+1;
    end if;
  end if;
end if;
end process clearAddress;
--------------------------------------------------------------------------------
-- FSM 
--------------------------------------------------------------------------------
FSMnextstate:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= INIT;
    else
      state <= nextstate;
    end if;
  end if;
end process FSMnextstate;
--
FsmTransition:process(clear_done,mca_ready,timeout,readable,state)
begin
  nextstate <= state;
  case state is 
  when INIT =>
    if mca_ready then
      nextstate <= WRITE;
    end if;
  when WRITE =>
    if timeout then
      nextstate <= WAITREADABLE;
    end if;
  when WAITREADABLE =>
    if readable then
      nextstate <= CLEAR;
    end if;
  when CLEAR =>
    if clear_done then
      nextstate <= WRITE;
    end if;
  end case;
end process;
--
outputReg:process(clk)
begin
if rising_edge(clk) then
  if new_max and to_0IfX(max_count) >= threshold then
    most_frequent <= to_std_logic(most_frequent_int);
    new_value <= TRUE;
  else
    new_value <= FALSE;
  end if;
end if;
end process outputReg;
--
--------------------------------------------------------------------------------
-- Time
--------------------------------------------------------------------------------
timeout <= timer=0;
timing:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    if timeconstant<MIN_TIMECONSTANT then
      timer <= to_unsigned(MIN_TIMECONSTANT,TIMECONSTANT_BITS);
    else
      timer <= timeconstant;
    end if;
  else
    if timeout then 
      if timeconstant<MIN_TIMECONSTANT then
        timer <= to_unsigned(MIN_TIMECONSTANT,TIMECONSTANT_BITS);
      else
        timer <= timeconstant;
      end if;
    elsif mca_ready then
      timer <= timer-1;
    end if;
  end if;
end if;
end process timing;
end architecture MCA;
