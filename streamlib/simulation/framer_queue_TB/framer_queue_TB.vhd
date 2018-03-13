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

entity framer_queue_TB is
generic(
	ADDRESS_BITS:integer:=4
);

end entity framer_queue_TB;

architecture testbench of framer_queue_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

--------------------------------------------------------------------------------
-- UUT signals
--------------------------------------------------------------------------------
signal sim_count:unsigned(63 downto 0);
signal data0:streambus_t;
signal address0:unsigned(ADDRESS_BITS-1 downto 0);
signal we0:boolean_vector(BUS_CHUNKS-1 downto 0);
signal length0:unsigned(ADDRESS_BITS downto 0);
signal commit0:boolean;
signal data1:streambus_t;
signal address1:unsigned(ADDRESS_BITS-1 downto 0);
signal we1:boolean_vector(BUS_CHUNKS-1 downto 0);
signal length1:unsigned(ADDRESS_BITS downto 0);
signal commit1:boolean;
signal data2:streambus_t;
signal address2:unsigned(ADDRESS_BITS-1 downto 0);
signal we2:boolean_vector(BUS_CHUNKS-1 downto 0);
signal length2:unsigned(ADDRESS_BITS downto 0);
signal commit2:boolean;
signal free:unsigned(ADDRESS_BITS downto 0);
signal ready1:boolean;
signal ready2:boolean;
signal framer_free:unsigned(ADDRESS_BITS downto 0);
signal data:streambus_t;
signal we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal length:unsigned(ADDRESS_BITS downto 0);
signal commit:boolean;
--------------------------------------------------------------------------------

begin
clk <= not clk after CLK_PERIOD/2;
length <= to_unsigned(1,ADDRESS_BITS+1);

UUT:entity work.framer_queue
generic map(
  BUS_CHUNKS   => BUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data0 => data0,
  we0 => we0,
  address0 => address0,
  commit0 => commit0,
  length0 => length0,
  data1 => data1,
  we1 => we1,
  address1 => address1,
  commit1 => commit1,
  length1 => length1,
  data2 => data2,
  we2 => we2,
  address2 => address2,
  commit2 => commit2,
  length2 => length2,
  free => free,
  ready1 => ready1,
  ready2 => ready2,
  framer_free => framer_free,
  data => data,
  we => we,
  length => length,
  commit => commit
);

stimulus:process is
begin
wait for CLK_PERIOD*4;
reset <= '0';
framer_free <= (ADDRESS_BITS => '1', others => '0');
wait for CLK_PERIOD;
we0 <= (others => TRUE);
we1 <= (others => FALSE);
we2 <= (others => FALSE);
data0.data <= X"0000000000000000";
data0.last <= (others => FALSE);
data0.discard <= (others => FALSE);
data1.data <= X"0000000000000001";
data1.last <= (others => FALSE);
data1.discard <= (others => FALSE);
data2.data <= X"0000000000000002";
data2.last <= (others => FALSE);
data2.discard <= (others => FALSE);
address0 <= to_unsigned(0,ADDRESS_BITS);
address1 <= to_unsigned(0,ADDRESS_BITS);
address2 <= to_unsigned(0,ADDRESS_BITS);
length0 <= (0 => '1', others => '0');
length1 <= (0 => '1', others => '0');
length2 <= (0 => '1', others => '0');
wait for CLK_PERIOD;
we1 <= (others => TRUE);
wait for CLK_PERIOD;
we0 <= (others => FALSE);
address1 <= to_unsigned(1,ADDRESS_BITS);
length0 <= (1 => '1', others => '0');
commit1 <= TRUE;
wait for CLK_PERIOD;
we1 <= (others => FALSE);
commit1 <= FALSE;
wait;
end process stimulus;

end architecture testbench;
