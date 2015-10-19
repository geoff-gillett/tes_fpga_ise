--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:10/01/2014 
--
-- Design Name: TES_digitiser
-- Module Name: sample_history
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
--FIXME this is plain ugly--use CE? --NOTE probably needs series 7 part
entity average is
generic(
  ADDRESS_BITS:integer:=4;
  DATA_BITS:integer:=14;
  SIGNED_DATA:boolean:=FALSE
);
port (
  clk:in std_logic;
  reset:in std_logic;
  n:in unsigned(bits(ADDRESS_BITS) downto 0); --av over 2^n
  n_updated:in boolean;
  data_in:in std_logic_vector(DATA_BITS-1 downto 0);
  enable:in boolean;
  average:out std_logic_vector(DATA_BITS-1 downto 0);
  valid:out boolean;
  newvalue:out boolean
);
end entity average;
--
architecture box of average is
signal sum:signed(ADDRESS_BITS+DATA_BITS downto 0):=(others => '0');
signal diff:signed(DATA_BITS downto 0):=(others => '0');
signal average_int:signed(ADDRESS_BITS+DATA_BITS downto 0);
signal data_add,data_remove:std_logic_vector(DATA_BITS-1 downto 0);
signal delay:unsigned(ADDRESS_BITS downto 0);
signal hold:unsigned(ADDRESS_BITS downto 0);
signal delay_valid,delay_updated,delay_valid_reg:boolean;
signal ring_newvalue,newvalue_int,newdiff,newsum:boolean;
type FSMstate is (INIT,FIRST,DIFFWAIT,ACCUMULATE,RUN);
signal state,nextstate:FSMstate;
signal valid_int:boolean;
begin
--
outputReg:process(clk)
begin
if rising_edge(clk) then
  valid <= valid_int;
  newvalue <= newvalue_int;
  if valid_int then
    average <= to_std_logic(average_int(DATA_BITS-1 downto 0));
  else
    average <= data_add;
  end if;
end if;
end process outputReg;
--
ringBuffer:entity teslib.ring_buffer
generic map(
	ADDRESS_BITS => ADDRESS_BITS,
	DATA_BITS => DATA_BITS
)
port map(
	clk => clk,
  reset => reset,
  wr_en => enable,
  data_in => std_logic_vector(data_in),
  zerodelay => data_add,
  delayed => data_remove,
  delay => delay,
  delay_updated => delay_updated,
  newvalue  => ring_newvalue,
  valid => delay_valid
);
--
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
FSMtransition:process(state,ring_newvalue,delay_valid,hold)
begin
nextstate <= state;
case state is 
when INIT =>
  if ring_newvalue and delay_valid then
    nextstate <= FIRST;
  end if;
when FIRST =>
  if not delay_valid then
    nextstate <= INIT;
  elsif hold=0 or ring_newvalue then
    nextstate <= DIFFWAIT;
  end if;
when DIFFWAIT => 
  if not delay_valid then
    nextstate <= INIT;
  elsif hold=0 then
    nextstate <= RUN;
  else
    nextstate <= ACCUMULATE;
  end if;
when ACCUMULATE =>
  if not delay_valid then
    nextstate <= INIT;
  elsif hold=0 then
    nextstate <= RUN;
  end if;
when RUN =>
  if not delay_valid then
    nextstate <= INIT;
  end if;
end case;  
end process FSMtransition;
--
FSMoutput:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    hold <= (others => '0');
    valid_int <= FALSE;
    newvalue_int <= FALSE;
  else
    newvalue_int <= FALSE;
    case nextstate is 
    when INIT =>
   	  hold <= shift_left(to_unsigned(1,ADDRESS_BITS+1),to_integer(n));
   	  valid_int <= FALSE;
   	when FIRST => 
   	  if ring_newvalue then
   	    hold <= hold-1;
   	  end if;
      if SIGNED_DATA then
        sum <= resize(signed(data_add),ADDRESS_BITS+DATA_BITS+1);
      else
        sum <= resize(signed('0' & data_add),ADDRESS_BITS+DATA_BITS+1);
      end if;
    when DIFFWAIT => 
      null;
    when ACCUMULATE =>
      if hold=0 and newdiff then
        sum <= sum+diff;
      elsif ring_newvalue then
   	    hold <= hold-1;
        if SIGNED_DATA then
          sum <= sum+signed(data_add);
        else
          sum <= sum+signed('0' & data_add);
        end if;
      end if;
    when RUN =>
      if newdiff then
        sum <= sum+diff;
      end if;
      newvalue_int <= newsum;
      if newsum then
        valid_int <= TRUE;
      end if;
    end case;
  end if;
end if;
end process FSMoutput;
--		       
pipeline:process(clk)
--variable average:signed(ADDRESS_BITS+DATA_BITS downto 0);
begin
if rising_edge(clk) then
  if reset = '1' then 
 		delay <= shift_left(to_unsigned(1,ADDRESS_BITS+1),to_integer(n));
 		delay_updated <= TRUE;
  else
 	  delay <= shift_left(to_unsigned(1,ADDRESS_BITS+1),to_integer(n));
 		delay_updated <= n_updated;
    delay_valid_reg <= delay_valid;
    newdiff <= ring_newvalue;
    newsum <= newdiff;
    if SIGNED_DATA then
      diff <= resize(signed(data_add),DATA_BITS+1)
              - resize(signed(data_remove),DATA_BITS+1);
    else
      diff <= signed('0' & data_add)-signed('0' & data_remove);
    end if;
    average_int <= shift_right(sum,to_integer(n));
--    average_int 
--      <= to_std_logic(resize(average,DATA_BITS));
  end if;
end if;
end process pipeline;
end architecture box;
