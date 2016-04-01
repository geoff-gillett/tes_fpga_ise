--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:3 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: mca_unit_TB
-- Project Name: TES_digitiser 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

library streamlib;
use streamlib.types.all;

--use work.protocol.all;
use work.registers.all;
use work.measurements.all;
use work.types.all;
use work.events.all;

entity mca_unit_TB is
generic(
  CHANNEL_BITS:integer:=1;
  ADDRESS_BITS:integer:=4;
  COUNTER_BITS:integer:=8;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICK_COUNT_BITS:integer:=32;
  TICK_PERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=8;
	NUM_VALUES:integer:=NUM_MCA_VALUES;
	NUM_VALIDS:integer:=NUM_MCA_TRIGGERS-1
);
end entity mca_unit_TB;

architecture testbench of mca_unit_TB is
constant CHANNELS:integer:=2**CHANNEL_BITS;
signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal update_asap:boolean;
signal update_on_completion:boolean;
signal updated:boolean;
signal registers:mca_registers_t;
signal channel_select:std_logic_vector(2**CHANNEL_BITS-1 downto 0);
signal value_select:std_logic_vector(NUM_MCA_VALUES-1 downto 0);
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGERS-2 downto 0);
signal values:mca_value_array(CHANNELS-1 downto 0);
signal value_valid:boolean;
signal stream:streambus_t;
signal valids:boolean_vector(CHANNELS-1 downto 0);
signal ready:boolean;
signal measurements:measurement_array_t(CHANNELS-1 downto 0);
signal value:signed(VALUE_BITS-1 downto 0);
signal valid: boolean;
signal initialising:boolean;
signal tick_period:unsigned(TICK_PERIOD_BITS-1 downto 0);

begin
	
clk <= not clk after CLK_PERIOD/2;

chanGen:for c in 0 to CHANNELS-1 generate
begin
	
	measurements(c).filtered.sample <= to_signed(c,SIGNAL_BITS);
	measurements(c).slope.sample <= to_signed(-c,SIGNAL_BITS);
		
  valueSelector:entity work.mca_value_selector
  generic map(
    VALUE_BITS => VALUE_BITS,
    NUM_VALUES => NUM_VALUES,
    NUM_VALIDS => NUM_VALIDS
  )
  port map(
    clk => clk,
    reset => reset,
    measurements => measurements(c),
    value_select => value_select,
    trigger_select => trigger_select,
    value => values(c),
    valid => valids(c)
  );
  
end generate;

channelSelector:entity work.mca_channel_selector
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  VALUE_BITS   => VALUE_BITS
)
port map(
  clk => clk,
  reset => reset,
  channel_select => channel_select,
  values => values,
  valids => valids,
  value => value,
  valid => value_valid
);

UUT:entity work.mca_unit
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  VALUE_BITS => VALUE_BITS,
  TOTAL_BITS => TOTAL_BITS,
  TICKCOUNT_BITS => TICK_COUNT_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICK_PERIOD => MIN_TICK_PERIOD
)
port map(
  clk => clk,
  reset => reset,
  initialising => initialising,
  update_asap => update_asap,
  update_on_completion => update_on_completion,
  updated => updated,
  registers => registers,
  tick_period => tick_period,
  channel_select => channel_select,
  value_select => value_select,
  trigger_select => trigger_select,
  value => value,
  value_valid => value_valid,
  stream => stream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
registers.bin_n <= to_unsigned(0,MCA_BIN_N_WIDTH);
registers.channel <= to_unsigned(0,CHANNEL_WIDTH);
registers.value <= MCA_FILTERED_SIGNAL;
registers.trigger <= CLOCK_MCA_TRIGGER;
registers.last_bin <= to_unsigned(2**ADDRESS_BITS-1,MCA_ADDRESS_BITS);
registers.lowest_value <= to_signed(-1,MCA_VALUE_BITS);
registers.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
tick_period <= to_unsigned(32,TICK_PERIOD_BITS);
update_asap <= FALSE;
update_on_completion <= FALSE;
--value <= (others => '0');
--value_valid <= TRUE;
ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait until not initialising;
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait until updated;
wait for CLK_PERIOD;
registers.channel <= to_unsigned(1,CHANNEL_WIDTH);
update_on_completion <= TRUE;
wait for CLK_PERIOD;
update_on_completion <= FALSE;
wait until updated;
wait for CLK_PERIOD;
registers.value <= MCA_SLOPE_SIGNAL;
update_on_completion <= TRUE;
wait for CLK_PERIOD;
update_on_completion <= FALSE;

wait;
end process stimulus;

end architecture testbench;
