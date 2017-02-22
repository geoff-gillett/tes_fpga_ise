--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: axi_mca
-- Project Name: mca_lib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;

entity axi_mca_buffer is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:natural:=14;
  --width of counters and stream
  COUNTER_BITS:natural:=32;
  TOTAL_BITS:natural:=64
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0);
  
  swap:in boolean; -- true to count FALSE reads and clears
  mca_idle:out boolean; -- can swap
  
  bin:in unsigned(ADDRESS_BITS-1 downto 0);
  bin_valid:in boolean; -- increment this bin
  out_of_bounds:in boolean; --oob are not counted for most frequent or total
  
  -- probability distribution statistics
  most_frequent_bin:out unsigned(ADDRESS_BITS-1 downto 0);
  new_most_frequent_bin:out boolean; -- new bin, may have same count as previous
  most_frequent_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_most_frequent:out boolean; -- new count or new bin
  total_in_bounds:out unsigned(TOTAL_BITS-1 downto 0);
  --flag when switching to streaming, stats valid for period at the point
  swapped:out boolean; 
  
  stream:out std_logic_vector(COUNTER_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity axi_mca_buffer;

architecture blockram of axi_mca_buffer is
--
subtype MCA_count is unsigned(COUNTER_BITS-1 downto 0);
subtype MCA_bin is unsigned(ADDRESS_BITS-1 downto 0); -- RAM buffer address

signal count:MCA_count;
signal valid_int,last_int:boolean;

type fsmstate is (IDLE,COUNTING,INIT_STREAM,STREAMING,STREAM_END);
signal state,nextstate:fsmstate:=IDLE;
signal start,not_streaming:boolean;
signal last_bin_m1:MCA_bin;
signal bin_to_read:MCA_bin:=(others => '0');
signal last_incr_addr:boolean;
signal incr_addr:boolean;
signal last_bin_reg:unsigned(ADDRESS_BITS-1 downto 0);
signal readable:boolean;
signal last_clear:boolean;
signal clear:boolean;
signal buffer_idle:boolean;

begin
valid <= valid_int;
last <= last_int;  
swapped <= state=INIT_STREAM;
mca_idle <= state=IDLE;

lastBinReg: process (clk) is
begin
  if rising_edge(clk) then
    if state=IDLE and swap then
      last_bin_reg <= last_bin;
      last_bin_m1 <= last_bin-1;
    end if;
  end if;
end process lastBinReg;

mcaBuffer:entity work.mca_buffer3
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS => TOTAL_BITS
)
port map(
  clk => clk,
  reset => reset,
  mca_idle => buffer_idle,
  swap => swap,
  bin => bin,
  bin_valid => bin_valid,
  out_of_bounds => out_of_bounds,
  most_frequent_bin => most_frequent_bin,
  new_most_frequent_bin => new_most_frequent_bin,
  most_frequent_count => most_frequent_count,
  new_most_frequent => new_most_frequent,
  total_in_bounds => total_in_bounds,
  readable => readable,
  last_clear => last_clear,
  clear => clear,
  bin_to_read => bin_to_read,
  count => count
);

fsmNextstate:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= IDLE;
    else
      state <= nextstate;
    end if;
  end if;
end process fsmNextstate;

fsmTransition:process(
  swap,state,incr_addr,last_incr_addr,readable,last_int,ready,valid_int
)
begin
  nextstate <= state;
  clear <= FALSE;
  last_clear <= FALSE;
  case state is 
    when IDLE =>
      if swap then
        nextstate <= COUNTING;
      end if;
    when COUNTING => 
      if readable then
        nextstate <= INIT_STREAM;
      end if;
    when INIT_STREAM => 
      nextstate <= STREAMING;
    when STREAMING => -- not empty when in this state
      if last_incr_addr and incr_addr then 
        nextstate <= STREAM_END;
      end if;
      clear <= incr_addr;
    when STREAM_END => 
--      nextstate <= IDLE;
      clear <= TRUE;
      last_clear <= TRUE;
      if valid_int and ready and last_int then
        nextstate <= IDLE;
      end if;
  end case;
end process fsmTransition;

not_streaming <= state/=STREAMING; -- and state/=STREAM_END;
last_incr_addr <= bin_to_read=last_bin_m1;
start <= state=INIT_STREAM;

streamer:entity streamlib.ram_stream
generic map(
  WIDTH => COUNTER_BITS,
  LATENCY => 3
)
port map(
  clk => clk,
  reset => reset,
  empty => not_streaming,
  write => start,
  last_incr_addr => last_incr_addr,
  incr_addr => incr_addr,
  ram_data => std_logic_vector(count),
  stream => stream,
  valid => valid_int,
  ready => ready,
  last => last_int
);

streamAddress:process(clk)
begin
if rising_edge(clk) then
  if start then
    bin_to_read <= (others => '0');
  elsif incr_addr and not not_streaming then 
    bin_to_read <= bin_to_read+1;
  end if;
end if;
end process streamAddress;

end architecture blockram;
