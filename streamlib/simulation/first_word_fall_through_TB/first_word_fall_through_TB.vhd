library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity first_word_fall_through_TB is
generic(
  LATENCY:integer:=2;
  DATA_BITS:integer:=8;
  ADDRESS_BITS:integer:=4
);
end entity first_word_fall_through_TB;

architecture RTL of first_word_fall_through_TB is

constant CLK_PERIOD:time:=4 ns;
subtype word is std_logic_vector(DATA_BITS-1 downto 0);
type ram_t is array(0 to 2**ADDRESS_BITS-1) of word;

signal ram:ram_t;
signal din,dout,dout_r:word;
signal rd_addr,wr_addr:unsigned(2**ADDRESS_BITS-1 downto 0);

signal we:boolean;

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal read:boolean;
signal read_en:boolean;
signal data:std_logic_vector(DATA_BITS-1 downto 0);
signal stream:std_logic_vector(DATA_BITS-1 downto 0);
signal ready:boolean;
signal valid:boolean;
 
begin
clk <= not clk after CLK_PERIOD/2;
reset <= '0' after 2*CLK_PERIOD;



fwft:entity work.stream_register
  generic map(
    WIDTH => DATA_BITS
  )
  port map(
    clk       => clk,
    reset     => reset,
    stream_in => dout,
    ready_out => ready_out,
    valid_in  => valid_in,
    stream    => stream,
    ready     => ready,
    valid     => valid
  );


end architecture RTL;
