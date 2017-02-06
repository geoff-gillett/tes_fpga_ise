library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;
use extensions.debug.all;

library dsp;
use dsp.types.all;

use work.registers.all;
use work.types.all;
use work.measurements.all;

entity channel_TB is
generic(
  CHANNEL:natural:=0;
  BASELINE_BITS:natural:=11;
  WIDTH:natural:=18;
  FRAC:natural:=3;
  WIDTH_OUT:natural:=16;
  FRAC_OUT:natural:=3;
  SLOPE_FRAC:natural:=8; --internal precision
  SLOPE_FRAC_OUT:natural:=8;
  ADC_WIDTH:natural:=14;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  ENDIAN:string:="LITTLE";
  STRICT_CROSSING:boolean:=TRUE
);
end entity channel_TB;

architecture testbench of channel_TB is

signal clk:std_logic:='1';
signal reset1:std_logic:='1';
signal reset2:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;

signal adc_sample:signed(ADC_WIDTH-1 downto 0);
signal registers:channel_registers_t;
signal start:boolean;
signal commit:boolean;
signal dump:boolean;
signal framer_overflow:boolean;
signal framer_error:boolean;
signal m:measurements_t;
signal stream:streambus_t;
signal valid:boolean;
signal ready:boolean;

signal clk_count:integer:=0;
file stream_file:integer_file;
file trace_file:integer_file;
signal event_enable:boolean;

constant SIM_WIDTH:natural:=9;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal squaresig:unsigned(ADC_WIDTH-1 downto 0);
signal stage1_config:fir_control_in_t;
signal stage1_events:fir_control_out_t;
signal stage2_config:fir_control_in_t;
signal stage2_events:fir_control_out_t;
signal baseline_config:fir_control_in_t;
signal baseline_events:fir_control_out_t;
signal simenable:boolean:=FALSE;

constant CF:integer:=2**17/5; --20%

begin
clk <= not clk after CLK_PERIOD/2;
  
UUT:entity work.channel
generic map(
  CHANNEL => CHANNEL,
  BASELINE_BITS => BASELINE_BITS,
  WIDTH => WIDTH,
  FRAC => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  SLOPE_FRAC => SLOPE_FRAC,
  SLOPE_FRAC_OUT => SLOPE_FRAC_OUT,
  ADC_WIDTH => ADC_WIDTH,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  ENDIAN  => ENDIAN,
  STRICT_CROSSING => STRICT_CROSSING
)
port map(
  clk => clk,
  reset1 => reset1,
  reset2 => reset2,
  adc_sample => adc_sample,
  registers => registers,
  event_enable => event_enable,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  baseline_config => baseline_config,
  baseline_events => baseline_events,
  start => start,
  commit => commit,
  dump => dump,
  framer_overflow => framer_overflow,
  framer_error => framer_error,
  measurements => m,
  stream => stream,
  valid => valid,
  ready => ready
);

file_open(stream_file,"../stream",WRITE_MODE);
StreamWriter:process
begin
	while TRUE loop
    wait until rising_edge(clk);
    if valid and ready then
    	writeInt(stream_file,stream.data(31 downto 0),"BIG");
    	writeInt(stream_file,stream.data(63 downto 32),"BIG");
      if stream.last(0) then
    		write(stream_file, -clk_count); 
    	else
    		write(stream_file, clk_count);
    	end if;
    end if;
	end loop;
end process StreamWriter;

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
	while TRUE loop
    wait until rising_edge(clk);
	  writeInt(trace_file,m.raw.sample,"BIG");
	  writeInt(trace_file,m.filtered.sample,"BIG");
	  writeInt(trace_file,m.slope.sample,"BIG");
	end loop;
end process traceWriter; 

clkCount:process is
begin
		wait until rising_edge(clk);
		clk_count <= clk_count+1;
end process clkCount;

--stimulusFile:process
--file sample_file:text is in "../input_signals/short";
--variable file_line:line; -- text line buffer 
--variable str_sample:string(4 downto 1);
--variable sample_in:std_logic_vector(15 downto 0);
--begin
--while not endfile(sample_file) loop
--  readline(sample_file, file_line);
--  read(file_line, str_sample);
--  sample_in:=hexstr2vec(str_sample);
--  wait until rising_edge(clk);
--  --adc_sample <= resize(unsigned(sample_in), ADC_WIDTH);
--  if clk_count mod 10000 = 0 then
--    report "clk " & integer'image(clk_count);
--  end if;
--  --assert false report str_sample severity note;
--end loop;
--wait;
--end process stimulusFile;

stimulusFile:process
	file sample_file:integer_file is in 
	     "../input_signals/50mvCh1on_amp_100khzdiode_250_1.bin";
	variable sample:integer;
	--variable sample_in:std_logic_vector(13 downto 0);
begin
	while not endfile(sample_file) loop
		read(sample_file, sample);
		wait until rising_edge(clk);
		adc_sample <= to_signed(sample, 14);
		--sample_reg <= resize(sample_in, 14);
		--adc_samples(1) <= (others => '0'); -- adc_samples(0);
		if clk_count mod 10000 = 0 then
			report "sample " & integer'image(clk_count);
		end if;
		--assert false report str_sample severity note;
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
squaresig <= to_unsigned(10,ADC_WIDTH)
             when sim_count(SIM_WIDTH-1)='0' 
             else to_unsigned(400,ADC_WIDTH);
--adc_sample <= squaresig;

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
registers.baseline.offset <= to_signed(761*8+6,WIDTH);
registers.baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
registers.baseline.threshold <= (others => '1');
registers.baseline.new_only <= TRUE;
registers.baseline.subtraction <= TRUE;
registers.baseline.timeconstant <= to_unsigned(250000,32);

registers.capture.constant_fraction  <= to_unsigned(CF,DSP_BITS-1);
registers.capture.slope_threshold <= to_unsigned(22*256,DSP_BITS-1); --2300
registers.capture.pulse_threshold <= to_unsigned(350*8,DSP_BITS-1);
registers.capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
registers.capture.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
registers.capture.detection <= PEAK_DETECTION_D;
registers.capture.timing <= CFD_LOW_TIMING_D;
registers.capture.height <= CFD_HEIGHT_D;
registers.capture.cfd_rel2min <= TRUE;
event_enable <= TRUE;

wait for CLK_PERIOD;
reset1 <= '0';
reset2 <= '0';
wait for CLK_PERIOD;
ready <= TRUE;
wait for CLK_PERIOD*1500;
simenable <= TRUE;
wait; 
end process stimulus;

end architecture testbench;
