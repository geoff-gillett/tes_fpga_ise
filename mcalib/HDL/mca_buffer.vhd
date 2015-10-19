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
--use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.types.all;
use streamlib.all;
--
--! Multi-channel analyser buffer
--! adder pipeline calculates increment to old value
entity mca_buffer is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:integer:=14;
  --width of counters and stream
  COUNTER_BITS:integer:=32
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  bin:in unsigned(ADDRESS_BITS-1 downto 0);
  bin_valid:in boolean; -- increment this bin
  overflow:in boolean;
  write:in boolean; -- true to count FALSE reads and clears
  ready:out boolean; -- ready after reset
  -- probability distribution maxima
  most_frequent:out unsigned(ADDRESS_BITS-1 downto 0);
  max_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_max:out boolean;
  -- read port
  -- read side is active (4 clks after write false) also indicates max_count and
  -- most frequent valid for entire buffer.
  readable:out boolean;
  -- 3 clk latency on reads
  bin_to_read:in unsigned(ADDRESS_BITS-1 downto 0);
  read_count:in boolean; -- read enable 3 clk latency
  count:out unsigned(COUNTER_BITS-1 downto 0)
);
end entity MCA_buffer;
architecture blockram of MCA_buffer is
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
--
signal wr_en,clear,clear_reg:boolean;
signal rd_addr,wr_addr,clear_addr:MCA_bin;
signal ram_out1,old_count,newcount,maxcount_int:MCA_count;
signal ram_out2,stream:MCA_count;
--------------------------------------------------------------------------------
-- Pipelines
--------------------------------------------------------------------------------
type bin_pipeline is array (natural range <>) of MCA_bin;
type count_pipeline is array (natural range <>) of MCA_count;
constant INC_BITS:integer:=2; 
signal inc:unsigned(INC_BITS-1 downto 0);
signal incremented_count:unsigned(COUNTER_BITS downto 0);
signal saturated:boolean;
-- pipelines handling read latency
signal newcount_pipe:count_pipeline(1 to 2);
signal rw_collision:boolean_vector(1 to 2);
-- count pipe handling and read/write address collision
signal collided:boolean;
signal write_pipe:boolean_vector(1 to 4);
signal bin_pipe:bin_pipeline(1 to 4);
signal valid_pipe:boolean_vector(1 to 4);
signal overflow_pipe:boolean_vector(1 to 5);
signal collision:boolean_vector(1 to 3);
begin
count <= stream;
max_count <= maxcount_int;
--------------------------------------------------------------------------------
-- Infer simple dual port RAM with registered outputs
--------------------------------------------------------------------------------
rd_addr <= bin_pipe(1);
MCAram:process(clk)
begin
if rising_edge(clk) then
  if wr_en then
    MCA(to_integer(to_0IfX(wr_addr))) <= newcount;
  end if;
 	ram_out2 <= MCA(to_integer(to_0IfX(wr_addr))); 
  ram_out1 <= MCA(to_integer(to_0IfX(rd_addr)));
end if;
end process MCAram;
--register ram outputs to meet timing
ramReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    old_count <= (others => '-');
    stream <= (others => '-');
  else
    old_count <= ram_out1;
    stream <= ram_out2;
  end if;
end if;
end process ramReg;
-- Handle R/W collisions in a shift register
addressCollision:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      rw_collision <= (others => FALSE);
    else
      rw_collision <= (to_0IfX(rd_addr)=to_0IfX(wr_addr) and wr_en) & 
                       rw_collision(1);
      newcount_pipe <= newcount & newcount_pipe(1);
    end if;
  end if;
end process addressCollision; 
-- pipeline collisions:is bin already in the pipeline?
collisions:process(clk)
variable col:boolean_vector(1 to 3);
begin
if rising_edge(clk) then
  if reset = '1' then
    collision <= (others => FALSE);
    col:=(others => FALSE);
    collided <= FALSE;
    valid_pipe <= (others => FALSE);
  else
    for i in 1 to 3 loop
     col(i):=to_0IfX(bin)=to_0IfX(bin_pipe(i)) and bin_valid and write and 
                          valid_pipe(i);
   end loop;
    valid_pipe <= (bin_valid and write and not unaryOR(col)) &
    							 valid_pipe(1 to 3);
    overflow_pipe <= overflow & overflow_pipe(1 to 4);
    collision <= col;
  end if;
end if;
end process collisions;
-- Check counter saturation
saturated <= incremented_count(COUNTER_BITS)='1' 
             or (not incremented_count(COUNTER_BITS-1 downto 0))=0;
-- Adder pipeline calculates the increment to the count while waiting for the 
-- old count to be read and processed.
adderPipeline:process(clk)
begin
if rising_edge(clk) then
  inc <= to_unsigned(1,INC_BITS)+unsigned(to_std_logic(collision(1 to 1)));
  if rw_collision(2) then
    incremented_count <= ('0' & newcount_pipe(2)) + inc + 
                         unsigned(to_std_logic(collision(2 to 2)));
  else
    incremented_count <= ('0' & old_count) + inc + 
                         unsigned(to_std_logic(collision(2 to 2)));
  end if;
  if clear or read_count then
    newcount <= (others => '0');
  elsif saturated then
    newcount <= (others => '1');
  else
    newcount <= incremented_count(COUNTER_BITS-1 downto 0)+
                unsigned(to_std_logic(collision(3 to 3)));
  end if;  
end if;
end process adderPipeline;
--
ramWrite:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    clear_reg <= FALSE;
  else
    write_pipe <= write & write_pipe(1 to 3);
    bin_pipe <= bin & bin_pipe(1 to 3);
    clear_reg <= clear;
    readable <= FALSE;
    if clear then
      wr_en <= TRUE;
      wr_addr <= clear_addr;
    elsif not write and not write_pipe(4) then
      wr_en <= read_count;
      wr_addr <= bin_to_read;
      readable <= TRUE;
    else 
      wr_en <= valid_pipe(4);
      wr_addr <= bin_pipe(4);
    end if;
  end if;
end if;
end process ramWrite;
--------------------------------------------------------------------------------
-- Track the bin with the highest count
--------------------------------------------------------------------------------
mostFrequent:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    maxcount_int <= (others => '0');
    most_frequent <= (others => '0');
  else
    if (not write_pipe(4) and write) or clear_reg then
      maxcount_int <= (others => '0');
      most_frequent <= (others => '0'); 
    else
      if (newcount >= maxcount_int) and wr_en and write_pipe(4) 
          and not overflow_pipe(5) then
        maxcount_int <= newcount;
        most_frequent <= wr_addr;
        new_max <= TRUE;
      else
        new_max <= FALSE;
      end if;
    end if;
  end if;
end if;
end process mostFrequent;
--------------------------------------------------------------------------------
-- Clear the MCA on reset
--------------------------------------------------------------------------------
ready <= not clear;
clearMCA:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    clear_addr <= (others => '0');
    clear <= TRUE;
  else
    if clear_addr=to_unsigned(2**ADDRESS_BITS-1,ADDRESS_BITS) then
      clear <= FALSE;
      clear_addr <= (others => '0');
    elsif clear then
      clear_addr <= clear_addr+1;
    end if;
  end if;
end if;
end process clearMCA;
end architecture blockram;
