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
library teslib;
use teslib.types.all;
use teslib.functions.all;
--------------------------------------------------------------------------------
--! ring buffer single clock domain 
--! implemented as SDP BRAM
--! actual delay is delay+2 due to BRAM latency
--------------------------------------------------------------------------------
entity RAM_delay is
generic(
  DEPTH:integer:=2**10; 
  DATA_BITS:integer:=18
);
port (
  clk:in std_logic;
  --
  data_in:in std_logic_vector(DATA_BITS-1 downto 0);
  -- data in is delayed by delay+2 (BRAM latency)
  --delay:in unsigned(DEPTH-1 downto 0);
  delay:in natural range 0 to DEPTH-1;
  delayed:out std_logic_vector(DATA_BITS-1 downto 0)
);
end entity RAM_delay;
--
architecture ram of RAM_delay is
-- ram signals
subtype word is std_logic_vector(DATA_BITS-1 downto 0);
type ram is array (0 to DEPTH-1) of word;
signal ring:ram:=(others => (others => '0'));
--
signal delay_addr:unsigned(ceilLog2(DEPTH)-1 downto 0);
signal ring_addr:unsigned(ceilLog2(DEPTH)-1 downto 0):=(others => '0');
signal data_out_int,data_out:std_logic_vector(DATA_BITS-1 downto 0);
begin
delayed <= data_out;
-- infer RAM
ramInstance:process(clk)
begin
if rising_edge(clk) then
  ring(to_integer(ring_addr)) <= data_in;
  data_out_int <= ring(to_integer(delay_addr));
  data_out <= data_out_int; --absorbed into RAM
end if;
end process ramInstance;
--
addrCount:process(clk)
begin
if rising_edge(clk) then
  ring_addr <= ring_addr+1;
  delay_addr <= ring_addr-delay;
end if;
end process addrCount;
--
end architecture ram;
