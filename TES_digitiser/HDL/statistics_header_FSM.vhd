--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11/04/2014 
--
-- Design Name: TES_digitiser
-- Module Name: statistics_header_FSM
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--
library teslib;
--use TES.events.all;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.types.all;
use streamlib.functions.all;

--TODO add start time to the header
entity statistics_header_FSM is
generic(
  CHANNEL_BITS:integer:=3;
  ADDRESS_BITS:integer:=14;
  COUNTER_BITS:integer:=32;
  VALUES:integer:=8;
  VALUE_BITS:integer:=AREA_BITS+1;
  TOTAL_BITS:integer:=64;
  STREAM_CHUNKS:integer:=2;
  ENDIANNESS:string:="LITTLE" --"BIG" or "LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  -- 
  go:in boolean;
  swap_buffer:in boolean;
  --
  channel_sel:in unsigned(CHANNEL_BITS-1 downto 0);
  value_sel:in boolean_vector(VALUES-1 downto 0);
  bin_n:in unsigned(bits(ADDRESS_BITS)-1 downto 0);
  lowest_value:in signed(VALUE_BITS-1 downto 0);
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0);
  --
  max_count:unsigned(COUNTER_BITS-1 downto 0);
  most_frequent:unsigned(ADDRESS_BITS-1 downto 0);
  start_time:in unsigned(TIMESTAMP_BITS-1 downto 0);
  stop_time:in unsigned(TIMESTAMP_BITS-1 downto 0);
  total:in unsigned(TOTAL_BITS-1 downto 0);
  --
  stream:out std_logic_vector(STREAM_CHUNKS*CHUNK_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity statistics_header_FSM;
--
architecture FSM of statistics_header_FSM is
type FSMstate is (IDLE,HEADER,MOSTFREQ,MAXCOUNT,LOWESTVALUE,STARTTIME1,
                  STARTTIME2,STOPTIME1,STOPTIME2,TOTAL1,TOTAL2); 
signal state,nextstate:FSMstate;
--
signal channel_sel_reg:unsigned(CHANNEL_BITS-1 downto 0);
signal value_sel_reg:boolean_vector(VALUES-1 downto 0);
signal bin_n_reg:unsigned(bits(ADDRESS_BITS)-1 downto 0);
signal lowest_value_reg:signed(2*CHUNK_DATABITS-1 downto 0);
signal last_bin_reg:unsigned(CHUNK_DATABITS-1 downto 0);
signal start_time_reg,stop_time_reg:unsigned(4*CHUNK_DATABITS-1 downto 0);
signal total_reg:unsigned(4*CHUNK_DATABITS-1 downto 0);
signal max_count_reg:unsigned(2*CHUNK_DATABITS-1 downto 0);
signal most_frequent_reg:unsigned(CHUNK_DATABITS-1 downto 0);
--
begin
--
controlRegs:process(clk)
begin
if rising_edge(clk) then
  if swap_buffer then
    channel_sel_reg <= channel_sel;
    bin_n_reg <= bin_n;
    lowest_value_reg <= resize(lowest_value,2*CHUNK_DATABITS);
    last_bin_reg <= resize(last_bin,CHUNK_DATABITS);
    value_sel_reg <= value_sel;
  end if;
  if go then
    total_reg <= resize(total,4*CHUNK_DATABITS);
    max_count_reg <= resize(max_count,2*CHUNK_DATABITS);
    most_frequent_reg <= resize(most_frequent,CHUNK_DATABITS);
    start_time_reg <= resize(start_time,4*CHUNK_DATABITS);
    stop_time_reg <= resize(stop_time,4*CHUNK_DATABITS);
  end if;
end if;
end process controlRegs;
--
FSMnextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    state <= IDLE;
  else
    state <= nextstate;
  end if;
end if;
end process FSMnextstate;
-- 
FSMtransition:process(state,go,ready)
begin
nextstate <= state;
case state is 
  when IDLE =>
    if go then
      nextstate <= HEADER;
    end if;
  when HEADER =>
    if ready then
      nextstate <= MOSTFREQ;
    end if;
  when MOSTFREQ =>
    if ready then
      nextstate <= MAXCOUNT;
    end if;
  when MAXCOUNT =>
    if ready then
      nextstate <= LOWESTVALUE;
    end if;
  when LOWESTVALUE =>
    if ready then
      nextstate <= STARTTIME1;
    end if;
  when STARTTIME1 =>
    if ready then
      nextstate <= STARTTIME2;
    end if;
  when STARTTIME2 =>
    if ready then
      nextstate <= STOPTIME1;
    end if;
  when STOPTIME1 =>
    if ready then
      nextstate <= STOPTIME2;
    end if;
  when STOPTIME2 =>
    if ready then
      nextstate <= TOTAL1;
    end if;
  when TOTAL1 =>
    if ready then
      nextstate <= TOTAL2;
    end if;
  when TOTAL2 =>
    if ready then
      nextstate <= IDLE;
    end if;
end case;
end process FSMtransition;
--
FSMoutput:process(clk)
variable data:std_logic_vector(STREAM_CHUNKS*CHUNK_DATABITS-1 downto 0);
begin
if rising_edge(clk) then
  case nextstate is 
  when IDLE =>
    stream <= (others => '-');
    valid <= FALSE;
    last <= FALSE;
  when HEADER =>
    -- streamed as 2 16 bit values
    --NOTE assumes max CHANNEL_BITS = 3
    --  3     |   2    |      1  |
    -- 1098765432109876|54321|098|76543210
    -- last_bin        |bin_n|chn|value_sel
    -- word 1          | word 2
    data := to_std_logic(
              last_bin_reg & 
              resize(bin_n_reg,5) & resize(channel_sel_reg,3) & 
              unsigned(to_std_logic(value_sel_reg))
            );
    stream <= "01" & SetEndianness(data(31 downto 16),ENDIANNESS) &
              "01" & SetEndianness(data(15 downto 0),ENDIANNESS);
    valid <= TRUE;
    last <= FALSE;
  when MOSTFREQ => 
    --streamed as a single 32 bit value though only lower 16 bits are nonzero
    data := SetEndianness(resize(most_frequent_reg,32),ENDIANNESS);
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when MAXCOUNT => 
    -- stream as a single 32 bit value
    data := SetEndianness(max_count_reg(31 downto 0),ENDIANNESS);
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when LOWESTVALUE =>
    -- streamed as a single 32 bit value
    data := SetEndianness(lowest_value_reg(31 downto 0),ENDIANNESS);
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when STARTTIME1 =>
    if ENDIANNESS="LITTLE" then
      data := SetEndianness(start_time_reg(31 downto 0),ENDIANNESS);
    else
      data := to_std_logic(start_time_reg(63 downto 32));
    end if;
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when STARTTIME2 =>
    if ENDIANNESS="LITTLE" then
      data := SetEndianness(start_time_reg(63 downto 32),ENDIANNESS);
    else
      data := to_std_logic(start_time_reg(31 downto 0));
    end if;
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when STOPTIME1 =>
    if ENDIANNESS="LITTLE" then
      data := SetEndianness(stop_time_reg(31 downto 0),ENDIANNESS);
    else
      data := to_std_logic(stop_time_reg(63 downto 32));
    end if;
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when STOPTIME2 =>
    if ENDIANNESS="LITTLE" then
      data := SetEndianness(stop_time_reg(63 downto 32),ENDIANNESS);
    else
      data := to_std_logic(stop_time_reg(31 downto 0));
    end if;
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when TOTAL1 =>
    if ENDIANNESS="LITTLE" then
      data := SetEndianness(total_reg(31 downto 0),ENDIANNESS);
    else
      data := to_std_logic(total_reg(63 downto 32));
    end if;
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= FALSE;
  when TOTAL2 =>
    if ENDIANNESS="LITTLE" then
      data := SetEndianness(total_reg(63 downto 32),ENDIANNESS);
    else
      data := to_std_logic(total_reg(31 downto 0));
    end if;
    stream <= "01" & data(31 downto 16) & "01" & data(15 downto 0);
    valid <= TRUE;
    last <= TRUE;
  end case;
end if;
end process FSMoutput;
end architecture FSM;
