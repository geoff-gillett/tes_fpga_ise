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
use std.textio.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;
use extensions.debug.all;

library streamlib;
use streamlib.types.all;

library dsp;
use dsp.types.all;

use work.types.all;
use work.registers.all;
use work.events.all;
use work.measurements.all;

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
  -- sample file ---------------------------------------------------------------
  FRAMER_ADDRESS_BITS:natural:=MEASUREMENT_FRAMER_ADDRESS_BITS;
  ETHERNET_ADDRESS_BITS:natural:=ETHERNET_FRAMER_ADDRESS_BITS;
  -- sim -----------------------------------------------------------------------
--  FRAMER_ADDRESS_BITS:natural:=7;
--  ETHERNET_ADDRESS_BITS:natural:=8;
  ACCUMULATE_N:natural:=7
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
signal enable:boolean:=FALSE;

file bytestream_file,trace_file:extensions.debug.integer_file;
file min_file,max_file:extensions.debug.integer_file;
file f0p_file,f0n_file:extensions.debug.integer_file;
file ptn_file,init_reg_file:extensions.debug.integer_file;
file rise_stamp_file,pulse_stamp_file:extensions.debug.integer_file;
file rise_start_file,pulse_start_file:extensions.debug.integer_file;
file height_valid_file,rise_stop_file:extensions.debug.integer_file;

signal filter_config:fir_ctl_in_array(CHANNELS-1 downto 0);
signal slope_config:fir_ctl_in_array(CHANNELS-1 downto 0);

signal m:measurements_array(CHANNELS-1 downto 0);
signal adc_count:signed(ADC_BITS-1 downto 0);

signal simenable:boolean:=FALSE;

constant SIM_WIDTH:natural:=8;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal doublesig:signed(ADC_WIDTH-1 downto 0);

signal store_reg:boolean;
signal event_enable:std_logic:='0';
signal clk_i:integer:=-1; --clk index for data files
signal flags:boolean_vector(10 downto 0);

begin
	
sample_clk <= not sample_clk after SAMPLE_CLK_PERIOD/2;
io_clk <= not IO_clk after IO_CLK_PERIOD/2;
clk_i <= clk_i+1 after SAMPLE_CLK_PERIOD;
reset0 <= '0' after 4*IO_CLK_PERIOD; 
reset1 <= '0' after 20*IO_CLK_PERIOD; 
reset2 <= '0' after 30*IO_CLK_PERIOD; 
--bytestream_ready <= io_clk_count mod 3 = 0;
                    

UUT:entity work.measurement_subsystem
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
  ACCUMULATE_N => ACCUMULATE_N,
  TRACE_FROM_STAMP => TRUE,
  MIN_TICK_PERIOD => 2000,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  ENET_FRAMER_ADDRESS_BITS => ETHERNET_ADDRESS_BITS
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
--ethernetstream_ready <= FALSE;
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
-- sample file -----------------------------------------------------------------
--global.mtu_words <= to_unsigned(187,MTU_BITS);
-- sim -------------------------------------------------------------------------
global.mtu_chunks <= to_unsigned(187,MTU_BITS);
global.tick_latency <= to_unsigned(120000,TICK_LATENCY_BITS);
global.tick_period <= to_unsigned(62500,TICK_PERIOD_BITS);
--global.mca.lowest_value <= to_signed(-2500,MCA_VALUE_BITS);
--global.mca.qualifier <= VALID_PEAK0_MCA_QUAL_D;
--TODO normalise these type names
--global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
--global.mca.value <= MCA_RAW_SIGNAL_D;
global.window <= to_unsigned(10, TIME_BITS);

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

chan_reg(0).baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
chan_reg(0).baseline.threshold <= (others => '1'); 
chan_reg(0).baseline.new_only <= TRUE;
chan_reg(0).baseline.subtraction <= FALSE;
chan_reg(0).baseline.timeconstant <= to_unsigned(25000,32);

--chan_reg(1).baseline.offset <= to_signed(-1000*8,DSP_BITS);
chan_reg(1).baseline.offset <= to_signed(0,DSP_BITS);
chan_reg(1).baseline.count_threshold <= to_unsigned(30,BASELINE_COUNTER_BITS);
chan_reg(1).baseline.threshold <= (others => '0'); 
chan_reg(1).baseline.new_only <= TRUE;
chan_reg(1).baseline.subtraction <= FALSE;
chan_reg(1).baseline.timeconstant <= to_unsigned(25000,32);

