--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Apr 2016
--
-- Design Name: TES_digitiser
-- Module Name: stream_cdc_TB
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

entity stream_cdc_TB is
generic(
	DATA_BITS:integer:=8
);
end entity stream_cdc_TB;

architecture testbench of stream_cdc_TB is

constant S_CLK_PERIOD:time:=8 ns;
constant R_CLK_PERIOD:time:=4 ns;

signal s_clk:std_logic:='1';
signal s_reset:std_logic:='1';
signal s_valid:boolean;
signal s_ready:boolean;
signal r_clk:std_logic:='1';
signal r_reset:std_logic:='1';
signal r_stream:std_logic_vector(DATA_BITS-1 downto 0);
signal r_valid:boolean;
signal r_ready:boolean;
signal sim_count:unsigned(DATA_BITS-1 downto 0);

begin

r_clk <= not r_clk after R_CLK_PERIOD/2;
s_clk <= not s_clk after S_CLK_PERIOD/2;

UUT:entity work.stream_cdc
generic map(
  WIDTH => 8
)
port map(
  s_clk => s_clk,
  s_reset => s_reset,
  s_stream => to_std_logic(sim_count),
  s_valid => s_valid,
  s_ready => s_ready,
  r_clk => r_clk,
  r_reset => r_reset,
  r_stream => r_stream,
  r_valid => r_valid,
  r_ready => r_ready
);

sim:process(s_clk)
begin
	if rising_edge(s_clk) then
		if s_reset = '1' then
			sim_count <= (others => '0');
		else
			if s_valid and s_ready then
				sim_count <= sim_count+1;
			end if;
		end if;
	end if;
end process sim;

stimulus:process is
begin
wait for S_CLK_PERIOD;
s_reset <= '0';
r_reset <= '0';
r_ready <= TRUE;
wait for R_CLK_PERIOD;
s_valid <= TRUE;
wait;
end process stimulus;

end architecture testbench;
