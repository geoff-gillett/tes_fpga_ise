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
	CHANNELS:natural:=2; -- need to adjust stimulus if changed
	ADC_CHANNELS:natural:=2;
	ENDIAN:string:="LITTLE";
	PACKET_GEN:boolean:=FALSE;
  ADC_WIDTH:natural:=14;
  WIDTH:natural:=16;
  FRAC:natural:=3;
  SLOPE_FRAC:natural:=8;
  AREA_WIDTH:natural:=32;
  AREA_FRAC:natural:=1;
  FRAMER_ADDRESS_BITS:natural:=6
);
end entity measurement_subsystem_TB;

architecture testbench of measurement_subsystem_TB is

constant CF:integer:=(2**17/5); --20%
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

signal adc_samples:adc_sample_array(CHANNELS-1 downto 0)
       :=(others => (others => '0'));
signal chan_reg:channel_register_array(CHANNELS-1 downto 0);

signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;

--mca
signal mca_interrupt:boolean;
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
signal clk_count,io_clk_count:integer:=0;

type int_file is file of integer;
file bytestream_file,trace_file:int_file;

signal filter_config:fir_ctl_in_array(CHANNELS-1 downto 0);
signal slope_config:fir_ctl_in_array(CHANNELS-1 downto 0);

signal m:measurements_array(CHANNELS-1 downto 0);
signal adc_count:signed(ADC_BITS-1 downto 0);

signal simenable:boolean:=FALSE;

constant SIM_WIDTH:natural:=9;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal doublesig:signed(ADC_WIDTH-1 downto 0);

begin
	
sample_clk <= not sample_clk after SAMPLE_CLK_PERIOD/2;
io_clk <= not IO_clk after IO_CLK_PERIOD/2;
reset0 <= '0' after 2*IO_CLK_PERIOD; 
reset1 <= '0' after 10*IO_CLK_PERIOD; 
reset2 <= '0' after 20*IO_CLK_PERIOD; 
--bytestream_ready <= sim_count(2 downto 0) /= "101";
bytestream_ready <= TRUE after 20 us;

