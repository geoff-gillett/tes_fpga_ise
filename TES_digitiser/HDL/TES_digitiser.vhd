--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: event_mux_TB
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.types.all;

--
library adclib;
use adclib.types.all;
--
library controllerlib;
--
library ethernetlib;
--
library mcalib;
--
library unisim;
use unisim.vcomponents.ibufds;
use unisim.vcomponents.bufg;
use unisim.vcomponents.bufr;

entity TES_digitiser is
generic(
  ------------------------------------------------------------------------------
  -- Hardware
  ------------------------------------------------------------------------------
  VERSION:unsigned(31 downto 0):=to_unsigned(23,32);
  ADC_CHIPS:integer:=4;
  ADC_CHIP_CHANNELS:integer:=2;
  --SPI_CHANNELS:integer:=5;
  ------------------------------------------------------------------------------
  -- Signal path parameters
  ------------------------------------------------------------------------------
  TES_CHANNEL_BITS:integer:=2;
  DELAY_BITS:integer:=10;
  SLOPE_ADDRESS_BITS:integer:=6;
  SYNC_ADDRESS_BITS:integer:=6;
  SIGNAL_AV_BITS:integer:=6;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_AV_BITS:integer:=10;
  MAX_PEAKS:integer:=4;
  ------------------------------------------------------------------------------
  -- Channel register defaults
  ------------------------------------------------------------------------------
  DEFAULT_DELAY:integer:=0;
  DEFAULT_SIGNAL_AVN:integer:=5;
  DEFAULT_SLOPE_N:integer:=3;
  DEFAULT_SYNC_CLKS:integer:=4;
  DEFAULT_BASELINE_TIMECONSTANT:integer:=0;
  DEFAULT_BASELINE_AVN:integer:=7;
  DEFAULT_START_THRESHOLD:integer:=1000;
  DEFAULT_STOP_THRESHOLD:integer:=1000;
  DEFAULT_SLOPE_THRESHOLD:integer:=15;
  DEFAULT_SLOPE_CROSSING:integer:=0;
  DEFAULT_AREA_THRESHOLD:integer:=1000;
  DEFAULT_FIXED_BASELINE:integer:=8192;
  ------------------------------------------------------------------------------
  -- MCAstream
  ------------------------------------------------------------------------------
  MCASTREAM_CHUNKS:integer:=2;
  MCA_ADDRESS_BITS:integer:=ADC_BITS;
  MCA_COUNTER_BITS:integer:=32;
  MCA_VALUE_BITS:integer:=AREA_BITS;
  MCA_TOTAL_BITS:integer:=64;
  MCA_VALUES:integer:=8;
  ------------------------------------------------------------------------------
  -- Eventstream
  ------------------------------------------------------------------------------
  EVENTSTREAM_CHUNKS:integer:=4;
  EVENT_THRESHOLD_BITS:integer:=12;  
  DEFAULT_EVENT_THRESHOLD:integer:=3000;
  EVENT_TIMEOUT_BITS:integer:=32;
  DEFAULT_EVENT_TIMEOUT:integer:=25000000;
  EVENT_LENGTH_BITS:integer:=SIZE_BITS;
  ------------------------------------------------------------------------------
  -- Etherenet stream
  ------------------------------------------------------------------------------
  ENDIANNESS:string:="LITTLE";
  STREAM_BITS:integer:=OUTSTREAM_DATA_BITS;
  MTU_BITS:integer:=12;
  MIN_FRAME_LENGTH:integer:=32;
  DEFAULT_MTU:integer:=750;
  ------------------------------------------------------------------------------
  -- General registers
  ------------------------------------------------------------------------------
  TICK_PERIOD_BITS:integer:=32;
  DEFAULT_TICK_PERIOD:integer:=25000000;
  TICK_COUNT_BITS:integer:=32
);
port(
  ------------------------------------------------------------------------------
  -- System clocks and resets
  ------------------------------------------------------------------------------
  clk_p:in std_logic; --to MMCM
  clk_n:in std_logic;
  global_reset:in std_logic;
  LEDs:out std_logic_vector(7 downto 0);
  ------------------------------------------------------------------------------
  -- USB-UART bridge
  ------------------------------------------------------------------------------
  main_Rx:in std_logic;
  main_Tx:out std_logic;
  ------------------------------------------------------------------------------
  -- FMC108 pins - HPC FMC connector on the ML605  
  ------------------------------------------------------------------------------
  AD9510_clkout6_p:in std_logic; --used to clock pipeline (source common to adc clks)  
  AD9510_clkout6_n:in std_logic;
  FMC_power_good:in std_logic;
  FMC_present_n:in std_logic; --FMC108 present in the HPC FMC connector
  FMC_AD9510_status:in std_logic;
  FMC_reset:out std_logic;
  FMC_internal_clk_en:out std_logic;
  FMC_VCO_power_en:out std_logic;
  FMC_AD9510_function:out std_logic;
  -- Texas instruments ADS62P49 ADC chip SPI communication
  ADC_spi_clk:out std_logic;
  ADC_spi_ce_n:out std_logic_vector(ADC_CHIPS-1 downto 0);
  ADC_spi_miso:in std_logic_vector(ADC_CHIPS-1 downto 0);
  ADC_spi_mosi:out std_logic;
  -- Analog Devices AD9510 PLL/clock distribution SPI communication
  AD9510_spi_clk:out std_logic;
  AD9510_spi_ce_n:out std_logic;
  AD9510_spi_miso:in std_logic;
  AD9510_spi_mosi:out std_logic;
  -- ADS62P49 clocks derived from AD9510
  adc_clk_p:in std_logic_vector(ADC_CHIPS-1 downto 0);
  adc_clk_n:in std_logic_vector(ADC_CHIPS-1 downto 0);
  -- ADS62P49 LVDS samples
  adc_0_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_0_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_1_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_1_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_2_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_2_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_3_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_3_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_4_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_4_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_5_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_5_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_6_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_6_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_7_p:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  adc_7_n:in std_logic_vector((ADC_BITS/2)-1 downto 0);
  ------------------------------------------------------------------------------
  -- embedded MAC
  ------------------------------------------------------------------------------
  phy_resetn:out std_logic;
  gmii_txd:out std_logic_vector(STREAM_BITS-1 downto 0);
  gmii_tx_en:out std_logic;
  gmii_tx_er:out std_logic;
  gmii_tx_clk:out std_logic;
  gmii_rxd:in std_logic_vector(STREAM_BITS-1 downto 0);
  gmii_rx_dv:in std_logic;
  gmii_rx_er:in std_logic;
  gmii_rx_clk:in std_logic;
  gmii_col:in std_logic;
  gmii_crs:in std_logic;
  mii_tx_clk:in std_logic;
  --
  mdio:inout std_logic;
  mdc:out std_logic;
  --
  tx_statistics_s:out std_logic;
  rx_statistics_s:out std_logic;
  --
  pause_req_s:in std_logic;
  --
  mac_speed:in std_logic_vector(1 downto 0);
  update_speed:in std_logic;
  serial_command:in std_logic;
  serial_response:out std_logic;
  --
  reset_error:in std_logic;
  frame_error:out std_logic;
  frame_errorn:out std_logic
);
end entity TES_digitiser;
architecture ML605 of TES_digitiser is
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
constant ADC_CHANNELS:integer:=ADC_CHIPS*ADC_CHIP_CHANNELS;
constant TES_CHANNELS:integer:=2**TES_CHANNEL_BITS;
constant SPI_CHANNELS:integer:=ADC_CHIPS+1;
--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
--component MMCM_clk_wiz_v3_6
--port(
--  -- clock in ports
--  clk_in1_p:in std_logic;
--  clk_in1_n:in std_logic;
--  -- clock out ports
--  clk_out1:out std_logic;
--  clk_out2:out std_logic;
--  clk_out3:out std_logic;
--  clk_out4:out std_logic;
--  -- status and control signals
--  locked:out std_logic
--);
--end component;

