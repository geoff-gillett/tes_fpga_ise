--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: MCA_buffer
-- Project Name: MCA
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;
--
--library teslib;
--use teslib.types.all;
--use teslib.functions.all;
--
library streamlib;
--use streaming.types.all;
--use streamlib.all;
--
--! Multi-channel analyser buffer
--! adder pipeline calculates increment to old value
entity axi_mca is
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
  --
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0);
  
  swap:in boolean; -- true to count FALSE reads and clears
  mca_idle:out boolean; -- can swap
  --
  bin:in unsigned(ADDRESS_BITS-1 downto 0);
  bin_valid:in boolean; -- increment this bin
  out_of_bounds:in boolean; --oob are not counted for most frequent or total
--  ready:out boolean; -- ready after reset
  -- probability distribution maxima
  most_frequent_bin:out unsigned(ADDRESS_BITS-1 downto 0);
  new_most_frequent_bin:out boolean; -- new bin, may have same count as previous
  most_frequent_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_most_frequent:out boolean; -- new count or new bin
  total_in_bounds:out unsigned(TOTAL_BITS-1 downto 0);
  total_valid:out boolean;
  
  -- read port
  -- read side is active (4 clks after write false) also indicates max_count and
  -- most frequent valid for entire buffer.
  
  stream:out std_logic_vector(COUNTER_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity axi_mca;

architecture blockram of axi_mca is
--
--------------------------------------------------------------------------------
-- MCA ram signals
--------------------------------------------------------------------------------
subtype MCA_count is unsigned(COUNTER_BITS-1 downto 0);
subtype MCA_bin is unsigned(ADDRESS_BITS-1 downto 0); -- RAM buffer address
--RAM buffer definitions

type MCA_ram is array (0 to 2**ADDRESS_BITS-1) of MCA_count;
signal MCA:MCA_ram:=(others => (others => '0'));
attribute ram_style:string;
attribute ram_style of MCA:signal is "block";

signal wr_en:boolean;
signal rd_addr,wr_addr,mf_int:MCA_bin;
signal ram_out1,dout,din,mf_count_int:MCA_count;
signal ram_out2,count:MCA_count;
signal valid_int,last_int:boolean;

--------------------------------------------------------------------------------
-- Pipelines
--------------------------------------------------------------------------------
type bin_pipeline is array (natural range <>) of MCA_bin;
type count_pipeline is array (natural range <>) 
                       of unsigned(COUNTER_BITS downto 0);
constant INC_BITS:integer:=2; 
type inc_pipe is array (natural range <>) of unsigned(INC_BITS-1 downto 0);

constant LATENCY:natural:=2;
constant DEPTH:natural:=LATENCY+1;  -- pipeline depth

signal inc:inc_pipe(1 to LATENCY);
signal incremented_count:unsigned(COUNTER_BITS downto 0);

signal saturated:boolean;
-- pipelines handling read latency
signal newcount_pipe:count_pipeline(1 to LATENCY);
signal at2_pipe:boolean_vector(1 to LATENCY);
signal swap_pipe:boolean_vector(1 to DEPTH);
signal bin_pipe:bin_pipeline(1 to DEPTH);
signal valid_pipe:boolean_vector(1 to DEPTH);
signal oob_pipe:boolean_vector(1 to DEPTH);
signal bin_at_pipe:boolean_vector(1 to DEPTH);

type fsmstate is (IDLE,COUNTING,INIT1,STREAMING,STREAM_END);
signal state,nextstate:fsmstate:=IDLE;
signal rw_collision_pipe:boolean_vector(1 to LATENCY);
signal start,not_streaming:boolean;
signal last_bin_m1:MCA_bin;
signal bin_to_read:MCA_bin;
signal last_read:boolean;
signal next_addr:boolean;
signal last_bin_reg:unsigned(ADDRESS_BITS-1 downto 0);
signal new_mf,new_mf_bin:boolean;
signal total_int:unsigned(TOTAL_BITS-1 downto 0);

begin
mca_idle <= state=IDLE;
valid <= valid_int;
last <= last_int;  
total_valid <= state=INIT1;
total_in_bounds <= total_int;
most_frequent_bin <= mf_int;
most_frequent_count <= mf_count_int;
new_most_frequent <= new_mf;
new_most_frequent_bin <= new_mf_bin;
--------------------------------------------------------------------------------
-- Infer simple dual port RAM with registered outputs read latency=2
--------------------------------------------------------------------------------
rd_addr <= bin;
MCAram:process(clk)
begin
if rising_edge(clk) then
  if wr_en then
    MCA(to_integer(wr_addr)) <= din;
  end if;
  ram_out1 <= MCA(to_integer(rd_addr));
 	ram_out2 <= MCA(to_integer(wr_addr)); 
  count <= ram_out2;
  dout <= ram_out1;
end if;
end process MCAram;

comparitors:process(bin,bin_pipe,bin_valid,valid_pipe)
begin
  for i in 1 to DEPTH loop
    bin_at_pipe(i) <= bin=bin_pipe(i) and bin_valid and valid_pipe(i);
  end loop;
end process comparitors;

main:process(clk)
begin
  if rising_edge(clk) then
--    if reset='1' then
    if state=IDLE then
      at2_pipe <= (others => FALSE);
      valid_pipe <= (others => FALSE);
      rw_collision_pipe <= (others => FALSE);
      oob_pipe <= (others => FALSE);
      if swap then
        last_bin_m1 <= last_bin-1;
        last_bin_reg <= last_bin;
      end if;
    else
      
      -- pipelines
      bin_pipe <= bin & bin_pipe(1 to DEPTH-1);
      oob_pipe <= out_of_bounds & oob_pipe(1 to DEPTH-1);
      swap_pipe <= swap & swap_pipe(1 to DEPTH-1);
      
      at2_pipe <= bin_at_pipe(2) & at2_pipe(1);
      rw_collision_pipe  <= bin_at_pipe(3) & rw_collision_pipe(1);
      newcount_pipe <= incremented_count & newcount_pipe(1 to LATENCY-1);
      valid_pipe <= (bin_valid and state=COUNTING and not bin_at_pipe(1)) &
    							  valid_pipe(1 to DEPTH-1);
      
      inc(1)(0) <= to_std_logic(not bin_at_pipe(1));
      inc(1)(1) <= to_std_logic(bin_at_pipe(1));
      inc(2) <= inc(1);
      
      if rw_collision_pipe(LATENCY) then
        incremented_count <= newcount_pipe(LATENCY) + inc(LATENCY);
      elsif at2_pipe(LATENCY) then
        incremented_count <= newcount_pipe(1) + inc(1);
      else
        incremented_count <= ('0' & dout) + inc(1);
      end if;
    end if;
  end if;
end process main;

saturated <= incremented_count(COUNTER_BITS)='1';

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
  swap,state,swap_pipe,bin_pipe,saturated,valid_pipe,incremented_count,
  bin_to_read,next_addr,last_read
)
begin
  nextstate <= state;
  wr_en <= FALSE;
  din <= (others => '0');
  wr_addr <= (others => '0');
  
  case state is 
    when IDLE =>
      if swap then
        nextstate <= COUNTING;
      end if;
    when COUNTING => 
      if swap_pipe(DEPTH) then
        nextstate <= INIT1;
        --start <= TRUE;
      end if;
      wr_en <= valid_pipe(DEPTH);
      wr_addr <= bin_pipe(DEPTH);
      if saturated then
        din <= (others => '1');
      else
        din <= incremented_count(COUNTER_BITS-1 downto 0);
      end if;
    when INIT1 => 
      nextstate <= STREAMING;
    when STREAMING => -- not empty when in this state
      if last_read and next_addr then 
        nextstate <= STREAM_END;
      end if;
      din <= (others => '0');
      wr_addr <= bin_to_read;
      wr_en <= next_addr;
    when STREAM_END => 
      nextstate <= IDLE;
      din <= (others => '0');
      wr_addr <= bin_to_read;
      wr_en <= TRUE;
  end case;
