--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Creation Date:20/10/2015 
--
-- Repository Name: tes_fpga_ise
-- Module Name: ethernet_test
-- Project Name: tests
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--
-- For testing the frame generation on the FPGA side and capture speed on the 
-- PC side.
-- Generates ticks with 100ms period and events as fast as possible.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library ethernetlib;
--
library streamlib;
use streamlib.types.all;
use streamlib.functions.all;
--
library main;

entity ethernet_test is
generic(
	TICK_PERIOD:integer:=25000000;
	STREAM_BITS:integer:=8
);
port (
  clk_p:in std_logic; --to MMCM
  clk_n:in std_logic;
  global_reset:in std_logic;
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
end entity ethernet_test;

architecture RTL of ethernet_test is
	
--IP cores
component test_MMCM
port
(
	-- Clock in ports
  board_clk_P:in std_logic;
  board_clk_N:in std_logic;
  -- Clock out ports
  IO_clk:out std_logic;
  IOdelay_refclk:out std_logic;
  saxi_aclk:out std_logic;
  pipeline_clk:out std_logic;
  -- Status and control signals
  RESET:in std_logic;
  LOCKED:out std_logic
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

constant CHANNEL_BITS:integer:=3;
  --
constant MCASTREAM_CHUNKS:integer:=2;
constant EVENTSTREAM_CHUNKS:integer:=4;
constant EVENT_THRESHOLD_BITS:integer:=12;  
constant EVENT_TIMEOUT_BITS:integer:=32;
constant EVENT_LENGTH_BITS:integer:=SIZE_BITS;
constant MTU_BITS:integer:=12;
constant MIN_FRAME_LENGTH:integer:=32;
constant ENDIANNESS:string:="LITTLE";
  --
constant TICK_PERIOD_BITS:integer:=32;
constant MINIMUM_TICK_PERIOD:integer:=2**14;
constant TIMESTAMP_BITS:integer:=64;
  --
constant DEFAULT_MTU:integer:=750;

--------------------------------------------------------------------------------
-- Clock and reset signals
--------------------------------------------------------------------------------
signal reset_IO_clk,IO_clk,pipeline_clk:std_logic;
signal reset0,reset1,reset2,CPU_reset,MMCM_locked:std_logic;
signal AD9510_clk_stopped,pipeline_mmcm_locked:std_logic;
signal s_axi_aclk,iodelay_refclk:std_logic;
attribute keep:string;

attribute keep of AD9510_clk_stopped:signal is "true";
attribute keep of pipeline_mmcm_locked:signal is "true";
attribute keep of reset0:signal is "true";
attribute keep of reset1:signal is "true";
attribute keep of reset2:signal is "true";
attribute keep of CPU_reset:signal is "true";

signal eventstream:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal eventstream_valid:boolean;
signal eventstream_last:boolean;
signal eventstream_ready:boolean;
signal framebuffer_din : std_logic_vector(17 downto 0);
signal framebuffer_wr_en : std_logic;
signal framebuffer_rd_en : std_logic;
signal framebuffer_dout : std_logic_vector(8 downto 0);
signal framebuffer_full : std_logic;
signal framebuffer_empty : std_logic;
signal framechunk : std_logic_vector(CHUNK_BITS-1 downto 0);
signal framechunk_valid : boolean;
signal framechunk_ready : boolean;
signal reset_pipeline_clk : std_logic;
signal ready_out : boolean;
signal frame_stream : std_logic_vector(STREAM_BITS-1 downto 0);
signal ready : std_logic;
signal valid : boolean;
signal last : boolean;

begin
--------------------------------------------------------------------------------
-- Clock and reset tree
--------------------------------------------------------------------------------

testClkGen:test_MMCM
port map(
  -- Clock in ports
  board_clk_P => clk_p,
  board_clk_N => clk_p,
  -- Clock out ports
  IO_clk => IO_clk,
  IOdelay_refclk => IOdelay_refclk,
  saxi_aclk => s_axi_aclk,
  pipeline_clk => pipeline_clk,
  -- Status and control signals
  RESET  => global_reset,
  LOCKED => mmcm_locked
);

--
sresetIOclk:entity teslib.reset_sync
port map(
  clk => IO_clk,
  enable => mmcm_locked,
  reset_in => global_reset,
  reset_out => reset_IO_clk
);

sresetPipelineclk:entity teslib.reset_sync
port map(
  clk => pipeline_clk,
  enable => mmcm_locked,
  reset_in => global_reset,
  reset_out => reset_pipeline_clk
);

teststream:entity work.test_eventstream
	generic map(
		TICK_PERIOD => TICK_PERIOD,
		BUS_CHUNKS  => EVENTSTREAM_CHUNKS
	)
	port map(
		clk               => pipeline_clk,
		reset             => reset_pipeline_clk,
		eventstream       => eventstream,
		eventstream_valid => eventstream_valid,
		eventstream_ready => eventstream_ready,
		eventstream_last  => eventstream_last
	);

transmitter:entity ethernetlib.transmitter
generic map(
  MCASTREAM_CHUNKS   => MCASTREAM_CHUNKS,
  EVENTSTREAM_CHUNKS => EVENTSTREAM_CHUNKS,
  THRESHOLD_BITS     => EVENT_THRESHOLD_BITS,
  TIMEOUT_BITS       => EVENT_TIMEOUT_BITS,
  EVENT_LENGTH_BITS  => EVENT_LENGTH_BITS,
  MTU_BITS           => MTU_BITS,
  MIN_FRAME_LENGTH   => MIN_FRAME_LENGTH,
  ENDIANNESS         => ENDIANNESS
)
port map(
  clk               => pipeline_clk,
  reset             => reset_pipeline_clk,
  LEDs              => open,
  framechunk        => framechunk,
  framechunk_valid  => framechunk_valid,
  framechunk_ready  => framechunk_ready,
  MTU               => to_unsigned(DEFAULT_MTU,MTU_BITS),
  threshold         => to_unsigned(3000,MTU_BITS),
  timeout           => to_unsigned(25000000,EVENT_TIMEOUT_BITS),
  eventstream       => eventstream,
  eventstream_valid => eventstream_valid,
  eventstream_ready => eventstream_ready,
  mcastream         => (others=>'0'),
  mcastream_valid   => FALSE,
  mcastream_ready   => FALSE
);

framebuffer_din <= '0' & framechunk(15 downto 8) 
											 & framechunk(CHUNK_LASTBIT) 
											 & framechunk(7 downto 0);
framebuffer_wr_en <= to_std_logic(framechunk_valid and framebuffer_full='0');
framechunk_ready <= framebuffer_full='0';
-- downsize to bytes and cross from sample_clk to IO_clk domain
frameBuffer:frame_buffer
port map(
  wr_rst => reset_pipeline_clk,
  wr_clk => pipeline_clk,
  rd_rst => reset_IO_clk,
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

end architecture RTL;
