library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.debug.all;

library dsp;
use dsp.types.all;
use dsp.FIR_142SYM_23NSYM_16bit;

use work.registers21.all;
use work.types.all;
use work.measurements21.all;
use std.textio.all;

entity measure_TB is
generic(
  WIDTH:integer:=16;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1;
  ADDRESS_BITS:natural:=MEASUREMENT_FRAMER_ADDRESS_BITS;
  RAW_DELAY:integer:=1026 --46
);
end entity measure_TB;

architecture testbench of measure_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';

file trace_file:extensions.debug.integer_file;

constant CLK_PERIOD:time:=4 ns;

signal reg:capture_registers_t;
signal stage1_config:fir_control_in_t;
signal stage2_config:fir_control_in_t;

constant SIM_WIDTH:natural:=7;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal simenable:boolean:=FALSE;

constant CF:integer:=2**17/2;
signal m:measurements_t;
signal event_enable:boolean;
signal raw,f,s:signed(WIDTH-1 downto 0);
signal clk_c:integer:=0; --clk index for data files


begin
clk <= not clk after CLK_PERIOD/2;
clk_c <= clk_c+1 after CLK_PERIOD;
--------------------------------------------------------------------------------
-- data recording
--------------------------------------------------------------------------------
--internal raw,f and s signals
file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    write(trace_file, to_integer(m.raw));
    write(trace_file, to_integer(m.f));
    write(trace_file, to_integer(m.s));
  end loop;
end process traceWriter; 

fir:entity FIR_142SYM_23NSYM_16bit
generic map(
  WIDTH => WIDTH,
  FRAC => 3,
  SLOPE_FRAC => 8
)
port map(
  clk => clk,
  sample_in => raw,
  stage1_config => stage1_config,
  stage1_events => open,
  stage2_config => stage2_config,
  stage2_events => open,
  stage1 => f,
  stage2 => s
);

UUT:entity work.measure21
generic map(
  CF_WIDTH => 18,
  CF_FRAC => 17,
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  RAW_DELAY => RAW_DELAY,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  event_enable => event_enable,
  registers => reg,
  raw => raw,
  s => s,
  f => f,
  measurements => m
);

stimulusFile:process
	file sample_file:integer_file is in 
--	     "../input_signals/tes2_250_old.bin";
--	     "../bin_traces/july 10/gt1_100khz.bin";
--	     "../bin_traces/july 10/randn2.bin";
--	     "../bin_traces/july 10/randn.bin";
	     "../bin_traces/double_peak_signal.bin";
	variable sample:integer;
	--variable sample_in:std_logic_vector(13 downto 0);
begin
	while not endfile(sample_file) loop
		read(sample_file, sample);
		wait until rising_edge(clk);
--		raw <= to_signed(sample, WIDTH);
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
--raw <= to_signed(-100,WIDTH) 
--       when sim_count(SIM_WIDTH-1)='0' 
--       else to_signed(1000,WIDTH);

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

reg.constant_fraction  <= to_unsigned(CF,17);
reg.slope_threshold <= to_unsigned(0,WIDTH-1);
reg.pulse_threshold <= to_unsigned(0,WIDTH-1);
reg.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
reg.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
reg.detection <= PULSE_DETECTION_D;
reg.timing <= PULSE_THRESH_TIMING_D;
reg.height <= CFD_HEIGHT_D;

stimulus:process is
begin
  raw <= (WIDTH-1  => '0', others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*400;
  simenable <= TRUE;

  --impulse
  raw <= (WIDTH-1  => '0', others => '1');
  wait for CLK_PERIOD;
  raw <= (WIDTH-1  => '0', others => '0');
  wait;
end process;

end architecture testbench;