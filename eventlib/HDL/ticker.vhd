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

use work.events.all;

entity ticker is
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
  tickstream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity ticker;

architecture aligned of ticker is
--
constant CHANNELS:integer:=2**CHANNEL_BITS;
--
signal overflow_reg:boolean_vector(CHANNELS-1 downto 0);
signal tick_int,tick_reg,missed_tick,last_tick_missed:boolean;
type FSMstate is (IDLE,FIRST,SECOND);
signal state,nextstate:FSMstate;
signal tick_event:tickevent;
signal tick_bus:streambus_array(1 downto 0);
signal tickstream_int:streambus_t;
signal ready_int:boolean;
signal valid_int:boolean;
signal time_stamp:unsigned(TIMESTAMP_BITS-1 downto 0);
--
begin
tick <= tick_int;
tick_event.header.timestamp <= (others => '0');
timestamp <= time_stamp;
tick_bus <= to_streambus(tick_event);

overflowReg:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      overflow_reg <= (others => FALSE);
    else
    	if tick_int and state=IDLE then
				tick_event.full_timestamp <= time_stamp;
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
    state <= IDLE; 
  else
    state <= nextstate;
  end if;
end if;
end process FSMnextstate;

FSMtransition:process(state,tick_reg,missed_tick,ready_int, tick_bus)
begin
	nextstate <= state;
  case state is 
  when IDLE => 
  	valid_int <= FALSE;
    if tick_reg and not missed_tick then
    	nextstate <= FIRST;
    end if;
  when FIRST =>
  	valid_int <= TRUE;
  	tickstream_int <= tick_bus(0);
    if ready_int then
      nextstate <= SECOND;
    end if;
  when SECOND =>
  	valid_int <= TRUE;
  	tickstream_int <= tick_bus(1);
    if ready_int then
      nextstate <= IDLE;
    end if;
  end case;
end process FSMtransition;

reg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	missed_tick <= FALSE;
  	last_tick_missed <= FALSE;
  else
		missed_tick <= state/=IDLE and tick_int;
		tick_reg <= tick_int;
		
		if tick_reg then
			last_tick_missed <= missed_tick;
			tick_event.flags.tick_lost <= last_tick_missed;
		end if;
		
  end if;
end if;
end process reg;

outputstream:entity streamlib.register_slice
port map(
  clk       => clk,
  reset     => reset,
  stream_in => tickstream_int,
  ready_out => ready_int,
  valid_in  => valid_int,
  stream    => tickstream,
  ready     => ready,
  valid     => valid
);

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
  time_stamp => time_stamp,
  period => tick_period,
  current_period => open 
);
end architecture aligned;
