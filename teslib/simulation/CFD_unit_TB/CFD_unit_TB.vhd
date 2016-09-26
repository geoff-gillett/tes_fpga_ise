library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.registers.all;

entity CFD_unit_TB is
generic(
  WIDTH:integer:=18;
  CFD_DELAY:integer:=256
);
end entity CFD_unit_TB;

architecture testbench of CFD_unit_TB is

constant SIMWIDTH:integer:=6;

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal sig:signed(WIDTH-1 downto 0);
signal sim:signed(SIMWIDTH-1 downto 0);

signal slope:signed(WIDTH-1 downto 0);
signal raw_out:signed(WIDTH-1 downto 0);
signal filtered_out:signed(WIDTH-1 downto 0);
signal slope_out:signed(WIDTH-1 downto 0);
signal sample_out:signed(WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
signal filtered:signed(WIDTH-1 downto 0);
signal low_rising,high_rising,low_falling,high_falling,cfd_error:boolean;
signal constant_fraction:signed(WIDTH-1 downto 0);
signal slope_threshold:signed(WIDTH-1 downto 0);
signal pulse_threshold:signed(WIDTH-1 downto 0);
signal max,min,valid_peak,max_slope:boolean;
signal stage1_config:fir_control_in_t;
signal stage2_config:fir_control_in_t;
constant SIM_WIDTH:natural:=6;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal squaresig:signed(WIDTH-1 downto 0);
signal adc_sample:signed(WIDTH-1 downto 0);
  
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
  stage1_events => open,
  stage2_config => stage2_config,
  stage2_events => open,
  sample_out => sample_out,
  stage1 => filtered,
  stage2 => slope
);

UUT:entity work.CFD_unit
generic map(
  WIDTH => WIDTH,
  CFD_DELAY => CFD_DELAY
)
port map(
  clk => clk,
  reset1 => reset,
  raw => sample_out,
  slope => slope,
  filtered => filtered,
  constant_fraction => constant_fraction,
  slope_threshold => slope_threshold,
  pulse_threshold => pulse_threshold,
  low_rising => low_rising,
  low_falling => low_falling,
  high_rising => high_rising,
  high_falling => high_falling,
  max_slope => max_slope,
  cfd_error => cfd_error,
  raw_out => raw_out,
  slope_out => slope_out,
  filtered_out => filtered_out,
  max => max,
  min => min,
  valid_peak => valid_peak
);

simulate:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim <= to_signed(-16,SIMWIDTH);
    else
      sim <= sim + 1;
    end if;
  end if;
end process simulate;
sig <= resize(sim,WIDTH);

simsquare:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= (others => '0');
    else
      sim_count <= sim_count+1;
    end if;
  end if;
end process simsquare;
squaresig <= (WIDTH-1 => '1', others => '0') when sim_count(SIM_WIDTH-1)='1' 
             else (WIDTH-1 => '0', others => '1');
adc_sample <= squaresig;
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
  --slope <= to_signed(-8,WIDTH);
  constant_fraction  <= (16 => '0', others => '0');
  pulse_threshold <= (others => '0');
  slope_threshold <= (others => '0');
  
  --adc_sample <= (WIDTH-1 => '0', others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*64;
  --adc_sample <= (WIDTH-1 => '0', others => '1');
  wait for CLK_PERIOD;
  --adc_sample <= (WIDTH-1 => '0', others => '0');
  wait;
end process;

end architecture testbench;