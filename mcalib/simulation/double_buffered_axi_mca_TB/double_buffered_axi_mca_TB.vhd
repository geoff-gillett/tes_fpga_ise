--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15Feb.,2017
--
-- Design Name: TES_digitiser
-- Module Name: mca_buffer_TB
-- Project Name:  mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity double_buffered_axi_mca_TB is
generic(
  ADDRESS_BITS:natural:=4;
  COUNTER_BITS:natural:=32;
  TOTAL_BITS:natural:=64
);
end entity double_buffered_axi_mca_TB;

architecture testbench of double_buffered_axi_mca_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;
signal bin:unsigned(ADDRESS_BITS-1 downto 0);
signal bin_valid:boolean;
signal out_of_bounds:boolean;
signal last_bin:unsigned(ADDRESS_BITS-1 downto 0);
signal swap:boolean;
signal most_frequent_bin:unsigned(ADDRESS_BITS-1 downto 0);
signal most_frequent_count:unsigned(COUNTER_BITS-1 downto 0);
signal new_most_frequent:boolean;
signal total_in_bounds:unsigned(TOTAL_BITS-1 downto 0);
signal stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal valid:boolean;
signal ready:boolean;
signal last:boolean;
signal new_most_frequent_bin:boolean;

--simulation signals
signal count1,count2,count3:unsigned(ADDRESS_BITS-1 downto 0);
signal clk_count:natural:=0;
signal stop:boolean;
signal can_swap:boolean;
signal swapped:boolean;
begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.double_buffered_axi_mca
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS   => TOTAL_BITS
)
port map(
  clk => clk,
  reset => reset,
  bin => bin,
  bin_valid => bin_valid,
  out_of_bounds => out_of_bounds,
  last_bin => last_bin,
  swap => swap,
  stop => stop,
  can_swap => can_swap,
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

sim:process(clk)
begin
  if rising_edge(clk) then
    if reset  = '1' then
      count1 <= (others => '0');
      count2 <= (others => '0');
      count3 <= (others => '0');
    else
      clk_count <= clk_count+1;
      if bin_valid then
        count3 <= count3+1;
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
bin <= count1;
--ready <= clk_count mod 3/=0;
ready <= TRUE;
--bin <= (others => '0');
--out_of_bounds <= bin=0 or bin=last_bin;
out_of_bounds <= FALSE;

stimulus:process is
begin
last_bin <= to_unsigned(2**ADDRESS_BITS-1,ADDRESS_BITS);
stop <= FALSE;
--ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait until can_swap;
swap <= TRUE;
wait for CLK_PERIOD;
swap <= FALSE;
bin_valid <= TRUE;
wait until count2=2**ADDRESS_BITS-1;
swap <= TRUE;
wait for CLK_PERIOD;
swap <= FALSE;
wait until count2=2**ADDRESS_BITS-1;
swap <= TRUE;
wait for CLK_PERIOD;
swap <= FALSE;
stop <= TRUE;
wait for CLK_PERIOD;
stop <= FALSE;
wait;
end process stimulus;

end architecture testbench;
