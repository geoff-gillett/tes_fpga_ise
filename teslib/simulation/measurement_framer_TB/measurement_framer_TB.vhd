library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

use work.registers.all;
use work.events.all;
use work.measurements.all;

entity measurement_framer_TB is
generic(
  CHANNEL:integer:=0;
  WIDTH:integer:=18;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1;
  CFD_DELAY:integer:=256;
  FRAMER_ADDRESS_BITS:integer:=MEASUREMENT_FRAMER_ADDRESS_BITS;
  ENDIAN:string:="LITTLE"
);
end entity measurement_framer_TB;

architecture testbench of measurement_framer_TB is

constant SIMWIDTH:integer:=8;
constant CLK_PERIOD:time:=4 ns;

signal clk:std_logic:='1';
signal reset1,reset2:std_logic:='1';
signal sig:signed(WIDTH-1 downto 0);
signal sim:signed(SIMWIDTH-1 downto 0);

signal raw,slope,filtered:signed(WIDTH-1 downto 0);
signal reg:capture_registers_t;
signal m:measurements_t;
signal start,commit,dump:boolean;
signal stream:streambus_t;
signal valid,ready:boolean;
  
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
  sample_out => raw,
  stage1 => filtered,
  stage2 => slope
);

Meas:entity work.measure
generic map(
  CHANNEL => CHANNEL,
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CFD_DELAY => CFD_DELAY
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  registers => reg,
  raw => raw,
  slope => slope,
  filtered => filtered,
  measurements => m
);

UUT:entity work.measurement_framer
generic map(
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset => reset1,
  start => start,
  commit => commit,
  dump => dump,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
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
  --sig <= to_signed(0,WIDTH);
  reg.constant_fraction  <= (16 => '1', others => '0');
  reg.slope_threshold <= to_unsigned(20,WIDTH-1);
  reg.pulse_threshold <= to_unsigned(80,WIDTH-1);
  reg.area_threshold <= to_unsigned(1000,AREA_WIDTH-1);
  reg.max_peaks <= to_unsigned(2,PEAK_COUNT_BITS);
  reg.detection <= PULSE_DETECTION_D;
  reg.timing <= SLOPE_THRESH_TIMING_D;
  reg.height <= CFD_HEIGHT_D;
  wait for CLK_PERIOD;
  reset1 <= '0';
  wait for CLK_PERIOD*64;
  reset2 <= '0';
  wait for CLK_PERIOD*64;
  --sig <= to_signed(32000,WIDTH);
  wait for CLK_PERIOD;
  --sig <= to_signed(0,WIDTH);
  wait for CLK_PERIOD*2048;
  ready <= TRUE;
  wait;
end process;

end architecture testbench;