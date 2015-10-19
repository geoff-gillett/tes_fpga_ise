--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:17/05/2014 
--
-- Design Name: TES_digitiser
-- Module Name: eventstream_arbiter
-- Project Name: TES_digitiser
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
entity event_arbiter_buffers is
generic(
  CHANNEL_BITS:integer:=3;
  TIMESTAMP_BITS:integer:=64
);
port (
  clk:in std_logic;
  reset:in std_logic;
  start:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  commit:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  dump:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  tick:in boolean;
  timestamp:in unsigned(TIMESTAMP_BITS-1 downto 0);
  --
  eventtime:out unsigned(TIMESTAMP_BITS-1 downto 0);
  started:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  ticked:out boolean;
  time_valid:out boolean;
  --
  commited:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  dumped:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  --
  next_time:in boolean;
  full:out boolean
);
end entity event_arbiter_buffers;
--------------------------------------------------------------------------------
-- The FSM architecture is probably easier to improve
--------------------------------------------------------------------------------
architecture RTL of event_arbiter_buffers is
--
constant CHANNELS:integer:=2**CHANNEL_BITS;
constant TIMEFIFO_BITS:integer:=72;
-- timestamp bits used in time_fifo that tags the events
constant TIMETAG_BITS:integer:=minimum(TIMEFIFO_BITS-CHANNELS-1,TIMESTAMP_BITS);
--
component time_fifo
port (
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(TIMEFIFO_BITS-1 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(TIMEFIFO_BITS-1 downto 0);
  almost_full:out std_logic;
  full:out std_logic;
  empty:out std_logic
);
end component;
-- 
component commit_dump_fifo
port (
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(0 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(0 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;
--
signal commit_out,started_int:std_logic_vector(CHANNELS-1 downto 0);
signal commit_wr_en,commit_rd_en:std_logic_vector(CHANNELS-1 downto 0);
signal commit_empty,commit_full:std_logic_vector(CHANNELS-1 downto 0);
signal time_in,time_out:std_logic_vector(TIMEFIFO_BITS-1 downto 0);
signal buffers_full,time_empty,time_rd_en,time_wr_en:std_logic;
signal time_full:std_logic;
--
begin
full <= buffers_full='1';
time_valid <= time_empty='0';
started <= started_int;
eventtime(TIMETAG_BITS-1 downto 0) <= 
  unsigned(time_out(TIMETAG_BITS+CHANNELS downto CHANNELS+1));
eventtime(TIMESTAMP_BITS-1 downto TIMETAG_BITS+CHANNELS+1) <= (others => '0');
--------------------------------------------------------------------------------
-- Event buffering while measurement is performed 
--------------------------------------------------------------------------------
-- Time FIFO -- GLOBALTIME_BITS:TICK_BIT:START_BITS one start bit each channel
-- store time and starts until committed or dumped
--------------------------------------------------------------------------------
timeFIFO:component time_fifo
port map(
  clk => clk,
  srst => reset,
  din => time_in,
  wr_en => time_wr_en,
  rd_en => time_rd_en,
  dout => time_out,
  full => time_full, 
  almost_full => buffers_full, -- tell measurement unit to block starts
  empty => time_empty
);
--
time_wr_en <= to_std_logic(unaryOR(start) or tick);
time_in(TIMEFIFO_BITS-1 downto TIMETAG_BITS+CHANNELS+1) <= (others => '0');
time_in(TIMETAG_BITS+CHANNELS downto CHANNELS+1) 
  <= std_logic_vector(timestamp(TIMETAG_BITS-1 downto 0));
time_in(CHANNELS) <= to_std_logic(tick);
time_in(CHANNELS-1 downto 0) <= to_std_logic(start); 
started_int <= time_out(CHANNELS-1 downto 0) when time_empty='0' 
               else (others => '0');
ticked <= time_out(CHANNELS)='1';
time_rd_en <= to_std_logic(next_time);
commit_rd_en <= started_int when next_time else (others => '0');
--------------------------------------------------------------------------------
-- queue commits or dumps to match with starts
--------------------------------------------------------------------------------
commitDump:for i in 0 to CHANNELS-1 generate
begin
  commitDumpFIFO:component commit_dump_fifo
  port map(
    clk => clk,
    srst => reset,
    din => to_std_logic(commit(i downto i)),
    wr_en => commit_wr_en(i),
    rd_en => commit_rd_en(i),
    dout => commit_out(i downto i),
    full => commit_full(i),
    empty => commit_empty(i)
  );
  dumped(i) <= not commit_out(i) and not commit_empty(i);
  commited(i) <= commit_out(i) and not commit_empty(i);
end generate;
commit_wr_en <= to_std_logic(commit or dump);
end architecture RTL;