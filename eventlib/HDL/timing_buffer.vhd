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
--library streamlib;
--use streamlib.types.all;
-- 
entity timing_buffer is
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
end entity timing_buffer;
--------------------------------------------------------------------------------
-- The FSM architecture is probably easier to improve
--------------------------------------------------------------------------------
architecture RTL of timing_buffer is
--
constant CHANNELS:integer:=2**CHANNEL_BITS;
constant TIMEFIFO_BITS:integer:=72;
-- timestamp bits used in time_fifo that tags the events
constant TIMETAG_BITS:integer:=minimum(TIMEFIFO_BITS-CHANNELS-1,TIMESTAMP_BITS);
type bufferstate is (IDLE,WAITEVENT,VALIDEVENT);
type timestate is (IDLE,VALIDTIME);
signal buffer_state,buffer_nextstate:bufferstate;
signal reltime_state,reltime_nextstate:timestate;
--
signal timedif,last_eventtime,eventtime_reg
			 :unsigned(TIMETAG_BITS-1 downto 0);
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
signal commit_out,commited_reg,started_reg
			 :std_logic_vector(CHANNELS-1 downto 0);
signal commit_wr_en,commit_rd_en:std_logic_vector(CHANNELS-1 downto 0);
signal commit_empty,commit_full:std_logic_vector(CHANNELS-1 downto 0);
signal commited_int,dumped_int,dumped_reg:std_logic_vector(CHANNELS-1 downto 0);
signal time_in,time_out,time_out_reg:std_logic_vector(TIMEFIFO_BITS-1 downto 0);
signal buffers_full,time_empty,time_rd_en,time_wr_en:std_logic;
signal time_full:std_logic;
signal ticked_reg,valid_event,all_dumped,timedif_valid,timefifo_valid:boolean;
signal no_starts,all_dumped_reg,ticked_int,no_starts_reg:boolean;
signal started_int:std_logic_vector(CHANNELS-1 downto 0);
--
begin
full <= buffers_full='1';
valid <= buffer_state=VALIDEVENT;
started <= started_reg;
eventtime <= resize(eventtime_reg,TIMESTAMP_BITS);
commited <= commited_reg;
dumped <= dumped_reg;
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
ticked <= ticked_reg;
--time_rd_en <= to_std_logic(read_next);
--FIXME register this
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
commit_wr_en <= to_std_logic(commit or dump);
--------------------------------------------------------------------------------
-- FIFO output registers
--------------------------------------------------------------------------------
--time_rd_en <= to_std_logic(not valid_int) and not time_empty;
started_int <= time_out(CHANNELS-1 downto 0);
no_starts <= unsigned(started_int)=0;
all_dumped <= (started_int and dumped_int) = started_int; --includes case with just a tick
ticked_int <= time_out(CHANNELS)='1';
									
FIFOreg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    commited_reg <= (others => '0');
    dumped_reg <= (others => '0');
    time_out_reg <= (others => '0');
    all_dumped_reg <= FALSE;
    eventtime_reg <= (others => '0');
  else
  	-- FIXME need reg?
    if time_rd_en='1' then
  		timefifo_valid <= FALSE;
  		commited_reg <= (others => '0');
  		dumped_reg <= (others => '0');
		else
  		timefifo_valid <= time_empty='0';
      commited_reg <= commited_int;
      dumped_reg <= dumped_int;
		end if;
		if time_empty='0' then
			all_dumped_reg <= all_dumped;
      started_reg <= started_int;
	    ticked_reg <= ticked_int;
	    no_starts_reg <= no_starts; 
      eventtime_reg(TIMETAG_BITS-1 downto 0) <= 
        unsigned(time_out(TIMETAG_BITS+CHANNELS downto CHANNELS+1));
      eventtime_reg(TIMESTAMP_BITS-1 downto TIMETAG_BITS+CHANNELS+1) 
        <= (others => '0');
    else
      started_reg <= (others => '-');
	    ticked_reg <= FALSE;
      eventtime_reg <= (others => '-');
      all_dumped_reg <= FALSE;
	    no_starts_reg <= FALSE; 
    end if;
  end if;
end if;
end process FIFOreg;

--FIXME clock this??
ReadFifos:process(buffer_state,all_dumped_reg,started_reg,ticked_reg,read_next)
begin
case buffer_state is 
when IDLE =>
  time_rd_en <= '0';
  commit_rd_en <= (others => '0');
when WAITEVENT =>
	if all_dumped_reg and not ticked_reg then
		time_rd_en <= '1';
		commit_rd_en <= started_reg;
	end if;
when VALIDEVENT =>
	if read_next then
		time_rd_en <= '1';
		commit_rd_en <= started_reg;
	end if;	
end case;
end process ReadFifos;

--------------------------------------------------------------------------------
-- FSMs 
--------------------------------------------------------------------------------
--all_dumped <= (started_int = dumped_int) and unsigned(started_int) /= 0;
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
--
valid_event <= (ticked_reg or unaryOr(started_reg and commited_reg)) 
							 and timefifo_valid;
--							 
bufferFsmTransition:process(buffer_state,reltime_state,all_dumped_reg,
														timefifo_valid,read_next,ticked_reg,commited_reg,
														started_reg)
begin
buffer_nextstate <= buffer_state;
case buffer_state is 
when IDLE =>
  if timefifo_valid and reltime_state=VALIDTIME then
    buffer_nextstate <= WAITEVENT;
  end if;
when WAITEVENT =>
	if ticked_reg or unsigned(started_reg and commited_reg) /= 0 then
		buffer_nextstate <= VALIDEVENT;	
	elsif all_dumped_reg then
		buffer_nextstate <= IDLE;
	end if;
when VALIDEVENT =>
	if read_next then
		buffer_nextstate <= IDLE;
	end if;
end case;
end process bufferFsmTransition;
--
reltimeFsmTransition:process(reltime_state,timedif_valid,time_rd_en)
begin
reltime_nextstate <= reltime_state;
case reltime_state is 
when IDLE =>
	if timedif_valid then
		reltime_nextstate <= VALIDTIME;
	end if;
when VALIDTIME =>
	if time_rd_en='1' then
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
			--timedif <= (others => '0');
			timedif_valid <= FALSE;
		else
			if reltime_state=IDLE and timefifo_valid then
				timedif <= eventtime_reg-last_eventtime;
				timedif_valid <= TRUE;
			end if;
			if timedif_valid then
				if unaryOR(timedif(TIMETAG_BITS-1 downto RELTIME_BITS)) then
					reltime <= (others => '1');
				else
					reltime <= timedif(RELTIME_BITS-1 downto 0);
				end if;
			end if;
			if time_rd_en='1' then
				timedif_valid <= FALSE;
				if (not all_dumped_reg) or ticked_reg then
					last_eventtime <= eventtime_reg;
				end if;
			end if;
		end if;
	end if;
end process relativeTime;
end architecture RTL;