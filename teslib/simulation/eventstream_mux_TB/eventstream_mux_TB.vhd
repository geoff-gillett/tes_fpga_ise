--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:25 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: eventstream_mux_TB
-- Project Name: eventlib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;
use work.functions.all;

library streamlib;
use streamlib.types.all;

entity eventstream_mux_TB is
generic(
  CHANNEL_BITS:integer:=1;
  RELTIME_BITS:integer:=TIME_BITS;
  TIMESTAMP_BITS:integer:=64;
  TICK_BITS:integer:=32;
  MIN_TICKPERIOD:integer:=8
);
end entity eventstream_mux_TB;

architecture testbench of eventstream_mux_TB is
constant CHANNELS:integer:=2**CHANNEL_BITS;

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal start:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal commit:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal dump:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal instreams:streambus_array(2**CHANNEL_BITS-1 downto 0);
signal instream_valids:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal instream_readys:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal full:boolean;
signal tick_period:unsigned(TICK_BITS-1 downto 0);
signal overflows:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal muxstream:streambus_t;
signal valid:boolean;
signal ready:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

busGen:for c in 0 to CHANNELS-1 generate
begin
	instreams(c).data <= to_std_logic(c,BUS_DATABITS);
	instreams(c).discard <= (others => FALSE);
	instreams(c).last <= (0 => TRUE,others => FALSE);
end generate;

UUT:entity work.eventstream_mux
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  RELTIME_BITS => RELTIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICK_BITS,
  MIN_TICKPERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => 2
)
port map(
  clk => clk,
  reset => reset,
  start => start,
  commit => commit,
  dump => dump,
  instreams => instreams,
  instream_valids => instream_valids,
  instream_readys => instream_readys,
  full => full,
  tick_period => tick_period,
  overflows => overflows,
  muxstream => muxstream,
  valid => valid,
  ready => ready
);

--UUT:entity work.eventstream_mux
--generic map(
--  CHANNEL_BITS => CHANNEL_BITS,
--  RELTIME_BITS => RELTIME_BITS,
--  TIMESTAMP_BITS => TIMESTAMP_BITS,
--  TICKPERIOD_BITS => TICK_BITS,
--  MIN_TICKPERIOD => MIN_TICKPERIOD,
--  TICKPIPE_DEPTH => 2
--)
--port map(
--  clk => clk,
--  reset => reset,
--  start => start,
--  commit => commit,
--  dump => dump,
--  instreams => instreams,
--  instream_valids => instream_valids,
--  instream_readys => instream_readys,
--  full => full,
--  tick_period => tick_period,
--  overflows => overflows,
--  stream => outstream,
--  valid => valid,
--  ready => ready
--);

stimulus:process is
begin
start <= (others => FALSE);
commit <= (others => FALSE);
tick_period <= to_unsigned(16,TICK_BITS);
overflows <= (others => FALSE);
instream_valids <= (others => TRUE);
ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*4;
start <= (others => TRUE);
wait for CLK_PERIOD;
start <= (others => FALSE);
wait for CLK_PERIOD*4;
commit <= (others => TRUE);
wait for CLK_PERIOD;
commit <= (others => FALSE);
wait;
end process stimulus;

end architecture testbench;
