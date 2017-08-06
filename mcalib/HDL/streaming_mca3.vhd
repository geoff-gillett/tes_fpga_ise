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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

--! Streaming double buffered Multi-channel analyser
entity streaming_mca3 is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:integer:=14;
  --width of counters and stream
  --STREAM_CHUNKS:integer:=2;
  COUNTER_BITS:integer:=32;
  TOTAL_BITS:integer:=64
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  bin:in unsigned(ADDRESS_BITS-1 downto 0);
  bin_valid:in boolean;
  out_of_bounds:in boolean;
  -- values are counted in the other buffer *after* swap_buffer is asserted
  swap_buffer:in boolean;
  can_swap:out boolean;
  -- last bin to put on stream 
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0);
  --
  total:out unsigned(TOTAL_BITS-1 downto 0);
  most_frequent:out unsigned(ADDRESS_BITS-1 downto 0);
  max_count:out unsigned(COUNTER_BITS-1 downto 0);
  readable:out boolean;
  --
  stream:out std_logic_vector(COUNTER_BITS-1 downto 0);
  valid:out boolean;
  last:out boolean;
  ready:in boolean
);
end entity streaming_mca3;

architecture double_buffered_blockram of streaming_mca3 is
--------------------------------------------------------------------------------
--constant STREAM_BITS:integer:=STREAM_CHUNKS*CHUNK_DATABITS;
--------------------------------------------------------------------------------
subtype MCA_count is unsigned(COUNTER_BITS-1 downto 0);
subtype MCA_bin is unsigned(ADDRESS_BITS-1 downto 0); -- RAM buffer address
type FSMstate is (IDLE,STREAMING,CLEAR);
signal state,nextstate:FSMstate;
signal bin_to_read,last_bin_reg,last_bin_reg_m1:MCA_bin;
signal count:MCA_Count;
signal data:std_logic_vector(COUNTER_BITS-1 downto 0);
signal mca_intialised,last_MCA_addr,swap_buffer_int:boolean;
signal clearing,readable_int:boolean;
signal read_count,can_swap_int:boolean;
signal last_read,read_bin,empty:boolean;
signal start:boolean;
--------------------------------------------------------------------------------

constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of bin_to_read:signal is DEBUG;
attribute mark_debug of read_bin:signal is DEBUG;
attribute mark_debug of count:signal is DEBUG;

begin
  
--valid <= mca_valid;
--last <= mca_last;
can_swap <= can_swap_int; 
readable <= readable_int;
swap_buffer_int <= can_swap_int and mca_intialised and swap_buffer;

core:entity work.mca
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS => TOTAL_BITS
)
port map(
  clk => clk,
  reset => reset,
  bin => bin,
  bin_valid => bin_valid,
  out_of_bounds => out_of_bounds,
  swap_buffer => swap_buffer_int,
  ready => mca_intialised,
  readable => readable_int,
  total => total,
  most_frequent => most_frequent,
  max_count => max_count,
  new_max => open,
  bin_to_read => bin_to_read,
  read_bin => read_bin,
  count => count
);
data <= std_logic_vector(count);
--last_read <= last_addr and state=STREAMING;

--read_bin_valid <= state=STREAMING;
empty <= not (state=STREAMING);
start <= state=IDLE and readable_int;
fwft:entity streamlib.serialiser
generic map(
  WIDTH => COUNTER_BITS
)
port map(
  clk => clk,
  reset => reset,
  empty => empty,
  write => start,
  last_address => last_read,
  read => read_count,
  ram_data => data,
  stream => stream,
  valid => valid,
  ready => ready,
  last => last
);
--------------------------------------------------------------------------------
-- control registers
--------------------------------------------------------------------------------
bufferSelect:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    last_bin_reg <= last_bin;
    last_bin_reg_m1 <= last_bin-1;
    can_swap_int <= FALSE; 
    clearing <= TRUE;
  else
    if clearing and mca_intialised then
      can_swap_int <= TRUE;
      clearing <= FALSE;
    end if;
    if swap_buffer_int then
      last_bin_reg <= last_bin;
      last_bin_reg_m1 <= last_bin-1;
      can_swap_int <= FALSE;
    elsif last_MCA_addr and read_bin then
      can_swap_int <= TRUE;
    end if;
  end if;
end if;
end process bufferSelect;

--------------------------------------------------------------------------------
-- FSM for stream output
--------------------------------------------------------------------------------
fsmNextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    state <= IDLE;    
  else
    state <= nextstate;
  end if;
end if;
end process fsmNextstate;

fsmTransition:process(state,readable_int,last_MCA_addr,last_read,read_count)
begin
  nextstate <= state;
  case state is 
    when IDLE =>
      if readable_int then
        nextstate <= STREAMING;
      end if;
    when STREAMING =>
      if last_MCA_addr and read_count then
        nextstate <= IDLE;
      elsif last_read and read_count then
        nextstate <= CLEAR;
      end if;
    when CLEAR =>
      if last_MCA_addr and read_count then --last bin in MCA
        nextstate <= IDLE;
      end if;
  end case;
end process fsmTransition;

--------------------------------------------------------------------------------
-- Stream address
--------------------------------------------------------------------------------
--last_addr <= bin_to_read=to_0IfX(last_bin_reg);  --last bin to put on stream
last_MCA_addr <= bin_to_read=to_unsigned(2**ADDRESS_BITS-2,ADDRESS_BITS);
read_bin <= (state=STREAMING and read_count) or state=CLEAR;
last_read <= bin_to_read=to_0ifX(last_bin_reg_m1);
streamAddress:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    bin_to_read <= (others => '0');
  else  
    if start then
      bin_to_read <= (others => '0');
    elsif read_bin then
    	bin_to_read <= bin_to_read+1;
    end if;
  end if;
end if;
end process streamAddress;
end architecture double_buffered_blockram;