--------------------------------------------------------------------------------
--chan_reg(0).capture.slope_threshold <= to_unsigned(8*256,DSP_BITS-1); --2300
--reject first pulse
--chan_reg(0).capture.area_threshold <= to_unsigned(14000,AREA_WIDTH-1);
----two separate peaks
--chan_reg(0).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+3,DSP_BITS-1); 

-- pulse_threshold_neg & pulse_start simultaneous.
--chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(50,TRACE_LENGTH_BITS);

-- trace_last & pulse_start simultaneous.
--chan_reg(0).capture.pulse_threshold <= to_unsigned(116*8,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(15,TRACE_LENGTH_BITS);

-- double peaked pulse
--chan_reg(0).capture.pulse_threshold <= to_unsigned(108*8,DSP_BITS-1); 

--noise test
--chan_reg(0).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1); 

--double_peak
--chan_reg(0).capture.slope_threshold <= to_unsigned(1000,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(3000,DSP_BITS-1); 

--chan_reg(0).capture.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);
--chan_reg(0).capture.trace_length <= to_unsigned(16,TRACE_LENGTH_BITS);

--sample file
--chan_reg(0).capture.slope_threshold <= to_unsigned(800,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(529*8,DSP_BITS-1); 
--chan_reg(0).capture.area_threshold <= to_unsigned(200000,AREA_WIDTH-1);

--------------------------------------------------------------------------------
-- data recording
--------------------------------------------------------------------------------

file_open(bytestream_file,"../bytestream", WRITE_MODE);
byteStreamWriter:process
begin
  while TRUE loop
    wait until rising_edge(io_clk);
    if bytestream_valid and bytestream_ready then
      write(bytestream_file, to_integer(unsigned(bytestream)));
      if bytestream_last then
        write(bytestream_file, -io_clk_count); --identify last by -ve value
      else
        write(bytestream_file, io_clk_count);
      end if;
    end if;
  end loop;
end process byteStreamWriter;

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    write(trace_file, to_integer(m(0).raw));
    write(trace_file, to_integer(m(0).f));
    write(trace_file, to_integer(m(0).s));
  end loop;
end process traceWriter; 

flags <= -- byte 1
         --  5           6          7                        
         m(0).rise2 & m(0).rise1 & m(0).valid_rise & 
         --byte 0
         -- 0            1                   2                   
         m(0).rise0 & m(0).rise_start(NOW) & m(0).pulse_start(NOW) & 
         -- 3                4               5                6                 
         m(0).will_cross & m(0).will_arm & m(0).cfd_error & m(0).cfd_overrun & 
         -- 7
         m(0).cfd_valid;
         
file_open(min_file, "../min_data",WRITE_MODE);
minWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).min(NOW) then
      write(min_file, clk_i);
      write(min_file, to_integer(m(0).f));
      write(min_file, to_integer(m(0).s));
      write(min_file, to_integer(m(0).cfd_low));
      write(min_file, to_integer(m(0).cfd_high));
      write(min_file, to_integer(to_unsigned(flags)));
      write(min_file, to_integer(m(0).max_slope));
      write(min_file, to_integer(m(0).minima(NOW)));
      write(min_file, to_integer(m(0).s_area));
      write(min_file, to_integer(m(0).s_extrema));
    end if;
  end loop;
end process minWriter; 

file_open(max_file, "../max_data",WRITE_MODE);
maxWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).max(NOW) then
      write(max_file, clk_i);
      write(max_file, to_integer(m(0).f));
      write(max_file, to_integer(m(0).s));
      write(max_file, to_integer(to_unsigned(flags)));
      write(max_file, to_integer(m(0).s_area));
      write(max_file, to_integer(m(0).s_extrema));
      write(max_file, to_integer(m(0).peak_height));
    end if;
  end loop;
end process maxWriter; 

file_open(f0p_file, "../f0p_xings",WRITE_MODE);
f0pWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).f_0_p then
        write(f0p_file, clk_i);
        write(f0p_file, to_integer(m(0).f_area));
        write(f0p_file, to_integer(m(0).f_extrema));
    end if;
  end loop;
end process f0pWriter; 

file_open(f0n_file, "../f0n_xings",WRITE_MODE);
f0nWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).f_0_n then
        write(f0n_file, clk_i);
        write(f0n_file, to_integer(m(0).f_area));
        write(f0n_file, to_integer(m(0).f_extrema));
    end if;
  end loop;
end process f0nWriter; 

