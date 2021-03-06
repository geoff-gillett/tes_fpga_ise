--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:9 May 2016
--
-- Design Name: TES_digitiser
-- Module Name: famer_TB
-- Project Name: 
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

entity framer_TB is
generic(
	ADDRESS_BITS:integer:=4
);

end entity framer_TB;

architecture testbench of framer_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal data:streambus_t;
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal chunk_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal length:unsigned(ADDRESS_BITS downto 0);
signal commit:boolean;
signal free:unsigned(ADDRESS_BITS downto 0);
signal stream:streambus_t;
signal valid:boolean;
signal ready:boolean;
signal we:boolean;

signal sim_count:unsigned(63 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;
length <= to_unsigned(1,ADDRESS_BITS+1);
address <= (others => '0'); --resize(sim_count(1 downto 0),ADDRESS_BITS);
chunk_we <= (others => TRUE) when address < free and we else (others => FALSE);
commit <= address < free and we;

sim:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			sim_count <= (others => '0');
		else
			if we and address < free then
        sim_count <= sim_count + 1;
      end if;
		end if;
	end if;
end process sim;

data.data <= to_std_logic(sim_count);
data.discard <= (others => FALSE);
data.last <= (others => FALSE);

UUT:entity work.framer
generic map(
  BUS_CHUNKS   => 4,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => address,
  chunk_we => chunk_we,
  length => length,
  commit => commit,
  free => free,
  stream => stream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
ready <= FALSE;
we <= FALSE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
we <= TRUE;
wait for CLK_PERIOD*40;
we <= FALSE;
ready <= TRUE;
wait for CLK_PERIOD*23;
ready <= FALSE;
we <= TRUE;
wait for CLK_PERIOD*21;
ready <= TRUE;
wait;
wait for CLK_PERIOD;
end process stimulus;

end architecture testbench;