UUT:entity work.measurement_subsystem5
generic map(
  DSP_CHANNELS => CHANNELS,
  ADC_CHANNELS => ADC_CHANNELS,
  ENDIAN => ENDIAN,
  PACKET_GEN => PACKET_GEN,
  ADC_WIDTH => ADC_WIDTH,
  WIDTH => WIDTH,
  FRAC => FRAC,
  SLOPE_FRAC => SLOPE_FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  ACCUMULATE_N => 3,
  TRACE_FROM_STAMP => TRUE,
  MIN_TICK_PERIOD => 2000,
  MEASUREMENT_FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => sample_clk,
  reset1 => reset1,
  reset2 => reset2,
  mca_interrupt => mca_interrupt,
  samples => adc_samples,
  channel_reg => chan_reg,
  global_reg => global,
  filter_config => filter_config,
  filter_events => open,
  slope_config => slope_config,
  slope_events => open,
  measurements => m,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

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

--register settings
global.mtu <= to_unsigned(256,MTU_BITS);
global.tick_latency <= to_unsigned(2**16,TICK_LATENCY_BITS);
global.tick_period <= to_unsigned(2049,TICK_PERIOD_BITS);
global.mca.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
global.mca.bin_n <= (others => '0');
global.mca.channel <= (others => '0');
global.mca.last_bin <= (others => '1');
--global.mca.lowest_value <= to_signed(-2500,MCA_VALUE_BITS);
global.mca.lowest_value <= to_signed(-2000,MCA_VALUE_BITS);
--global.mca.qualifier <= VALID_PEAK0_MCA_QUAL_D;
--TODO normalise these type names
--global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
--global.mca.value <= MCA_RAW_SIGNAL_D;
global.window <= to_unsigned(2, TIME_BITS);

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

chan_reg(0).baseline.offset <= to_signed(0,DSP_BITS);
chan_reg(0).baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
chan_reg(0).baseline.threshold <= (others => '1'); --to_unsigned(700,BASELINE_BITS-1);--(others => '1');
chan_reg(0).baseline.new_only <= TRUE;
chan_reg(0).baseline.subtraction <= FALSE;
chan_reg(0).baseline.timeconstant <= to_unsigned(25000,32);

--chan_reg(1).baseline.offset <= to_signed(-1000*8,DSP_BITS);
chan_reg(1).baseline.offset <= to_signed(0,DSP_BITS);
chan_reg(1).baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
chan_reg(1).baseline.threshold <= (others => '0'); --to_unsigned(700,BASELINE_BITS-1);--(others => '1');
chan_reg(1).baseline.new_only <= TRUE;
chan_reg(1).baseline.subtraction <= FALSE;
chan_reg(1).baseline.timeconstant <= to_unsigned(25000,32);

chan_reg(0).capture.adc_select <= (0 => '1', others => '0');
chan_reg(0).capture.delay <= (others => '0');
chan_reg(0).capture.constant_fraction  <= to_unsigned(CF,CFD_BITS-1);
--chan_reg(0).capture.slope_threshold <= to_unsigned(10*256,DSP_BITS-1);
--chan_reg(0).capture.slope_threshold <= to_unsigned(2*256,DSP_BITS-1);
--chan_reg(0).capture.pulse_threshold <= to_unsigned(800*8,DSP_BITS-1);
--chan_reg(0).capture.pulse_threshold <= to_unsigned(5*8,DSP_BITS-1);
chan_reg(0).capture.slope_threshold <= to_unsigned(8*256,DSP_BITS-1); --2300
--chan_reg(0).capture.area_threshold <= to_unsigned(100000,AREA_WIDTH-1);
chan_reg(0).capture.area_threshold <= to_unsigned(14000,AREA_WIDTH-1);
--chan_reg(0).capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
chan_reg(0).capture.max_peaks <= to_unsigned(0,PEAK_COUNT_BITS);
chan_reg(0).capture.detection <= TRACE_DETECTION_D;
chan_reg(0).capture.timing <= PULSE_THRESH_TIMING_D;
chan_reg(0).capture.height <= CFD_HEIGHT_D;
chan_reg(0).capture.cfd_rel2min <= FALSE;
chan_reg(0).capture.trace_stride <= (others => '0');

--------------------------------------------------------------------------------
-- pulse_threshold_neg & pulse_start simultaneous.
chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(16,TRACE_LENGTH_BITS);

-- trace_last & pulse_start simultaneous.
--chan_reg(0).capture.pulse_threshold <= to_unsigned(116*8,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(15,TRACE_LENGTH_BITS);

chan_reg(0).capture.trace_length <= to_unsigned(45,TRACE_LENGTH_BITS);
--------------------------------------------------------------------------------


chan_reg(1).capture.adc_select <= (0 => '0', others => '0');
chan_reg(1).capture.delay <= (0 => '0', others => '0');
chan_reg(1).capture.constant_fraction  <= to_unsigned(CF,CFD_BITS-1);
--chan_reg(1).capture.slope_threshold <= to_unsigned(10*256,DSP_BITS-1);
--chan_reg(1).capture.pulse_threshold <= to_unsigned(800*8,DSP_BITS-1);
chan_reg(1).capture.slope_threshold <= to_unsigned(8*256,DSP_BITS-1); --2300
--chan_reg(1).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); --start peak stop
chan_reg(1).capture.pulse_threshold <= to_unsigned(114*8,DSP_BITS-1); --start peak stop
chan_reg(1).capture.area_threshold <= to_unsigned(10,AREA_WIDTH-1);
chan_reg(1).capture.max_peaks <= to_unsigned(6,PEAK_COUNT_BITS);
chan_reg(1).capture.detection <= PEAK_DETECTION_D;
chan_reg(1).capture.timing <= PULSE_THRESH_TIMING_D;
chan_reg(1).capture.height <= CFD_HEIGHT_D;
chan_reg(1).capture.cfd_rel2min <= FALSE;
chan_reg(1).capture.trace_stride <= (others => '0');
chan_reg(1).capture.trace_length <= to_unsigned(4,TRACE_LENGTH_BITS);

file_open(bytestream_file,"../bytestream",WRITE_MODE);
byteStreamWriter:process(io_clk)
begin
  if rising_edge(io_clk) then
    if bytestream_valid and bytestream_ready then
      write(bytestream_file, to_integer(unsigned(bytestream)));
      if bytestream_last then
        write(bytestream_file, -io_clk_count); --identify last by -ve value
      else
        write(bytestream_file, io_clk_count);
      end if;
    end if;
  end if;
end process byteStreamWriter;

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process(sample_clk)
begin
  if rising_edge(sample_clk) then
    write(trace_file, to_integer(to_0(m(0).raw.sample)));
    write(trace_file, to_integer(to_0(m(0).filtered.sample)));
    write(trace_file, to_integer(to_0(m(0).slope.sample)));
    write(trace_file, to_integer(to_0(m(0).filtered_long)));
  end if;
end process traceWriter; 

clkCount:process(sample_clk)
begin
  if rising_edge(sample_clk) then
    clk_count <= clk_count+1;
  end if;
end process clkCount;

ioClkCount:process(io_clk)
begin
  if rising_edge(io_clk) then
    io_clk_count <= io_clk_count+1;
  end if;
end process ioClkCount;

stimulusFile:process
	file sample_file:int_file is in 
--	     "../input_signals/tes2_250_old.bin";
	     "../input_signals/50mvCh1on_amp_100khzdiode_250_1.bin";
	variable sample:integer;
	--variable sample_in:std_logic_vector(13 downto 0);
begin
	while not endfile(sample_file) loop
		read(sample_file, sample);
		wait until rising_edge(sample_clk);
		--adc_samples(0) <= to_std_logic(sample, 14);
		--sample_reg <= resize(sample_in, 14);
		adc_samples(1) <= (others => '0'); -- adc_samples(0);
		if clk_count mod 10000 = 0 then
			report "sample " & integer'image(clk_count);
		end if;
		--assert false report str_sample severity note;
	end loop;
	wait;
end process stimulusFile;

ramp:process (sample_clk) is
begin
  if rising_edge(sample_clk) then
    if reset1 = '1' then
      adc_count <= (others => '0');
    else
      adc_count <= adc_count+1;
    end if;
  end if;
end process ramp;

simcount:process(sample_clk)
begin
  if rising_edge(sample_clk) then
    if not simenable then
      sim_count <= (others => '0');
    else
      sim_count <= sim_count + 1;
    end if;
  end if;
end process simcount;

doublesig <= to_signed(-200,ADC_WIDTH)
             when sim_count < 10
             else to_signed(800,ADC_WIDTH)
             when sim_count < 40
             else to_signed(-100,ADC_WIDTH)
             when sim_count < 100
             else to_signed(1000,ADC_WIDTH)
             when sim_count < 300
             else to_signed(-200,ADC_WIDTH);
               
adc_samples(0) <= std_logic_vector(signed(doublesig));
--adc_samples(0) <= std_logic_vector(adc_count);
--adc_samples(0) <= (others => '0');

mcaControlStimulus:process
begin
  global.mca.update_asap <= FALSE;
  global.mca.update_on_completion <= FALSE;
  global.channel_enable <= "00000000";
  chan_reg(0).capture.trace_type <= SINGLE_TRACE_D;
  chan_reg(0).capture.trace_signal <= FILTERED_TRACE_D;
	wait for SAMPLE_CLK_PERIOD*64;
  simenable <= TRUE;
--	global.mca.value <= MCA_FILTERED_SIGNAL_D;
--	global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
--	global.mca.qualifier <= ALL_MCA_QUAL_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
	
  wait for 1000 ns;
  global.channel_enable <= "00000001";
  wait for 12 us;
  global.channel_enable <= "00000000";
  chan_reg(0).capture.trace_type <= AVERAGE_TRACE_D;
  wait for 4 us;
  global.channel_enable <= "00000001";
  wait for 20 us;
  chan_reg(0).capture.trace_type <= DOT_PRODUCT_D;

--  wait for 70511 ns;
--  global.channel_enable <= "00000000";
--  wait for 12011 ns;
--  global.channel_enable <= "00000011";
--  wait for 40511 ns;
--  global.channel_enable <= "00000000";
--  wait for 13003 ns;
--  global.channel_enable <= "00000011";
  
  
--	wait for SAMPLE_CLK_PERIOD*20;
--	global.mca.value <= MCA_FILTERED_SIGNAL_D;
--	global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
--	global.mca.qualifier <= VALID_PEAK_MCA_QUAL_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--  global.mca.update_asap <= FALSE;
--  wait until mca_interrupt;
--	global.mca.value <= MCA_FILTERED_SIGNAL_D;
--	global.mca.trigger <= MCA_DISABLED_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
--  wait;
----  chan_reg(0).baseline.offset <= to_signed(5,DSP_BITS);
--  wait until mca_interrupt;
----  chan_reg(0).baseline.offset <= to_signed(4,DSP_BITS);
--  wait until mca_interrupt;
----  chan_reg(0).baseline.offset <= to_signed(3,DSP_BITS);
--  wait until mca_interrupt;
----  chan_reg(0).baseline.offset <= to_signed(2,DSP_BITS);
--  wait;
--  wait until mca_interrupt;
--	global.mca.value <= MCA_FILTERED_SIGNAL_D;
--	global.mca.trigger <= SLOPE_NEG_0XING_MCA_TRIGGER_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
--	wait until mca_interrupt;
--	global.mca.value <= MCA_FILTERED_EXTREMA_D;
--	global.mca.trigger <= FILTERED_0XING_MCA_TRIGGER_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
--	wait until mca_interrupt;
--	global.mca.value <= MCA_FILTERED_AREA_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
--	wait until mca_interrupt;
--	global.mca.value <= MCA_SLOPE_SIGNAL_D;
--	global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
--	wait until mca_interrupt;
--	global.mca.value <= MCA_SLOPE_EXTREMA_D;
--	global.mca.trigger <= SLOPE_0XING_MCA_TRIGGER_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
--	wait until mca_interrupt;
--	global.mca.value <= MCA_SLOPE_AREA_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
--	wait for SAMPLE_CLK_PERIOD;
--	wait until mca_interrupt;
--	global.mca.value <= MCA_RAW_SIGNAL_D;
--	global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
--	global.mca.update_asap <= TRUE;
--	wait for SAMPLE_CLK_PERIOD;
--	global.mca.update_asap <= FALSE;
	wait;
end process mcaControlStimulus;	

end architecture testbench;
