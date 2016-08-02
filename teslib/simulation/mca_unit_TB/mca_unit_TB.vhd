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
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICK_COUNT_BITS:integer:=32;
  TICK_PERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=8;
	NUM_VALUES:integer:=NUM_MCA_VALUE_D;
	NUM_VALIDS:integer:=NUM_MCA_TRIGGER_D-1
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
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal values:mca_value_array(CHANNELS-1 downto 0);
signal value_valid:boolean;
signal stream:streambus_t;
signal valids:boolean_vector(CHANNELS-1 downto 0);
signal ready:boolean;
signal measurements:measurement_array(CHANNELS-1 downto 0);
signal value:signed(VALUE_BITS-1 downto 0);
signal valid: boolean;
signal initialising:boolean;
signal tick_period:unsigned(TICK_PERIOD_BITS-1 downto 0);

begin
	
clk <= not clk after CLK_PERIOD/2;

value <= X"00000001";
value_valid <= TRUE;
UUT:entity work.mca_unit
  generic map(
    CHANNELS => CHANNELS,
    ADDRESS_BITS => ADDRESS_BITS,
    COUNTER_BITS => COUNTER_BITS,
    VALUE_BITS => VALUE_BITS,
    TOTAL_BITS => TOTAL_BITS,
    TICKCOUNT_BITS => 32,
    TICKPERIOD_BITS => 32,
    MIN_TICK_PERIOD => MIN_TICK_PERIOD,
    TICKPIPE_DEPTH => TICKPIPE_DEPTH,
    ENDIANNESS => ENDIANNESS
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
registers.bin_n <= to_unsigned(0,MCA_BIN_N_BITS);
registers.channel <= to_unsigned(0,3);
registers.value <= MCA_FILTERED_SIGNAL_D;
registers.trigger <= CLOCK_MCA_TRIGGER_D;
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
wait for CLK_PERIOD*128;
registers.ticks <= to_unsigned(10,MCA_TICKCOUNT_BITS);
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait for CLK_PERIOD*1280;
registers.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait;
end process stimulus;

end architecture testbench;
