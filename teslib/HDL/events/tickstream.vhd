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

library extensions;
use extensions.boolean_vector.all;

library streamlib;
use streamlib.types.all;

use work.events.all;
use work.types.all;
--use work.functions.all;

entity tickstream is
generic(
  CHANNEL_BITS:integer:=3;
  TICKPERIOD_BITS:integer:=32;
  MINIMUM_PERIOD:integer:=2**TIME_BITS;
  TIMESTAMP_BITS:integer:=64;
  TICKPIPE_DEPTH:integer:=2;
  ENDIANNESS:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  tick:out boolean;
  timestamp:out unsigned(TIMESTAMP_BITS-1 downto 0);
  tick_period:in unsigned(TICKPERIOD_BITS-1 downto 0);
  --
  overflow:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --
  tickstream:out streambus_t;
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
signal data:streambus_t;
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
signal wr_en:boolean_vector(BUS_CHUNKS-1 downto 0);
signal tick_event:tick_event_t;
--signal tick_bus:streambus_array_t(1 downto 0);
signal time_stamp:unsigned(TIMESTAMP_BITS-1 downto 0);
signal tick_pipe:boolean_vector(0 to TICKPIPE_DEPTH);
signal current_period:unsigned(TICKPERIOD_BITS-1 downto 0);
--
begin
tick <= tick_int;
tick_event.rel_timestamp <= (others => '-');
tick_event.flags.event_type.tick <= TRUE;

timestamp <= time_stamp;

--FIXME this is a waste of 2 BRAMS
--Only need to buffer a few ticks
framer:entity streamlib.framer
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
--tick_bus <= to_streambus(tick_event,ENDIANNESS);

overflowReg:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      overflow_reg <= (others => FALSE);
    else
    	if tick_int then
    		tick_event.full_timestamp <= time_stamp;
        tick_event.flags.overflow(CHANNELS-1 downto 0) 
        	<= overflow_reg or overflow;
        tick_event.period <= current_period;
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
    state <= IDLE; 
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
        data <= to_streambus(tick_event,0,ENDIANNESS);
        wr_en <= (others => TRUE);
        address <= (others => '0');
        commit <= FALSE;
     when SECOND =>
        data <= to_streambus(tick_event,1,ENDIANNESS);
        wr_en <= (others => TRUE);
        address <= (0 => '1', others => '0');
        commit <= TRUE;
    end case;
  end if;
end if;
end process reg;

tick_int <= tick_pipe(TICKPIPE_DEPTH);
tickPipe:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			tick_pipe(1 to TICKPIPE_DEPTH) <= (others => FALSE);	
		else
			tick_pipe(1 to TICKPIPE_DEPTH) <= tick_pipe(0 to TICKPIPE_DEPTH-1);
		end if;
	end if;
end process tickPipe;

tickCounter:entity work.tick_counter
generic map(
  MINIMUM_PERIOD => MINIMUM_PERIOD,
  TICK_BITS => TICKPERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset,
  tick => tick_pipe(0),
  time_stamp => time_stamp,
  period => tick_period,
  current_period => current_period
);
end architecture aligned;
