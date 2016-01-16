--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:8 Dec 2015
--
-- Design Name: TES_digitiser
-- Module Name: baseline_estimator_TB
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
--
library dsplib;


entity baseline_estimator_TB is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  BASELINE_BITS:integer:=10;
  --width of counters and stream
  COUNTER_BITS:integer:=18;
  TIMECONSTANT_BITS:integer:=32;
  MAX_AVERAGE_ORDER:integer:=7;
  OUT_BITS:integer:=16
);
end entity baseline_estimator_TB;

architecture testbench of baseline_estimator_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal sample:sample_t;
signal sample_valid:boolean;
signal timeconstant:unsigned(TIMECONSTANT_BITS-1 downto 0);
signal threshold:unsigned(BASELINE_BITS-2 downto 0);
signal count_threshold:unsigned(COUNTER_BITS-1 downto 0);
signal average_order:natural range 0 to MAX_AVERAGE_ORDER;
signal baseline_estimate:signed(OUT_BITS-1 downto 0);
signal range_error:boolean;
signal new_only:boolean;
begin
	
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.baseline_estimator
generic map(
  BASELINE_BITS => BASELINE_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS,
  MAX_AVERAGE_ORDER => MAX_AVERAGE_ORDER,
  OUT_BITS => OUT_BITS
)
port map(
  new_only => new_only,
  clk => clk,
  reset => reset,
  sample => sample,
  sample_valid => sample_valid,
  timeconstant => timeconstant,
  threshold => threshold,
  count_threshold => count_threshold,
  average_order => average_order,
  baseline_estimate => baseline_estimate,
  range_error => range_error
);
--
stimulus:process is
begin
sample <= to_signed(0,SAMPLE_BITS);
timeconstant <= to_unsigned((2**BASELINE_BITS)*4,TIMECONSTANT_BITS);
sample_valid <= TRUE;
threshold <= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
count_threshold <= to_unsigned(30,COUNTER_BITS);
average_order <= 7;
new_only <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait;
end process stimulus;

end architecture testbench;
