library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.debug.all;

library dsp;
use dsp.types.all;
use dsp.FIR_142SYM_23NSYM_16bit;

use work.registers.all;
use work.types.all;
use work.measurements.all;
use std.textio.all;

entity measure_TB is
generic(
  WIDTH:natural:=16;
  FRAC:natural:=3;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  RAW_DELAY:natural:=1026 --46
);
end entity measure_TB;

architecture testbench of measure_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';

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
signal clk_i:integer:=2; --clk index for data files

file trace_file,min_file,max_file:extensions.debug.integer_file;
file low_file,high_file,maxslope_file:extensions.debug.integer_file;
signal flags:boolean_vector(8 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;
clk_i <= clk_i+1 after CLK_PERIOD;
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

flags <= m.valid_rise & m.rise0 & m.rise_start(NOW) & m.pulse_start(NOW) & m.will_cross & 
         m.will_arm & m.cfd_error & m.cfd_overrun & m.cfd_valid;
         
file_open(min_file, "../min_data",WRITE_MODE);
minWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.min(NOW) then
      write(min_file, clk_i);
      write(min_file, to_integer(m.f));
      write(min_file, to_integer(m.s));
      write(min_file, to_integer(m.cfd_low));
      write(min_file, to_integer(m.cfd_high));
      write(min_file, to_integer(to_unsigned(flags)));
      write(min_file, to_integer(m.max_slope));
      write(min_file, to_integer(m.minima(NOW)));
    end if;
  end loop;
end process minWriter; 

file_open(max_file, "../max_data",WRITE_MODE);
maxWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.max(NOW) then
      write(max_file, clk_i);
      write(max_file, to_integer(m.f));
      write(max_file, to_integer(m.s));
      write(max_file, to_integer(to_unsigned(flags)));
    end if;
  end loop;
end process maxWriter; 

file_open(low_file, "../low_xings",WRITE_MODE);
lowWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.cfd_low_p then
      write(low_file, clk_i);
    end if;
  end loop;
end process lowWriter; 

file_open(high_file, "../high_xings",WRITE_MODE);
highWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.cfd_high_p then
      write(high_file, clk_i);
    end if;
  end loop;
end process highWriter; 

file_open(maxslope_file, "../maxslope_xings",WRITE_MODE);
maxslopeWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.max_slope_p then
      write(maxslope_file, clk_i);
    end if;
  end loop;
end process maxslopeWriter; 

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

UUT:entity work.measure
generic map(
  CF_WIDTH => 18,
  CF_FRAC => 17,
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  RAW_DELAY => RAW_DELAY
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
	     "../bin_traces/july 10/randn.bin";
--	     "../bin_traces/double_peak_signal.bin";
	variable sample:integer;
	--variable sample_in:std_logic_vector(13 downto 0);
begin
	while not endfile(sample_file) loop
		read(sample_file, sample);
		wait until rising_edge(clk);
		raw <= to_signed(sample, WIDTH);
	end loop;
	wait;
end process stimulusFile;

simsquare:process(clk)
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
reg.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);
reg.detection <= PULSE_DETECTION_D;
reg.timing <= PULSE_THRESH_TIMING_D;
reg.height <= PEAK_HEIGHT_D;
reg.cfd_rel2min <= FALSE;
event_enable <= TRUE;

stimulus:process is
begin
--  raw <= (WIDTH-1  => '0', others => '0');
  wait for CLK_PERIOD;
  reset <= '0';
  wait for CLK_PERIOD*300;
  simenable <= TRUE;

--  --impulse
--  raw <= (WIDTH-1  => '0', others => '1');
--  wait for CLK_PERIOD;
--  raw <= (WIDTH-1  => '0', others => '0');
--  wait for CLK_PERIOD*300;
--  raw <= (WIDTH-1  => '0', others => '1');
--  wait for CLK_PERIOD;
--  raw <= (WIDTH-1  => '0', others => '0');
  wait;
end process;

end architecture testbench;