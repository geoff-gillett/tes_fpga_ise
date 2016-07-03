library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

entity packet_generator_TB is
end entity packet_generator_TB;

architecture RTL of packet_generator_TB is
signal reset:std_logic:='1';
signal clk:std_logic:='1';
constant CLK_PERIOD:time:= 4 ns;
signal period:unsigned(31 downto 0);
signal stream:streambus_t;
signal ready:boolean:=FALSE;
signal valid:boolean;

begin
clk <= not clk after CLK_PERIOD/2; 
reset <= '0' after 2*CLK_PERIOD;
ready <= TRUE after 2*CLK_PERIOD;
period <= to_unsigned(16,32);



UUT:entity work.packet_generator
port map(
  clk    => clk,
  reset  => reset,
  period => period,
  stream => stream,
  ready  => ready,
  valid  => valid
);
end architecture RTL;
