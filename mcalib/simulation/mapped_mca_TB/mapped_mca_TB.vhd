--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:30Jan.,2017
--
-- Design Name: TES_digitiser
-- Module Name: mapped_mca_TB
-- Project Name:  mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.logic.all;

entity mapped_mca_TB is
generic(
  ADDRESS_BITS:natural:=8;
  TOTAL_BITS:natural:=64;
  VALUE_BITS:natural:=32;
  COUNTER_BITS:natural:=32
);
end entity mapped_mca_TB;

architecture testbench of mapped_mca_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

signal value:signed(VALUE_BITS-1 downto 0);
signal value_valid:boolean;
signal swap_buffer:boolean;
signal enabled:boolean;
signal can_swap:boolean;
signal bin_n:unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0);
signal last_bin:unsigned(ADDRESS_BITS-1 downto 0);
signal lowest_value:signed(VALUE_BITS-1 downto 0);
signal max_count:unsigned(COUNTER_BITS-1 downto 0);
signal most_frequent:unsigned(ADDRESS_BITS-1 downto 0);
signal total:unsigned(TOTAL_BITS-1 downto 0);
signal readable:boolean;
signal stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal valid:boolean;
signal ready:boolean;
signal last:boolean;

signal sim_count:signed(VALUE_BITS-1 downto 0);
signal sim_enable:boolean;
constant DEPTH:natural:=6;
type value_pipe is array (1 to DEPTH) of signed(VALUE_BITS-1 downto 0);
signal pipe:value_pipe;

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.mapped_mca
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  TOTAL_BITS => TOTAL_BITS,
  VALUE_BITS => VALUE_BITS,
  COUNTER_BITS => COUNTER_BITS
)
port map(
  clk => clk,
  reset => reset,
  value => value,
  value_valid => value_valid,
  swap_buffer => swap_buffer,
  enabled => enabled,
  can_swap => can_swap,
  bin_n => bin_n,
  last_bin => last_bin,
  lowest_value => lowest_value,
  max_count => max_count,
  most_frequent => most_frequent,
  total => total,
  readable => readable,
  stream => stream,
  valid => valid,
  ready => ready,
  last => last
);

simcount:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= to_signed(-10,VALUE_BITS);
    else
      pipe <= value & pipe(1 to DEPTH-1);
      if sim_enable then
        if sim_count > to_signed(2**ADDRESS_BITS,VALUE_BITS) then
          sim_count <= to_signed(-10,VALUE_BITS); 
        else
          sim_count <= sim_count+1;
        end if;
      end if;
    end if;
  end if;
end process simcount;
value <= sim_count;

stimulus:process is
begin
sim_enable <= FALSE;
value_valid <= FALSE;
swap_buffer <= FALSE;
last_bin <= to_unsigned(2**ADDRESS_BITS-1,ADDRESS_BITS);
lowest_value <= (others => '0');
bin_n <= (others => '0');
ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait until can_swap;
sim_enable <= TRUE;
swap_buffer <= TRUE;
wait for CLK_PERIOD;
swap_buffer <= FALSE;
wait;
end process stimulus;

end architecture testbench;
