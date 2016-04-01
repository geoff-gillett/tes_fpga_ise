--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:31 Mar 2016
--
-- Design Name: TES_digitiser
-- Module Name: axi_adapter_TB
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity axi_adapter_TB is
generic(
	AXI_CHUNKS:integer:=2
);
end entity axi_adapter_TB;

architecture testbench of axi_adapter_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal axi_stream:std_logic_vector(AXI_CHUNKS*CHUNK_DATABITS-1 downto 0);
signal axi_valid:boolean;
signal axi_ready:boolean;
signal axi_last:boolean;
signal stream:streambus_t;
signal valid:boolean;
signal ready:boolean;

signal simcount:unsigned(15 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

sim : process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			simcount <= (others => '0');
		else
			if axi_valid and axi_ready then
				simcount <= simcount+1;
			end if;
		end if;
	end if;
end process sim;

axi_last <= simcount(2 downto 0)= "111";
axi_stream <= std_logic_vector(resize(simcount,AXI_CHUNKS*CHUNK_DATABITS));

UUT:entity work.axi_adapter
generic map(
  AXI_CHUNKS => AXI_CHUNKS
)
port map(
  clk => clk,
  reset => reset,
  axi_stream => axi_stream,
  axi_valid => axi_valid,
  axi_ready => axi_ready,
  axi_last => axi_last,
  stream => stream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
axi_valid <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
ready <= TRUE;
wait for CLK_PERIOD*2;
ready <= FALSE;
wait for CLK_PERIOD*2;
ready <= TRUE;
wait for CLK_PERIOD*3;
ready <= FALSE;
wait for CLK_PERIOD*2;
ready <= TRUE;
wait for CLK_PERIOD*4;
ready <= FALSE;
wait for CLK_PERIOD*2;
ready <= TRUE;
wait for CLK_PERIOD*4;
ready <= FALSE;

wait;
end process stimulus;

end architecture testbench;
