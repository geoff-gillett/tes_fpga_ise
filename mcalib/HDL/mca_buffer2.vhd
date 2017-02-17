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
entity mca_buffer2 is
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
  --last_bin:in unsigned(ADDRESS_BITS-1 downto 0);
  
  mca_idle:out boolean; -- can swap
  swap:in boolean; -- true to count FALSE reads and clears
  --
  bin:in unsigned(ADDRESS_BITS-1 downto 0);
  bin_valid:in boolean; -- increment this bin
  out_of_bounds:in boolean; --oob are not counted for most frequent or total
  
  -- probability distribution maxima
  most_frequent_bin:out unsigned(ADDRESS_BITS-1 downto 0);
  new_most_frequent_bin:out boolean; -- new bin, may have same count as previous
  most_frequent_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_most_frequent:out boolean; -- new count or new bin
  total_in_bounds:out unsigned(TOTAL_BITS-1 downto 0);
  
  -- bin_to_read interface active when readable
  readable:out boolean; --total valid when true
  last_clear:in boolean; -- clear and last_clear moves mca to IDLE state
  clear:in boolean; --clears data at bin_to_read port is in read first mode
  -- read latency = 2 
  bin_to_read:in unsigned(ADDRESS_BITS-1 downto 0); 
  count:out unsigned(COUNTER_BITS-1 downto 0)
);
end entity mca_buffer2;

architecture blockram of mca_buffer2 is
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
signal ram_out2:MCA_count;

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

type fsmstate is (IDLE,COUNTING,READING);
signal state,nextstate:fsmstate:=IDLE;
signal rw_collision_pipe:boolean_vector(1 to LATENCY);
signal not_reading:boolean;
--signal bin_to_read:MCA_bin;
signal new_mf,new_mf_bin:boolean;
signal total_int:unsigned(TOTAL_BITS-1 downto 0);

begin
mca_idle <= state=IDLE;
readable <= state=READING;
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
  bin_to_read,clear,last_clear
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
        nextstate <= READING;
      end if;
      wr_en <= valid_pipe(DEPTH);
      wr_addr <= bin_pipe(DEPTH);
      if saturated then
        din <= (others => '1');
      else
        din <= incremented_count(COUNTER_BITS-1 downto 0);
      end if;
    when READING => 
      if last_clear and clear then 
        nextstate <= IDLE;
      end if;
      din <= (others => '0');
      wr_addr <= bin_to_read;
      wr_en <= clear;
  end case;
end process fsmTransition;

not_reading <= state/=READING; -- and state/=STREAM_END;
--------------------------------------------------------------------------------
-- statistics tracking 
--------------------------------------------------------------------------------
mostFrequent:process(clk)
begin
if rising_edge(clk) then
  if state=IDLE then
    mf_count_int <= (others => '0');
    mf_int <= (others => '0'); 
    new_mf <= FALSE;
    new_mf_bin <= FALSE;
    total_int <= (others => '0');
  elsif state=COUNTING then
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
