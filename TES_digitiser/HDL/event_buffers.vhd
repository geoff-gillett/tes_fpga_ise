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
entity event_buffers is
generic(
  CHANNEL_BITS:integer:=3;
  RELTIME_BITS:integer:=16;
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
  reltime:out unsigned(RELTIME_BITS-1 downto 0);
  started:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  ticked:out boolean;
  commited:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  dumped:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  valid:out boolean;
  --
  read_next:in boolean;
  full:out boolean
);
end entity event_buffers;
--------------------------------------------------------------------------------
-- The FSM architecture is probably easier to improve
--------------------------------------------------------------------------------
architecture RTL of event_buffers is
--
constant CHANNELS:integer:=2**CHANNEL_BITS;
constant TIMEFIFO_BITS:integer:=72;
-- timestamp bits used in time_fifo that tags the events
constant TIMETAG_BITS:integer:=minimum(TIMEFIFO_BITS-CHANNELS-1,TIMESTAMP_BITS);
type FSMstate is (IDLE,TIMEVALID);
signal buffer_state,buffer_nextstate:FSMstate;
signal reltime_state,reltime_nextstate:FSMstate;
--
signal timedif,last_eventtime,eventtime_int
			 :unsigned(TIMESTAMP_BITS-1 downto 0);
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
signal commited_int,dumped_int:std_logic_vector(CHANNELS-1 downto 0);
signal time_in,time_out,time_out_reg:std_logic_vector(TIMEFIFO_BITS-1 downto 0);
signal buffers_full,time_empty,time_rd_en,time_wr_en:std_logic;
signal time_full:std_logic;
signal ticked_int,valid_event,all_dumped,timedif_valid,valid_int:boolean;
--
begin
full <= buffers_full='1';
valid <= buffer_state=TIMEVALID;
started <= started_int;
eventtime_int(TIMETAG_BITS-1 downto 0) <= 
  unsigned(time_out(TIMETAG_BITS+CHANNELS downto CHANNELS+1));
eventtime_int(TIMESTAMP_BITS-1 downto TIMETAG_BITS+CHANNELS+1) 
	<= (others => '0');
eventtime <= eventtime_int;
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
ticked_int <= time_out(CHANNELS)='1';
ticked <= ticked_int;
time_rd_en <= to_std_logic(read_next);
commit_rd_en <= started_int when read_next else (others => '0');
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
  dumped_int(i) <= not commit_out(i) and not commit_empty(i);
  commited_int(i) <= commit_out(i) and not commit_empty(i);
end generate;
commited <= commited_int;
dumped <= dumped_int;
commit_wr_en <= to_std_logic(commit or dump);

--------------------------------------------------------------------------------
-- FIFO output registers
--------------------------------------------------------------------------------

FIFOreg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    commited <= (others => '0');
    dumped <= (others => '0');
    time_out_reg <= (others => '0');
  else
    
  end if;
end if;
end process FIFOreg;

--------------------------------------------------------------------------------
-- FSMs
--------------------------------------------------------------------------------
fsmNextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    buffer_state <= IDLE;
    reltime_state <= IDLE;
  else
    buffer_state <= buffer_nextstate;
    reltime_state <= reltime_nextstate;
  end if;
end if;
end process fsmNextstate;

started_int <= time_out(CHANNELS-1 downto 0) when time_empty='0' 
							 else (others => '0');
valid_event <= ticked_int or unaryOr(started_int and commited_int);
all_dumped <= started_int = dumped_int;
bufferFsmTransition:process(buffer_state,valid_event,read_next,reltime_state)
begin
buffer_nextstate <= buffer_state;
case buffer_state is 
when IDLE =>
  if valid_event and reltime_state=TIMEVALID then
    buffer_nextstate <= TIMEVALID;
  end if;
when TIMEVALID =>
	if read_next then
		buffer_nextstate <= IDLE;
	end if;
end case;
end process bufferFsmTransition;

reltimeFsmTransition:process(reltime_state,read_next,timedif_valid)
begin
reltime_nextstate <= reltime_state;
case reltime_state is 
when IDLE =>
	if timedif_valid then
		reltime_nextstate <= TIMEVALID;
	end if;
when TIMEVALID =>
	if read_next then
		reltime_nextstate <= IDLE;
	end if;
end case;
end process reltimeFsmTransition;
--
relativeTime:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			reltime <= (others => '1');
			last_eventtime <= (others => '0');
			timedif_valid <= FALSE;
		else
			if reltime_state=IDLE and time_empty='0' then
				timedif <= eventtime_int-last_eventtime;
				timedif_valid <= TRUE;
			end if;
			if timedif_valid then
				if unaryOR(timedif(TIMESTAMP_BITS-1 downto RELTIME_BITS)) then
					reltime <= (others => '1');
				else
					reltime <= timedif(RELTIME_BITS-1 downto 0);
				end if;
			end if;
			if read_next then
				timedif_valid <= FALSE;
				if (not all_dumped) or ticked_int then
					last_eventtime <= eventtime_int;
				end if;
			end if;
		end if;
	end if;
end process relativeTime;

end architecture RTL;