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
entity mca_buffer3 is
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
end entity mca_buffer3;

architecture blockram of mca_buffer3 is
--
constant SAT_AT_DIN:boolean:=TRUE;
constant READ_LAT:natural:=2; --RAM read latency changes required when not 2
constant RAM_IN_REG:natural:=1; --if 1 register din, wr_addr and wr_en

constant PROC_LAT:natural:=2; -- clk required to calculate new count from dout
constant INC_BITS:integer:=ceilLog2(READ_LAT+1); 
constant DEPTH:natural:=READ_LAT+PROC_LAT;  -- pipeline depth
constant COL_DEPTH:natural:=DEPTH+RAM_IN_REG+1;
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


signal oldcount:unsigned(COUNTER_BITS downto 0);

-- pipelines 
type bin_pipeline is array (natural range <>) of MCA_bin;
type count_pipeline is array (natural range <>) 
                       of unsigned(COUNTER_BITS downto 0);
type inc_pipeline is array (natural range <>) of unsigned(INC_BITS-1 downto 0);


signal inc_pipe:inc_pipeline(1 to READ_LAT);
signal newcount,incremented_count:unsigned(COUNTER_BITS downto 0);
signal swap_pipe:boolean_vector(1 to COL_DEPTH);
signal bin_pipe:bin_pipeline(1 to COL_DEPTH);
signal valid_pipe:boolean_vector(1 to COL_DEPTH);
signal oob_pipe:boolean_vector(1 to COL_DEPTH);

type fsmstate is (IDLE,COUNTING,READING);
signal state,nextstate:fsmstate:=IDLE;
signal new_mf,new_mf_bin:boolean;
signal total_int:unsigned(TOTAL_BITS-1 downto 0);

signal double:boolean;
signal collision:boolean_vector(READ_LAT+1 to COL_DEPTH);
signal newcount_pipe:count_pipeline(READ_LAT+1 to COL_DEPTH);

signal din_mux:MCA_count;
signal wr_addr_mux:unsigned(ADDRESS_BITS-1 downto 0);
signal wr_en_mux:boolean;
signal active:boolean;

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
--wr_addr <= bin_pipe(DEPTH);
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

-- same bin twice in a row second is made invalid and first has increment 2
-- if READ_LAT > 2 this needs to change to include a increment of 3
double <= bin=bin_pipe(1) and bin_valid and valid_pipe(1) and active; 

incremented_count <= oldcount + inc_pipe(READ_LAT);

pipeline:process(clk)
begin
  if rising_edge(clk) then
    if state=IDLE then
      valid_pipe <= (others => FALSE); 
      oob_pipe <= (others => FALSE);
      collision <= (others => FALSE);
      active <= TRUE;
      inc_pipe <= (others => (others => '0'));
      --newcount <= (others => '-');
    else
      -- priority MUX for old count earlier collisions have priority
      oldcount <= '0' & dout;
      for i in COL_DEPTH downto READ_LAT+1 loop
        collision(i) 
          <= bin_pipe(1)=bin_pipe(i) and valid_pipe(1) and valid_pipe(i);
        if collision(i) then
          oldcount <= newcount_pipe(i);
        end if;
      end loop;
      
      if swap then
        active <= FALSE;
      end if;
      
      valid_pipe 
        <= (bin_valid and not double and active) & valid_pipe(1 to COL_DEPTH-1);
      inc_pipe <= to_unsigned(double & not double) & inc_pipe(1 to READ_LAT-1);
      oob_pipe <= out_of_bounds & oob_pipe(1 to COL_DEPTH-1);
      bin_pipe <= bin & bin_pipe(1 to COL_DEPTH-1);
      swap_pipe <= swap & swap_pipe(1 to COL_DEPTH-1);
      

      if not SAT_AT_DIN then --saturation MUX after adder
        if incremented_count(COUNTER_BITS)='1' then
          newcount_pipe <= ('0' & to_unsigned(2**COUNTER_BITS-1,COUNTER_BITS)) &
                           newcount_pipe(READ_LAT+1 to COL_DEPTH-1);
        else
          newcount_pipe 
            <= incremented_count & newcount_pipe(READ_LAT+1 to COL_DEPTH-1);
        end if;
      else
        newcount_pipe 
          <= incremented_count & newcount_pipe(READ_LAT+1 to COL_DEPTH-1);
--        newcount <= incremented_count;
      end if;
--      newcount_pipe <= newcount & newcount_pipe(READ_LAT+1 to COL_DEPTH-1);
    end if;
  end if;
end process pipeline;

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

fsmTransition:process(swap,state,swap_pipe,clear,last_clear)
begin
  nextstate <= state;
  case state is 
    when IDLE =>
      if swap then
        nextstate <= COUNTING;
      end if;
    when COUNTING => 
      if swap_pipe(COL_DEPTH) then
        nextstate <= READING;
      end if;
    when READING => 
      if last_clear and clear then 
        nextstate <= IDLE;
      end if;
  end case;
end process fsmTransition;

newcount <= newcount_pipe(READ_LAT+1);
ramInputMUX:process(newcount,state,bin_to_read,bin_pipe,clear,valid_pipe)
begin
  if SAT_AT_DIN then --saturation MUX at din
    if state=READING then
      din_mux <= (others => '0');
      wr_addr_mux <= bin_to_read;
      wr_en_mux <= clear;
    elsif newcount(COUNTER_BITS)='1' then
      din_mux <= (others => '1');
      wr_addr_mux <= bin_pipe(DEPTH);
      wr_en_mux <= valid_pipe(DEPTH);
    else
      din_mux <= newcount(COUNTER_BITS-1 downto 0);
      wr_addr_mux <= bin_pipe(DEPTH);
      wr_en_mux <= valid_pipe(DEPTH);
    end if;
  else
    if state=READING then
      din_mux <= (others => '0');
      wr_addr_mux <= bin_to_read;
      wr_en_mux <= clear;
    else
      din_mux <= newcount(COUNTER_BITS-1 downto 0);
      wr_addr_mux <= bin_pipe(DEPTH);
      wr_en_mux <= valid_pipe(DEPTH);
    end if;
  end if;
end process ramInputMUX;

ramInRegGen:if RAM_IN_REG=1 generate
  ramInReg:process(clk)
  begin
    if rising_edge(clk) then
      if state=IDLE then
        din <= (others => '-');
        wr_addr <= (others => '-');
        wr_en <= FALSE;
      else
        din <= din_mux;
        wr_en <= wr_en_mux;
        wr_addr <= wr_addr_mux;
      end if;
    end if;
  end process ramInReg;
end generate;

noRamInRegGen:if RAM_IN_REG=0 generate
  ramInReg:process(din_mux,state,wr_addr_mux,wr_en_mux)
  begin
    if state=IDLE then
      din <= (others => '-');
      wr_addr <= (others => '-');
      wr_en <= FALSE;
    else
      din <= din_mux;
      wr_en <= wr_en_mux;
      wr_addr <= wr_addr_mux;
    end if;
  end process ramInReg;
end generate;

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
    
    if valid_pipe(2) and not oob_pipe(2) then
      total_int <= total_int + inc_pipe(1);
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
