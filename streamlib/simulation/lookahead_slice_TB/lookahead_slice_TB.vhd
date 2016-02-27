--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:9 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: lookahead_slice_TB
-- Project Name: streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

entity lookahead_slice_TB is
generic(
  WIDTH:integer:=16
);
end entity lookahead_slice_TB;

architecture testbench of lookahead_slice_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal stream_in:unsigned(WIDTH-1 downto 0);
signal ready_out:boolean;
signal valid_in:boolean;
signal lookahead:std_logic_vector(WIDTH-1 downto 0);
signal lookahead_valid:boolean;
signal stream:std_logic_vector(WIDTH-1 downto 0);
signal ready:boolean;
signal valid:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

sim:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			stream_in <= (others => '0');
		else
			if ready_out and valid_in then
				stream_in <= stream_in+1;
			end if;
		end if;
	end if;
end process sim;

UUT:entity work.lookahead_slice
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  stream_in => to_std_logic(stream_in),
  ready_out => ready_out,
  valid_in => valid_in,
  lookahead => lookahead,
  lookahead_valid => lookahead_valid,
  stream => stream,
  ready => ready,
  valid => valid
);

stimulus:process is
begin
ready <= TRUE;
valid_in <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*10;
valid_in <= FALSE;
wait for CLK_PERIOD*10;
valid_in <= TRUE;
wait for CLK_PERIOD*10;
ready <= FALSE;
wait for CLK_PERIOD*10;
ready <= TRUE;
wait;
end process stimulus;

end architecture testbench;