component pipelineMMCM
port(
   -- Clock in ports
  AD9510_clkout6:in std_logic;
  -- Clock out ports
  pipeline_clk:out std_logic;
  -- Status and control signals
  locked:out std_logic
 );
end component;

component IO_MMCM
port(
  -- Clock in ports
  board_clk_P : in std_logic;
  board_clk_N : in std_logic;
  -- Clock out ports
  IO_clk : out std_logic;
  IOdelay_refclk : out std_logic;
  saxi_aclk : out std_logic;
  -- Status and control signals
  locked : out std_logic
);
end component;

component frame_buffer
port (
  wr_clk:in std_logic;
  wr_rst:in std_logic;
  rd_clk:in std_logic;
  rd_rst:in std_logic;
  din:in std_logic_vector(17 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(8 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;
--------------------------------------------------------------------------------
-- Clock and reset signals
--------------------------------------------------------------------------------
signal global_reset_IO_clk,IO_clk,pipeline_clk,AD9510_clkout6_buf:std_logic;
signal reset0,reset1,reset2,CPU_reset,IO_MMCM_locked,AD9510_clkout6:std_logic;
signal AD9510_clk_stopped,pipeline_mmcm_locked:std_logic;
signal s_axi_aclk,iodelay_refclk:std_logic;
attribute keep:string;

attribute keep of AD9510_clk_stopped:signal is "true";
attribute keep of pipeline_mmcm_locked:signal is "true";
attribute keep of reset0:signal is "true";
attribute keep of reset1:signal is "true";
attribute keep of reset2:signal is "true";
attribute keep of CPU_reset:signal is "true";
--------------------------------------------------------------------------------
-- FMC108 signals
--------------------------------------------------------------------------------
constant IODELAY_CONTROL_BITS:integer:=ADC_BITS+bits(ADC_CHANNELS);
-- DDR
signal adc_clk,adc_clk_buf:std_logic_vector(ADC_CHIPS-1 downto 0);
signal adc_ddr:ddr_sample_array(ADC_CHANNELS-1 downto 0);
--
signal iodelay_control:std_logic_vector(IODELAY_CONTROL_BITS-1 downto 0);
signal iodelay_updated:boolean;
--
signal FMC_internal_clk_en_int,FMC_VCO_power_en_int,FMC_present:std_logic;
signal adc_fifo_full:boolean_vector(ADC_CHANNELS-1 downto 0);
signal adc_enables:boolean_vector(ADC_CHANNELS-1 downto 0);
signal adc_sample:adc_sample_array(ADC_CHANNELS-1 downto 0);
signal adc_valid:boolean;
--------------------------------------------------------------------------------
-- Channel pipeline wiring
--------------------------------------------------------------------------------
signal eventstream_enables:boolean_vector(TES_CHANNELS-1 downto 0);
signal channel_rx,channel_tx:std_logic_vector(TES_CHANNELS-1 downto 0);
signal write_register,write_register_IO_clk
			 :boolean_vector(TES_CHANNELS-1 downto 0);
signal register_address:registeraddress_array(TES_CHANNELS-1 downto 0);
signal register_write_data:registerdata_array(TES_CHANNELS-1 downto 0);
signal register_read_data:registerdata_array(TES_CHANNELS-1 downto 0);
signal pulse_areas:pulse_area_array(TES_CHANNELS-1 downto 0);
signal mca_pulse_areas:pulse_area_array(TES_CHANNELS-1 downto 0);
signal sample_areas:sample_area_array(TES_CHANNELS-1 downto 0);
signal mca_sample_areas:sample_area_array(TES_CHANNELS-1 downto 0);
signal events_lost,pulse_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal mca_pulse_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal sample_extremas,slope_extremas:rel_sample_array(TES_CHANNELS-1 downto 0);
signal mca_sample_extremas:rel_sample_array(TES_CHANNELS-1 downto 0);
signal mca_slope_extremas:rel_sample_array(TES_CHANNELS-1 downto 0);
signal sample_out:rel_sample_array(TES_CHANNELS-1 downto 0);
signal mca_sample:rel_sample_array(TES_CHANNELS-1 downto 0);
signal baseline_out:sample_array(TES_CHANNELS-1 downto 0);
signal mca_baseline:sample_array(TES_CHANNELS-1 downto 0);
signal pulse_lengths:time_array(TES_CHANNELS-1 downto 0);
signal mca_pulse_lengths:time_array(TES_CHANNELS-1 downto 0);
signal sample_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal mca_sample_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal max_valids,min_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal slope_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal mca_max_valids,mca_min_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal mca_slope_valids:boolean_vector(TES_CHANNELS-1 downto 0);
signal start,signal_valid:boolean_vector(TES_CHANNELS-1 downto 0);
--------------------------------------------------------------------------------
-- MUX signals
--------------------------------------------------------------------------------
signal commit,dump:boolean_vector(TES_CHANNELS-1 downto 0);
signal instream:eventbus_array(TES_CHANNELS-1 downto 0);
signal instream_last,instream_valid:boolean_vector(TES_CHANNELS-1 downto 0);
signal ready_for_instream:boolean_vector(TES_CHANNELS-1 downto 0);
signal mux_full:boolean;
--------------------------------------------------------------------------------
-- Events 
--------------------------------------------------------------------------------
signal eventstream:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal eventstream_valid,eventstream_ready:boolean;
signal event_threshold:unsigned(EVENT_THRESHOLD_BITS-1 downto 0);
signal event_timeout:unsigned(EVENT_TIMEOUT_BITS-1 downto 0);
--------------------------------------------------------------------------------
-- output stream
--------------------------------------------------------------------------------
signal MTU:unsigned(MTU_BITS-1 downto 0);
signal tick_period:unsigned(TICK_PERIOD_BITS-1 downto 0);
signal frame_stream:std_logic_vector(STREAM_BITS-1 downto 0);
signal valid,last,ready_out:boolean;
signal ready:std_logic;
signal framechunk:std_logic_vector(CHUNK_BITS-1 downto 0);
signal framechunk_valid,framechunk_ready:boolean;
signal framebuffer_din:std_logic_vector(17 downto 0);
signal framebuffer_wr_en,framebuffer_rd_en:std_logic;
signal framebuffer_dout:std_logic_vector(8 downto 0);
signal framebuffer_full,framebuffer_empty:std_logic;
--------------------------------------------------------------------------------
-- MCA signals
--------------------------------------------------------------------------------
signal mca_updated,mca_updated_sclk:boolean;
signal mca_update_asap,mca_update_on_completion:boolean;
signal mca_ticks:unsigned(TICK_COUNT_BITS-1 downto 0);
signal mca_bin_n:unsigned(bits(MCA_ADDRESS_BITS)-1 downto 0);
signal mca_lowest_value:signed(MCA_VALUE_BITS-1 downto 0);
signal mca_last_bin:unsigned(MCA_ADDRESS_BITS-1 downto 0);
signal mca_channel_select:unsigned(bits(TES_CHANNELS)-1 downto 0);
signal mca_value_select:boolean_vector(MCA_VALUES-1 downto 0);
signal mcastream:std_logic_vector(MCASTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal mcastream_valid,mcastream_ready:boolean;
--------------------------------------------------------------------------------
-- Main CPU signals
--------------------------------------------------------------------------------
signal spi_clk,spi_mosi:std_logic;
signal spi_ce_n,spi_miso:std_logic_vector(SPI_CHANNELS-1 downto 0);
signal global_register_address:registeraddress;
signal global_register_write_data:registerdata;
signal global_register_read_data:registerdata;
signal write_global_register,write_global_register_IO_clk:boolean;
attribute keep of write_global_register:signal is "true";
--------------------------------------------------------------------------------
signal overflow_LEDs:std_logic_vector(7 downto 0):=(others => '0');
subtype overflow_counter is integer range 0 to 50000000;
type overflow_array is array (natural range <>) of overflow_counter;
signal overflow_count:overflow_array(TES_CHANNELS downto 0);
begin
--LEDs <= signal_pipeline_LEDs;
--LEDs <= padLeft(to_std_logic(eventstream_enables),8);
LEDs <= overflow_LEDs;
overflowLEDs:process (pipeline_clk) is
begin
if rising_edge(pipeline_clk) then
  if reset0 = '1' then
    for i in TES_CHANNELS downto 0 loop
       overflow_count(i) <= 0;
    end loop;
  else
    for i in TES_CHANNELS-1 downto 0 loop
      if events_lost(i) then
        overflow_count(i) <= 50000000;
      else
        if overflow_count(i) = 0 then
          overflow_LEDs(i) <= '0';
        else
          overflow_LEDs(i) <= '1';
          overflow_count(i) <= overflow_count(i)-1;
        end if;
      end if;
    end loop;
    if (mux_full) then
        overflow_count(TES_CHANNELS) <= 50000000;
    else
      if overflow_count(TES_CHANNELS) = 0 then
        overflow_LEDs(TES_CHANNELS) <= '0';
      else
        overflow_LEDs(TES_CHANNELS) <= '1';
        overflow_count(TES_CHANNELS) <= overflow_count(TES_CHANNELS)-1;
      end if;
    end if;
  end if;
end if;
end process overflowLEDs;

--
ADC_spi_ce_n <= spi_ce_n(ADC_CHIPS-1 downto 0); 
AD9510_spi_ce_n  <= spi_ce_n(ADC_CHIPS); 
spi_miso(ADC_CHIPS-1 downto 0) <= ADC_spi_miso; 
spi_miso(ADC_CHIPS) <= AD9510_spi_miso; 
ADC_spi_clk <= spi_clk;
AD9510_spi_clk <= spi_clk;
ADC_spi_mosi <= spi_mosi;
AD9510_spi_mosi <= spi_mosi;
FMC_reset <= reset0;
FMC_internal_clk_en <= FMC_internal_clk_en_int;
FMC_VCO_power_en <= FMC_VCO_power_en_int;
--
FMCfunction:process (IO_clk) is
begin
if rising_edge(IO_clk) then
  if reset0 = '1' then
    FMC_AD9510_function <= '0';
  else
    FMC_AD9510_function <= '1';
  end if;
end if;
end process FMCfunction;
--------------------------------------------------------------------------------
-- Clock and reset tree
--------------------------------------------------------------------------------
--clockTree:component MMCM_clk_wiz_v3_6
--port map(
--  clk_in1_p => clk_p,
--  clk_in1_n => clk_n,
--  clk_out1 => IO_clk, --125 Mhz
--  clk_out2 => s_axi_aclk, --FIXME replace s_axi_clk with IO_clk
--  clk_out3 => idelay_refclk, --200 MHz?
--  clk_out4 => open, --pipeline_clk, --250 MHz
--  locked => dcm_locked
--);

ioClkGen:IO_MMCM
port map(
  -- Clock in ports
  board_clk_p => clk_P,
  board_clk_n => clk_n,
  -- Clock out ports
  IO_clk => IO_clk,
  IOdelay_refclk => iodelay_refclk,
  saxi_aclk => s_axi_aclk,
  -- Status and control signals
  locked => IO_MMCM_locked
);

pipelineClkGen:pipelineMMCM
port map(
  -- Clock in ports
  AD9510_clkout6 => AD9510_clkout6,
  -- Clock out ports
  pipeline_clk => pipeline_clk,
  -- Status and control signals
  locked => pipeline_mmcm_locked
);
--
glbl_reset_gen:entity teslib.reset_sync
port map(
  clk => IO_clk,
  enable => IO_MMCM_locked,
  reset_in => global_reset,
  reset_out => global_reset_IO_clk
);
--------------------------------------------------------------------------------
-- FMC108 Input buffers
--------------------------------------------------------------------------------
clkInputBuffers:for i in ADC_CHIPS-1 downto 0 generate
  adcClkIbufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_clk_buf(i),
    I => adc_clk_p(i),
    IB => adc_clk_n(i)
  );
  adcClkBufr:bufr
  generic map (
    BUFR_DIVIDE => "BYPASS"
  )
  port map (
    ce => '1',
    clr=> '0',
    i  => adc_clk_buf(i),
    o  => adc_clk(i)
  );
end generate;
pipelineIbufds:ibufds
generic map(
  DIFF_TERM => TRUE,
  IOSTANDARD => "LVDS_25"
)
port map(
  O => AD9510_clkout6_buf,
  I => AD9510_clkout6_p,
  IB => AD9510_clkout6_n
);
pipelineBufr:bufr
generic map (
  BUFR_DIVIDE => "BYPASS"
)
port map (
  ce => '1',
  clr=> '0',
  i  => AD9510_clkout6_buf,
  o  => AD9510_clkout6
);
--pipelineBufg:bufg
--port map(
--  i => AD9510_clkout6_buf,
--  o => pipeline_clk
--);
adcDataBuffers:for i in ADC_BITS/2-1 downto 0 generate
  data0Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(0)(i),
    I => adc_0_p(i),
    IB => adc_0_n(i)
  );
  data1Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(1)(i),
    I => adc_1_p(i),
    IB => adc_1_n(i)
  );
  data2Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(2)(i),
    I => adc_2_p(i),
    IB => adc_2_n(i)
  );
  data3Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(3)(i),
    I => adc_3_p(i),
    IB => adc_3_n(i)
  );
  data4Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(4)(i),
    I => adc_4_p(i),
    IB => adc_4_n(i)
  );
  data5Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(5)(i),
    I => adc_5_p(i),
    IB => adc_5_n(i)
  );
  data6Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(6)(i),
    I => adc_6_p(i),
    IB => adc_6_n(i)
  );
  data7Ibufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_ddr(7)(i),
    I => adc_7_p(i),
    IB => adc_7_n(i)
  );
