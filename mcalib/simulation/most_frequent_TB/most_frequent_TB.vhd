--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:23Feb.,2017
--
-- Design Name: TES_digitiser
-- Module Name: most_frequent_TB
-- Project Name: mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity most_frequent_TB is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:integer:=4;
  --width of counters and stream
  COUNTER_BITS:integer:=9;
  TIMECONSTANT_BITS:integer:=32
);
end entity most_frequent_TB;

architecture testbench of most_frequent_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal timeconstant:unsigned(TIMECONSTANT_BITS-1 downto 0);
signal count_threshold:unsigned(COUNTER_BITS-1 downto 0);
signal sample:std_logic_vector(ADDRESS_BITS-1 downto 0);
signal sample_valid:boolean;
signal most_frequent_bin:unsigned(ADDRESS_BITS-1 downto 0);
signal new_most_frequent_bin:boolean;
signal most_frequent_count:unsigned(COUNTER_BITS-1 downto 0);
signal new_most_frequent:boolean;

signal count1,count2,count3:unsigned(ADDRESS_BITS-1 downto 0);
signal clk_count:natural:=0;
begin

clk <= not clk after CLK_PERIOD/2;
UUT:entity work.most_frequent2
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS
)
port map(
  clk => clk,
  reset => reset,
  timeconstant => timeconstant,
  count_threshold => count_threshold,
  sample => sample,
  sample_valid => sample_valid,
  most_frequent_bin => most_frequent_bin,
  new_most_frequent_bin => new_most_frequent_bin,
  most_frequent_count => most_frequent_count,
  new_most_frequent => new_most_frequent
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
      if sample_valid then
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
sample <= std_logic_vector(count1);
--bin <= (others => '0');
--out_of_bounds <= bin=0 or bin=last_bin;

stimulus:process is
begin
count_threshold <= to_unsigned(2,COUNTER_BITS);
timeconstant <= to_unsigned(136,TIMECONSTANT_BITS);
wait for CLK_PERIOD;
reset <= '0';
sample_valid <= TRUE;
wait;
end process stimulus;

end architecture testbench;
