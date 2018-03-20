library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.debug.all;

library dsp;
use dsp.types.all;
use dsp.FIR_SYM145_ASYM23_OUT16_3;

library streamlib;
use streamlib.types.all;

use work.registers.all;
use work.types.all;
use work.measurements.all;
use std.textio.all;

entity measurement_framer_TB is
generic(
  CHANNEL:natural:=0;
  WIDTH:natural:=16;
  FRAC:natural:=3;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  RAW_DELAY:natural:=1026;
  ADDRESS_BITS:natural:=10;
  DP_ADDRESS_BITS:natural:=11;
  ACCUMULATOR_WIDTH:natural:=48;
  ACCUMULATE_N:natural:=8;
  TRACE_FROM_STAMP:boolean:=TRUE;
  ENDIAN:string:="LITTLE"
);
end entity measurement_framer_TB;

architecture testbench of measurement_framer_TB is

signal clk:std_logic:='1';
signal reset:std_logic:='1';

constant CLK_PERIOD:time:=4 ns;

signal reg:capture_registers_t;
signal stage1_config:fir_control_in_t;
signal stage2_config:fir_control_in_t;

constant SIM_WIDTH:natural:=7;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal simenable:boolean:=FALSE;
signal store_reg:boolean;

constant CF:integer:=2**17/5;
signal m:measurements_t;
signal event_enable:boolean;
signal raw,f,s:signed(WIDTH-1 downto 0);
signal clk_i:integer:=-1; --clk index for data files

file trace_file,min_file,max_file:integer_file;
file f0p_file,f0n_file:integer_file;
file ptn_file,init_reg_file:integer_file;
file rise_stamp_file,pulse_stamp_file:integer_file;
file rise_start_file,pulse_start_file:integer_file;
file height_valid_file,rise_stop_file:integer_file;
file dump_file,commit_file,start_file:integer_file;
file framer_error_file,framer_overflow_file:integer_file;
file stream_file:integer_file;

signal flags:boolean_vector(10 downto 0);
signal mux_full:boolean;
signal start:boolean;
signal commit:boolean;
signal dump:boolean;
signal framer_overflow:boolean;
signal framer_error:boolean;
signal stream:streambus_t;
signal valid:boolean;
signal ready,ready_clk,ready_hold:boolean;
signal resetn:std_logic:='0';

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

flags <= -- byte 1
         --  5         6         7                        
         m.rise2 & m.rise1 & m.valid_rise & 
         --byte 0
         -- 0            1                  2                   3
         m.rise0 & m.rise_start(NOW) & m.pulse_start(NOW) & m.will_cross & 
         --  4             5              6             7
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
      write(min_file, to_integer(m.s_area));
      write(min_file, to_integer(m.s_extrema));
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
      write(max_file, to_integer(m.s_area));
      write(max_file, to_integer(m.s_extrema));
      write(max_file, to_integer(m.peak_height));
    end if;
  end loop;
end process maxWriter; 

file_open(f0p_file, "../f0p_xings",WRITE_MODE);
f0pWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.f_0_p then
        write(f0p_file, clk_i);
        write(f0p_file, to_integer(m.f_area));
        write(f0p_file, to_integer(m.f_extrema));
    end if;
  end loop;
end process f0pWriter; 

file_open(f0n_file, "../f0n_xings",WRITE_MODE);
f0nWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.f_0_n then
        write(f0n_file, clk_i);
        write(f0n_file, to_integer(m.f_area));
        write(f0n_file, to_integer(m.f_extrema));
    end if;
  end loop;
end process f0nWriter; 

file_open(ptn_file, "../ptn_xings",WRITE_MODE);
ptnWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.p_t_n(NOW) then
      write(ptn_file, clk_i);
      write(ptn_file, to_integer(m.pulse_area));
      write(ptn_file, to_integer(m.pulse_length));
      write(ptn_file, to_integer(m.pulse_timer(NOW)));
    end if;
  end loop;
end process ptnWriter; 

file_open(rise_start_file, "../rise_start",WRITE_MODE);
riseStartWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.rise_start(NOW) then
      write(rise_start_file, clk_i);
      write(rise_start_file, to_integer(m.pulse_timer(NOW)));
      write(rise_start_file, to_integer(m.rise_number));
      write(rise_start_file, to_integer(m.rise_address));
    end if;
  end loop;
end process riseStartWriter; 

file_open(rise_stop_file, "../rise_stop",WRITE_MODE);
riseStopWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.rise_stop(NOW) then
      write(rise_stop_file, clk_i);
      write(rise_stop_file, to_integer(m.pulse_timer(NOW)));
      write(rise_stop_file, to_integer(m.rise_number));
      write(rise_stop_file, to_integer(m.rise_address));
      write(rise_stop_file, to_integer(m.rise_timer(NOW)));
      write(rise_stop_file, to_integer(m.peak_height));
    end if;
  end loop;
