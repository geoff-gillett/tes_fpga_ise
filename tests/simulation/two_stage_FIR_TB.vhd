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
library dsplib;

entity two_stage_FIR_TB is
generic(
	STAGE1_IN_BITS:integer:=18;
	INTERSTAGE_SHIFT:integer:=22;
	STAGE1_OUT_WIDTH:integer:=45;
	STAGE2_OUT_WIDTH:integer:=48
);
end entity two_stage_FIR_TB;

architecture testbench of two_stage_FIR_TB is

signal clk:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;
signal sample:sample_t;
--signal interstage_shift:unsigned(bits(STAGE1_OUT_WIDTH-SIGNAL_BITS)-1 downto 0);
signal stage1_config_data:std_logic_vector(7 downto 0);
signal stage1_config_valid:boolean;
signal stage1_config_ready:boolean;
signal stage1_reload_data:std_logic_vector(31 downto 0);
signal stage1_reload_valid:boolean;
signal stage1_reload_ready:boolean;
signal stage1_reload_last:boolean;
signal stage2_shift:unsigned(bits(STAGE2_OUT_WIDTH-SIGNAL_BITS)-1 downto 0);
signal stage2_config_data:std_logic_vector(7 downto 0);
signal stage2_config_valid:boolean;
signal stage2_config_ready:boolean;
signal stage2_reload_data:std_logic_vector(31 downto 0);
signal stage2_reload_valid:boolean;
signal stage2_reload_ready:boolean;
signal stage2_reload_last:boolean;
signal stage1:std_logic_vector(STAGE1_OUT_WIDTH-1 downto 0);
signal stage2:std_logic_vector(STAGE2_OUT_WIDTH-1 downto 0);
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity dsplib.two_stage_FIR
generic map(
	STAGE1_IN_BITS => STAGE1_IN_BITS,
  INTERSTAGE_SHIFT => INTERSTAGE_SHIFT,
  STAGE1_OUT_WIDTH => STAGE1_OUT_WIDTH,
  STAGE2_OUT_WIDTH => STAGE2_OUT_WIDTH
)
port map(
  clk => clk,
  sample => sample,
  --interstage_shift => interstage_shift,
  stage1_config_data => stage1_config_data,
  stage1_config_valid => stage1_config_valid,
  stage1_config_ready => stage1_config_ready,
  stage1_reload_data=> stage1_reload_data,
  stage1_reload_valid => stage1_reload_valid,
  stage1_reload_ready => stage1_reload_ready,
  stage1_reload_last => stage1_reload_last,
  stage2_config_data => stage2_config_data,
  stage2_config_valid => stage2_config_valid,
  stage2_config_ready => stage2_config_ready,
  stage2_reload_data => stage2_reload_data,
  stage2_reload_valid => stage2_reload_valid,
  stage2_reload_ready => stage2_reload_ready,
  stage2_reload_last => stage2_reload_last,
  stage1 => stage1,
  stage2 => stage2
);

stimulus:process is
begin
sample <= (others => '0');
--interstage_shift <= to_unsigned(22,bits(STAGE1_OUT_WIDTH-SIGNAL_BITS));
stage1_config_data <= (others => '0');
stage1_config_valid <= FALSE;
stage1_reload_data <= (others => '0');
stage1_reload_valid <= FALSE;
stage1_reload_last <= FALSE;
stage2_shift <= to_unsigned(21,bits(STAGE1_OUT_WIDTH-SIGNAL_BITS));
stage2_config_data <= (others => '0');
stage2_config_valid <= FALSE;
stage2_reload_data <= (others => '0');
stage2_reload_valid <= FALSE;
stage2_reload_last <= FALSE;
wait for CLK_PERIOD*64;
sample <= to_signed(2**14-1,SAMPLE_BITS);
wait for CLK_PERIOD;
sample <= (others => '0');
wait;
end process stimulus;

end architecture testbench;
