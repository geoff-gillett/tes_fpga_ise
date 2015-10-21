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

entity test_pulsestream_TB is
generic(
  BUS_CHUNKS:integer:=4
);
end entity test_pulsestream_TB;

architecture testbench of test_pulsestream_TB is
	signal clk: std_logic:='1';
	signal reset:std_logic:='1';
	signal pulsestream:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
	signal pulsestream_valid:boolean;
	signal pulsestream_ready:boolean;
	
	constant CLK_PERIOD:time:=4 ns;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.test_pulsestream
generic map(
  BUS_CHUNKS   => BUS_CHUNKS
)
port map(
  clk               => clk,
  reset             => reset,
  pulsestream       => pulsestream,
  pulsestream_valid => pulsestream_valid,
  pulsestream_ready => pulsestream_ready
);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
pulsestream_ready <= TRUE;
wait;
end process stimulus;

end architecture testbench;
