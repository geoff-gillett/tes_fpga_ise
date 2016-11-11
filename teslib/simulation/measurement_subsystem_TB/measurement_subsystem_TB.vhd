--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:18 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: measurement_unit_TB
-- Project Name: tes library (teslib)
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;
use std.textio.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

library dsp;
use dsp.types.all;

use work.types.all;
use work.registers.all;
use work.events.all;
use work.measurements.all;
use work.debug.all;

entity measurement_subsystem_TB is
generic(
	CHANNELS:integer:=2; -- need to adjust stimulus if changed
	ENDIAN:string:="LITTLE";
	PACKET_GEN:boolean:=FALSE
);
end entity measurement_subsystem_TB;

architecture testbench of measurement_subsystem_TB is

--constant CHANNELS:integer:=2**CHANNEL_BITS;
component enet_cdc_fifo
port (
  wr_clk:in std_logic;
  wr_rst:in std_logic;
  rd_clk:in std_logic;
  rd_rst:in std_logic;
  din:in std_logic_vector(71 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(8 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;
			
signal sample_clk:std_logic:='1';	
signal io_clk:std_logic:='1';	
signal reset0:std_logic:='1';	
signal reset1:std_logic:='1';	
signal reset2:std_logic:='1';	
constant SAMPLE_CLK_PERIOD:time:=4 ns;
constant IO_CLK_PERIOD:time:=8 ns;

signal mca_initialising:boolean;
signal adc_samples:adc_sample_array(CHANNELS-1 downto 0);
signal sample_reg:adc_sample_t;
signal chan_reg:channel_register_array(CHANNELS-1 downto 0);

-- discrete types as unsigned for reading into settings file
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
--mca
signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:boolean:=FALSE;
signal bytestream_last:boolean;
signal cdc_din:std_logic_vector(71 downto 0);
signal cdc_ready:boolean;
signal cdc_valid:boolean;
signal cdc_wr_en:std_logic;
signal cdc_rd_en:std_logic;
signal cdc_dout:std_logic_vector(8 downto 0);
signal cdc_full:std_logic;
signal cdc_empty:std_logic;
signal bytestream_int:std_logic_vector(8 downto 0);
signal global:global_registers_t;
signal clk_count:integer:=0;

type int_file is file of integer;
file bytestream_file,trace_file:int_file;

signal filter_config:fir_ctl_in_array(CHANNELS-1 downto 0);
signal slope_config:fir_ctl_in_array(CHANNELS-1 downto 0);
signal baseline_config:fir_ctl_in_array(CHANNELS-1 downto 0);

--signals for vcd dump
signal bytestream_valid_v,bytestream_ready_v:std_logic;
signal ethernetstream_v:std_logic_vector(63 downto 0);
signal ethernetstream_valid_v,ethernetstream_ready_v:std_logic;
signal ethernetstream_last_v:std_logic;
signal m:measurements_array(CHANNELS-1 downto 0);

begin
	
sample_clk <= not sample_clk after SAMPLE_CLK_PERIOD/2;
io_clk <= not IO_clk after IO_CLK_PERIOD/2;
reset0 <= '0' after 2*IO_CLK_PERIOD; 
reset1 <= '0' after 10*IO_CLK_PERIOD; 
reset2 <= '0' after 20*IO_CLK_PERIOD; 
bytestream_ready <= TRUE after 2*IO_CLK_PERIOD;

UUT:entity work.measurement_subsystem
generic map(
  DSP_CHANNELS => CHANNELS,
  ENDIAN => ENDIAN,
  PACKET_GEN => PACKET_GEN
)
port map(
  clk => sample_clk,
  reset1 => reset1,
  reset2 => reset2,
  mca_initialising => mca_initialising,
  samples => adc_samples,
  channel_reg => chan_reg,
  global_reg => global,
  filter_config => filter_config,
  filter_events => open,
  slope_config => slope_config,
  slope_events => open,
  baseline_config => baseline_config,
  baseline_events => open,
  measurements => m,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);
ethernetstream_v <= ethernetstream.data;
ethernetstream_valid_v <= to_std_logic(ethernetstream_valid);
ethernetstream_ready_v <= to_std_logic(ethernetstream_ready);
ethernetstream_last_v <= to_std_logic(ethernetstream.last(0));

cdc_din <= '0' & ethernetstream.data(63 downto 56) &
           '0' & ethernetstream.data(55 downto 48) &
           '0' & ethernetstream.data(47 downto 40) &
           '0' & ethernetstream.data(39 downto 32) &
           '0' & ethernetstream.data(31 downto 24) &
           '0' & ethernetstream.data(23 downto 16) &
           '0' & ethernetstream.data(15 downto 8) &
           to_std_logic(ethernetstream.last(0)) & 
           ethernetstream.data(7 downto 0);
           
ethernetstream_ready <= cdc_full='0';
cdc_wr_en <= to_std_logic(ethernetstream_valid); 

cdcFIFO:enet_cdc_fifo
port map (
  wr_clk => sample_clk,
  wr_rst =>	reset1,
  rd_clk => io_clk,
  rd_rst => reset1,
  din => cdc_din,
  wr_en => cdc_wr_en,
  rd_en => cdc_rd_en,
  dout => cdc_dout,
  full => cdc_full,
  empty => cdc_empty
);
cdc_valid <= cdc_empty='0';
cdc_rd_en <= to_std_logic(cdc_ready);

bytestreamReg:entity streamlib.stream_register
generic map(
  WIDTH => 9
)
port map(
  clk => io_clk,
  reset => reset2,
  stream_in => cdc_dout,
  ready_out => cdc_ready,
  valid_in => cdc_valid,
  stream => bytestream_int,
  ready => bytestream_ready,
  valid => bytestream_valid
);

bytestream <= bytestream_int(7 downto 0);
bytestream_last <= bytestream_int(8)='1';
bytestream_valid_v <= to_std_logic(bytestream_valid);
bytestream_ready_v <= to_std_logic(bytestream_ready);

--register settings
global.mtu <= to_unsigned(1500,MTU_BITS);
global.tick_latency <= to_unsigned(2**16,TICK_LATENCY_BITS);
global.tick_period <= to_unsigned(2**16,TICK_PERIOD_BITS);
global.mca.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
global.mca.bin_n <= (others => '0');
global.mca.channel <= (others => '0');
global.mca.last_bin <= (others => '1');
global.mca.lowest_value <= to_signed(-1000,MCA_VALUE_BITS);
--TODO normalise these type names
global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
global.mca.value <= MCA_RAW_SIGNAL_D;

filter_config(0).config_data <= (others => '0');
filter_config(0).config_valid <= '0';
filter_config(0).reload_data <= (others => '0');
filter_config(0).reload_last <= '0';
filter_config(0).reload_valid <= '0';
filter_config(1).config_data <= (others => '0');
filter_config(1).config_valid <= '0';
filter_config(1).reload_data <= (others => '0');
filter_config(1).reload_last <= '0';
filter_config(1).reload_valid <= '0';
slope_config(0).config_data <= (others => '0');
slope_config(0).config_valid <= '0';
slope_config(0).reload_data <= (others => '0');
slope_config(0).reload_last <= '0';
slope_config(0).reload_valid <= '0';
slope_config(1).config_data <= (others => '0');
slope_config(1).config_valid <= '0';
slope_config(1).reload_data <= (others => '0');
slope_config(1).reload_last <= '0';
slope_config(1).reload_valid <= '0';
baseline_config(0).config_data <= (others => '0');
baseline_config(0).config_valid <= '0';
baseline_config(0).reload_data <= (others => '0');
baseline_config(0).reload_last <= '0';
baseline_config(0).reload_valid <= '0';
baseline_config(1).config_data <= (others => '0');
baseline_config(1).config_valid <= '0';
baseline_config(1).reload_data <= (others => '0');
baseline_config(1).reload_last <= '0';
baseline_config(1).reload_valid <= '0';

chan_reg(0).baseline.offset <= std_logic_vector(to_unsigned(260,ADC_BITS));
chan_reg(0).baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
chan_reg(0).baseline.threshold <= (others => '1');
chan_reg(0).baseline.new_only <= TRUE;
chan_reg(0).baseline.subtraction <= TRUE;
chan_reg(0).baseline.timeconstant <= to_unsigned(2**16,32);
chan_reg(1).baseline.offset <= std_logic_vector(to_unsigned(260,ADC_BITS));
chan_reg(1).baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
chan_reg(1).baseline.threshold <= (others => '1');
chan_reg(1).baseline.new_only <= TRUE;
chan_reg(1).baseline.subtraction <= TRUE;
chan_reg(1).baseline.timeconstant <= to_unsigned(2**16,32);

chan_reg(0).capture.constant_fraction  <= (16 => '1', others => '0');
chan_reg(0).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1);
chan_reg(0).capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1);
chan_reg(0).capture.area_threshold <= to_unsigned(10000,AREA_WIDTH-1);
chan_reg(0).capture.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
chan_reg(0).capture.detection <= PULSE_DETECTION_D;
chan_reg(0).capture.timing <= SLOPE_MAX_TIMING_D;
chan_reg(0).capture.height <= CFD_HEIGHT_D;
chan_reg(1).capture.constant_fraction  <= (16 => '1', others => '0');
chan_reg(1).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1);
chan_reg(1).capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1);
chan_reg(1).capture.area_threshold <= to_unsigned(10000,AREA_WIDTH-1);
chan_reg(1).capture.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
chan_reg(1).capture.detection <= PULSE_DETECTION_D;
chan_reg(1).capture.timing <= SLOPE_MAX_TIMING_D;
chan_reg(1).capture.height <= CFD_HEIGHT_D;

