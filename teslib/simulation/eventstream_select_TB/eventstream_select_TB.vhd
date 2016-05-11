--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:24 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: eventstream_selector_TB
-- Project Name: eventlib
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

library streamlib;
use streamlib.stream.all;

entity eventstream_selector_TB is
generic(
	-- number of input streams (MAX 12)
  CHANNELS:integer:=4
);
end entity eventstream_selector_TB;

architecture testbench of eventstream_selector_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	

constant CLK_PERIOD:time:=4 ns;

signal sel:boolean_vector(CHANNELS-1 downto 0);
signal done:boolean;
signal instreams:streambus_array(CHANNELS-1 downto 0);
signal valids:boolean_vector(CHANNELS-1 downto 0);
signal readys:boolean_vector(CHANNELS-1 downto 0);
signal mux_stream:streambus_t;
signal mux_valid:boolean;
signal mux_ready:boolean;
signal sim_count:unsigned(BUS_DATABITS-CHANNELS-1 downto 0);
signal go:boolean;

begin
clk <= not clk after CLK_PERIOD/2;

sim:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			sim_count <= (others => '0');
		else
			if mux_valid and mux_ready then
				sim_count <= sim_count+1;
			end if;
		end if;
	end if;
end process sim;

busGen:for chan in 0 to CHANNELS-1 generate
	instreams(chan).data <= to_std_logic(chan,4) & to_std_logic(sim_count);
	instreams(chan).keep_n <= (others => FALSE);
	instreams(chan).last <= (0 => TRUE, others =>FALSE);
end generate;

UUT:entity work.eventstream_select
generic map(
  CHANNELS => CHANNELS
)
port map(
  sel_valid => go,
  clk => clk,
  reset => reset,
  sel => sel,
  done => done,
  instreams => instreams,
  valids => valids,
  readys => readys,
  mux_stream => mux_stream,
  mux_valid => mux_valid,
  mux_ready => mux_ready
);

stimulus:process is
begin
valids <= (others => TRUE);
mux_ready <= TRUE;	
sel <= (others => FALSE);
go <= FALSE;
mux_ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
go <= TRUE;
sel <= (0 => TRUE,others => FALSE);
wait for CLK_PERIOD;
go <= FALSE;
sel <= (2 => TRUE,others => FALSE);
wait until done;
go <= TRUE;
sel <= (2 => TRUE,others => FALSE);
wait for CLK_PERIOD;
go <= FALSE;
wait;
end process stimulus;

end architecture testbench;
