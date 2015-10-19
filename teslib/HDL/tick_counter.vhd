--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:01/08/2014 
--
-- Design Name: TES_digitiser
-- Module Name: tick_counter
-- Project Name: TES_Library
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity tick_counter is
generic (
  MINIMUM_PERIOD:integer:=2**14;
  TICK_BITS:integer:=32;
  TIMESTAMP_BITS:integer:=64
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  tick:out boolean;
  time_stamp:out unsigned(TIMESTAMP_BITS-1 downto 0);
  period:in unsigned(TICK_BITS-1 downto 0);
  --
  current_period:out unsigned(TICK_BITS-1 downto 0)
);
end entity tick_counter;

architecture RTL of tick_counter is
constant MIN_PERIOD:unsigned(TICK_BITS-1 downto 0)
                   :=to_unsigned(MINIMUM_PERIOD,TICK_BITS);
signal tickcount,current_period_int:unsigned(TICK_BITS-1 downto 0);
signal tick_int:boolean;
begin
tick <= tick_int;
tickLength:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    if period < MIN_PERIOD then
      current_period_int <= MIN_PERIOD-1;
      current_period <= MIN_PERIOD;
    else
      current_period_int <= period-1;
      current_period <= period;
    end if;
  else
    if tick_int then
      if period < MIN_PERIOD then
        current_period_int <= MIN_PERIOD-1;
        current_period <= MIN_PERIOD;
      else
        current_period_int <= period-1;
        current_period <= period;
      end if;
    end if;
  end if;
end if;
end process tickLength;
--
tickTimer:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      tickcount <= (others => '0'); 
      tick_int <= TRUE;
    else
      tick_int <= FALSE;
      if tickcount=current_period_int then
        tickcount <= (others => '0');
        tick_int <= TRUE;
      else
        tickcount <= tickcount+1;
      end if;
    end if;
  end if;
end process tickTimer;
--
globalTime:entity work.clock
generic map(TIME_BITS => TIMESTAMP_BITS)
port map(
  clk => clk,
  reset => reset,
  initialise_to_1 => FALSE,
  te => TRUE,
  rolling_over => open,
  time_stamp => time_stamp
);
end architecture RTL;