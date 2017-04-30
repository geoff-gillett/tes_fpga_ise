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
  WIDTH:integer:=16;
  CF_WIDTH:integer:=18;
  CF_FRAC:integer:=17;
  DELAY:integer:=200;
  STRICT_CROSSING:boolean:=TRUE;
  SIM_WIDTH:integer:=10
);
end entity CFD_TB;

architecture testbench of CFD_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  

constant CLK_PERIOD:time:=4 ns;

signal constant_fraction:signed(CF_WIDTH-1 downto 0);

signal sim_count:signed(SIM_WIDTH-1 downto 0);
signal stage1_config:fir_control_in_t;
signal stage1_events:fir_control_out_t;
signal stage2_config:fir_control_in_t;
signal stage2_events:fir_control_out_t;
signal simenable:boolean:=FALSE;
signal filtered:signed(WIDTH-1 downto 0);
signal slope:signed(WIDTH-1 downto 0);

constant CF:integer:=2**17/5;
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
signal rel2min : boolean;
signal will_go_above_pulse_threshold : boolean;
signal will_arm:boolean;
signal armed:boolean;
signal above_pulse_threshold : boolean;
signal cfd_error:boolean;
signal cfd_valid:boolean;
signal sample_in:signed(WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

fir:entity work.FIR_142SYM_23NSYM_16bit
generic map(
  WIDTH => WIDTH,
  FRAC => 3,
  SLOPE_FRAC => 8
)
port map(
  clk => clk,
  sample_in => sample_in,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  stage1 => filtered,
  stage2 => slope
);

UUT:entity work.CFD8
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  DELAY => DELAY,
  STRICT_CROSSING => STRICT_CROSSING
)
port map(
  clk => clk,
  reset => reset,
  slope => slope,
  filtered => filtered,
  constant_fraction => constant_fraction,
  slope_threshold => slope_threshold,
  pulse_threshold => pulse_threshold,
  rel2min => rel2min,
  cfd_low_threshold => cfd_low_threshold,
  cfd_high_threshold => cfd_high_threshold,
  max => max,
  min => min,
  max_slope => max_slope,
  will_go_above_pulse_threshold => will_go_above_pulse_threshold,
  will_arm => will_arm,
  overrun => overrun,
  slope_out => slope_out,
  slope_threshold_pos => slope_threshold_pos,
  armed => armed,
  above_pulse_threshold => above_pulse_threshold,
  filtered_out => filtered_out,
  pulse_threshold_pos => pulse_threshold_pos,
  pulse_threshold_neg => pulse_threshold_neg,
  cfd_error => cfd_error,
  cfd_valid => cfd_valid
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
--adc_sample <= to_signed(-100,WIDTH) 
--              when sim_count(SIM_WIDTH-1)='0' 
--              else to_signed(1000,WIDTH);
                
--sample_in <= resize(sim_count,WIDTH);


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

constant_fraction <= to_signed(CF,CF_WIDTH);
--constant_fraction <= (others => '0');
slope_threshold <= to_signed(2300,WIDTH);
pulse_threshold <= to_signed(300,WIDTH);
wait for CLK_PERIOD;
reset <= '0';
sample_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD*256;
--simenable <= TRUE;
sample_in <= to_signed(10000,WIDTH);
wait for CLK_PERIOD*1;
sample_in <= to_signed(0,WIDTH);
wait;
end process stimulus;

end architecture testbench;