end generate;
--------------------------------------------------------------------------------
-- FMC108 hardware TODO handle reset on the signal pipeline properly
--------------------------------------------------------------------------------
FMC108:entity adclib.fmc108
generic map(
  ADC_CHIPS => ADC_CHIPS,
  CHIP_CHANNELS => ADC_CHIP_CHANNELS,
  IODELAY_VALUE => 0
)
port map(
  chip_clks => adc_clk,
  adc_ddr => adc_ddr,
  pipeline_clk => pipeline_clk,
  reset => reset1,
  adc_enables => adc_enables,
  samples_valid => adc_valid,
  fifo_full => adc_fifo_full,
  samples => adc_sample,
  inc => iodelay_control(ADC_BITS/2-1 downto 0),
  dec => iodelay_control(ADC_BITS-1 downto ADC_BITS/2),
  channel => unsigned(
    iodelay_control(IODELAY_CONTROL_BITS-1 downto ADC_BITS)
  ),
  update => iodelay_updated
);
--------------------------------------------------------------------------------
-- Channel pipelines
--------------------------------------------------------------------------------
TESchannel:for chan in TES_CHANNELS-1 downto 0 generate
  CPU:entity controllerlib.channel_controller
  port map(
    clk => IO_clk,
    reset => reset0,
    uart_tx => channel_rx(chan),
    uart_rx => channel_tx(chan),
    data_out => register_write_data(chan),
    address => register_address(chan),
    write => write_register_IO_clk(chan),
    data_in => register_read_data(chan)
  );
  syncWrite:entity teslib.sync_boolean_pulse
  port map(
    in_clk => IO_clk,
    out_clk => pipeline_clk,
    pulse_in => write_register_IO_clk(chan),
    pulse_out => write_register(chan)
  );
  channelPipeline:entity work.channel_pipeline
  generic map(
    CHANNEL_NUMBER => chan,
    DELAY_BITS => DELAY_BITS,
    SLOPE_ADDRESS_BITS => SLOPE_ADDRESS_BITS,
    SYNC_ADDRESS_BITS => SYNC_ADDRESS_BITS,
    SIGNAL_AV_BITS => SIGNAL_AV_BITS,
    BASELINE_TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
    BASELINE_AV_BITS => BASELINE_AV_BITS,
    MAX_PEAKS => MAX_PEAKS,
    ENDIANNESS => ENDIANNESS,
    DEFAULT_DELAY => DEFAULT_DELAY,
    DEFAULT_SIGNAL_AVN => DEFAULT_SIGNAL_AVN,
    DEFAULT_SLOPE_N => DEFAULT_SLOPE_N,
    DEFAULT_SYNC_CLKS => DEFAULT_SYNC_CLKS,
    DEFAULT_BASELINE_TIMECONSTANT => DEFAULT_BASELINE_TIMECONSTANT,
    DEFAULT_BASELINE_AVN => DEFAULT_BASELINE_AVN,
    DEFAULT_START_THRESHOLD => DEFAULT_START_THRESHOLD,
    DEFAULT_STOP_THRESHOLD => DEFAULT_STOP_THRESHOLD,
    DEFAULT_SLOPE_THRESHOLD => DEFAULT_SLOPE_THRESHOLD,
    DEFAULT_SLOPE_CROSSING => DEFAULT_SLOPE_CROSSING,
    DEFAULT_AREA_THRESHOLD => DEFAULT_AREA_THRESHOLD,
    DEFAULT_FIXED_BASELINE => DEFAULT_FIXED_BASELINE
  )
  port map(
    pipeline_clk => pipeline_clk,
    reset1 => reset1,
    reset2 => reset2,
    ADC_sample => unsigned(adc_sample(chan)),
    eventstream_enabled => eventstream_enables(chan),
    mux_full => mux_full,
    event_lost => events_lost(chan),
    dirty => signal_valid(chan),
    register_write_value => register_write_data(chan),
    register_read_value => register_read_data(chan),
    register_address => register_address(chan),
    register_write => write_register(chan),
    sample => sample_out(chan),
    baseline => baseline_out(chan),
    local_maxima => max_valids(chan),
    local_minima => min_valids(chan),
    sample_extrema => sample_extremas(chan),
    sample_area => sample_areas(chan),
    sample_valid => sample_valids(chan),
    pulse_area => pulse_areas(chan),
    pulse_length => pulse_lengths(chan),
    pulse_valid => pulse_valids(chan),
    slope_extrema => slope_extremas(chan),
    slope_valid => slope_valids(chan),
    start_mux => start(chan),
    commit_pulse => commit(chan),
    dump_pulse => dump(chan),
    eventstream => instream(chan),
    eventstream_valid => instream_valid(chan),
    eventstream_ready => ready_for_instream(chan),
    eventstream_last => instream_last(chan)
  );