mcaControlStimulus:process
begin
  global.mca.update_asap <= FALSE;
  global.mca.update_on_completion <= FALSE;
	wait for SAMPLE_CLK_PERIOD;
	wait until not mca_initialising;
	global.mca.update_asap <= TRUE;
	wait for SAMPLE_CLK_PERIOD;
	global.mca.update_asap <= FALSE;
	wait;
end process mcaControlStimulus;	

file_open(bytestream_file,"../bytestream",WRITE_MODE);
byteStreamWriter:process
begin
	while TRUE loop
    wait until rising_edge(io_clk);
    if bytestream_valid and bytestream_ready then
    	write(bytestream_file, to_integer(unsigned(bytestream)));
      if bytestream_last then
    		write(bytestream_file, -clk_count); --identify last by -ve value
    	else
    		write(bytestream_file, clk_count);
    	end if;
    end if;
	end loop;
end process byteStreamWriter;

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
	while TRUE loop
    wait until rising_edge(sample_clk);
	  write(trace_file, to_integer(to_0(m(0).raw.sample)));
	  write(trace_file, to_integer(to_0(m(0).filtered.sample)));
	  write(trace_file, to_integer(to_0(m(0).slope.sample)));
	  write(trace_file, to_integer(to_0(m(0).baseline)));
	end loop;
end process traceWriter; 

clkCount:process is
begin
		wait until rising_edge(sample_clk);
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
		wait until rising_edge(sample_clk);
		adc_samples(0) <= resize(sample_in, 14);
		sample_reg <= resize(sample_in, 14);
		adc_samples(1) <= sample_reg;
		if clk_count mod 10000 = 0 then
			report "clk " & integer'image(clk_count);
		end if;
		--assert false report str_sample severity note;
	end loop;
	wait;
end process stimulusFile;

end architecture testbench;
