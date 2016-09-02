library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.registers.all;

entity CFD_unit_TB is
generic(
  WIDTH:integer:=18
);
end entity CFD_unit_TB;

architecture testbench of CFD_unit_TB is

constant SIMWIDTH:integer:=6;

signal clk:std_logic:='1';
signal reset1,reset2:std_logic:='1';
signal sig:signed(WIDTH-1 downto 0);
signal sim:signed(SIMWIDTH-1 downto 0);
signal cf:unsigned(16 downto 0);

signal slope:signed(WIDTH-1 downto 0);
signal raw_out:signed(WIDTH-1 downto 0);
signal filtered_out:signed(WIDTH-1 downto 0);
signal slope_out:signed(WIDTH-1 downto 0);
signal sample_out:signed(WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
signal filtered:signed(WIDTH-1 downto 0);
signal reg:channel_registers_t;
signal rel2min,cfd_low,cfd_high,cfd_error:boolean;
  
begin
clk <= not clk after CLK_PERIOD/2;

FIR:entity work.two_stage_FIR
  generic map(
    WIDTH => WIDTH
  )
  port map(
    clk => clk,
    sample_in => sig,
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
    stage1 => filtered,
    stage2 => slope
  );

UUT:entity work.CFD_unit
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  raw => sample_out,
  slope => slope,
  filtered => filtered,
  constant_fraction => cf,
  rel2min => rel2min,
  cfd_low => cfd_low,
  cfd_high => cfd_high,
  cfd_error => cfd_error,
  raw_out => raw_out,
  slope_out => slope_out,
  filtered_out => filtered_out
);

simulate:process(clk)
begin
  if rising_edge(clk) then
    if reset1 = '1' then
      sim <= to_signed(-16,SIMWIDTH);
    else
      sim <= sim + 1;
    end if;
  end if;
end process simulate;
sig <= resize(sim,WIDTH);

stimulus:process is
begin
  --slope <= to_signed(-8,WIDTH);
  --sig <= to_signed(1,WIDTH);
  cf  <= (16 => '1', others => '0');
  rel2min <= TRUE;
  --reg.capture.slope_threshold <= to_unsigned(10,WIDTH-1);
  wait for CLK_PERIOD;
  reset1 <= '0';
  wait for CLK_PERIOD*64;
  reset2 <= '0';
  wait for CLK_PERIOD*64;
  --sig <= to_signed(-8000,WIDTH);
  wait for CLK_PERIOD;
  --sig <= to_signed(8000*8,WIDTH);
  wait for CLK_PERIOD;
  --sig <= to_signed(0,WIDTH);
  wait;
end process;

end architecture testbench;