file_open(ptn_file, "../ptn_xings",WRITE_MODE);
ptnWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).p_t_n(NOW) then
      write(ptn_file, clk_i);
      write(ptn_file, to_integer(m(0).pulse_area));
      write(ptn_file, to_integer(m(0).pulse_length));
      write(ptn_file, to_integer(m(0).pulse_timer(NOW)));
    end if;
  end loop;
end process ptnWriter; 

file_open(rise_start_file, "../rise_start",WRITE_MODE);
riseStartWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).rise_start(NOW) then
      write(rise_start_file, clk_i);
      write(rise_start_file, to_integer(m(0).pulse_timer(NOW)));
      write(rise_start_file, to_integer(m(0).rise_number));
      write(rise_start_file, to_integer(m(0).rise_address));
    end if;
  end loop;
end process riseStartWriter; 

file_open(rise_stop_file, "../rise_stop",WRITE_MODE);
riseStopWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).rise_stop(NOW) then
      write(rise_stop_file, clk_i);
      write(rise_stop_file, to_integer(m(0).pulse_timer(NOW)));
      write(rise_stop_file, to_integer(m(0).rise_number));
      write(rise_stop_file, to_integer(m(0).rise_address));
      write(rise_stop_file, to_integer(m(0).rise_timer(NOW)));
      write(rise_stop_file, to_integer(m(0).peak_height));
    end if;
  end loop;
end process riseStopWriter; 

file_open(height_valid_file, "../height_valid",WRITE_MODE);
heightvalidWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).rise_stop(NOW) then
      write(rise_stop_file, clk_i);
      write(rise_stop_file, to_integer(m(0).pulse_timer(NOW)));
      write(rise_stop_file, to_integer(m(0).rise_number));
      write(rise_stop_file, to_integer(m(0).rise_address));
      write(rise_stop_file, to_integer(m(0).rise_timer(NOW)));
      write(rise_stop_file, to_integer(m(0).peak_height));
    end if;
  end loop;
end process heightvalidWriter; 

file_open(pulse_start_file, "../pulse_start",WRITE_MODE);
pulseStartWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).pulse_start(NOW) then
      write(pulse_start_file, clk_i);
      write(pulse_start_file, to_integer(m(0).enabled(NOW)));
      write(pulse_start_file, to_integer(m(0).reg(NOW).area_threshold));
      write(pulse_start_file, to_integer(m(0).reg(NOW).cfd_rel2min));
      write(pulse_start_file, to_integer(m(0).reg(NOW).constant_fraction));
      write(pulse_start_file, to_integer(m(0).reg(NOW).detection));
      write(pulse_start_file, to_integer(m(0).reg(NOW).height));
      write(pulse_start_file, to_integer(m(0).reg(NOW).max_peaks));
      write(pulse_start_file, to_integer(m(0).reg(NOW).pulse_threshold));
      write(pulse_start_file, to_integer(m(0).reg(NOW).slope_threshold));
      write(pulse_start_file, to_integer(m(0).reg(NOW).timing));
    end if;
  end loop;
end process pulseStartWriter; 


file_open(rise_stamp_file, "../stamp_rise",WRITE_MODE);
riseStampWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).stamp_rise(NOW) then
      write(rise_stamp_file, clk_i);
      write(rise_stamp_file, to_integer(m(0).pulse_timer(NOW)));
    end if;
  end loop;
end process riseStampWriter; 

file_open(pulse_stamp_file, "../stamp_pulse",WRITE_MODE);
pulseStampWriter:process
begin
  while TRUE loop
    wait until rising_edge(sample_clk);
    if m(0).stamp_pulse(NOW) then
      write(pulse_stamp_file, clk_i);
      write(pulse_stamp_file, to_integer(m(0).pulse_timer(NOW)));
    end if;
  end loop;
end process pulseStampWriter; 

