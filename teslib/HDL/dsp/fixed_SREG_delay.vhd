--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:03/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: moving_average
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
--library teslib;
use work.types.all;
use work.functions.all;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
entity fixed_SREG_delay is
generic(
  DELAY:integer:=128; --min 1 
  WIDTH:integer:=18
);
port (
  clk:in std_logic;
  --
  data:in std_logic_vector(WIDTH-1 downto 0);
  -- data in is delayed by delay+1 (BRAM latency)
  delayed:out std_logic_vector(WIDTH-1 downto 0)
);
end entity fixed_SREG_delay;
--
architecture sreg of fixed_SREG_delay is
subtype word is std_logic_vector(WIDTH-1 downto 0);
type pipeline is array (1 to DELAY) of word;
signal shifter:pipeline:=(others => (others => '0'));
--
       
begin

assert DELAY > 0
report "minimum delay 1" severity ERROR;  

shift:process (clk) is
begin
if rising_edge(clk) then
	shifter <= data & shifter(1 to DELAY-1);
end if;
end process shift;
delayed <= shifter(DELAY);
--
end architecture sreg;