end process fsmTransition;

not_streaming <= state/=STREAMING; -- and state/=STREAM_END;
last_read <= bin_to_read=last_bin_m1;
start <= state=INIT1;

streamer:entity streamlib.ram_stream
generic map(
  WIDTH => COUNTER_BITS,
  LATENCY => 2
)
port map(
  clk => clk,
  reset => reset,
  empty => not_streaming,
  write => start,
  last_incr_addr => last_read,
  incr_addr => next_addr,
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
  elsif next_addr and not not_streaming then 
    bin_to_read <= bin_to_read+1;
  end if;
end if;
end process streamAddress;

--------------------------------------------------------------------------------
-- statistics tracking 
--------------------------------------------------------------------------------
mostFrequent:process(clk)
begin
if rising_edge(clk) then
  if state/=COUNTING then
    mf_count_int <= (others => '0');
    mf_int <= (others => '0'); 
    new_mf <= FALSE;
    new_mf_bin <= FALSE;
    total_int <= (others => '0');
  else
    new_mf_bin <= FALSE;
    new_mf <= FALSE;
    if valid_pipe(3) and not oob_pipe(3) then
      total_int <= total_int+inc(2);
    end if;
      
    if (din >= mf_count_int) and wr_en and not oob_pipe(DEPTH) then 
      mf_count_int <= din;
      mf_int <= wr_addr;
      new_mf <= (din > mf_count_int) or mf_int/=wr_addr;
      new_mf_bin <=  mf_int/=wr_addr;
    end if;
  end if;
end if;
end process mostFrequent;

end architecture blockram;