end generate TESchannel;
--------------------------------------------------------------------------------
-- eventstream MUX
--------------------------------------------------------------------------------
MUX:entity work.event_mux
generic map(
  CHANNEL_BITS => TES_CHANNEL_BITS,
  EVENTSTREAM_CHUNKS => EVENTSTREAM_CHUNKS,
  TICK_BITS => TICK_PERIOD_BITS,
  TIMESTAMP_BITS => GLOBALTIME_BITS,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => pipeline_clk,
  reset1 => reset1,
  reset2 => reset2,
  start => start,
  commit => commit,
  dump => dump,
  instream => instream,
  instream_last => instream_last,
  instream_valid => instream_valid,
  ready_for_instream => ready_for_instream,
  full => mux_full,
  tick_period => tick_period,
  events_lost => events_lost,
  dirty => adc_fifo_full(TES_CHANNELS-1 downto 0),--signal_valid,
  eventstream => eventstream,
  valid => eventstream_valid,
  last => open, --eventstream_last,
  ready => eventstream_ready
);
--------------------------------------------------------------------------------
--MCA sample input routing
--------------------------------------------------------------------------------
mcaInputReg:process(pipeline_clk)
begin
  if rising_edge(pipeline_clk) then
    mca_sample <= sample_out;
    mca_baseline <= baseline_out; 
    mca_sample_extremas <= sample_extremas;
    mca_sample_areas <= sample_areas;
    mca_slope_extremas <= slope_extremas;
    mca_pulse_areas <= pulse_areas;
    mca_pulse_lengths <= pulse_lengths;
    mca_max_valids <= max_valids;
    mca_min_valids <= min_valids;
    mca_sample_valids <= sample_valids;
    mca_slope_valids <= slope_valids;
    mca_pulse_valids <= pulse_valids;
  end if;