file_open(init_reg_file, "../init_reg",WRITE_MODE);
initRegWriter:process
begin
    wait until store_reg;
    write(init_reg_file, clk_i);
    write(init_reg_file, to_integer(unsigned(global.channel_enable)));
    write(init_reg_file, to_integer(chan_reg(0).capture.area_threshold));
    write(init_reg_file, to_integer(chan_reg(0).capture.cfd_rel2min));
    write(init_reg_file, to_integer(chan_reg(0).capture.constant_fraction));
    write(init_reg_file, to_integer(chan_reg(0).capture.detection));
    write(init_reg_file, to_integer(chan_reg(0).capture.height));
    write(init_reg_file, to_integer(chan_reg(0).capture.max_peaks));
    write(init_reg_file, to_integer(chan_reg(0).capture.pulse_threshold));
    write(init_reg_file, to_integer(chan_reg(0).capture.slope_threshold));
    write(init_reg_file, to_integer(chan_reg(0).capture.timing));
    write(init_reg_file, to_integer(chan_reg(0).capture.trace_type));
    write(init_reg_file, to_integer(chan_reg(0).capture.trace_signal));
    write(init_reg_file, to_integer(chan_reg(0).capture.trace_length));
    write(init_reg_file, to_integer(chan_reg(0).capture.trace_stride));
    write(init_reg_file, to_integer(global.mtu_chunks));
    write(init_reg_file, to_integer(global.tick_latency));
    write(init_reg_file, to_integer(global.tick_period));
    write(init_reg_file, to_integer(global.window));
    write(init_reg_file, to_integer(global.mca.value));
    write(init_reg_file, to_integer(global.mca.trigger));
    write(init_reg_file, to_integer(global.mca.qualifier));
    write(init_reg_file, to_integer(global.mca.ticks));
    write(init_reg_file, to_integer(global.mca.bin_n));
    write(init_reg_file, to_integer(global.mca.channel));
    write(init_reg_file, to_integer(global.mca.last_bin));
    write(init_reg_file, to_integer(global.mca.lowest_value));
    wait;
end process initRegWriter; 
--------------------------------------------------------------------------------
clkCount:process(sample_clk)
begin
  if rising_edge(sample_clk) then
    clk_count <= clk_count+1;
    if clk_count mod 1071 = 0 then
      enable <= not enable;
    end if;
  end if;
end process clkCount;

ioClkCount:process(io_clk)
begin
  if rising_edge(io_clk) then
    io_clk_count <= io_clk_count+1;
  end if;
end process ioClkCount;

stimulusFile:process
	file sample_file:integer_file is in 
--	     "../input_signals/tes2_250_old.bin";
--	     "../bin_traces/july 10/gt1_100khz.bin";
--	     "../bin_traces/gt1_100khz_adc.bin";
	     "C:/TES_project/bin_traces/noise.bin";
--	     "../bin_traces/july 10/randn2.bin";
--	     "../bin_traces/july 10/randn.bin";
--	     "../bin_traces/double_peak_sample.bin";
	variable sample:integer;
	--variable sample_in:std_logic_vector(13 downto 0);
begin
	while not endfile(sample_file) loop
		read(sample_file, sample);
		wait until rising_edge(sample_clk);
		adc_samples(0) <= to_std_logic(sample, 14);
		adc_samples(1) <= to_std_logic(sample, 14);
	end loop;
	wait;
end process stimulusFile;

--stimulusFile2:process
--	file sample_file:integer_file is in 
----	     "../input_signals/tes2_250_old.bin";
----	     "../bin_traces/july 10/gt1_100khz.bin";
--	     "../bin_traces/july 10/randn2.bin";
----	     "../bin_traces/double_peak.bin";
--	variable sample:integer;
--	--variable sample_in:std_logic_vector(13 downto 0);
--begin
--	while not endfile(sample_file) loop
--		read(sample_file, sample);
--		wait until rising_edge(sample_clk);
--		adc_samples(1) <= to_std_logic(sample, 14);
--	end loop;
--	wait;
--end process stimulusFile2;
--adc_samples(1) <= (others => '0');

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
               
--adc_samples(0) <= std_logic_vector(signed(doublesig));
--adc_samples(0) <= std_logic_vector(adc_count);
--adc_samples(0) <= (others => '0');
--adc_samples(0) <= (ADC_WIDTH-1 => '1',others => '0') when 
--                  sim_count(SIM_WIDTH-1)='0' else
--                  (ADC_WIDTH-1 => '0',others => '1');

--enable test
--global.channel_enable <= "00000001";
--event_enable <= not event_enable after 1 us;
--global.channel_enable <= "000000" & event_enable & event_enable;
--global.channel_enable <= "0000000" & event_enable;


mcaControlStimulus:process
begin
  global.mca.update_asap <= FALSE;
  global.mca.update_on_completion <= FALSE;
--  global.channel_enable <= "00000000";
  chan_reg(0).capture.adc_select <= (0 => '1', others => '0');
  chan_reg(0).capture.delay <= (others => '0');
  chan_reg(0).capture.constant_fraction  <= to_unsigned(CF,CFD_BITS-1);
