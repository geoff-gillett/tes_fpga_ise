--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20Dec.,2016
--
-- Design Name: TES_digitiser
-- Module Name: channel_registers_TB
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dsp;
use dsp.types.all;

use work.registers.all;
use work.types.all; --TODO move register defs to registers package

entity channel_registers_TB is
generic(
  CHANNEL:natural:=0;
  FILTER_COEF_WIDTH:natural:=23;
  SLOPE_COEF_WIDTH:natural:=25;
  BASELINE_COEF_WIDTH:natural:=25
);
end entity channel_registers_TB;

architecture testbench of channel_registers_TB is
  
signal clk:std_logic:='1';  
signal reset1,reset2:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal data:register_data_t; 
signal address:register_address_t;
signal write:std_logic;
signal value:register_data_t;
signal registers:channel_registers_t;
signal filter_config:fir_control_in_t;
signal filter_events:fir_control_out_t;
signal slope_config:fir_control_in_t;
signal slope_events:fir_control_out_t;
signal baseline_config:fir_control_in_t;
signal baseline_events:fir_control_out_t;

constant LAST_BIT:natural:=31;
constant RESET_BIT:natural:=30;
constant FILTER_BIT:natural:=29;
constant SLOPE_BIT:natural:=28;
constant BASELINE_BIT:natural:=27;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.channel_registers2
generic map(
  CHANNEL      => CHANNEL,
  FILTER_COEF_WIDTH => FILTER_COEF_WIDTH,
  SLOPE_COEF_WIDTH => SLOPE_COEF_WIDTH,
  BASELINE_COEF_WIDTH => BASELINE_COEF_WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  data => data,
  address => address,
  write => write,
  value => value,
  registers => registers,
  filter_config => filter_config,
  filter_events => filter_events,
  slope_config => slope_config,
  slope_events => slope_events,
  baseline_config => baseline_config,
  baseline_events => baseline_events
);

chan:entity work.channel_FIR71
  generic map(
    CHANNEL => 0,
    WIDTH => 18,
    FRAC => 3,
    WIDTH_OUT => 16,
    FRAC_OUT => 1,
    ADC_WIDTH => 14,
    AREA_WIDTH => AREA_WIDTH,
    AREA_FRAC => AREA_FRAC,
    ENDIAN => "LITTLE"
  )
  port map(
    clk => clk,
    reset1 => reset1,
    reset2 => reset2,
    adc_sample => (others => '0'),
    registers => registers,
    event_enable => FALSE,
    stage1_config => filter_config,
    stage1_events => filter_events,
    stage2_config => slope_config,
    stage2_events => slope_events,
    baseline_config => baseline_config,
    baseline_events => baseline_events,
    start => open,
    commit => open,
    dump => open,
    framer_overflow => open,
    framer_error => open,
    measurements => open,
    stream => open,
    valid => open,
    ready => FALSE
  );

stimulus:process is
begin
data <= (SLOPE_BIT => '1', others => '0');
address <= (FIR_RELOAD_ADDR_BIT =>'1', others => '0');
write <= '0';
wait for CLK_PERIOD;
reset1 <= '0';
reset2 <= '0';

wait for CLK_PERIOD*10;
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD*1;
write <= '0';

--wait until value(0)='1';
--write <= '1';
--wait for CLK_PERIOD*1;
--write <= '0';

--wait until value(0)='1';
--write <= '1';
--wait for CLK_PERIOD*1;
--write <= '0';

data <= (LAST_BIT => '1', SLOPE_BIT => '1', others => '0');
wait until value(0)='1';
write <= '1';
wait for CLK_PERIOD;
write <= '0';

wait;
end process stimulus;

end architecture testbench;
