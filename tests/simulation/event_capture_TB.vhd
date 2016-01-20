--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:14 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: event_capture_TB
-- Project Name: tests 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;

library streamlib;
use streamlib.stream.all;
use streamlib.events.all;

entity event_capture_TB is
generic(
  CHANNEL:integer:=1;
  PEAK_COUNT_BITS:integer:=4;
  ADDRESS_BITS:integer:=9;
  BUS_CHUNKS:integer:=4
);
end entity event_capture_TB;

architecture testbench of event_capture_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
--
signal rel_to_min:boolean;
signal use_cfd_timing:boolean;
signal signal_in:signal_t;
signal peak:boolean;
signal peak_start:boolean;
signal overflow:boolean;
signal pulse_pos_xing:boolean;
signal pulse_neg_xing:boolean;
signal cfd_low:boolean;
signal cfd_high:boolean;
signal cfd_error:boolean;
signal minima:signal_t;
signal slope_area:area_t;
signal enqueue:boolean;
signal dump:boolean;
signal commit:boolean;
signal peak_count:unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
signal height:signal_t;
signal eventstream:streambus;
signal valid:boolean;
signal ready:boolean;
signal height_format:heighttype;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity streamlib.event_capture
generic map(
  CHANNEL => CHANNEL,
  PEAK_COUNT_BITS => PEAK_COUNT_BITS,
  ADDRESS_BITS => ADDRESS_BITS,
  BUS_CHUNKS => BUS_CHUNKS
)
port map(
  clk => clk,
  reset => reset,
	height_format => height_format,
  rel_to_min => rel_to_min,
  use_cfd_timing => use_cfd_timing,
  signal_in => signal_in,
  peak => peak,
  peak_start => peak_start,
  overflow => overflow,
  pulse_pos_xing => pulse_pos_xing,
  pulse_neg_xing => pulse_neg_xing,
  cfd_low => cfd_low,
  cfd_high => cfd_high,
  cfd_error => cfd_error,
  --minima => minima,
  slope_area => slope_area,
  enqueue => enqueue,
  dump => dump,
  commit => commit,
  peak_count => peak_count,
  height => height,
  eventstream => eventstream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
height_format <= CFD_HEIGHT;
rel_to_min <= TRUE;
use_cfd_timing <= TRUE;
signal_in <= (others => '0');
peak <= FALSE;
peak_start <= FALSE;
pulse_pos_xing <= FALSE;
pulse_neg_xing <= FALSE;
cfd_low <= FALSE;
cfd_high <= FALSE;
minima <= (others => '0');
slope_area <= (others => '0');
ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
peak_start <= TRUE;
wait for CLK_PERIOD;
peak_start <= FALSE;
signal_in <= to_signed(100,SIGNAL_BITS);
pulse_pos_xing <= TRUE;
wait for CLK_PERIOD;
pulse_pos_xing <= FALSE;
cfd_low <= TRUE;
wait for CLK_PERIOD;
cfd_low <= FALSE;
cfd_high <= TRUE;
wait for CLK_PERIOD;
cfd_high <= FALSE;
peak_start <= TRUE;
wait for CLK_PERIOD;
peak_start <= FALSE;
cfd_low <= TRUE;
wait for CLK_PERIOD;
cfd_high <= TRUE;
wait for CLK_PERIOD;
cfd_high <= FALSE;
pulse_neg_xing <= TRUE;
wait for CLK_PERIOD;
pulse_neg_xing <= FALSE;
wait;
end process stimulus;

end architecture testbench;
