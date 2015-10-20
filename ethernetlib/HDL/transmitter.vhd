--------------------------------------------------------------------------------
--      Author: Geoff Gillett
--     Project: TES counter for ML605 development board with
--              FMC108 ADC mezzanine card
--        File: IO_control.vhd
-- Description: AXI arbiter/MUX for transmission of commands
--              and data to the host PC via the Virtex-6
--              embeded trimode ethernet MAC. 
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
--------------------------------------------------------------------------------
--!* The transmitter needs to:
--!* Arbitrate access to the outgoing Ethernet pipe. 
--!* Add Ethernet frame header 
--!* count frames
--!* count objects
--------------------------------------------------------------------------------
--FIXME comments need rework
entity transmitter is
generic(
  MCASTREAM_CHUNKS:integer:=2;
  EVENTSTREAM_CHUNKS:integer:=4;
  THRESHOLD_BITS:integer:=12;   --! requires FIFO change
  TIMEOUT_BITS:integer:=32;
  EVENT_LENGTH_BITS:integer:=SIZE_BITS;
  MTU_BITS:integer:=12;
  MIN_FRAME_LENGTH:integer:=46;
  ENDIANNESS:string:="LITTLE"
); 
port (
  --! TODO fix these comments
  clk:in std_logic;
  reset:in std_logic;
  LEDs:out std_logic_vector(7 downto 0);
  --!* outgoing stream interface  
  framechunk:out std_logic_vector(CHUNK_BITS-1 downto 0); 
  framechunk_valid:out boolean;
  framechunk_ready:in boolean;
  --!* sample_clk domain
  --!* Parameters
  --! Maximum Ethernet payload in Ethernet words (bytes)
  MTU:in unsigned(MTU_BITS-1 downto 0);
  threshold:in unsigned(THRESHOLD_BITS-1 downto 0);
  timeout:in unsigned(TIMEOUT_BITS-1 downto 0);
  --!* Event AXI-S interface (input from event FIFO)
  eventstream:in std_logic_vector(EVENTSTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
  eventstream_valid:in boolean;
  eventstream_ready:out boolean;
  --!* Parameters
  --! Prioritise events when threshold events are buffered
  --! Threshold range 12-4093 NOTE this is actually changed in the IO_clk domain 
  --event_words:in unsigned(bits(EVENT_BUS_WORDS-1)-1 downto 0);
  --!* Trace AXI-S interface 
  mcastream:in std_logic_vector(MCASTREAM_CHUNKS*CHUNK_BITS-1 downto 0);
  mcastream_valid:in boolean;
  mcastream_ready:out boolean
);
end transmitter;
--  
architecture RTL of transmitter is
--
component event_buffer
port(
  wr_clk:in std_logic;
  wr_rst:in std_logic;
  rd_clk:in std_logic;
  rd_rst:in std_logic;
  din:in std_logic_vector(71 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  prog_full_thresh:in std_logic_vector(11 downto 0);
  dout:out std_logic_vector(17 downto 0);
  full:out std_logic;
  empty:out std_logic;
  prog_full:out std_logic
);
end component;
component statistics_buffer
port (
  wr_clk:in std_logic;
  wr_rst:in std_logic;
  rd_clk:in std_logic;
  rd_rst:in std_logic;
  din:in std_logic_vector(35 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(17 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;
--------------------------------------------------------------------------------      
signal timeout_reg,timer:unsigned(TIMEOUT_BITS-1 downto 0);
signal eventbuffer_full,eventbuffer_wr_en,eventbuffer_rd_en:std_logic;
signal eventbuffer_empty,eventbuffer_prog_full:std_logic;
signal eventbuffer_valid:boolean;
signal mcabuffer_full,mcabuffer_wr_en,mcabuffer_rd_en,mcabuffer_empty:std_logic;
signal eventbuffer_dout:std_logic_vector(CHUNK_BITS-1 downto 0);
signal eventchunk,mcachunk:std_logic_vector(CHUNK_BITS-1 downto 0);
signal eventchunk_valid,eventchunk_ready,eventbuffer_ready:boolean;
signal mcabuffer_ready:boolean;
signal mcabuffer_dout:std_logic_vector(CHUNK_BITS-1 downto 0);
signal mcachunk_valid,mcachunk_ready,mcabuffer_valid:boolean;
signal timedout,eventframe_sent,flush_events:boolean;
--------------------------------------------------------------------------------      
-- Testing
--------------------------------------------------------------------------------      
signal framer_LEDs:std_logic_vector(7 downto 0);
begin
LEDs <= framer_LEDs;
eventbuffer_wr_en <= to_std_logic(eventbuffer_full='0' and eventstream_valid);
eventstream_ready <= eventbuffer_full='0';
eventBuffer:event_buffer
port map(
  wr_rst => reset,
  wr_clk => clk,
  rd_rst => reset,
  rd_clk => clk,
  din => eventstream,
  wr_en => eventbuffer_wr_en,
  rd_en => eventbuffer_rd_en,
  prog_full_thresh => to_std_logic(threshold),
  dout => eventbuffer_dout,
  full => eventbuffer_full,
  empty => eventbuffer_empty,
  prog_full => eventbuffer_prog_full
);
eventbuffer_rd_en <= to_std_logic(eventbuffer_empty='0' and eventbuffer_ready);
eventbuffer_valid 
	<= eventbuffer_empty='0' and eventbuffer_dout(CHUNK_KEEPBIT)='1';
eventchunkReg:entity streamlib.register_slice
generic map(STREAM_BITS => CHUNK_BITS)
port map(
	clk => clk,
  reset => reset,
  stream_in => eventbuffer_dout,
  ready_out => eventbuffer_ready,
  valid_in => eventbuffer_valid,
  last_in => FALSE,
  stream => eventchunk,
  ready => eventchunk_ready,
  valid => eventchunk_valid,
  last => open
);
mcabuffer_wr_en <= to_std_logic(mcabuffer_full='0' and mcastream_valid);
mcastream_ready <= mcabuffer_full='0';
mcaBuffer:statistics_buffer
port map(
  wr_clk => clk,
  wr_rst => reset,
  rd_clk => clk,
  rd_rst => reset,
  din => mcastream,
  wr_en => mcabuffer_wr_en,
  rd_en => mcabuffer_rd_en,
  dout => mcabuffer_dout,
  full => mcabuffer_full,
  empty => mcabuffer_empty
);
mcabuffer_rd_en <= to_std_logic(mcabuffer_empty='0' and mcabuffer_ready);
mcabuffer_valid <= mcabuffer_empty='0' and mcabuffer_dout(CHUNK_KEEPBIT)='1';
mcachunkReg:entity streamlib.register_slice
generic map(STREAM_BITS => CHUNK_BITS)
port map(
	clk => clk,
  reset => reset,
  stream_in => mcabuffer_dout,
  ready_out => mcabuffer_ready,
  valid_in => mcabuffer_valid,
  last_in => FALSE,
  stream => mcachunk,
  ready => mcachunk_ready,
  valid => mcachunk_valid,
  last => open
);

framer:entity work.ethernet_framer
generic map(
	MTU_BITS => MTU_BITS,
  EVENT_LENGTH_BITS => EVENT_LENGTH_BITS,
  MIN_FRAME_LENGTH => MIN_FRAME_LENGTH,
  ENDIANNESS => ENDIANNESS
)
port map(
	clk => clk,
  reset => reset,
  LEDs => framer_LEDs,
  MTU => MTU,
  flush_events => flush_events,
  eventbuffer_empty => to_boolean(eventbuffer_empty),
  eventframe_sent => eventframe_sent,
  eventchunk => eventchunk,
  eventchunk_valid => eventchunk_valid,
  eventchunk_ready => eventchunk_ready,
  mcachunk => mcachunk,
  mcachunk_valid => mcachunk_valid,
  mcachunk_ready => mcachunk_ready,
  framechunk => framechunk,
  framechunk_valid => framechunk_valid,
  framechunk_ready => framechunk_ready
);
timeoutCounter:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    timer <= timeout;
    timeout_reg <= timeout;
  else
    if eventframe_sent then
      timeout_reg <= timeout;
      timer <= timeout;
    elsif not timedout and timeout_reg/=0 then
      timer <= timer-1;
    end if;
  end if;
end if;
end process timeoutCounter;
timedout <= timer=0 and timeout_reg/=0;
flushEvents:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    flush_events <= FALSE;
  else
    if timedout or eventbuffer_prog_full='1' or eventbuffer_full='1' then
    	flush_events <= TRUE;
    elsif eventbuffer_empty='1' then	
    	flush_events <= FALSE;
    end if;
  end if;
end if;
end process flushEvents;
end RTL;
