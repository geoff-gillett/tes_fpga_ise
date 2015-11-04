--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:22/02/2014 
-- 
-- Design Name: TES_digitiser
-- Module Name: tick_unit
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
library streamlib;
use streamlib.types.all;
use streamlib.functions.all;
--
entity tick_unit is
generic(
  CHANNEL_BITS:integer:=3;
  STREAM_CHUNKS:integer:=4;
  SIZE_BITS:integer:=SIZE_BITS;
  TICK_BITS:integer:=32;
  MINIMUM_TICK_PERIOD:integer:=2**TIME_BITS;
  TIMESTAMP_BITS:integer:=64;
  ENDIANNESS:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  tick:out boolean;
  timestamp:out unsigned(TIMESTAMP_BITS-1 downto 0);
  tick_period:in unsigned(TICK_BITS-1 downto 0);
  --
  events_lost:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  dirty:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --signal_valid:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  tickstream:out std_logic_vector(STREAM_CHUNKS*CHUNK_BITS-1 downto 0);
  valid:out boolean;
  last:out boolean;
  ready:in boolean
);
end entity tick_unit;

architecture aligned of tick_unit is
--
constant CHANNELS:integer:=2**CHANNEL_BITS;
constant ADDRESS_BITS:integer:=9;
constant DATA_BITS:integer:=STREAM_CHUNKS*CHUNK_DATABITS;
--
signal overflow_reg,param_reg:boolean_vector(CHANNELS-1 downto 0);
signal overflow_out,param_out:std_logic_vector(CHANNELS-1 downto 0);
signal full,tick_int,missed_tick,commit:boolean;
signal time_stamp:unsigned(TIMESTAMP_BITS-1 downto 0);
signal tick_period_header:unsigned(TICK_BITS-1 downto 0);
--
type FSMstate is (WRITE_TIMESTAMP,HEADER);
signal state,nextstate:FSMstate;
signal header_data,data:std_logic_vector(DATA_BITS-1 downto 0);
signal lasts,keeps:std_logic_vector(STREAM_CHUNKS-1 downto 0);
signal address,length:unsigned(ADDRESS_BITS-1 downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
signal wr_en:boolean_vector(STREAM_CHUNKS-1 downto 0);
signal tickstream_int:std_logic_vector(EVENTBUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal valid_int,ready_int,last_int:boolean;
--
begin
tick <= tick_int and reset='0';
timestamp <= time_stamp;
--------------------------------------------------------------------------------
-- These data words must be changed for CHANNEL_BITS>3 or TICK_BITS>32
--------------------------------------------------------------------------------
-- tick data firstword
-- TODO add tick missed flag
--6|32109|87654|32109876543210|98765432|
-- |size |FMx0D| relative time|overflow| D=dirty flag 
-- |      tick period 32 bits          |
--
-- TODO improve alignment
-- 
-- size 16 bits
-- rel time 16 bits
-- flags 32 bits,
-- timestamp 64 bits

header_data <= std_logic_vector(to_unsigned(8,CHUNK_DATABITS)) &
		 					 to_std_logic(0, CHUNK_DATABITS) &
               to_std_logic(resize(unsigned(param_out),8)) &
               std_logic_vector(resize(unsigned(overflow_out),8)) &
               to_std_logic(0, 16);
--<= std_logic_vector(to_unsigned(8,SIZE_BITS)) &
--               "0000" & to_std_logic(unaryOR(param_out)) &
--               "00000000000000" & --replaced by mux
--               std_logic_vector(resize(unsigned(overflow_out),8)) &
--               SetEndianness(resize(tick_period_header,32),ENDIANNESS);
length <= to_unsigned(2,ADDRESS_BITS);
--------------------------------------------------------------------------------
FSMnextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    state <= WRITE_TIMESTAMP; 
  else
    state <= nextstate;
  end if;
end if;
end process FSMnextstate;
FSMtransition:process(state,tick_int,full,missed_tick)
begin
nextstate <= state;
case state is 
  when WRITE_TIMESTAMP =>
    if (tick_int or missed_tick) and not full then
      nextstate <= HEADER;
    end if;
  when HEADER =>
    nextstate <= WRITE_TIMESTAMP;
end case;
end process FSMtransition;
dataReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    missed_tick <= FALSE;
    full <= FALSE;
  else
    full <= free < to_unsigned(2,EVENTBUS_CHUNKS*CHUNK_BITS);
    case state is 
      when WRITE_TIMESTAMP =>
        if (tick_int or missed_tick) then
          if full then
            data <= (others => '-');
            wr_en <= (others => FALSE);
            address <= (others => '0');
            lasts <= "----";
            keeps <= "----";
            commit <= FALSE;
            missed_tick <= TRUE;
          else
            missed_tick <= FALSE;
            data <= SetEndianness(time_stamp,ENDIANNESS);
            wr_en <= (others => TRUE);
            address <= to_unsigned(1,ADDRESS_BITS);
            lasts <= "0001";
            keeps <= "1111";
            commit <= FALSE;
          end if;
        else
          data <= (others => '-');
          wr_en <= (others => FALSE);
          address <= (others => '0');
          lasts <= "----";
          keeps <= "----";
          commit <= FALSE;
        end if;
      when HEADER =>
          data <= header_data;
          wr_en <= (others => TRUE);
          address <= (others => '0');
          lasts <= "0000";
          keeps <= "1111";
          commit <= TRUE;
    end case;
  end if;
end if;
end process dataReg;
overflowReg:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      overflow_reg <= (others => FALSE);
    else
      for i in 0 to CHANNELS-1 loop
        if tick_int and not full then
          overflow_out(i) <= to_std_logic(overflow_reg(i) or events_lost(i));
          overflow_reg(i) <= FALSE;
        end if;
        if events_lost(i) or missed_tick then
          overflow_reg(i) <= TRUE;
        end if;
     end loop;
    end if;
  end if;
end process overflowReg;
parameterReg:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      param_reg <= (others => FALSE);
    else
      for i in 0 to CHANNELS-1 loop
        if tick_int and not full then
          param_out(i) <= to_std_logic(param_reg(i) or dirty(i)); 
          param_reg(i) <= FALSE;
        end if;
        if dirty(i) then
          param_reg(i) <= TRUE;
        end if;
      end loop;     
    end if;
  end if;
end process parameterReg;
framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => EVENTBUS_CHUNKS,
  ADDRESS_BITS => 9
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => address,
  lasts => lasts,
  keeps => keeps,
  chunk_we => wr_en,
  free => free,
  length => length,
  commit => commit,
  stream => tickstream_int,
  valid => valid_int,
  ready => ready_int
);
last_int <= busLast(tickstream_int,EVENTBUS_CHUNKS);
streamReg:entity streamlib.register_slice
generic map(STREAM_BITS => EVENTBUS_CHUNKS*CHUNK_BITS)
port map(
	clk => clk,
  reset => reset,
  stream_in => tickstream_int,
  valid_in => valid_int,
  last_in => last_int,
  ready_out => ready_int,
  stream => tickstream,
  valid => valid,
  last => last,
  ready => ready
);
tickCounter:entity teslib.tick_counter
generic map(
  MINIMUM_PERIOD => MINIMUM_TICK_PERIOD,
  TICK_BITS => TICK_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset,
  tick => tick_int,
  time_stamp => time_stamp,
  period => tick_period,
  current_period => tick_period_header
);
end architecture aligned;
