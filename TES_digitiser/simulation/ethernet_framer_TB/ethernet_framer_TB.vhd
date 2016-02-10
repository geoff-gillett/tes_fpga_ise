--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:8 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: ethernet_framer_TB
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;

library eventlib;
use eventlib.events.all;

use work.registers.all;

entity ethernet_framer_TB is
generic(
	MTU_BITS:integer:=MTU_BITS;
	TICK_LATENCY_BITS:integer:=TICK_LATENCY_BITS;
	FRAMER_ADDRESS_BITS:integer:=5;
	DEFAULT_MTU:integer:=16;
	DEFAULT_TICK_LATENCY:integer:=16
);
end entity ethernet_framer_TB;

architecture testbench of ethernet_framer_TB is
signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal mtu:unsigned(MTU_BITS-1 downto 0);
signal tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal eventstream:streambus_t;
signal eventstream_valid:boolean;
signal eventstream_ready:boolean;
signal mcastream:streambus_t;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
--
signal event_sim_count,mca_sim_count:unsigned(15 downto 0);
signal mcastream_last:boolean;
signal tick:std_logic;

begin
	
clk <= not clk after CLK_PERIOD/2;

sim:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			event_sim_count <= (others => '0');
			mca_sim_count <= (others => '0');
		else
			if eventstream_ready and eventstream_valid then
				event_sim_count <= event_sim_count+1;
			end if;
			if mcastream_ready and mcastream_valid then
				mca_sim_count <= mca_sim_count+1;
			end if;
		end if;
	end if;
end process sim;

tick <= '1' when event_sim_count(3 downto 0)="1000" else '0';

eventstream.data <= to_std_logic(0,32) & 
										tick & to_std_logic(0,15) &
										to_std_logic(resize(event_sim_count,16));
										
eventstream.keep_n <= (others => FALSE);
eventstream.last <= (0 => TRUE,others => FALSE);

mcastream.data <= to_std_logic(0,48) & 
									to_std_logic(resize(mca_sim_count,16));
									
mcastream.keep_n <= (others => FALSE);
mcastream_last <= mca_sim_count(8 downto 0)="10000000";
mcastream.last <= (0 => mcastream_last,others => FALSE);

UUT:entity work.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  TICK_LATENCY_BITS => TICK_LATENCY_BITS,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY
)
port map(
  clk => clk,
  reset => reset,
  mtu => mtu,
  tick_latency => tick_latency,
  eventstream => eventstream,
  eventstream_valid => eventstream_valid,
  eventstream_ready => eventstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

stimulus:process is
begin
mtu <= to_unsigned(160,MTU_BITS);
tick_latency <= to_unsigned(16,TICK_LATENCY_BITS);
eventstream_valid <= TRUE;
mcastream_valid <= TRUE;
ethernetstream_ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait;
end process stimulus;

end architecture testbench;
