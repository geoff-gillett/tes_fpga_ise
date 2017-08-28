--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:26 Aug. 2017
--
-- Design Name: TES_digitiser
-- Module Name: FIR_TB
-- Project Name:  dsplib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity FIR_TB is
  generic(
    WIDTH:natural:=16;
    FRAC:natural:=3;
    SLOPE_FRAC:natural:=7
  );
end entity FIR_TB;

architecture testbench of FIR_TB is

signal clk:std_logic:='1';  
signal resetn:std_logic:='0';  
constant CLK_PERIOD:time:=4 ns;
signal sample_in:signed(WIDTH-1 downto 0);
signal stage1_config:fir_control_in_t;
signal stage2_config:fir_control_in_t;
signal f:signed(WIDTH-1 downto 0);
signal s:signed(WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

stage1_config.config_data <= (others => '0');
stage1_config.config_valid <= '0';
stage1_config.reload_data <= (others => '0');
stage1_config.reload_last <= '0';
stage1_config.reload_valid <= '0';
stage2_config.config_data <= (others => '0');
stage2_config.config_valid <= '0';
stage2_config.reload_data <= (others => '0');
stage2_config.reload_last <= '0';
stage2_config.reload_valid <= '0';

UUT:entity work.FIR_SYM141_ASYM23_OUT16_3
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  SLOPE_FRAC => SLOPE_FRAC
)
port map(
  clk => clk,
  resetn => resetn,
  sample_in => sample_in,
  stage1_config => stage1_config,
  stage1_events => open,
  stage2_config => stage2_config,
  stage2_events => open,
  stage1 => f,
  stage2 => s
);

stimulus:process is
begin
sample_in <= (others => '0');
wait for CLK_PERIOD*40;
resetn <= '1';
wait for 250*CLK_PERIOD;
sample_in <= to_signed(3000, WIDTH);
wait for CLK_PERIOD;
--sample_in <= (others => '0');
wait;
end process stimulus;

end architecture testbench;
