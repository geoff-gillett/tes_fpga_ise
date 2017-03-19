--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:19Mar.,2017
--
-- Design Name: TES_digitiser
-- Module Name: fir_reload_TB
-- Project Name:  teslib  
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

library dsp;
use dsp.types.all;

use work.registers.all;
use work.types.all;
use work.registers.all;
use work.measurements.all;

entity fir_reload_TB is
generic(
	CHANNEL:integer:=0;
  FILTER_COEF_WIDTH:natural:=23;
  SLOPE_COEF_WIDTH:natural:=25;
  BASELINE_COEF_WIDTH:natural:=25;
  DSP_CHANNELS:natural:=2;
  ADC_CHANNELS:natural:=2;
  VALUE_PIPE_DEPTH:natural:=1;
	ENDIAN:string:="LITTLE";
	PACKET_GEN:boolean:=FALSE;
	ADC_WIDTH:integer:=14;
	WIDTH:integer:=18;
	FRAC:integer:=3;
	WIDTH_OUT:integer:=16;
	FRAC_OUT:integer:=3;
	SLOPE_FRAC:natural:=8;
	SLOPE_FRAC_OUT:natural:=8;
	AREA_WIDTH:natural:=32;
	AREA_FRAC:natural:=1
);
end entity fir_reload_TB;

architecture testbench of fir_reload_TB is

signal clk:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;
signal reset1:std_logic:='1';
signal reset2:std_logic:='1';

signal data:registerdata_array(DSP_CHANNELS-1 downto 0);
signal address:registeraddress_array(DSP_CHANNELS-1 downto 0);
signal write:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal value:registerdata_array(DSP_CHANNELS-1 downto 0);
signal mca_interrupt:boolean;
signal samples:adc_sample_array(ADC_CHANNELS-1 downto 0);
signal channel_reg:channel_register_array(DSP_CHANNELS-1 downto 0);
signal global_reg:global_registers_t;
signal measurements:measurements_array(DSP_CHANNELS-1 downto 0);
signal ethernetstream:streambus_t;
signal filter_config:fir_ctl_in_array(DSP_CHANNELS-1 downto 0);
signal filter_events:fir_ctl_out_array(DSP_CHANNELS-1 downto 0);
signal slope_config:fir_ctl_in_array(DSP_CHANNELS-1 downto 0);
signal slope_events:fir_ctl_out_array(DSP_CHANNELS-1 downto 0);
signal baseline_config:fir_ctl_in_array(DSP_CHANNELS-1 downto 0);
signal baseline_events:fir_ctl_out_array(DSP_CHANNELS-1 downto 0);
signal registers:channel_register_array(DSP_CHANNELS-1 downto 0);
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;

begin
clk <= not clk after CLK_PERIOD/2;

chanGen:for c in 0 to DSP_CHANNELS-1 generate
  UUT:entity work.channel_registers2
  generic map(
    CHANNEL => CHANNEL,
    FILTER_COEF_WIDTH => FILTER_COEF_WIDTH,
    SLOPE_COEF_WIDTH => SLOPE_COEF_WIDTH,
    BASELINE_COEF_WIDTH => BASELINE_COEF_WIDTH
  )
  port map(
    clk => clk,
    reset => reset1,
    data => data(c),
    address => address(c),
    write => write(c),
    value => value(c),
    registers => registers(c),
    filter_config => filter_config(c),
    filter_events => filter_events(c),
    slope_config => slope_config(c),
    slope_events => slope_events(c),
    baseline_config => baseline_config(c),
    baseline_events => baseline_events(c)
  ); 
end generate;

measurement:entity work.measurement_subsystem3
generic map(
  DSP_CHANNELS => DSP_CHANNELS,
  ADC_CHANNELS => ADC_CHANNELS,
  VALUE_PIPE_DEPTH => VALUE_PIPE_DEPTH,
  ENDIAN => ENDIAN,
  PACKET_GEN => PACKET_GEN,
  ADC_WIDTH => ADC_WIDTH,
  WIDTH => WIDTH,
  FRAC => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  SLOPE_FRAC => SLOPE_FRAC,
  SLOPE_FRAC_OUT => SLOPE_FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  mca_interrupt => mca_interrupt,
  samples => samples,
  channel_reg => channel_reg,
  global_reg => global_reg,
  filter_config => filter_config,
  filter_events => filter_events,
  slope_config => slope_config,
  slope_events => slope_events,
  baseline_config => baseline_config,
  baseline_events => baseline_events,
  measurements => measurements,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

stimulus:process is
begin
samples <= (others => (others => '0'));
write <= (others => '0');
address(1) <= (others => '-');
address(0) <= (23 => '1', others => '0');
data  <=  (others => (others => '0'));
wait for CLK_PERIOD;
reset1 <= '0';
wait for CLK_PERIOD*16;
reset2 <= '0';
wait for CLK_PERIOD;
data(0) <= (27 => '1', others => '0');
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
wait until value(0)(0)='1';
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
wait until value(0)(0)='1';
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
wait until value(0)(0)='1';
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
wait until value(0)(0)='1';
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
wait until value(0)(0)='1';
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
wait until value(0)(0)='1';
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
wait until value(0)(0)='1';
data(0) <= (27 => '1', others => '0');
write(0) <= '1';
wait for CLK_PERIOD;
write(0) <= '0';
--wait until value(0)(0)='1';
--write(0) <= '1';
--wait for CLK_PERIOD;
--write(0) <= '0';
wait;
end process stimulus;

end architecture testbench;
