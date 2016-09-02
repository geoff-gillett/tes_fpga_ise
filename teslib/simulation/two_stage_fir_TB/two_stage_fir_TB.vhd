--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:16 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: two_stage_fir_TB
-- Project Name: teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
use work.types.all;
use work.registers.all;
use work.dsptypes.all;

entity two_stage_fir_TB is
generic(
  WIDTH:integer:=DSP_BITS 
);
end entity two_stage_fir_TB;

architecture testbench of two_stage_fir_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	

constant CLK_PERIOD:time:=4 ns;
signal adc_sample:signed(WIDTH-1 downto 0);
signal stage1,stage2,sample_out:signed(WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.two_stage_FIR
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  sample_in => adc_sample,
  stage1_config_data => (others => '0'),
  stage1_config_valid => '0',
  stage1_config_ready => open,
  stage1_reload_data => (others => '0'),
  stage1_reload_valid => '0',
  stage1_reload_ready => open,
  stage1_reload_last => '0',
  stage1_reload_last_missing => open,
  stage1_reload_last_unexpected => open,
  stage2_config_data => (others => '0'),
  stage2_config_valid => '0',
  stage2_config_ready => open,
  stage2_reload_data => (others => '0'),
  stage2_reload_valid => '0',
  stage2_reload_ready => open,
  stage2_reload_last => '0',
  stage2_reload_last_missing => open,
  stage2_reload_last_unexpected => open,
  sample_out => sample_out,
  stage1 => stage1,
  stage2 => stage2
);

stimulus:process is
begin
adc_sample <= (others => '0');
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*64;
adc_sample <= to_signed(8000*8,WIDTH);
wait for CLK_PERIOD*32;
adc_sample <= (others => '0');
wait;
end process stimulus;

end architecture testbench;