end process mcaInputReg;
--------------------------------------------------------------------------------
-- MCA
--------------------------------------------------------------------------------
-- flag crossings
update:entity teslib.sync_boolean_pulse
port map(
  in_clk => pipeline_clk,
  out_clk => IO_clk,
  pulse_in => mca_updated_sclk,
  pulse_out => mca_updated
);

MCA:entity work.statistics
generic map(
  CHANNEL_BITS => TES_CHANNEL_BITS,
  ADDRESS_BITS => ADC_BITS,
  COUNTER_BITS => MCA_COUNTER_BITS,
  VALUE_BITS => MCA_VALUE_BITS,
  TOTAL_BITS => MCA_TOTAL_BITS,
  TICK_COUNT_BITS => TICK_COUNT_BITS,
  TICK_PERIOD_BITS => TICK_PERIOD_BITS,
  STREAM_CHUNKS => MCASTREAM_CHUNKS,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => pipeline_clk,
  reset => reset1,
  LEDs => open,
  update_asap => mca_update_asap,
  update_on_completion => mca_update_on_completion,
  updated => mca_updated,
  bin_n => mca_bin_n,
  lowest_value => mca_lowest_value,
  last_bin => mca_last_bin,
  ticks => mca_ticks,
  tick_period => tick_period,
  channel_select => mca_channel_select,
  value_select => mca_value_select,
  samples => mca_sample,
  baselines  => mca_baseline,
  extremas => mca_sample_extremas,
  areas => mca_sample_areas,
  derivative_extremas => mca_slope_extremas,
  pulse_areas => mca_pulse_areas,
  pulse_lengths => mca_pulse_lengths,
  max_valids => mca_max_valids,
  --min_valids => min_valids,
  sample_valids => mca_sample_valids,
  derivative_valids => mca_slope_valids,
  pulse_valids => mca_pulse_valids,
  stream => mcastream,
  valid => mcastream_valid,
  ready => mcastream_ready
);
--------------------------------------------------------------------------------
-- Ethernet framing
--------------------------------------------------------------------------------
transmitter:entity ethernetlib.transmitter
generic map(
	MCASTREAM_CHUNKS => MCASTREAM_CHUNKS,
  EVENTSTREAM_CHUNKS => EVENTSTREAM_CHUNKS,
  THRESHOLD_BITS => EVENT_THRESHOLD_BITS,
  TIMEOUT_BITS => EVENT_TIMEOUT_BITS,
  EVENT_LENGTH_BITS => EVENT_LENGTH_BITS,
  MTU_BITS => MTU_BITS,
  MIN_FRAME_LENGTH => MIN_FRAME_LENGTH,
  ENDIANNESS => ENDIANNESS
)
port map(
	clk => pipeline_clk,
  reset => reset1,
  LEDs => open,
  framechunk => framechunk,
  framechunk_valid => framechunk_valid,
  framechunk_ready => framechunk_ready,
  MTU => MTU,
  threshold => event_threshold,
  timeout => event_timeout,
  eventstream => eventstream,
  eventstream_valid => eventstream_valid,
  eventstream_ready => eventstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready
);
--------------------------------------------------------------------------------
-- Ethernet MAC
--------------------------------------------------------------------------------
framebuffer_din <= '0' & framechunk(15 downto 8) 
											 & framechunk(CHUNK_LASTBIT) 
											 & framechunk(7 downto 0);
