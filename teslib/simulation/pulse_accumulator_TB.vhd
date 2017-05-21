--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:16Apr.,2017
--
-- Design Name: TES_digitiser
-- Module Name: pulse_accumulator_TB
-- Project Name:  teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.logic.all;

entity pulse_accumulator_TB is
generic(
  ADDRESS_BITS:integer:=16;
  WIDTH:integer:=16;
  ACCUMULATOR_WIDTH:integer:=36
);
end entity pulse_accumulator_TB;

architecture testbench of pulse_accumulator_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;

constant DIV_BITS:integer:=ceillog2(ACCUMULATOR_WIDTH-WIDTH);
signal divide_n,loop_count:unsigned(DIV_BITS-1 downto 0);
signal sample:signed(WIDTH-1 downto 0);
signal accumulate:boolean;
signal write,done,inc,loop_done:boolean;
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal data:signed(WIDTH-1 downto 0);

begin

clk <= not clk after CLK_PERIOD/2;
UUT:entity work.pulse_accumulator
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  WIDTH => WIDTH,
  ACCUMULATOR_WIDTH => ACCUMULATOR_WIDTH
)
port map(
  clk => clk,
  reset => reset,
  accumulate_n => divide_n,
  sample => sample,
  accumulate => accumulate,
  write => write,
  address => address,
  data => data
);

name:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      address <= (others => '0');
      loop_count <= (others => '0');
    else
      if inc then
        address <= address+1;
        if address=to_unsigned(2**ADDRESS_BITS-1,ADDRESS_BITS) then
          loop_count <= loop_count+1;
          loop_done <= TRUE;
        else
          loop_done <= FALSE;
        end if;
        if loop_count =
           shift_left(to_unsigned(1,DIV_BITS),to_integer(divide_n))-1 then
          loop_count <= (others => '0');
          done <= TRUE;
        else
          done <= FALSE;
        end if;
      end if;
    end if;
  end if;
end process name;


stimulus:process is
begin
divide_n <= to_unsigned(1,DIV_BITS);  
sample <= to_signed(16, WIDTH);
accumulate <= FALSE;
write <= FALSE;
address <= (others => '0');
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
inc <= TRUE;
write <= TRUE;
accumulate <= FALSE;
wait until loop_done;
accumulate <= TRUE;
wait until done;
write <= FALSE;
inc <= FALSE;

wait for CLK_PERIOD*2;
inc <= TRUE;
divide_n <= to_unsigned(0,DIV_BITS); 
wait until loop_done;
divide_n <= to_unsigned(1,DIV_BITS); 
 
wait;
end process stimulus;

end architecture testbench;
