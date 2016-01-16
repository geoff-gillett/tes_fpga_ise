--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:08/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: event_framer
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
use streamlib.functions.all;
--use streamlib.all;
--
entity event_framer is
generic(
  CHANNEL:integer:=1;
  MAX_PEAKS:integer:=4;
  ADDRESS_BITS:integer:=9;
  BUS_CHUNKS:integer:=4;
  ENDIANNESS:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  sample:in sample_t;
  area_threshold:in area_t;
  --! buffer overflow signal
  enabled:in boolean;
	-- framer overflow happens if framer goes full during any part of measurement
  event_lost:out boolean; 
  mux_full:in boolean;
  --! measurement in
  start:in boolean; -- from measurement
  peak:in boolean;
  pulse_area:in area_t;
  pulse_length:in time_t;
  pulse_valid:in boolean; --measurement stop
  --! to mux
  start_mux:out boolean; --to mux (start filtered for mux overflow) needed?
  dump:out boolean;
  commit:out boolean;
  --! stream
  eventstream:out eventbus_t;
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity event_framer;
--
architecture packed of event_framer is
--
constant DATA_BITS:integer:=BUS_CHUNKS*CHUNK_DATABITS;
constant PEAK_COUNT_BITS:integer:=ceilLog2(MAX_PEAKS);
--
signal relative_time,rel_time:time_t;
signal data,headerdata:std_logic_vector(DATA_BITS-1 downto 0);
signal frame_addr,length:unsigned(ADDRESS_BITS-1 downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
signal chunk_wr_en,lasts,keeps:std_logic_vector(EVENTBUS_CHUNKS-1 downto 0);
signal commit_int,commit_reg,dump_int,local_rollover,started:boolean;
signal peak_data:std_logic_vector(2*CHUNK_DATABITS-1 downto 0);
signal peak_count:unsigned(PEAK_COUNT_BITS downto 0); 
signal peak_num:unsigned(PEAK_COUNT_BITS-1 downto 0); 
signal peaks_lost,peak_reg,peaks_full,overflow:boolean;
signal eventstream_int:std_logic_vector(EVENTBUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal valid_int,ready_int,last_int:boolean;
--
begin
dump <= dump_int;
commit <= commit_int;
event_lost <= overflow;
--------------------------------------------------------------------------------
-- overflow handling
--------------------------------------------------------------------------------
--startFilter:process(clk)
--begin
--if rising_edge(clk) then
--  if reset = '1' then
--    started <= FALSE;
--  else
--    pulse_start <= FALSE;
--    if start and not mux_overflow then
--      started <= TRUE;
--      pulse_start <= TRUE;
--    end if;
--    if pulse_valid then
--      started <= FALSE;
--    end if;
--  end if;
--end if;
--end process startFilter;
--------------------------------------------------------------------------------
-- Buffers event frames and prepares stream 
--------------------------------------------------------------------------------
framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => EVENTBUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => frame_addr,
  lasts => lasts, 
  keeps => keeps,
  chunk_we => to_boolean(chunk_wr_en),
  free => free,
  length => length,
  commit => commit_int,
  stream => eventstream_int,
  valid => valid_int,
  ready => ready_int
);
last_int <= busLast(eventstream_int,EVENTBUS_CHUNKS);
streamreg:entity streamlib.register_slice
generic map(STREAM_BITS => EVENTBUS_CHUNKS*CHUNK_BITS)
port map(
	clk => clk,
  reset => reset,
  stream_in => eventstream_int,
  valid_in => valid_int,
  last_in => last_int,
  ready_out => ready_int,
  stream => eventstream,
  valid => valid,
  last => last,
  ready => ready
);
--------------------------------------------------------------------------------
-- Record the event in the Frame Memory
--------------------------------------------------------------------------------
measure:process(clk)
variable chunk_len:unsigned(SIZE_BITS-1 downto 0);
variable word_len:unsigned(SIZE_BITS-2 downto 0);
variable addr:unsigned(SIZE_BITS-2 downto 0);
variable lower5bytes:std_logic_vector(5*8-1 downto 0);
begin
if rising_edge(clk) then
  if reset = '1' then
    data <= (others => '-');
    chunk_wr_en <= (others => '0');
    dump_int <= FALSE;
    commit_int <= FALSE;
    commit_reg <= FALSE;
    overflow <= FALSE;
  else
    dump_int <= FALSE;
    commit_int <= commit_reg;
    commit_reg <= FALSE;
    start_mux <= FALSE;
    overflow <= FALSE;
    if start then
      if mux_full then
        overflow <= TRUE;
      elsif enabled then
        overflow <= FALSE;  
        started <= TRUE;
        start_mux <= TRUE;
      end if;
    end if;
    if pulse_valid and started then --rewrite last peak with last bit set
      started <= FALSE;
      --len is in chunks length is in buswords
      word_len:=resize(peak_count(PEAK_COUNT_BITS downto 1)
                      +peak_count(0 downto 0),SIZE_BITS-1)+1; 
      length <= resize(word_len,ADDRESS_BITS);
      chunk_len:=to_unsigned(4,SIZE_BITS)+(peak_count & '0');
      
      -- TODO: fix this comment
      --header is streamed as a single 8-byte value with endianity set by
      --the generic LITTLE_ENDIAN in event_mux.vhd
      -- Field    lengths
      -- size     5
      -- chan     3
      -- flags    2 (T=type 1-Pulse 0-Tick) (P=Peaks lost)
      -- reltime  14 This field is added by event_mux.vhd
      -- length   14
      -- area     26
      -- LITTLE Endian reverses order of lower 5 bytes only (length and area)
      --   6     |      5 |        |        |   3    |   2   |   1   |      0
      --32109|876|54|32109876543210|98765432109876|54321098765432109876543210
      --size |chn|TP|rel time      | length       | area
      --
      -- TODO: improve alignment
      -- size 16 bits
      -- rel time 16 bits
      -- flags 16 bits, includes channel
      -- length 16
      --
      -- area 32 bits
      -- peak 32 bits
      -- more peaks -- packed to 64 bit boundary
      
      
      lower5bytes:=to_std_logic(pulse_length) & to_std_logic(pulse_area);
      headerdata <= to_std_logic(chunk_len & to_unsigned(CHANNEL,3)) 
                    & "1" & to_std_logic(peaks_lost) 
                    & to_std_logic(to_unsigned(0,TIME_BITS)) --rel_time added by mux
                    & setEndianness(lower5bytes,ENDIANNESS);
      --FIXME move the space check to actual write point     
      if free < word_len or overflow then 
        dump_int <= TRUE;
        overflow <= TRUE;
      else
        if pulse_area < area_threshold then
          dump_int <= TRUE;
        else
          commit_reg <= TRUE;
        end if;
      end if;
      --data <= peak_data & peak_data;
      --frame_addr <= resize(peak_num(PEAK_COUNT_BITS-1 downto 1)+1,ADDRESS_BITS);
      addr:=resize(peak_num(PEAK_COUNT_BITS-1 downto 1),SIZE_BITS-1);
      frame_addr <= resize(addr+1,ADDRESS_BITS);
      if peak_num(0)='0' then
        data <= peak_data & std_logic_vector(to_unsigned(0,2*CHUNK_DATABITS));
        chunk_wr_en <= "1111";
        keeps <= "1100";
        lasts <= "0100";
      else
        data <= std_logic_vector(to_unsigned(0,2*CHUNK_DATABITS)) & peak_data;
        chunk_wr_en <= "0011";
        keeps <= "0011";
        lasts <= "0001";
      end if;
    elsif commit_reg then
      frame_addr <= (others => '0');
      data <= headerdata;  
      chunk_wr_en <= "1111";
      keeps <= "1111";
      if peak_count=0 then
        lasts <= "0001";
      else
        lasts <= "0000";
      end if;
    elsif peak_reg then
      --data <= peak_data & peak_data;
      lasts <= "0000";
      addr:=resize(peak_num(PEAK_COUNT_BITS-1 downto 1),SIZE_BITS-1);
      frame_addr <= resize(addr+1,ADDRESS_BITS);
      if addr < free then --(PEAK_COUNT_BITS-2 downto 0) then
        if peak_num(0) = '0' then
          data <= peak_data & std_logic_vector(to_unsigned(0,2*CHUNK_DATABITS));
          chunk_wr_en <= "1111";
          keeps <= "1100";
        else
          data <= std_logic_vector(to_unsigned(0,2*CHUNK_DATABITS)) & peak_data;
          chunk_wr_en <= "0011";
          keeps <= "0011";
        end if;
      else
        overflow <= TRUE;
      end if;
    else
      chunk_wr_en <= "0000";
      keeps <= "0000";
      lasts <= "0000";
    end if;
  end if;
end if;
end process measure;
--------------------------------------------------------------------------------
-- Record peak value and time
--------------------------------------------------------------------------------
peaks_full <= peak_count=to_unsigned(MAX_PEAKS, PEAK_COUNT_BITS+1);
recordPeak:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    peak_count <= (others => '0');
  else
    peak_reg <= FALSE;
    if start then
      peaks_lost <= FALSE;
      peak_num <= (others => '0');
      if peak then
        peak_data <= std_logic_vector(to_unsigned(0,CHUNK_DATABITS)) &
                     SetEndianness(resize(sample,CHUNK_DATABITS),ENDIANNESS);
        peak_count <= to_unsigned(1,PEAK_COUNT_BITS+1);
      else 
        peak_count <= (others => '0');
      end if;
    else
      if peak then
        if not peaks_full then
          peak_num <= peak_count(PEAK_COUNT_BITS-1 downto 0);
          peak_count <= peak_count+1;
          peak_reg <= TRUE;
        else
          peaks_lost <= TRUE;
        end if;   
        peak_data <= SetEndianness(resize(rel_time,CHUNK_DATABITS),ENDIANNESS) &
                     SetEndianness(resize(sample,CHUNK_DATABITS),ENDIANNESS);
      end if;
    end if;
  end if;
end if;
end process recordPeak;
--------------------------------------------------------------------------------
-- Time
--------------------------------------------------------------------------------
rel_time <= (others => '0') when start else relative_time;
relativeTime:entity teslib.clock
generic map(TIME_BITS => TIME_BITS)
port map(
  clk => clk,
  reset => to_std_logic(start),
  te => TRUE,
  initialise_to_1 => TRUE,
  rolling_over => local_rollover,
  time_stamp => relative_time
);
end architecture packed;