end process riseStopWriter; 

file_open(height_valid_file, "../height_valid",WRITE_MODE);
heightvalidWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.rise_stop(NOW) then
      write(rise_stop_file, clk_i);
      write(rise_stop_file, to_integer(m.pulse_timer(NOW)));
      write(rise_stop_file, to_integer(m.rise_number));
      write(rise_stop_file, to_integer(m.rise_address));
      write(rise_stop_file, to_integer(m.rise_timer(NOW)));
      write(rise_stop_file, to_integer(m.peak_height));
    end if;
  end loop;
end process heightvalidWriter; 

file_open(pulse_start_file, "../pulse_start",WRITE_MODE);
pulseStartWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.pulse_start(NOW) then
      write(pulse_start_file, clk_i);
      write(pulse_start_file, to_integer(m.enabled(NOW)));
      write(pulse_start_file, to_integer(m.reg(NOW).area_threshold));
      write(pulse_start_file, to_integer(m.reg(NOW).cfd_rel2min));
      write(pulse_start_file, to_integer(m.reg(NOW).constant_fraction));
      write(pulse_start_file, to_integer(m.reg(NOW).detection));
      write(pulse_start_file, to_integer(m.reg(NOW).height));
      write(pulse_start_file, to_integer(m.reg(NOW).max_peaks));
      write(pulse_start_file, to_integer(m.reg(NOW).pulse_threshold));
      write(pulse_start_file, to_integer(m.reg(NOW).slope_threshold));
      write(pulse_start_file, to_integer(m.reg(NOW).timing));
      write(pulse_start_file, to_integer(m.reg(NOW).trace_type));
      write(pulse_start_file, to_integer(m.reg(NOW).trace_signal));
      write(pulse_start_file, to_integer(m.reg(NOW).trace_length));
      write(pulse_start_file, to_integer(m.reg(NOW).trace_stride));
    end if;
  end loop;
end process pulseStartWriter; 


file_open(rise_stamp_file, "../stamp_rise",WRITE_MODE);
riseStampWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.stamp_rise(NOW) then
      write(rise_stamp_file, clk_i);
      write(rise_stamp_file, to_integer(m.pulse_timer(NOW)));
    end if;
  end loop;
end process riseStampWriter; 

file_open(pulse_stamp_file, "../stamp_pulse",WRITE_MODE);
pulseStampWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if m.stamp_pulse(NOW) then
      write(pulse_stamp_file, clk_i);
      write(pulse_stamp_file, to_integer(m.pulse_timer(NOW)));
    end if;
  end loop;
end process pulseStampWriter; 

file_open(framer_error_file, "../framer_error",WRITE_MODE);
framerErrorWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if framer_error then
      write(framer_error_file, clk_i);
    end if;
  end loop;
end process framerErrorWriter; 

file_open(framer_overflow_file, "../framer_overflow",WRITE_MODE);
frameroverflowWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if framer_overflow then
      write(framer_overflow_file, clk_i);
    end if;
  end loop;
end process framerOverflowWriter; 

file_open(commit_file, "../commit",WRITE_MODE);
commitWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if commit then
      write(commit_file, clk_i);
    end if;
  end loop;
end process commitWriter; 

file_open(dump_file, "../dump",WRITE_MODE);
dumpWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if commit then
      write(dump_file, clk_i);
    end if;
  end loop;
end process dumpWriter; 

file_open(start_file, "../start",WRITE_MODE);
startWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if start then
      write(start_file, clk_i);
    end if;
  end loop;
end process startWriter; 

file_open(stream_file, "../stream",WRITE_MODE);
streamWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if ready and valid then
      if stream.last(0) then
        write(stream_file, -clk_i);
      else
        write(stream_file, clk_i);
      end if;
      write(stream_file,to_integer(signed(to_0(stream.data(31 downto 0)))));
      write(stream_file,to_integer(signed(to_0(stream.data(63 downto 32)))));
    end if;
  end loop;
end process streamWriter; 

fir:entity FIR_SYM145_ASYM23_OUT16_3
generic map(
  WIDTH => WIDTH,
  FRAC => 3,
  SLOPE_FRAC => 8
)
port map(
  clk => clk,
  resetn => resetn,
  sample_in => raw,
  stage1_config => stage1_config,
  stage1_events => open,
  stage2_config => stage2_config,
  stage2_events => open,
  stage1 => f,
  stage2 => s
);

measurment:entity work.measure
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
  baseline => (others => '0'),
  raw => raw,
  s => s,
  f => f,
  measurements => m
);

UUT:entity work.measurement_framer
generic map(
  CHANNEL => CHANNEL,
  WIDTH => WIDTH,
  ADDRESS_BITS => ADDRESS_BITS,
  DP_ADDRESS_BITS => DP_ADDRESS_BITS,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH,
  ACCUMULATE_N => ACCUMULATE_N,
  TRACE_FROM_STAMP => TRACE_FROM_STAMP,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset => reset,
  measurements => m,
  mux_full => mux_full,
  start => start,
  commit => commit,
  dump => dump,
  overflow => framer_overflow,
  error => framer_error,
  stream => stream,
  valid => valid,
  ready => ready
);

