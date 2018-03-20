library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.boolean_vector.all;
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
  CF_WIDTH:natural:=18;
  CF_FRAC:natural:=17;
  WIDTH:natural:=16;
  FRAC:natural:=3;
  SLOPE_FRAC:natural:=8; 
  ADC_WIDTH:natural:=14;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  ENDIAN:string:="LITTLE"
);
end entity channel_TB;

architecture testbench of channel_TB is
file trace_file:integer_file;
file stream_file:integer_file;

signal clk:std_logic:='1';
signal clk_i:integer:=-1; --clk index for data files
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
signal event_enable:boolean;

constant SIM_WIDTH:natural:=9;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal idle_count:unsigned(SIM_WIDTH downto 0);
signal adc_count:signed(8 downto 0);
signal squaresig,doublesig:signed(ADC_WIDTH-1 downto 0);
signal stage1_config:fir_control_in_t;
signal stage1_events:fir_control_out_t;
signal stage2_config:fir_control_in_t;
signal stage2_events:fir_control_out_t;
signal simenable:boolean:=FALSE;
signal long:boolean:=TRUE;

signal flags:boolean_vector(10 downto 0);

constant CF:integer:=2**17/20; --20%

begin
clk <= not clk after CLK_PERIOD/2;
clk_i <= clk_i+1 after CLK_PERIOD;
  
UUT:entity work.channel
generic map(
  CHANNEL => CHANNEL,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  WIDTH => WIDTH,
  FRAC => FRAC,
  SLOPE_FRAC => SLOPE_FRAC,
  ADC_WIDTH => ADC_WIDTH,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  ENDIAN  => ENDIAN
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
  mux_full => FALSE,
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

--------------------------------------------------------------------------------
-- data recording
--------------------------------------------------------------------------------
flags <= -- byte 1
         --  5         6         7                        
         m.rise2 & m.rise1 & m.valid_rise & 
         --byte 0
         -- 0            1                  2                   3
         m.rise0 & m.rise_start(NOW) & m.pulse_start(NOW) & m.will_cross & 
         --  4             5              6             7
         m.will_arm & m.cfd_error & m.cfd_overrun & m.cfd_valid;

--file_open(stream_file, "../stream",WRITE_MODE);
--streamWriter:process
--begin
--  while TRUE loop
--    wait until rising_edge(clk);
--    if ready and valid then
--      if stream.last(0) then
--        write(stream_file, -clk_i);
--      else
--        write(stream_file, clk_i);
--      end if;
--      write(stream_file,to_integer(signed(to_0(stream.data(31 downto 0)))));
--      write(stream_file,to_integer(signed(to_0(stream.data(63 downto 32)))));
--    end if;
--  end loop;
--end process streamWriter; 
--file_open(stream_file,"../stream",WRITE_MODE);

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    write(trace_file, to_integer(m.baseline));
    write(trace_file, to_integer(m.raw));
    write(trace_file, to_integer(m.f));
    write(trace_file, to_integer(m.s));
  end loop;
end process traceWriter; 

clkCount:process is
begin
		wait until rising_edge(clk);
		clk_count <= clk_count+1;
end process clkCount;

stimulusFile:process
	file sample_file:integer_file is in 
--	     "../input_signals/tes2_250_old.bin";
--	     "../bin_traces/gt1_100khz.bin";
--	     "../bin_traces/july 10/randn2.bin";
--	     "../bin_traces/july 10/randn.bin";
--	     "C:/TES_project/bin_traces/noise.bin";
--	     "C:/TES_project/bin_traces/gaussian_noise.bin";
	     "C:/TES_project/bin_traces/gaussian_noise20Mhz.bin";
--	     "../bin_traces/double_peak_signal.bin";
	variable sample:integer;
	--variable sample_in:std_logic_vector(13 downto 0);
begin
	while not endfile(sample_file) loop
		read(sample_file, sample);
		wait until rising_edge(clk);
		adc_sample <= to_signed(sample, 14);
	end loop;
	wait;
end process stimulusFile;

simsquare:process (clk) is
begin
  if rising_edge(clk) then
    if long then
      null;
    end if;
    if not simenable then
      sim_count <= (others => '0');
      adc_count <= (others => '0');
      idle_count <= (others => '0');
    else
      sim_count <= sim_count+1;
      adc_count <= adc_count+1;
    end if;
  end if;
end process simsquare;
squaresig <= to_signed(-10,ADC_WIDTH)
             when sim_count(SIM_WIDTH-1)='0' 
             else to_signed(100,ADC_WIDTH);
               
doublesig <= to_signed(-200,ADC_WIDTH)
             when sim_count < 10
             else to_signed(800,ADC_WIDTH)
             when sim_count < 40
             else to_signed(0,ADC_WIDTH)
             when sim_count < 110
             else to_signed(1000,ADC_WIDTH)
             when sim_count < 300
             else to_signed(-200,ADC_WIDTH);
             
--adc_sample <= signed(squaresig);
--adc_sample <= signed(doublesig);
--adc_sample <= resize(adc_count,ADC_WIDTH);
--adc_sample <= doublesig;

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
registers.baseline.offset <= to_signed(0,WIDTH);
--registers.baseline.count_threshold <= to_unsigned(80,BASELINE_COUNTER_BITS);
registers.baseline.count_threshold <= to_unsigned(50,BASELINE_COUNTER_BITS);
registers.baseline.threshold <= (others => '1');
registers.baseline.new_only <= TRUE;
registers.baseline.subtraction <= TRUE;
--registers.baseline.timeconstant <= to_unsigned(15000,32);
registers.baseline.timeconstant <= to_unsigned(10000,32);

registers.capture.constant_fraction  <= to_unsigned(CF,DSP_BITS-1);
registers.capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
registers.capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1); --startpeakstop
registers.capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
registers.capture.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
registers.capture.detection <= PULSE_DETECTION_D;
registers.capture.timing <= PULSE_THRESH_TIMING_D;
registers.capture.height <= PEAK_HEIGHT_D;
registers.capture.cfd_rel2min <= FALSE;
registers.capture.trace_pre <= (others => '0');
event_enable <= TRUE;

--adc_sample <= to_signed(0,ADC_WIDTH);
wait for CLK_PERIOD*20;
reset1 <= '0';
wait for CLK_PERIOD*40;
reset2 <= '0';
wait for CLK_PERIOD;
ready <= TRUE;
wait for CLK_PERIOD*1500;
simenable <= TRUE;

while TRUE loop
  registers.baseline.offset <= to_signed(0,WIDTH);
  wait for 500 us;
  registers.baseline.offset <= to_signed(800,WIDTH);
  wait for 500 us;
  registers.baseline.offset <= to_signed(-800,WIDTH);
end loop;


end process stimulus;

end architecture testbench;
