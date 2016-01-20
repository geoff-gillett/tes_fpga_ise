--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: stream_framer_TB
-- Project Name: tests 
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

library streamlib;
use streamlib.stream.all;

entity stream_framer_TB is
generic(
  BUS_CHUNKS:integer:=4;
  ADDRESS_BITS:integer:=4
);
end entity stream_framer_TB;

architecture testbench of stream_framer_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal data:streambus;
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal chunk_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal success:boolean;
signal length:unsigned(ADDRESS_BITS-1 downto 0);
signal commit:boolean;
signal free:unsigned(ADDRESS_BITS downto 0);
signal stream:streambus;
signal valid:boolean;
signal ready:boolean;
signal counter:unsigned(BUS_DATABITS-1 downto 0);
begin
clk <= not clk after CLK_PERIOD/2;

sim:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    counter <= (others => '0');
  else
   	if unaryOR(chunk_we) then
   		counter <= counter + 1;
   	end if;
  end if;
end if;
end process sim;
data.data <= to_std_logic(counter);

UUT:entity streamlib.stream_framer
generic map(
  BUS_CHUNKS => BUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => address,
  chunk_we => chunk_we,
  success => success,
  length => length,
  commit => commit,
  free => free,
  stream => stream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
length <= to_unsigned(1,ADDRESS_BITS);
chunk_we <= (others => FALSE);
data.keep_n <= (others => FALSE);
data.last <= (0 => TRUE, others => FALSE);
address <= to_unsigned(0,ADDRESS_BITS);
ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
chunk_we <= (others => TRUE);
commit <= TRUE;
wait for CLK_PERIOD;
wait for CLK_PERIOD*16;
chunk_we <= (others => FALSE);
wait for CLK_PERIOD*8;
commit <= FALSE;
wait;
end process stimulus;

end architecture testbench;
