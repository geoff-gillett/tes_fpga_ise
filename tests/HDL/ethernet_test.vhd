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
  CHANNEL_BITS:integer:=3;
  --
  MCASTREAM_CHUNKS:integer:=2;
  EVENTSTREAM_CHUNKS:integer:=4;
  EVENT_THRESHOLD_BITS:integer:=12;  
  EVENT_TIMEOUT_BITS:integer:=32;
  EVENT_LENGTH_BITS:integer:=SIZE_BITS;
  MTU_BITS:integer:=12;
  MIN_FRAME_LENGTH:integer:=32;
  ENDIANNESS:string:="LITTLE";
  --
  TICK_PERIOD_BITS:integer:=32;
  MINIMUM_TICK_PERIOD:integer:=2**14;
  TIMESTAMP_BITS:integer:=64;
  --
  DEFAULT_MTU:integer:=750
);
port (
  clk:in std_logic;
  rst:in std_logic
);
end entity ethernet_test;

architecture RTL of ethernet_test is

signal event_counter:unsigned(25 downto 0);
signal framer_free:unsigned(9 downto 0);
signal framer_full:boolean;
signal tickstream:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal tickstream_valid:boolean;
signal tickstream_last:boolean;
signal tickstream_ready:boolean;

signal event1:std_logic_vector(63 downto 0);
signal event2:std_logic_vector(63 downto 0);
signal eventbus1:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal eventbus2:std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);

begin

ticker:entity main.tick_unit
generic map(
  CHANNEL_BITS        => CHANNEL_BITS,
  STREAM_CHUNKS       => EVENTSTREAM_CHUNKS,
  SIZE_BITS           => SIZE_BITS,
  TICK_BITS           => TICK_PERIOD_BITS,
  MINIMUM_TICK_PERIOD => MINIMUM_TICK_PERIOD,
  TIMESTAMP_BITS      => TIMESTAMP_BITS,
  ENDIANNESS          => ENDIANNESS
)
port map(
  clk         => clk,
  reset       => reset,
  tick        => tick,
  timestamp   => open,
  tick_period => to_unsigned(25000000,TICK_PERIOD_BITS),
  events_lost => open,
  dirty       => open,
  tickstream  => tickstream,
  valid       => tickstream_valid,
  last        => tickstream_last,
  ready       => tickstream_ready
);



framer:entity streamlib.framer
generic map(
  BUS_CHUNKS   => EVENTSTREAM_CHUNKS,
  ADDRESS_BITS => 9
)
port map(
  clk      => clk,
  reset    => reset,
  data     => data,
  address  => address,
  lasts    => lasts,
  keeps    => keeps,
  chunk_we => chunk_we,
  wr_valid => wr_valid,
  length   => length,
  commit   => commit,
  free     => framer_free,
  stream   => stream,
  valid    => valid,
  ready    => ready
);


event1 <= "001100010" & std_logic_vector(event_counter(13 downto 0)) & 
						 SetEndianness(event_counter(13 downto 0) & 
						 							 event_counter(25 downto 0), ENDIANNESS
						 );
event2 <= SetEndianness(event_counter(13 downto 0), ENDIANNESS) & 
						SetEndianness(event_counter(13 downto 0), ENDIANNESS) &
						"00000000000000000000000000000000";

eventbus1 <= "01" & event1(63 downto 48) & "01" & event1(47 downto 32) &
						 "01" & event1(32 downto 16) & "01" & event1(15 downto 0);
						 
eventbus2 <= "01" & event2(63 downto 48) & "01" & event2(47 downto 32) &
						 "01" & event2(32 downto 16) & "11" & event2(15 downto 0);

						 
-- this process fills the framer with events and ticks
framer_full <= framer_free /= 0;
eventGen:process(clk)
begin
if rising_edge(clk) then
	if not framer_full then
		if not tickstream_valid then
			
		end if;
	end if;
end if;
end process eventGen;


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
  clk               => clk,
  reset             => reset,
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

TEMAC:entity ethernetlib.v6_emac_v2_3
port map(
  global_reset_IO_clk => global_reset_IO_clk,
  IO_clk              => IO_clk,
  s_axi_aclk          => s_axi_aclk,
  refclk_bufg         => refclk_bufg,
  tx_axis_fifo_tdata  => tx_axis_fifo_tdata,
  tx_axis_fifo_tvalid => tx_axis_fifo_tvalid,
  tx_axis_fifo_tready => tx_axis_fifo_tready,
  tx_axis_fifo_tlast  => tx_axis_fifo_tlast,
  phy_resetn          => phy_resetn,
  gmii_txd            => gmii_txd,
  gmii_tx_en          => gmii_tx_en,
  gmii_tx_er          => gmii_tx_er,
  gmii_tx_clk         => gmii_tx_clk,
  gmii_rxd            => gmii_rxd,
  gmii_rx_dv          => gmii_rx_dv,
  gmii_rx_er          => gmii_rx_er,
  gmii_rx_clk         => gmii_rx_clk,
  gmii_col            => gmii_col,
  gmii_crs            => gmii_crs,
  mii_tx_clk          => mii_tx_clk,
  mdio                => mdio,
  mdc                 => mdc,
  tx_statistics_s     => tx_statistics_s,
  rx_statistics_s     => rx_statistics_s,
  pause_req_s         => pause_req_s,
  mac_speed           => mac_speed,
  update_speed        => update_speed,
  serial_command      => serial_command,
  serial_response     => serial_response,
  reset_error         => reset_error,
  frame_error         => frame_error,
  frame_errorn        => frame_errorn
);


end architecture RTL;
