--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/04/2014 
--
-- Design Name: TES_digitiser
-- Module Name: mca_unit
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;


--! Adds value mapping to bins to basic MCA (MCA.vhd).
--FIXME comments out of date
--FIXME the whole MCA hierarchy is pretty confusing the second time around
-- Note: need swap buffer on first can swap to initialise everything.
-- 

entity mapped_mca is
generic(
  ADDRESS_BITS:integer:=14;
  TOTAL_BITS:integer:=64;
  VALUE_BITS:integer:=28;
  COUNTER_BITS:integer:=32
);
port (
  clk:in std_logic;
  reset:in std_logic;  
  --
  value:in signed(VALUE_BITS-1 downto 0);
  value_valid:in boolean;
  --The write buffer is swapped and control signals bin_n last_bin and 
  --lowest_value are registered. The stream will become valid when it is not the
  --first assertion after reset. This initial swap_buffer after reset is 
  --required before any values are counted.
  swap_buffer:in boolean;
  -- if FALSE control signals are registered but buffer is not swapped.
  enabled:in boolean; 
  --swap_buffer is ignored when not mca_ready.
  --mca_ready when cleared after reset and the stream is read after swap_buffer.
  can_swap:out boolean;
  --!control signals mapping values to bins registered on swap_buffer
  bin_n:in unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0); --bin width = 2**bin_n
  --number of bins = last_bin+1, values that map to a bin >= last_bin 
  --are counted in last_bin
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0); 
  --values<=lowest_value are mapped to bin 0. 
  lowest_value:in signed(VALUE_BITS-1 downto 0);
  --total valid when stream valid;
  max_count:out unsigned(COUNTER_BITS-1 downto 0);
  most_frequent:out unsigned(ADDRESS_BITS-1 downto 0);
  total:out unsigned(TOTAL_BITS-1 downto 0);
  readable:out boolean;
  -- stream interface for count data 
  stream:out std_logic_vector(COUNTER_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity mapped_mca;
--
architecture RTL of mapped_mca is
--
signal bin,last_bin_reg,last_bin_temp:unsigned(ADDRESS_BITS-1 downto 0);
signal bin_n_reg,bin_n_temp:unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0);
signal bin_valid,swap_int,swapping,MCA_can_swap,can_swap_int,just_reset:boolean;
signal lowest_value_reg,offset_value:signed(VALUE_BITS-1 downto 0);
signal bin_value:unsigned(VALUE_BITS-1 downto 0);
signal swap_pipe,valid_pipe,enabled_pipe:boolean_vector(1 to 3);
signal overflowed,overflow,underflow,underflowed:boolean;
--signal total_int:unsigned(TOTAL_BITS-1 downto 0);
--
begin
--
can_swap <= can_swap_int;
controlRegisters:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    just_reset <= TRUE;
    swapping <= FALSE;
  else
    swap_pipe <= shift(swap_buffer and can_swap_int,swap_pipe);
    valid_pipe <= shift(value_valid,valid_pipe);
    enabled_pipe <= shift(enabled,enabled_pipe);
    swap_int <= FALSE;
    can_swap_int <= not (swapping or swap_buffer) and MCA_can_swap;
    if swap_buffer and can_swap_int then
      lowest_value_reg <= lowest_value;
      bin_n_temp <= bin_n;
      last_bin_temp <= last_bin;
      swapping <= TRUE;
    end if;
    if swap_pipe(1) then
      bin_n_reg <= bin_n_temp;
    end if;
    if swap_pipe(2) then
      last_bin_reg <= last_bin_temp;
      just_reset <= FALSE;
      swap_int <= not just_reset and enabled_pipe(2);
    end if;
    if swap_pipe(3) then
      swapping <= FALSE;
    end if;
  end if;
end if;
end process controlRegisters;
--------------------------------------------------------------------------------
-- processing pipeline
--------------------------------------------------------------------------------
--swap+1
underflowed <= to_0IfX(value) <= to_0IfX(lowest_value_reg);
valueOffset:process (clk)
constant MIN:signed(VALUE_BITS-1 downto 0):=(VALUE_BITS-1 => '1',others => '0');
begin
  if rising_edge(clk) then
    if underflowed then
      offset_value <= MIN;
    else
      offset_value <= value-lowest_value_reg+MIN;
    end if;
  end if;
end process valueOffset;
--swap+2
valueBin:process(clk)
variable ordered:unsigned(VALUE_BITS-1 downto 0); 
begin
if rising_edge(clk) then
  --suppress sim warnings from numeric_std
  ordered:=unsigned(not std_logic(offset_value(VALUE_BITS-1)) &
                   std_logic_vector(offset_value(VALUE_BITS-2 downto 0)));
  bin_value <= shift_right(ordered,to_integer(to_0IfX(bin_n_reg)));
end if;
end process valueBin;
--swap+3
overflowed <= to_0IfX(bin_value) >= resize(to_0IfX(last_bin_reg),VALUE_BITS);
underflow <= to_0IfX(bin_value)=0;
binOut:process(clk)
begin
if rising_edge(clk) then
  bin_valid <= valid_pipe(2) and enabled_pipe(2);
  overflow <= overflowed or underflow;
  if overflowed then
    bin <= last_bin_reg;
  else
    bin <= bin_value(ADDRESS_BITS-1 downto 0);
  end if;
end if;
end process binOut;
--
MCA:entity work.streaming_mca
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
  overflow => overflow,
  swap_buffer => swap_int,
  can_swap => MCA_can_swap,
  last_bin => last_bin_temp,
  total => total,
  max_count => max_count,
  most_frequent => most_frequent,
  readable => readable,
  stream => stream,
  valid => valid,
  last => last,
  ready => ready
);
end architecture RTL;
