--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:7 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: streambus_buffer_TB
-- Project Name:treamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;

entity streambus_buffer_TB is
end entity streambus_buffer_TB;

architecture testbench of streambus_buffer_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	

constant CLK_PERIOD:time:=4 ns;

signal instream:streambus_t;
signal instream_valid:boolean;
signal instream_ready:boolean;
signal outstream:streambus_t;
signal outstream_valid:boolean;
signal outstream_ready:boolean;

signal sim_count:unsigned(15 downto 0);

begin
	
clk <= not clk after CLK_PERIOD/2;

sim:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			sim_count <= (others => '0');
		else
			if instream_valid and instream_ready then
				sim_count <= sim_count+1;
			end if;
		end if;
	end if;
end process sim;
instream.data <= to_std_logic(resize(sim_count,64));
instream.discard <= (others => FALSE);
instream.last <= (others => FALSE);

UUT:entity work.streambus_buffer
port map(
  clk => clk,
  reset => reset,
  instream => instream,
  instream_valid  => instream_valid,
  instream_ready  => instream_ready,
  stream => outstream,
  valid => outstream_valid,
  ready => outstream_ready
);

stimulus:process is
begin
outstream_ready <= FALSE;
instream_valid <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait until not instream_ready;
outstream_ready <= TRUE;
instream_valid <= FALSE;
wait until not outstream_valid;
instream_valid <= TRUE;
wait for CLK_PERIOD;
instream_valid <= FALSE;
wait for CLK_PERIOD;
instream_valid <= TRUE;
wait for CLK_PERIOD;
instream_valid <= FALSE;
wait for CLK_PERIOD;
instream_valid <= TRUE;
wait for CLK_PERIOD;
instream_valid <= FALSE;
wait for CLK_PERIOD;
instream_valid <= TRUE;

outstream_ready <= FALSE;
wait for CLK_PERIOD;
outstream_ready <= TRUE;
wait for CLK_PERIOD;
outstream_ready <= FALSE;
wait for CLK_PERIOD;
outstream_ready <= TRUE;
wait for CLK_PERIOD;
outstream_ready <= FALSE;
wait for CLK_PERIOD;
outstream_ready <= TRUE;
wait for CLK_PERIOD;
outstream_ready <= FALSE;
wait for CLK_PERIOD;
outstream_ready <= TRUE;
wait for CLK_PERIOD;
outstream_ready <= FALSE;
wait for CLK_PERIOD;
outstream_ready <= TRUE;
wait;
end process stimulus;

end architecture testbench;
