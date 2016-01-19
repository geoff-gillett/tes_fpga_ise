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

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;
use streamlib.events.all;

entity tickstream is
generic(
  CHANNEL_BITS:integer:=3;
  PERIOD_BITS:integer:=32;
  MINIMUM_PERIOD:integer:=2**TIME_BITS;
  TIMESTAMP_BITS:integer:=64
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  tick:out boolean;
  timestamp:out unsigned(TIMESTAMP_BITS-1 downto 0);
  tick_period:in unsigned(PERIOD_BITS-1 downto 0);
  --
  overflow:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  tickstream:out streambus;
  valid:out boolean;
  ready:in boolean
);
end entity tickstream;

architecture aligned of tickstream is
--
constant CHANNELS:integer:=2**CHANNEL_BITS;
constant ADDRESS_BITS:integer:=9;
--
signal overflow_reg:boolean_vector(CHANNELS-1 downto 0);
signal full,tick_int,tick_reg,missed_tick,last_tick_missed,commit:boolean;
type FSMstate is (IDLE,FIRST,SECOND);
signal state,nextstate:FSMstate;
signal data:streambus;
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
signal wr_en:boolean_vector(BUS_CHUNKS-1 downto 0);
signal tick_event:tickevent;
signal tick_bus:streambus_array(1 downto 0);
--
begin
tick <= tick_int;
tick_event.timestamp <= (others => '0');
timestamp <= tick_event.full_timestamp;

framer:entity streamlib.stream_framer
generic map(
  BUS_CHUNKS => BUS_CHUNKS,
  ADDRESS_BITS => 9
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => address,
  chunk_we => wr_en,
  free => free,
  length => to_unsigned(2,ADDRESS_BITS),
  commit => commit,
  stream => tickstream,
  valid => valid,
  ready => ready
);
full <= free < to_unsigned(2,ADDRESS_BITS+1);
tick_bus <= to_streambus(tick_event);

overflowReg:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      overflow_reg <= (others => FALSE);
    else
    	if tick_int then
        tick_event.flags.overflow(CHANNELS-1 downto 0) 
        	<= overflow_reg or overflow;
        overflow_reg <= (others => FALSE);
      else 
      	overflow_reg <= overflow_reg or overflow;
      end if;
    end if;
  end if;
end process overflowReg;

FSMnextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    state <= FIRST; 
  else
    state <= nextstate;
  end if;
end if;
end process FSMnextstate;

FSMtransition:process(state,tick_reg,missed_tick)
begin
nextstate <= state;
case state is 
when IDLE => 
  if tick_reg and not missed_tick then
    nextstate <= FIRST;
  end if;
when FIRST =>
	nextstate <= SECOND;
when SECOND =>
  nextstate <= IDLE;
end case;
end process FSMtransition;

reg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	missed_tick <= FALSE;
  	last_tick_missed <= FALSE;
  else
		missed_tick <= full and tick_int;
		tick_reg <= tick_int;
		
		if tick_reg then
			last_tick_missed <= missed_tick;
			tick_event.flags.tick_lost <= last_tick_missed;
  	end if;
  	 
    case state is 
    when IDLE =>
    	commit <= FALSE;
    	wr_en <= (others => FALSE);
    when FIRST =>
        data <= tick_bus(0);
        wr_en <= (others => TRUE);
        address <= (others => '0');
        commit <= FALSE;
     when SECOND =>
        data <= tick_bus(1);
        wr_en <= (others => TRUE);
        address <= (others => '0');
        commit <= TRUE;
    end case;
  end if;
end if;
end process reg;

tickCounter:entity teslib.tick_counter
generic map(
  MINIMUM_PERIOD => MINIMUM_PERIOD,
  TICK_BITS => PERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset,
  tick => tick_int,
  time_stamp => tick_event.full_timestamp,
  period => tick_period,
  current_period => open 
);
end architecture aligned;
