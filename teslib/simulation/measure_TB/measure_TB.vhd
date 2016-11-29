library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dsp;
use dsp.types.all;

use work.registers.all;
use work.types.all;
use work.measurements.all;

entity measure_TB is
generic(
  WIDTH:integer:=18;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1;
  CFD_DELAY:integer:=1026 --46
);
end entity measure_TB;

architecture testbench of measure_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';

signal slope:signed(WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
signal filtered:signed(WIDTH-1 downto 0);

signal reg:capture_registers_t;
signal stage1_config:fir_control_in_t;
signal stage2_config:fir_control_in_t;
signal adc_sample:signed(WIDTH-1 downto 0);

constant SIM_WIDTH:natural:=7;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal simenable:boolean:=FALSE;
signal stage1_events:fir_control_out_t;
signal stage2_events:fir_control_out_t;

constant CF:integer:=2**17/2;
signal m:measurements_t;
  
begin
clk <= not clk after CLK_PERIOD/2;

FIR:entity dsp.two_stage_FIR2
generic map(
  WIDTH => DSP_BITS
)
port map(
  clk => clk,
  sample_in => adc_sample,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  stage1 => filtered,
  stage2 => slope
);

UUT:entity work.measure2
generic map(
  CHANNEL => 0,
  WIDTH => WIDTH,
  FRAC => FRAC,
  WIDTH_OUT => 16,
  FRAC_OUT => 1,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CFD_DELAY => CFD_DELAY
)
port map(
  enable => TRUE,
  clk => clk,
  reset => reset,
  registers => reg,
  slope => slope,
  filtered => filtered,
  measurements => m
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
  
  reg.constant_fraction  <= to_unsigned(0,17);
  reg.slope_threshold <= to_unsigned(2300,WIDTH-1);
  reg.pulse_threshold <= to_unsigned(300,WIDTH-1);
  reg.area_threshold <= to_unsigned(10000,AREA_WIDTH-1);
  reg.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
  reg.detection <= PULSE_DETECTION_D;
  reg.timing <= PULSE_THRESH_TIMING_D;
  reg.height <= CFD_HEIGHT_D;
--  adc_sample <= (WIDTH-1  => '0', others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*400;
  simenable <= TRUE;
--  adc_sample <= (WIDTH-1  => '0', others => '1');
  wait for CLK_PERIOD;
--  adc_sample <= (WIDTH-1  => '0', others => '0');
  wait;
end process;

end architecture testbench;