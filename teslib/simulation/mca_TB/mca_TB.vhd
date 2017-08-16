--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15Feb.,2017
--
-- Design Name: TES_digitiser
-- Module Name: mca_buffer_TB
-- Project Name:  mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.registers.all;

entity mca_TB is
generic(
  CHANNELS:integer:=2;
  ADDRESS_BITS:integer:=4;
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICKCOUNT_BITS:integer:=32;
  TICKPERIOD_BITS:integer:=32;
  VALUE_PIPE_DEPTH:natural:=1;
  MINIMUM_TICK_PERIOD:natural:=16;
  ENDIANNESS:string:="LITTLE"
);
end entity mca_TB;

architecture testbench of mca_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  

constant CLK_PERIOD:time:=4 ns;
signal bin:unsigned(ADDRESS_BITS-1 downto 0);
signal out_of_bounds:boolean;
signal stream:streambus_t;
signal valid:boolean;
signal ready:boolean;
signal value:signed(VALUE_BITS-1 downto 0);
signal value_valid:boolean;
signal updated:boolean;
signal registers:mca_registers_t;
signal tick_period:unsigned(TICKPERIOD_BITS-1 downto 0);
signal channel_select:std_logic_vector(CHANNELS-1 downto 0);
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal qualifier_select:std_logic_vector(NUM_MCA_QUAL_D-1 downto 0);

--simulation signals
signal count1,count2:unsigned(ADDRESS_BITS-1 downto 0);
signal clk_count:natural:=0;
---

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.mca
generic map(
  CHANNELS => CHANNELS,
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  VALUE_BITS => VALUE_BITS,
  TOTAL_BITS => TOTAL_BITS,
  TICKCOUNT_BITS => TICKCOUNT_BITS,
  TICKPERIOD_BITS => TICKPERIOD_BITS,
  VALUE_PIPE_DEPTH => VALUE_PIPE_DEPTH,
  MINIMUM_TICK_PERIOD => MINIMUM_TICK_PERIOD,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset,
  --update_asap => update_asap,
  --update_on_completion => update_on_completion,
  updated => updated,
  registers => registers,
  tick_period => tick_period,
  channel_select => channel_select,
  value_select => value_select,
  trigger_select => trigger_select,
  qualifier_select => qualifier_select,
  value => value,
  value_valid => value_valid,
  stream => stream,
  valid => valid,
  ready => ready
);
  
sim:process(clk)
begin
  if rising_edge(clk) then
    if reset  = '1' then
      count1 <= (others => '0');
      count2 <= (others => '0');
    else
      clk_count <= clk_count+1;
      if value_valid then
        if count2=count1 then
          count1 <= count1+1;
          count2 <= (others => '0');
        else
          count2 <= count2+1;
        end if;
      end if;
    end if;
  end if;
end process sim;
bin <= count1;
--ready <= clk_count mod 3/=0;
ready <= TRUE;
--bin <= (others => '0');
--out_of_bounds <= bin=0 or bin=last_bin;
out_of_bounds <= FALSE;
value <= resize(signed('0' & bin),VALUE_BITS);

stimulus:process is
begin
registers.last_bin <= to_unsigned(2**ADDRESS_BITS-1,MCA_ADDRESS_BITS);
registers.bin_n <= to_unsigned(0,MCA_BIN_N_BITS);
registers.lowest_value <= to_signed(1,VALUE_BITS);
registers.channel <= (others => '0');
registers.qualifier <= ALL_MCA_QUAL_D;
registers.trigger <= MCA_DISABLED_D;
registers.value <= MCAVAL_F_D;
registers.update_asap <= FALSE;
registers.update_on_completion <= FALSE;
registers.ticks <= (0 => '0', others => '0');
tick_period <= to_unsigned(136,TICK_PERIOD_BITS);

value_valid <= FALSE;
--ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*4;
registers.update_asap <= TRUE;
registers.trigger <= CLOCK_MCA_TRIGGER_D;
registers.ticks <= (0 => '1', others => '0');
wait for CLK_PERIOD;
registers.update_asap <= FALSE;
wait until updated;
value_valid <= TRUE;
registers.ticks <= (1 => '1', others => '0');
registers.update_on_completion <= TRUE;
wait for CLK_PERIOD;
registers.update_on_completion <= FALSE;

wait;
--wait until count2=2**ADDRESS_BITS-1;
--swap <= TRUE;
--wait for CLK_PERIOD;
--swap <= FALSE;
--wait until count2=2**ADDRESS_BITS-1;
--swap <= TRUE;
--wait for CLK_PERIOD;
--swap <= FALSE;
----wait until count2=2**ADDRESS_BITS-1;
--wait until can_swap;
--swap <= TRUE;
--enabled <= FALSE;
--wait for CLK_PERIOD;
--swap <= FALSE;
wait;
end process stimulus;

end architecture testbench;
