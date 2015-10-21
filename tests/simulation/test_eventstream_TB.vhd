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

entity test_eventstream_TB is
generic(
  BUS_CHUNKS:integer:=4
);
end entity test_eventstream_TB;

architecture testbench of test_eventstream_TB is
	
signal clk: std_logic:='1';
signal reset:std_logic:='1';
signal eventstream:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal eventstream_valid:boolean;
signal eventstream_ready:boolean;
signal eventstream_last : boolean;
	
constant CLK_PERIOD:time:=4 ns;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.test_eventstream
generic map(
  TICK_PERIOD         => 25000000,
  BUS_CHUNKS          => BUS_CHUNKS
)
port map(
  clk               => clk,
  reset             => reset,
  eventstream       => eventstream,
  eventstream_valid => eventstream_valid,
  eventstream_ready => eventstream_ready,
  eventstream_last  => eventstream_last
);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
eventstream_ready <= TRUE;
wait;
end process stimulus;

end architecture testbench;
