--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:7 Jun 2016
--
-- Design Name: TES_digitiser
-- Module Name: stream_register_TB
-- Project Name: streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
use work.types.all;

entity stream_register_TB is
	generic(WIDTH:integer:=16);
end entity stream_register_TB;

architecture testbench of stream_register_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal stream_in:std_logic_vector(WIDTH-1 downto 0);
signal ready_out:boolean;
signal valid_in:boolean;
signal stream:std_logic_vector(WIDTH-1 downto 0);
signal ready:boolean;
signal valid:boolean;
signal sim_count:unsigned(WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

sim : process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			sim_count <= (others => '0');
		else
			if ready_out and valid_in then
				sim_count <= sim_count + 1;	
			end if;
		end if;
	end if;
end process sim;
stream_in <= std_logic_vector(sim_count);

UUT:entity work.stream_register
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_in,
  ready_out => ready_out,
  valid_in => valid_in,
  stream => stream,
  ready => ready,
  valid => valid
);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
valid_in  <= TRUE;
wait for CLK_PERIOD*8;
ready <= TRUE;
wait for CLK_PERIOD*8;
ready <= FALSE;
wait for CLK_PERIOD;
ready <= TRUE;
wait for CLK_PERIOD*8;
valid_in  <= FALSE;
wait for CLK_PERIOD*8;
valid_in  <= TRUE;
wait;
end process stimulus;

end architecture testbench;
