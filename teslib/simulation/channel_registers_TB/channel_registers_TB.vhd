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
  CONFIG_BITS:natural:=8;
	CONFIG_WIDTH:integer:=8;
	--bits in a filter coefficient
	COEF_BITS:integer:=25; 
	--width in the filter reload axi-stream
	COEF_WIDTH:integer:=32
);
end entity channel_registers_TB;

architecture testbench of channel_registers_TB is
  
component baseline_av
port (
  aclk:in std_logic;
  aclken:in std_logic;
  s_axis_data_tvalid:in std_logic;
  s_axis_data_tready:out std_logic;
  s_axis_data_tdata:in std_logic_vector(23 downto 0);
  s_axis_config_tvalid:in std_logic;
  s_axis_config_tready:out std_logic;
  s_axis_config_tdata:in std_logic_vector(7 downto 0);
  s_axis_reload_tvalid:in std_logic;
  s_axis_reload_tready:out std_logic;
  s_axis_reload_tlast:in std_logic;
  s_axis_reload_tdata:in std_logic_vector(31 downto 0);
  m_axis_data_tvalid:out std_logic;
  m_axis_data_tdata:out std_logic_vector(47 downto 0);
  event_s_reload_tlast_missing:out std_logic;
  event_s_reload_tlast_unexpected:out std_logic
);
end component;

signal clk:std_logic:='1';  
signal reset1,reset2:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal data:register_data_t; 
signal address:register_address_t;
signal write:std_logic;
signal value:register_data_t;
signal axis_done:std_logic;
signal axis_error:std_logic;
signal registers:channel_registers_t;
signal filter_config:fir_control_in_t;
signal filter_events:fir_control_out_t;
signal slope_config:fir_control_in_t;
signal slope_events:fir_control_out_t;
signal baseline_config:fir_control_in_t;
signal baseline_events:fir_control_out_t;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.channel_registers
generic map(
  CHANNEL      => CHANNEL,
  CONFIG_BITS  => CONFIG_BITS,
  CONFIG_WIDTH => CONFIG_WIDTH,
  COEF_BITS    => COEF_BITS,
  COEF_WIDTH   => COEF_WIDTH
)
port map(
  clk => clk,
  reset => reset1,
  data => data,
  address => address,
  write => write,
  value => value,
  axis_done => axis_done,
  axis_error => axis_error,
  registers => registers,
  filter_config => filter_config,
  filter_events => filter_events,
  slope_config => slope_config,
  slope_events => slope_events,
  baseline_config => baseline_config,
  baseline_events => baseline_events
);

chan:entity work.channel4
  generic map(
    CHANNEL => 0,
    WIDTH => 18,
    FRAC => 3,
    WIDTH_OUT => 16,
    FRAC_OUT => 1,
    ADC_WIDTH => 14,
    AREA_WIDTH => AREA_WIDTH,
    AREA_FRAC => AREA_FRAC,
    CFD_DELAY => 1026,
    ENDIAN => "LITTLE"
  )
  port map(
    clk => clk,
    reset1 => reset1,
    reset2 => reset2,
    adc_sample => (others => '0'),
    registers => registers,
    event_enable => TRUE,
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
wait for CLK_PERIOD;
reset1 <= '0';
wait for CLK_PERIOD*16;
address(BASELINE_RELOAD_ADDR_BIT) <= '1';
value <= (0 => '1', others => '0');
write <= '1';
wait for CLK_PERIOD;
wait;

end process stimulus;

end architecture testbench;