--  chan_reg(0).capture.detection <= TRACE_DETECTION_D;
  chan_reg(0).capture.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);
--  chan_reg(0).capture.timing <= PULSE_THRESH_TIMING_D;
  chan_reg(0).capture.trace_type <= SINGLE_TRACE_D;
  chan_reg(0).capture.trace_signal <= FILTERED_TRACE_D;
  chan_reg(0).capture.trace_length <= to_unsigned(256,TRACE_LENGTH_BITS);
  chan_reg(0).capture.height <= PEAK_HEIGHT_D;
  chan_reg(0).capture.cfd_rel2min <= FALSE;
  --
  chan_reg(1).capture.adc_select <= (1 => '1', others => '0');
  chan_reg(1).capture.delay <= to_unsigned(10,DELAY_BITS);
  chan_reg(1).capture.constant_fraction  <= to_unsigned(CF,CFD_BITS-1);
  chan_reg(1).capture.detection <= PULSE_DETECTION_D;
  chan_reg(1).capture.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);
  chan_reg(1).capture.timing <= PULSE_THRESH_TIMING_D;
  chan_reg(1).capture.trace_type <= SINGLE_TRACE_D;
  chan_reg(1).capture.trace_signal <= FILTERED_TRACE_D;
  chan_reg(1).capture.trace_length <= to_unsigned(512,TRACE_LENGTH_BITS);
--  chan_reg(1).capture.height <= CFD_HIGH_D;
  chan_reg(1).capture.height <= PEAK_HEIGHT_D;
  chan_reg(1).capture.cfd_rel2min <= FALSE;
  chan_reg(1).capture.trace_stride <= (others => '0');
  
	global.mca.value <= MCA_FILTERED_EXTREMA_D;
	global.mca.trigger <= FILTERED_0XING_MCA_TRIGGER_D;
	global.mca.qualifier <= ALL_MCA_QUAL_D;
  global.mca.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
  global.mca.bin_n <= to_unsigned(0,MCA_BIN_N_BITS);
  global.mca.channel <= (others => '0');
  global.mca.last_bin <= (others => '1'); --to_unsigned(1023,MCA_ADDRESS_BITS);
  global.mca.lowest_value <= to_signed(-8000,MCA_VALUE_BITS);
--	global.mca.update_asap <= TRUE;