stimulusFile:process
	file sample_file:integer_file is in 
--	     "../input_signals/tes2_250_old.bin";
--	     "../bin_traces/gt1_100khz_signal.bin";
	     "C:/TES_project/bin_traces/noise.bin";
--	     "../bin_traces/july 10/randn2.bin";
--	     "../bin_traces/july 10/randn.bin";
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
--reg.slope_threshold <= to_unsigned(0,WIDTH-1);
--reg.pulse_threshold <= to_unsigned(0,WIDTH-1);
--reg.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
--reg.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);
reg.trace_signal <= FILTERED_TRACE_D;
reg.timing <= PULSE_THRESH_TIMING_D;
reg.height <= PEAK_HEIGHT_D;
reg.cfd_rel2min <= FALSE;
event_enable <= TRUE;
--------------------------------------------------------------------------------
-- gt1 samples
--------------------------------------------------------------------------------
reg.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
--reg.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
reg.pulse_threshold <= to_unsigned(0,DSP_BITS-1); 
reg.trace_length <= to_unsigned(100,TRACE_LENGTH_BITS);
reg.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
--chan_reg(0).baseline.offset <= to_signed(-500*8-793,DSP_BITS);
reg.trace_stride <= (0 => '0', others => '0');
reg.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);

file_open(init_reg_file, "../init_reg",WRITE_MODE);
initRegWriter:process
begin
    wait until rising_edge(clk) and store_reg;
    write(init_reg_file, clk_i);
    write(init_reg_file, to_integer(event_enable));
    write(init_reg_file, to_integer(reg.area_threshold));
    write(init_reg_file, to_integer(reg.cfd_rel2min));
    write(init_reg_file, to_integer(reg.constant_fraction));
    write(init_reg_file, to_integer(reg.detection));
    write(init_reg_file, to_integer(reg.height));
    write(init_reg_file, to_integer(reg.max_peaks));
    write(init_reg_file, to_integer(reg.pulse_threshold));
    write(init_reg_file, to_integer(reg.slope_threshold));
    write(init_reg_file, to_integer(reg.timing));
    write(init_reg_file, to_integer(reg.trace_type));
    write(init_reg_file, to_integer(reg.trace_signal));
    write(init_reg_file, to_integer(reg.trace_length));
    write(init_reg_file, to_integer(reg.trace_stride));
    file_close(init_reg_file);
    wait;
end process initRegWriter; 

ready_clk <= (clk_i mod (5*256)) = 0;
ready <= (clk_i mod 16) = 0;
--ready <= FALSE when ready_hold else ready_clk;
--ready <= TRUE;

stimulus:process is
begin
  store_reg <= FALSE;
  reg.trace_type <= SINGLE_TRACE_D;
  ready_hold <= TRUE;
--  raw <= (WIDTH-1  => '0', others => '0');
  wait for CLK_PERIOD*300;
  wait for CLK_PERIOD;
  store_reg <= TRUE;
  wait for CLK_PERIOD;
  store_reg <= FALSE;
  reset <= '0';
  resetn <= '1';
  while TRUE loop
    reg.timing <= PULSE_THRESH_TIMING_D;
    reg.detection <= PULSE_DETECTION_D;
    wait for 4 us;
    reg.detection <= TRACE_DETECTION_D;
    wait for 4 us;
    reg.timing <= CFD_LOW_TIMING_D;
    reg.detection <= PULSE_DETECTION_D;
    wait for 4 us;
    reg.detection <= TRACE_DETECTION_D;
    wait for 4 us;
    reg.timing <= PULSE_THRESH_TIMING_D;
    reg.detection <= PULSE_DETECTION_D;
    wait for 4 us;
    reg.detection <= TRACE_DETECTION_D;
    wait for 4 us;
    reg.timing <= MAX_SLOPE_TIMING_D;
    reg.detection <= PULSE_DETECTION_D;
    wait for 4 us;
    reg.detection <= TRACE_DETECTION_D;
    wait for 4 us;
  end loop;
  
--  wait for 2730 us;
--  reg.trace_type <= DOT_PRODUCT_TRACE_D;
--  wait for 100 us;
--  wait for 3580 us;
--  ready_hold <= FALSE;
  
--  --impulse
--  raw <= (WIDTH-1  => '0', others => '1');
--  wait for CLK_PERIOD;
--  raw <= (WIDTH-1  => '0', others => '0');
--  wait for CLK_PERIOD*300;
--  raw <= (WIDTH-1  => '0', others => '1');
--  wait for CLK_PERIOD;
--  raw <= (WIDTH-1  => '0', others => '0');
end process;

end architecture testbench;