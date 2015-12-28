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
	WIDTH:integer:=18
);
end entity two_stage_FIR_TB;

architecture testbench of two_stage_FIR_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';
	
constant CLK_PERIOD:time:=4 ns;
signal sample:signed(WIDTH-1 downto 0);
--signal interstage_shift:unsigned(bits(STAGE1_OUT_WIDTH-SIGNAL_BITS)-1 downto 0);
signal stage1_config_data:std_logic_vector(7 downto 0);
signal stage1_config_valid:boolean;
signal stage1_config_ready:boolean;
signal stage1_reload_data:std_logic_vector(31 downto 0);
signal stage1_reload_valid:boolean;
signal stage1_reload_ready:boolean;
signal stage1_reload_last:boolean;
signal stage2_config_data:std_logic_vector(7 downto 0);
signal stage2_config_valid:boolean;
signal stage2_config_ready:boolean;
signal stage2_reload_data:std_logic_vector(31 downto 0);
signal stage2_reload_valid:boolean;
signal stage2_reload_ready:boolean;
signal stage2_reload_last:boolean;
signal stage1:signed(WIDTH-1 downto 0);
signal stage2:signed(WIDTH-1 downto 0);
signal sim_sample:unsigned(ADC_BITS-1 downto 0);
begin
clk <= not clk after CLK_PERIOD/2;

sim : process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			sim_sample <= (others => '0');
		else
			if sim_sample=127 then
				sim_sample <= (others => '0');
			else
				sim_sample <=sim_sample+1;
			end if;
		end if;
	end if;
end process sim;


UUT:entity dsplib.two_stage_FIR
generic map(
	WIDTH => WIDTH
)
port map(
  clk => clk,
  sample_in => sample,
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

--sample <= shift_left(resize(signed(sim_sample),WIDTH),WIDTH-SAMPLE_BITS);

stimulus:process is
begin
wait for CLK_PERIOD;
stage1_config_data <= (others => '0');
stage1_config_valid <= FALSE;
stage1_reload_data <= (others => '0');
stage1_reload_valid <= FALSE;
stage1_reload_last <= FALSE;
stage2_config_data <= (others => '0');
stage2_config_valid <= FALSE;
stage2_reload_data <= (others => '0');
stage2_reload_valid <= FALSE;
stage2_reload_last <= FALSE;
reset <= '0';
sample <= (others => '0');
wait for CLK_PERIOD*16;
sample <= to_signed(2**14,WIDTH);
wait for CLK_PERIOD;
sample <= to_signed(0,WIDTH);
wait;
end process stimulus;

end architecture testbench;