--global.channel_enable <= "00000011";
--global.channel_enable <= "00000001";
--------------------------------------------------------------------------------
----two separate peaks
--------------------------------------------------------------------------------
--  chan_reg(0).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
--  chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+3,DSP_BITS-1); 
--  chan_reg(0).capture.trace_length <= to_unsigned(50,TRACE_LENGTH_BITS);
--  chan_reg(0).capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
--------------------------------------------------------------------------------
--sample file
--------------------------------------------------------------------------------
--chan_reg(0).capture.slope_threshold <= to_unsigned(800,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(529*8,DSP_BITS-1); 
--chan_reg(0).capture.area_threshold <= to_unsigned(200000,AREA_WIDTH-1);
--chan_reg(1).capture.slope_threshold <= to_unsigned(800,DSP_BITS-1); --2300
--chan_reg(1).capture.pulse_threshold <= to_unsigned(529*8,DSP_BITS-1); 
--chan_reg(1).capture.area_threshold <= to_unsigned(200000,AREA_WIDTH-1);
--------------------------------------------------------------------------------
-- pulse_threshold_neg & pulse_start simultaneous.
--------------------------------------------------------------------------------
--chan_reg(0).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
----chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
--chan_reg(0).capture.pulse_threshold <= to_unsigned(106*8+1,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(512,TRACE_LENGTH_BITS);
--chan_reg(0).capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
--------------------------------------------------------------------------------
-- gt1_100khz_adc
--------------------------------------------------------------------------------
--chan_reg(0).capture.slope_threshold <= to_unsigned(1500,DSP_BITS-1); --2300
----chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
--chan_reg(0).capture.pulse_threshold <= to_unsigned(3000,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(512,TRACE_LENGTH_BITS);
--chan_reg(0).capture.area_threshold <= to_unsigned(10000,AREA_WIDTH-1);
--chan_reg(0).baseline.offset <= to_signed(0,DSP_BITS);
--chan_reg(0).capture.trace_stride <= (0 => '0', others => '0');
--chan_reg(0).capture.trace_pre <= to_unsigned(64,TRACE_PRE_BITS);
--chan_reg(0).capture.trace_signal <= FILTERED_TRACE_D; 
--------------------------------------------------------------------------------
-- noise
--------------------------------------------------------------------------------
chan_reg(0).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
chan_reg(0).capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1); 
chan_reg(0).capture.trace_length <= to_unsigned(512,TRACE_LENGTH_BITS);
chan_reg(0).capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
chan_reg(0).baseline.offset <= to_signed(0,DSP_BITS);
chan_reg(0).capture.trace_stride <= (0 => '0', others => '0');
chan_reg(0).capture.trace_pre <= to_unsigned(64,TRACE_PRE_BITS);

chan_reg(1).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
chan_reg(1).capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1); 
--chan_reg(1).capture.trace_length <= to_unsigned(512,TRACE_LENGTH_BITS);
chan_reg(1).capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
--chan_reg(1).baseline.offset <= to_signed(0,DSP_BITS);
--chan_reg(1).capture.trace_stride <= (0 => '0', others => '0');
--chan_reg(1).capture.trace_pre <= to_unsigned(64,TRACE_PRE_BITS);
--------------------------------------------------------------------------------
-- double peak thesis
--------------------------------------------------------------------------------
--chan_reg(0).capture.slope_threshold <= to_unsigned(4500,DSP_BITS-1); --2300
----chan_reg(0).capture.pulse_threshold <= to_unsigned(109*8+1,DSP_BITS-1); 
--chan_reg(0).capture.pulse_threshold <= to_unsigned(2700,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(512,TRACE_LENGTH_BITS);
--chan_reg(0).capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
--chan_reg(0).baseline.offset <= to_signed(0,DSP_BITS);
--chan_reg(0).capture.trace_stride <= (0 => '0', others => '0');
--chan_reg(0).capture.max_peaks <= to_unsigned(1,PEAK_COUNT_BITS);

--------------------------------------------------------------------------------
-- randn samples
--------------------------------------------------------------------------------
--chan_reg(0).capture.slope_threshold <= to_unsigned(0,DSP_BITS-1); --2300
--chan_reg(0).capture.pulse_threshold <= to_unsigned(0,DSP_BITS-1); 
--chan_reg(0).capture.trace_length <= to_unsigned(64,TRACE_LENGTH_BITS);
--chan_reg(0).capture.trace_stride <= (0 => '0', others => '0');
--chan_reg(0).capture.area_threshold <= to_unsigned(0,AREA_WIDTH-1);
--chan_reg(0).baseline.offset <= to_signed(0,DSP_BITS);
--------------------------------------------------------------------------------
--Trace settings
--------------------------------------------------------------------------------
chan_reg(0).capture.trace_type <= SINGLE_TRACE_D;
--chan_reg(0).capture.trace_stride <= (0 => '0', others => '0');
--chan_reg(0).capture.trace_length <= to_unsigned(512,TRACE_LENGTH_BITS);
--chan_reg(0).capture.trace_type <= AVERAGE_TRACE_D;
--chan_reg(0).capture.detection <= PULSE_DETECTION_D;
chan_reg(0).capture.timing <= PULSE_THRESH_TIMING_D;
--------------------------------------------------------------------------------
wait until reset2='0';
simenable <= TRUE;
bytestream_ready <= TRUE;
global.channel_enable <= "00000011";
store_reg <= TRUE;

while TRUE loop
  chan_reg(0).capture.timing <= PULSE_THRESH_TIMING_D;
  chan_reg(0).capture.detection <= PULSE_DETECTION_D;
  wait for 1 us;
  chan_reg(0).capture.detection <= TRACE_DETECTION_D;
  wait for 1 us;
  chan_reg(0).capture.timing <= CFD_LOW_TIMING_D;
  chan_reg(0).capture.detection <= PULSE_DETECTION_D;
  wait for 1 us;
  chan_reg(0).capture.detection <= TRACE_DETECTION_D;
  wait for 1 us;
  chan_reg(0).capture.timing <= PULSE_THRESH_TIMING_D;
  chan_reg(0).capture.detection <= PULSE_DETECTION_D;
  wait for 1 us;
  chan_reg(0).capture.detection <= TRACE_DETECTION_D;
  wait for 1 us;
  chan_reg(0).capture.timing <= MAX_SLOPE_TIMING_D;
  chan_reg(0).capture.detection <= PULSE_DETECTION_D;
  wait for 1 us;
  chan_reg(0).capture.detection <= TRACE_DETECTION_D;
  wait for 1 us;
end loop;
end process mcaControlStimulus;	

end architecture testbench;
