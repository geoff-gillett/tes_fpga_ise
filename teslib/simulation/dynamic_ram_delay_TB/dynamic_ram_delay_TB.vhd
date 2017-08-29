--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:28 Aug. 2017
--
-- Design Name: TES_digitiser
-- Module Name: dynamic_ram_delay_TB
-- Project Name:  teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dynamic_ram_delay_TB is
generic(
  DEPTH:natural:=16;
  DATA_BITS:natural:=16
  
);
end entity dynamic_ram_delay_TB;

architecture testbench of dynamic_ram_delay_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;
signal data_in:std_logic_vector(DATA_BITS-1 downto 0);
signal data_out:std_logic_vector(DATA_BITS-1 downto 0);
signal delay:natural range 0 to DEPTH-1;
signal delayed:std_logic_vector(DATA_BITS-1 downto 0);

signal count:unsigned(DATA_BITS-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;
  
sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      count <= (others => '0');
    else
      count <= count+1;
    end if;
  end if;
end process sim;
data_in <= std_logic_vector(count);

UUT:entity work.dynamic_RAM_delay2
generic map(
  DEPTH => DEPTH,
  DATA_BITS => DATA_BITS
)
port map(
  clk => clk,
  data_in => data_in,
  data_out => data_out,
  delay => delay,
  delayed => delayed
);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
delay <= 1;
wait;
end process stimulus;

end architecture testbench;
