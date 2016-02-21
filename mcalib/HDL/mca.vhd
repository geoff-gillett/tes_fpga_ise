--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: histogram_unit
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
--
--library teslib;
--use teslib.types.all;
--use teslib.functions.all;

--library streamlib;
--use streamlib.types.all;

--! double buffered MCA 
entity mca is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:integer:=14;
  --width of counters and stream
  COUNTER_BITS:integer:=32;
  TOTAL_BITS:integer:=64
);
port(
  clk:in std_logic;
  reset:in std_logic;
  ready:out boolean; -- ready after reset and buffer cleared.
  --
  bin:in unsigned(ADDRESS_BITS-1 downto 0);
  bin_valid:in boolean;
  overflow:in boolean;
  -- values are counted in the other buffer *after* swap_buffer is asserted
  swap_buffer:in boolean;
  -- flag indicating that the new buffer can be read and total is valid 
  readable:out boolean; -- 
  -- distribution data
  total:out unsigned(TOTAL_BITS-1 downto 0);
  most_frequent:out unsigned(ADDRESS_BITS-1 downto 0); -- bin with maximum count
  max_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_max:out boolean;
  --
  bin_to_read:in unsigned(ADDRESS_BITS-1 downto 0); --bin to read
  read_bin:in boolean; --read enable
  count:out unsigned(COUNTER_BITS-1 downto 0) --count from read_bin (LATENCY 3)
);
end entity mca;
architecture double_buffered_blockram of mca is
--------------------------------------------------------------------------------
-- MCA buffer signals
--------------------------------------------------------------------------------
subtype MCA_count is unsigned(COUNTER_BITS-1 downto 0);
subtype MCA_bin is unsigned(ADDRESS_BITS-1 downto 0); -- RAM buffer address
--
signal wr_buffer,rd_buffer:std_logic; 
signal write0,write1,ready0,new_max0,new_max1:boolean;
signal read_en0,read_en1,swap_buffer_int,swap_buffer_reg,valid_reg:boolean;
signal most_frequent0,most_frequent1:MCA_bin;
signal max_count0,max_count1,count0,count1:MCA_count;
signal readable0,readable1,readable_int:boolean;
signal total_reg,total_int:unsigned(TOTAL_BITS-1 downto 0);
--------------------------------------------------------------------------------
begin
ready <= ready0;
readable <= readable_int;
--total <= total_reg;
--------------------------------------------------------------------------------
-- MCA buffers 
--------------------------------------------------------------------------------
swap_buffer_int <= swap_buffer and ready0;
buffer0:entity work.mca_buffer
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS
)
port map(
  clk => clk,
  reset => reset,
  bin => bin,
  bin_valid => bin_valid,
  overflow => overflow,
  write => write0,
  ready => ready0,
  most_frequent => most_frequent0,
  max_count => max_count0,
  new_max => new_max0,
  readable => readable0,
  bin_to_read => bin_to_read,
  read_count => read_en0,
  count => count0
);
--
buffer1:entity work.mca_buffer
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS
)
port map(
  clk => clk,
  reset => reset,
  bin => bin,
  bin_valid => bin_valid,
  overflow => overflow,
  write => write1,
  ready => open,
  most_frequent => most_frequent1,
  max_count => max_count1,
  new_max => new_max1,
  readable => readable1,
  bin_to_read => bin_to_read,
  read_count => read_en1,
  count => count1
);
--
write1 <= wr_buffer='1';
write0 <= wr_buffer='0';
read_en0 <= read_bin and rd_buffer='0' and wr_buffer='1' and not readable_int;
read_en1 <= read_bin and rd_buffer='1' and wr_buffer='0' and not readable_int;
count <= count0 when rd_buffer='0' else count1;
--
bufferSelect:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    wr_buffer <= '0';
    rd_buffer <= '1';
    readable_int <= FALSE;
    total_int <= (others => '0');
    valid_reg <= FALSE;
  else
    readable_int <= FALSE;
    swap_buffer_reg <= swap_buffer_int;
    valid_reg <= bin_valid;
    if swap_buffer_int then
      wr_buffer <= not wr_buffer;
    end if;
    if swap_buffer then
      total_int <= (others => '0');
      if bin_valid and not overflow then
        total_reg <= total_int+1;
      else
        total_reg <= total_int;
      end if;
    else      
      if ready0 and bin_valid and not overflow then
        total_int <= total_int+1;
      end if;
    end if;
    if wr_buffer=rd_buffer then
      total <= total_reg;
    else
      total <= total_int;
    end if;
    if wr_buffer='0' and rd_buffer='0' and readable1 then
      rd_buffer <= '1';
      readable_int <= TRUE;
    end if;
    if wr_buffer='1' and rd_buffer='1' and readable0 then
      rd_buffer <= '0';
      readable_int <= TRUE;
    end if;
    if rd_buffer='0' then
      most_frequent <= most_frequent1;
      max_count <= max_count1;
      new_max <= new_max1;
    else
      most_frequent <= most_frequent0;
      max_count <= max_count0;
      new_max <= new_max0;
    end if;
  end if;
end if;
end process bufferSelect;
end double_buffered_blockram;
