library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;

use work.registers.all;
use work.types.all;
use work.measurements.all;
use work.debug.all;

entity channel_TB is
generic(
  CHANNEL:natural:=0;
  ENDIAN:string:="LITTLE"
);
end entity channel_TB;

architecture testbench of channel_TB is

signal clk:std_logic:='1';
signal reset1:std_logic:='1';
signal reset2:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;

signal adc_sample:adc_sample_t;
signal registers:channel_registers_t;
signal stage1_config:fir_control_in_t;
signal stage1_events:fir_control_out_t;
signal stage2_config:fir_control_in_t;
signal stage2_events:fir_control_out_t;
signal baseline_config:fir_control_in_t;
signal baseline_events:fir_control_out_t;
signal start:boolean;
signal commit:boolean;
signal dump:boolean;
signal m:measurements_t;
signal stream:streambus_t;
signal valid:boolean;
signal ready:boolean;

signal clk_count:integer:=0;
file stream_file:natural_file;
file trace_file:int_file;

begin
clk <= not clk after CLK_PERIOD/2;
  
UUT:entity work.channel
generic map(
  CHANNEL => CHANNEL,
  ENDIAN => ENDIAN
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  adc_sample => adc_sample,
  registers => registers,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  baseline_config => baseline_config,
  baseline_events => baseline_events,
  start => start,
  commit => commit,
  dump => dump,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
);

file_open(stream_file,"../stream",WRITE_MODE);
byteStreamWriter:process
begin
	while TRUE loop
    wait until rising_edge(clk);
    if valid and ready then
    	write(stream_file, to_integer(to_0(signed(stream.data(63 downto 32)))));
    	write(stream_file, to_integer(to_0(signed(stream.data(31 downto 0)))));
      if stream.last(0) then
    		write(stream_file, -clk_count); 
    	else
    		write(stream_file, clk_count);
    	end if;
    end if;
	end loop;
end process byteStreamWriter;

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
	while TRUE loop
    wait until rising_edge(clk);
	  write(trace_file, to_integer(to_0(m.raw.sample)));
	  write(trace_file, to_integer(to_0(m.filtered.sample)));
	  write(trace_file, to_integer(to_0(m.slope.sample)));
	  write(trace_file, to_integer(to_0(m.baseline)));
	end loop;
end process traceWriter; 

clkCount:process is
begin
		wait until rising_edge(clk);
		clk_count <= clk_count+1;
end process clkCount;

stimulusFile:process
file sample_file:text is in "../input_signals/short";
variable file_line:line; -- text line buffer 
variable str_sample:string(4 downto 1);
variable sample_in:std_logic_vector(15 downto 0);
begin
while not endfile(sample_file) loop
  readline(sample_file, file_line);
  read(file_line, str_sample);
  sample_in:=hexstr2vec(str_sample);
  wait until rising_edge(clk);
  adc_sample <= resize(sample_in, ADC_BITS);
  if clk_count mod 10000 = 0 then
    report "clk " & integer'image(clk_count);
  end if;
  --assert false report str_sample severity note;
end loop;
wait;
end process stimulusFile;

stimulus:process
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
baseline_config.config_data <= (others => '0');
baseline_config.config_valid <= '0';
baseline_config.reload_data <= (others => '0');
baseline_config.reload_last <= '0';
baseline_config.reload_valid <= '0';
registers.baseline.offset <= std_logic_vector(to_unsigned(260,ADC_BITS));
registers.baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
registers.baseline.threshold <= (others => '1');
registers.baseline.new_only <= TRUE;
registers.baseline.subtraction <= TRUE;
registers.baseline.timeconstant <= to_unsigned(2**16,32);

registers.capture.constant_fraction  <= (16 => '1', others => '0');
registers.capture.slope_threshold <= to_unsigned(0,DSP_BITS-1);
registers.capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1);
registers.capture.area_threshold <= to_unsigned(10000,AREA_WIDTH-1);
registers.capture.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
registers.capture.detection <= PULSE_DETECTION_D;
registers.capture.timing <= SLOPE_MAX_TIMING_D;
registers.capture.height <= CFD_HEIGHT_D;

wait for CLK_PERIOD;
reset1 <= '0';
reset2 <= '0';
wait for CLK_PERIOD;
ready <= TRUE;
wait; 
end process stimulus;

end architecture testbench;