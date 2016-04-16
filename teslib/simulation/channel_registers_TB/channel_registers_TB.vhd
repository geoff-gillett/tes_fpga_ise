--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Apr 2016
--
-- Design Name: TES_digitiser
-- Module Name: channel_registers_TB
-- Project Name: teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;

use work.types.all;
use work.registers.all;

entity channel_registers_TB is
generic(
	CONFIG_BITS:integer:=7;
	CONFIG_STREAM_WIDTH:integer:=7;
	COEF_BITS:integer:=25;
	COEF_STREAM_WIDTH:integer:=32
);
end entity channel_registers_TB;

architecture testbench of channel_registers_TB is

signal stream_clk:std_logic:='1';	
signal reg_clk:std_logic:='1';	
signal stream_reset:std_logic:='1';	
signal reg_reset:std_logic:='1';	
constant STREAM_CLK_PERIOD:time:=4 ns;
constant REG_CLK_PERIOD:time:=8 ns;

signal address:register_address_t;
signal write:boolean;
signal registers:channel_registers_t;
signal filter_config_data:std_logic_vector(CONFIG_STREAM_WIDTH-1 downto 0);
signal filter_config_valid:boolean;
signal filter_config_ready:boolean;
signal filter_reload_data:std_logic_vector(COEF_STREAM_WIDTH-1 downto 0);
signal filter_reload_valid:boolean;
signal filter_reload_last:boolean;
signal filter_reload_last_error:boolean;
signal differentiator_config_data:
       std_logic_vector(CONFIG_STREAM_WIDTH-1 downto 0);
signal differentiator_config_valid:boolean;
signal differentiator_config_ready:boolean;
signal differentiator_reload_data:
 			 std_logic_vector(COEF_STREAM_WIDTH-1 downto 0);
signal differentiator_reload_valid:boolean;
signal differentiator_reload_ready:boolean;
signal differentiator_reload_last:boolean;
signal differentiator_reload_last_error:boolean;
signal filter_reload_ready:boolean;
signal sim_count:unsigned(AXI_DATA_BITS-1 downto 0);
signal last:boolean;
signal value:register_data_t;
signal axis_ready:boolean;
signal axis_done:boolean;
signal axis_error:boolean;

begin
stream_clk <= not stream_clk after STREAM_CLK_PERIOD/2;
reg_clk <= not reg_clk after REG_CLK_PERIOD/2;

sim:process(reg_clk)is
begin
	if rising_edge(reg_clk) then
		if reg_reset = '1' then
			sim_count <= (others => '0');
		else
			if write then
				sim_count <=sim_count+1;
			end if;
		end if;
	end if;
end process sim;
last <= sim_count=to_unsigned(23, AXI_DATA_BITS);

address <= (FILTER_RELOAD_ADDR_BIT => '1', others => '0');
simwrite:process
begin
	wait for REG_CLK_PERIOD*4;
	write <= TRUE;
	wait for REG_CLK_PERIOD;
	write <= FALSE;
	wait until axis_done;
end process simwrite;

reg:entity work.channel_registers
generic map(
  CONFIG_BITS => CONFIG_BITS,
  CONFIG_STREAM_WIDTH => CONFIG_STREAM_WIDTH,
  COEF_BITS => COEF_BITS,
  COEF_STREAM_WIDTH => COEF_STREAM_WIDTH
)
port map(
  reg_clk => reg_clk,
  reg_reset => reg_reset,
  data => 
  	to_std_logic(last) & to_std_logic(sim_count(AXI_DATA_BITS-2 downto 0)),
  address => address,
  write => write,
  value => value,
  axis_ready => axis_ready,
  axis_done => axis_done,
  axis_error => axis_error,
  stream_clk => stream_clk,
  stream_reset => stream_reset,
  registers => registers,
  filter_config_data => filter_config_data,
  filter_config_valid => filter_config_valid,
  filter_config_ready => filter_config_ready,
  filter_reload_data => filter_reload_data,
  filter_reload_valid => filter_reload_valid,
  filter_reload_ready => filter_reload_ready,
  filter_reload_last => filter_reload_last,
  filter_reload_last_error => filter_reload_last_error,
  differentiator_config_data => differentiator_config_data,
  differentiator_config_valid => differentiator_config_valid,
  differentiator_config_ready => differentiator_config_ready,
  differentiator_reload_data => differentiator_reload_data,
  differentiator_reload_valid => differentiator_reload_valid,
  differentiator_reload_ready => differentiator_reload_ready,
  differentiator_reload_last => differentiator_reload_last,
  differentiator_reload_last_error => differentiator_reload_last_error
);

stimulus:process is
begin
wait for REG_CLK_PERIOD;
stream_reset <= '0';
reg_reset <= '0';
wait for REG_CLK_PERIOD;
filter_reload_ready <= TRUE;
wait;
end process stimulus;

end architecture testbench;