framebuffer_wr_en <= to_std_logic(framechunk_valid and framebuffer_full='0');
framechunk_ready <= framebuffer_full='0';
-- downsize to bytes and cross from sample_clk to IO_clk domain
frameBuffer:frame_buffer
port map(
  wr_rst => reset0,
  wr_clk => pipeline_clk,
  rd_rst => reset0,
  rd_clk => IO_clk,
  din => framebuffer_din,
  wr_en => framebuffer_wr_en,
  rd_en => framebuffer_rd_en,
  dout => framebuffer_dout,
  full => framebuffer_full,
  empty => framebuffer_empty
);
--valid <= not framebuffer_empty;
--last <= framebuffer_dout(8) and not framebuffer_empty;
framebuffer_rd_en <= to_std_logic(ready_out and framebuffer_empty='0');
streamReg:entity streamlib.register_slice
generic map(STREAM_BITS => 8)
port map(
	clk => IO_clk,
  reset => reset0,
  stream_in => framebuffer_dout(7 downto 0),
  ready_out => ready_out,
  valid_in => to_boolean(not framebuffer_empty),
  last_in => to_boolean(framebuffer_dout(8)),
  stream => frame_stream,
  ready => to_boolean(ready),
  valid => valid,
  last => last
);
TEMAC:entity ethernetlib.v6_emac_v2_3
port map(
  global_reset_IO_clk => reset0, 
  IO_clk => IO_clk,
  s_axi_aclk => s_axi_aclk,
  refclk_bufg => iodelay_refclk,
  tx_axis_fifo_tdata => frame_stream,
  tx_axis_fifo_tvalid => to_std_logic(valid),
  tx_axis_fifo_tready => ready,
  tx_axis_fifo_tlast => to_std_logic(last),
  phy_resetn => phy_resetn,
  gmii_txd => gmii_txd,
  gmii_tx_en => gmii_tx_en,
  gmii_tx_er => gmii_tx_er,
  gmii_tx_clk => gmii_tx_clk,
  gmii_rxd => gmii_rxd,
  gmii_rx_dv => gmii_rx_dv,
  gmii_rx_er => gmii_rx_er,
  gmii_rx_clk => gmii_rx_clk,
  gmii_col => gmii_col,
  gmii_crs => gmii_crs,
  mii_tx_clk => mii_tx_clk,
  mdio => mdio,
  mdc => mdc,
  tx_statistics_s => tx_statistics_s,
  rx_statistics_s => rx_statistics_s,
  pause_req_s => pause_req_s,
  mac_speed => mac_speed,
  update_speed => update_speed,
  serial_command => serial_command,
  serial_response => serial_response,
  reset_error => reset_error,
  frame_error => frame_error,
  frame_errorn => frame_errorn
);
-------------------------------------------------------------------------------
-- Control unit--CPU, UARTs, general control registers
-------------------------------------------------------------------------------
globalRegisters:entity controllerlib.global_registers
generic map(
  VERSION => VERSION,
  TES_CHANNEL_BITS => TES_CHANNEL_BITS,
  ADC_CHANNELS => ADC_CHANNELS,
  MTU_BITS => MTU_BITS,
  EVENT_THRESHOLD_BITS => EVENT_THRESHOLD_BITS,
  EVENT_TIMEOUT_BITS => EVENT_TIMEOUT_BITS,
  TICK_PERIOD_BITS => TICK_PERIOD_BITS,
  TICK_COUNT_BITS => TICK_COUNT_BITS,
  MCA_ADDRESS_BITS => MCA_ADDRESS_BITS,
  MCA_VALUES => MCA_VALUES,
  MCA_VALUE_BITS => MCA_VALUE_BITS,
  IODELAY_CONTROL_BITS => IODELAY_CONTROL_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_EVENT_THRESHOLD => DEFAULT_EVENT_THRESHOLD,
  DEFAULT_EVENT_TIMEOUT => DEFAULT_EVENT_TIMEOUT,
  DEFAULT_TICK_PERIOD => DEFAULT_TICK_PERIOD
)
port map(
  clk => pipeline_clk,
  reset => reset1,
  data => global_register_write_data,
  address => global_register_address,
  data_out => global_register_read_data,
  write => write_global_register,
  FMC_internal_clk_en => FMC_internal_clk_en_int,
  FMC_VCO_power_en => FMC_VCO_power_en_int,
  MTU => MTU,
  event_threshold => event_threshold,
  event_timeout => event_timeout,
  tick_period => tick_period,
  adc_enables => adc_enables,
  eventstream_enables => eventstream_enables,
  mca_update_asap => mca_update_asap,
  mca_update_on_completion => mca_update_on_completion,
  mca_bin_n => mca_bin_n,
  mca_lowest_value => mca_lowest_value,
  mca_last_bin => mca_last_bin,
  mca_ticks => mca_ticks,
  mca_channel_sel => mca_channel_select,
  mca_value_sels => mca_value_select,
  iodelay_control => iodelay_control,
  iodelay_updated  => iodelay_updated

);
writeSync:entity teslib.sync_boolean_pulse
port map(
  in_clk => IO_clk,
  out_clk => pipeline_clk,
  pulse_in => write_global_register_IO_clk,
  pulse_out => write_global_register
);
FMC_present <= not FMC_present_n;
mainCPU:entity controllerlib.control_unit
generic map(TES_CHANNEL_BITS => TES_CHANNEL_BITS)
port map(
  clk => IO_clk,
  LEDs => open,
  global_reset => global_reset_IO_clk,
  reset0 => reset0,
  reset1 => reset1,
  reset2 => reset2,
  FMC_power_good => FMC_power_good,
  FMC_present => FMC_present,
  FMC_AD9510_status => FMC_AD9510_status,
  pipeline_mmcm_locked => pipeline_mmcm_locked,
  interrupt => FALSE,
  interrupt_ack => open,
  main_rx => main_rx,
  main_tx => main_tx,
  channel_rx => channel_rx,
  channel_tx => channel_tx,
  spi_clk => spi_clk,
  spi_ce_n => spi_ce_n,
  spi_miso => spi_miso,
  spi_mosi => spi_mosi,
  address => global_register_address,
  data_out => global_register_write_data,
  data_in => global_register_read_data,
  write => write_global_register_IO_clk
);
end architecture ML605;
