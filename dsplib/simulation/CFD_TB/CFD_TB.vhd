--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:22Nov.,2016
--
-- Design Name: TES_digitiser
-- Module Name: CFD_input_TB
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity CFD_TB is
generic(
  WIDTH:integer:=18;
  DELAY:integer:=1026;
  SIM_WIDTH:integer:=7
);
end entity CFD_TB;

architecture testbench of CFD_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  

constant CLK_PERIOD:time:=4 ns;

signal adc_sample,constant_fraction:signed(WIDTH-1 downto 0);

signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal stage1_config:fir_control_in_t;
signal stage1_events:fir_control_out_t;
signal stage2_config:fir_control_in_t;
signal stage2_events:fir_control_out_t;
signal simenable:boolean:=FALSE;
signal filtered:signed(WIDTH-1 downto 0);
signal slope:signed(WIDTH-1 downto 0);

constant CF:integer:=2**17/2;
signal slope_threshold:signed(WIDTH-1 downto 0);
signal pulse_threshold:signed(WIDTH-1 downto 0);
signal cfd_low_threshold:signed(WIDTH-1 downto 0);
signal cfd_high_threshold:signed(WIDTH-1 downto 0);
signal max_slope:signed(WIDTH-1 downto 0);
signal max:boolean;
signal min:boolean;
signal pulse_threshold_pos:boolean;
signal pulse_threshold_neg:boolean;
signal slope_threshold_pos:boolean;
signal slope_out:signed(WIDTH-1 downto 0);
signal filtered_out:signed(WIDTH-1 downto 0);
signal overrun:boolean;

begin
clk <= not clk after CLK_PERIOD/2;

FIR:entity work.two_stage_FIR
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  sample_in => adc_sample,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  sample_out => open,
  stage1 => filtered,
  stage2 => slope
);

UUT:entity work.CFD
generic map(
  WIDTH => WIDTH,
  DELAY => DELAY
)
port map(
  clk => clk,
  reset => reset,
  slope => slope,
  filtered => filtered,
  constant_fraction => constant_fraction,
  slope_threshold => slope_threshold,
  pulse_threshold => pulse_threshold,
  
  cfd_low_threshold => cfd_low_threshold,
  cfd_high_threshold => cfd_high_threshold,
  max_slope => max_slope,
  max => max,
  min => min,
  pulse_threshold_pos => pulse_threshold_pos,
  pulse_threshold_neg => pulse_threshold_neg,
  slope_threshold_pos => slope_threshold_pos,
  overrun => overrun,
  slope_out => slope_out,
  filtered_out => filtered_out
);


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
adc_sample <= to_signed(-100,WIDTH) 
              when sim_count(SIM_WIDTH-1)='0' 
              else to_signed(1000,WIDTH);


stimulus:process is
begin
--adc_sample <= to_signed(0,WIDTH);
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

constant_fraction <= to_signed(CF,WIDTH);
--constant_fraction <= (others => '0');
slope_threshold <= to_signed(2300,WIDTH);
pulse_threshold <= to_signed(300,WIDTH);
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*32;
simenable <= TRUE;
--adc_sample <= to_signed(4000,WIDTH);
wait for CLK_PERIOD;
--adc_sample <= to_signed(0,WIDTH);
wait;
end process stimulus;

end architecture testbench;
