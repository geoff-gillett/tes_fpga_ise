library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity closest0xing_TB is
generic(WIDTH:integer:=8);
end entity closest0xing_TB;

architecture RTL of closest0xing_TB is
  
signal clk:std_logic;
signal reset:std_logic;
signal signal_in:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH-1 downto 0);
signal pos_xing:boolean;
signal neg_xing:boolean;
  
begin

UUT:entity work.closest0xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  signal_out => signal_out,
  pos_xing => pos_xing,
  neg_xing => neg_xing
);

end architecture RTL;
