--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:2 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: axi_adapter_TB
-- Project Name: streamlib 
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

use work.stream.all;

entity axi_adapter_TB is
generic(
	AXI_CHUNKS:integer:=2
);
end entity axi_adapter_TB;

architecture testbench of axi_adapter_TB is
constant AXI_BITS:integer:=AXI_CHUNKS*CHUNK_DATABITS;
signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal axi_valid:boolean;
signal axi_ready:boolean;
signal axi_last:boolean;
signal stream:streambus_t;
signal valid:boolean;
signal ready:boolean;

signal simcount:unsigned(AXI_BITS-1 downto 0);
begin
clk <= not clk after CLK_PERIOD/2;

sim:process(clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			simcount <= (others => '0');
		else
			if axi_ready and axi_valid then
				simcount <= simcount+1;
			end if;
		end if;
	end if;
end process sim;

UUT:entity work.axi_adapter
generic map(
  AXI_CHUNKS => AXI_CHUNKS
)
port map(
  clk => clk,
  reset => reset,
  axi_stream => to_std_logic(simcount),
  axi_valid => axi_valid,
  axi_ready => axi_ready,
  axi_last => axi_last,
  stream => stream,
  valid => valid,
  ready => ready
);

axi_last <= FALSE; --simcount(1)='1';
--ready <= TRUE;

stimulus:process is
begin
axi_valid <= TRUE;
ready <= FALSE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*16;
axi_valid <= FALSE;
ready <= TRUE;
wait for CLK_PERIOD;
ready <= FALSE;
wait for CLK_PERIOD*2;
ready <= TRUE;
axi_valid <= TRUE;
wait;
end process stimulus;

end architecture testbench;
