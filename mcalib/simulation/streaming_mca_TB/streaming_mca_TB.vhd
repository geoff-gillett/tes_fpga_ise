--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:3Feb.,2017
--
-- Design Name: TES_digitiser
-- Module Name: streaming_mca_TB
-- Project Name:  mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity streaming_mca_TB is
generic(
  ADDRESS_BITS:natural:=4;
  COUNTER_BITS:natural:=32;
  TOTAL_BITS:natural:=64
);
end entity streaming_mca_TB;

architecture testbench of streaming_mca_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;
signal bin:unsigned(ADDRESS_BITS-1 downto 0);
signal bin_valid:boolean;
signal out_of_bounds:boolean;
signal swap_buffer:boolean;
signal can_swap:boolean;
signal last_bin:unsigned(ADDRESS_BITS-1 downto 0);
signal total:unsigned(TOTAL_BITS-1 downto 0);
signal most_frequent:unsigned(ADDRESS_BITS-1 downto 0);
signal max_count:unsigned(COUNTER_BITS-1 downto 0);
signal readable:boolean;
signal stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal valid:boolean;
signal last:boolean;
signal ready:boolean;
signal end_series:boolean;

--simulation signals
signal count1,count2:unsigned(ADDRESS_BITS-1 downto 0);

begin

clk <= not clk after CLK_PERIOD/2;

UUT:entity work.streaming_mca3
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
  swap_buffer => swap_buffer,
  can_swap => can_swap,
  last_bin => last_bin,
  total => total,
  most_frequent => most_frequent,
  max_count => max_count,
  readable => readable,
  stream => stream,
  valid => valid,
  last => last,
  ready => ready
);

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset  = '1' then
      count1 <= (others => '0');
      count2 <= (others => '0');
    else
      if bin_valid then
        if count2=count1 then
          count1 <= count1+1;
          count2 <= (others => '0');
        else
          count2 <= count2+1;
        end if;
      end if;
    end if;
  end if;
end process sim;
end_series <= count2=to_unsigned(2**ADDRESS_BITS-1,ADDRESS_BITS);
bin <= count1;
out_of_bounds <= bin=0 or bin=to_unsigned((2**ADDRESS_BITS)-1,ADDRESS_BITS);
ready <= count1(2)='1';
last_bin <= to_unsigned((2**ADDRESS_BITS)-1,ADDRESS_BITS);

stimulus:process is
begin
wait for CLK_PERIOD;
reset <= '0';
wait until can_swap;
bin_valid <= TRUE;
wait until end_series and can_swap;
swap_buffer <= TRUE;
wait for CLK_PERIOD;
swap_buffer <= FALSE;
wait until end_series and can_swap;
swap_buffer <= TRUE;
wait for CLK_PERIOD;
swap_buffer <= FALSE;
wait until end_series and can_swap;
swap_buffer <= TRUE;
wait for CLK_PERIOD;
swap_buffer <= FALSE;
wait;
end process stimulus;

end architecture testbench;
