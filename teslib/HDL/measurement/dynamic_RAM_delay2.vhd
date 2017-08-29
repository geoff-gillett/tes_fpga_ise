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

library extensions;
use extensions.logic.all;

use work.types.all;
use work.functions.all;

--------------------------------------------------------------------------------
-- ring buffer single clock domain 
-- implemented as SDP BRAM
-- delay is relative to data_out which has 4 clock latency from data_in
--------------------------------------------------------------------------------
entity dynamic_RAM_delay2 is
generic(
  DEPTH:integer:=2**10; 
  DATA_BITS:integer:=18
);
port (
  clk:in std_logic;
  --
  data_in:in std_logic_vector(DATA_BITS-1 downto 0);
  -- 3 clk latency
  data_out:out std_logic_vector(DATA_BITS-1 downto 0); 
  delay:in natural range 0 to DEPTH-1;
  delayed:out std_logic_vector(DATA_BITS-1 downto 0)
);
end entity dynamic_RAM_delay2;
--
architecture sdp of dynamic_RAM_delay2 is
-- ram signals
subtype word is std_logic_vector(DATA_BITS-1 downto 0);
type ram is array (0 to DEPTH-1) of word;
signal ring:ram:=(others => (others => '0'));
--
signal delay_addr:unsigned(ceilLog2(DEPTH)-1 downto 0);
signal ring_addr:unsigned(ceilLog2(DEPTH)-1 downto 0):=(others => '0');
signal ring_prev:unsigned(ceilLog2(DEPTH)-1 downto 0):=(others => '1');
signal data_int,delay_int,data_reg:std_logic_vector(DATA_BITS-1 downto 0);

begin
-- infer SDP RAM
ramInstance:process(clk)
begin
if rising_edge(clk) then
  data_reg <= data_in;
  
  ring(to_integer(ring_addr)) <= data_reg;
  data_int <= ring(to_integer(ring_prev));
  data_out <= data_int; --absorbed into RAM
  
  delay_int <= ring(to_integer(delay_addr));
  delayed <= delay_int;
end if;
end process ramInstance;
--
addrCount:process(clk)
begin
if rising_edge(clk) then
  ring_addr <= ring_addr+1;
  ring_prev <= ring_addr;
  delay_addr <= ring_addr-delay;
end if;
end process addrCount;
--
end architecture sdp;
