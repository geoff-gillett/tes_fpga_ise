--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/04/2014 
--
-- Design Name: TES_digitiser
-- Module Name: axi_mca
-- Project Name: mcalib
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

-- Adds value mapping to bins to double_buffered_axi_mca.
entity axi_mca is
generic(
  ADDRESS_BITS:integer:=14;
  TOTAL_BITS:integer:=64;
  VALUE_BITS:integer:=32;
  COUNTER_BITS:integer:=32
);
port (
  clk:in std_logic;
  reset:in std_logic;  
  
  value:in signed(VALUE_BITS-1 downto 0);
  value_valid:in boolean;
  -- When swap and can swap are TRUE the write buffer is swapped and control 
  -- signals bin_n last_bin and lowest_value are registered.
  swap:in boolean;
  -- if enabled is FALSE and swap is TRUE counting stops and current buffer is 
  -- streamed then the MCA goes idle.
  enabled:in boolean; 
  can_swap:out boolean;
  
  --control signals mapping values to bins registered on swap
  --These signal must remain constant for 4 clocks after swap
  bin_n:in unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0); --bin width = 2**bin_n
  --number of bins = last_bin+1, values that map to a bin >= last_bin 
  --are counted in last_bin
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0); 
  --values<lowest_value are mapped to bin 0. 
  lowest_value:in signed(VALUE_BITS-1 downto 0);
  
  -- probability distribution statistics
  total_in_bounds:out unsigned(TOTAL_BITS-1 downto 0);
  most_frequent_bin:out unsigned(ADDRESS_BITS-1 downto 0);
  new_most_frequent_bin:out boolean;
  most_frequent_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_most_frequent:out boolean;
  swapped:out boolean; --strobe indicating when to capture stats after swap
  
  --AXI stream interface
  stream:out std_logic_vector(COUNTER_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity axi_mca;

architecture RTL of axi_mca is
  
signal bin,last_bin_reg:unsigned(ADDRESS_BITS-1 downto 0);
signal last_valid_bin:signed(VALUE_BITS-1 downto 0);
signal bin_n_reg:unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0);
signal bin_valid,swap_int,swapping,MCA_can_swap,can_swap_int:boolean;
signal lowest_value_reg,offset_value:signed(VALUE_BITS-1 downto 0);
signal bin_value:signed(VALUE_BITS-1 downto 0);
signal stop:boolean;

constant DEPTH:natural:=3;
signal swap_pipe,valid_pipe,enabled_pipe:boolean_vector(1 to DEPTH);
signal overflow,out_of_bounds,underflow:boolean;--,underflowed:boolean;

-- debug
constant DEBUG:string:="FALSE";
attribute mark_debug:string;
attribute mark_debug of bin:signal is DEBUG;
attribute mark_debug of bin_valid:signal is DEBUG;
--attribute mark_debug of bin_n_reg:signal is DEBUG;

begin
	
can_swap <= can_swap_int;
controlRegisters:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    swapping <= FALSE;
    swap_int <= FALSE;
  else
    swap_pipe <= (swap and can_swap_int) & swap_pipe(1 to DEPTH-1);
    valid_pipe <= value_valid & valid_pipe(1 to DEPTH-1);
    enabled_pipe <= enabled & enabled_pipe(1 to DEPTH-1);
    swap_int <= FALSE;
    stop <= FALSE;
    can_swap_int <= not (swapping or swap) and MCA_can_swap; --reg ??
    if swap and can_swap_int then
      lowest_value_reg <= lowest_value;
      swapping <= TRUE;
    end if;
    if swap_pipe(DEPTH-2) then
      bin_n_reg <= bin_n;
    end if;
    if swap_pipe(DEPTH-1) then
      last_bin_reg <= last_bin;
      last_valid_bin <= resize(signed('0' & last_bin),VALUE_BITS)-1;
      swap_int <= enabled_pipe(DEPTH-1);
      stop <= not enabled_pipe(DEPTH-1);
    end if;
    if swap_pipe(DEPTH) then
      swapping <= FALSE;
    end if;
  end if; 
end if;
end process controlRegisters;

valueBin:process(clk)
begin
if rising_edge(clk) then
  offset_value <= value-lowest_value;--swap+1
  bin_value <= shift_right(offset_value,to_integer(to_0ifx(bin_n_reg)));--swap+2
end if;
end process valueBin;

overflow <= bin_value >= last_valid_bin;
underflow <= bin_value(VALUE_BITS-1)='1';

--swap+3
binOut:process(clk)
begin
if rising_edge(clk) then
  out_of_bounds <= overflow or underflow;
  if overflow then
    bin <= last_bin_reg;
  elsif underflow then
    bin <= (others => '0');
  else
    bin <= unsigned(bin_value(ADDRESS_BITS-1 downto 0))+1;
  end if;
end if;
end process binOut;
bin_valid <= valid_pipe(3);

MCA:entity work.double_buffered_axi_mca
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
  last_bin => last_bin,
  swap => swap_int,
  stop => stop,
  can_swap => MCA_can_swap,
  total_in_bounds => total_in_bounds,
  most_frequent_bin => most_frequent_bin,
  new_most_frequent_bin => new_most_frequent_bin,
  most_frequent_count => most_frequent_count,
  new_most_frequent => new_most_frequent,
  swapped => swapped,
  stream => stream,
  valid => valid,
  last => last,
  ready => ready
);

end architecture RTL;
