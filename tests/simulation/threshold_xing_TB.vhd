--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:13 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: FIR_stages_TB
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
use teslib.functions.all;
--
library streamlib;
use streamlib.types.all;
-- 
library adclib;
use adclib.types.all;
--
library dsplib;

entity threshold_xing_TB is
generic(
	THRESHOLD_BITS:integer:=18;
	THRESHOLD_FRAC:integer:=3
);
end entity threshold_xing_TB;

architecture testbench of threshold_xing_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;
signal threshold:signed(THRESHOLD_BITS-1 downto 0);
signal value:signed(THRESHOLD_BITS-1 downto 0);
signal pos_xing,closest_pos_xing:boolean;
signal neg_xing,closest_neg_xing:boolean;
signal value_out:signed(THRESHOLD_BITS-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.threshold_xing
generic map(
  THRESHOLD_BITS => THRESHOLD_BITS
)
port map(
  clk => clk,
  reset => reset,
  threshold => threshold,
  signal_in => value,
  pos_xing => pos_xing,
  closest_pos_xing => closest_pos_xing,
  neg_xing => neg_xing,
  closest_neg_xing => closest_neg_xing,
  signal_out => value_out
);


stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
threshold <= to_signed(300,THRESHOLD_BITS-THRESHOLD_FRAC) & 
						 to_signed(0,THRESHOLD_FRAC);
wait for CLK_PERIOD*64;
value <= to_signed(256,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(512,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(1024,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(2048,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(4096,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(2048,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(1024,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(512,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(256,THRESHOLD_BITS);
wait for CLK_PERIOD*16;
--value <= (others => '0');
--wait for CLK_PERIOD*32;
--value <= to_std_logic(to_unsigned(256,THRESHOLD_BITS));
--wait for CLK_PERIOD;
value <= to_signed(512,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(1024,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(2048,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(4096,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(2048,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(1024,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(512,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= to_signed(256,THRESHOLD_BITS);
wait for CLK_PERIOD;
value <= (others => '0');
wait;
end process stimulus;

end architecture testbench;
