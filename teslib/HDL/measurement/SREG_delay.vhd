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
--! ring buffer single clock domain 
--! implemented as shift register
--! actual delay is delay+3 due to latency (matches RAM architecture)
-- maximum delay is DEPTH-1
--------------------------------------------------------------------------------
entity SREG_delay is
generic(
  DEPTH:integer:=128; 
  DATA_BITS:integer:=18
);
port (
  clk:in std_logic;
  --
  data_in:in std_logic_vector(DATA_BITS-1 downto 0);
  -- data in is delayed by delay+1 (BRAM latency)
  delay:in natural range 0 to DEPTH-1;
  delayed:out std_logic_vector(DATA_BITS-1 downto 0)
);
end entity SREG_delay;
--
architecture sreg of SREG_delay is
subtype word is std_logic_vector(DATA_BITS-1 downto 0);
type pipeline is array (0 to DEPTH-1) of word;
signal shifter:pipeline;
signal delay_reg:word;
--
       
begin
shift:process (clk) is
begin
if rising_edge(clk) then
	shifter <= data_in & shifter(0 to DEPTH-2);
 	--this register is to match RAM implementation 
  delay_reg <= shifter(delay);
  delayed <= delay_reg;
end if;
end process shift;
--
end architecture sreg;
