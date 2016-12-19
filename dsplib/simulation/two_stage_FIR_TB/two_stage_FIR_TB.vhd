--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:19Dec.,2016
--
-- Design Name: TES_digitiser
-- Module Name: two_stage_FIR_TB
-- Project Name: dsplib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library extensions;
use extensions.debug.all;

use work.types.all;

entity two_stage_FIR_TB is
generic(WIDTH:natural:=18);
end entity two_stage_FIR_TB;

architecture testbench of two_stage_FIR_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal sample:signed(WIDTH-1 downto 0);
signal stage1_config:fir_control_in_t;
signal stage1_events:fir_control_out_t;
signal stage2_config:fir_control_in_t;
signal stage2_events:fir_control_out_t;
signal stage1:signed(WIDTH-1 downto 0);
signal stage2:signed(WIDTH-1 downto 0);

constant SIM_WIDTH:natural:=8;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal squaresig:signed(WIDTH-1 downto 0);
signal simenable:boolean:=FALSE;

file trace_file:integer_file;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.two_stage_FIR71
port map(
  clk => clk,
  sample_in => sample,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  stage1 => stage1,
  stage2 => stage2
);

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
	while TRUE loop
    wait until rising_edge(clk);
	  writeInt(trace_file,signed(stage1),"BIG");
	  writeInt(trace_file,signed(stage2),"BIG");
	end loop;
end process traceWriter; 

stimulusFile:process
file sample_file:text is in "../input_signals/double_peak";
variable file_line:line; -- text line buffer 
variable str_sample:string(4 downto 1);
variable sample_in:std_logic_vector(15 downto 0);
begin
while not endfile(sample_file) loop
  readline(sample_file, file_line);
  read(file_line, str_sample);
  sample_in:=hexstr2vec(str_sample);
  wait until rising_edge(clk);
  sample <= signed(sample_in(14 downto 0) & "000");
end loop;
wait;
end process stimulusFile;

simsquare:process (clk) is
begin
  if rising_edge(clk) then
    if not simenable then
      sim_count <= (others => '0');
    else
      sim_count <= sim_count+1;
    end if;
  end if;
end process simsquare;
squaresig <= to_signed(-100,WIDTH)
             when sim_count(SIM_WIDTH-1)='0' 
             else to_signed(400,WIDTH);
--sample <= squaresig;

stimulus:process is
begin
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
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*1500;
simenable <= TRUE;
wait;
end process stimulus;

end architecture testbench;
