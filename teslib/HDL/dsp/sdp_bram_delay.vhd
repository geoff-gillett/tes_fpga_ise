--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:03/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: moving_average
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.logic.all;


-- implemented as SP BRAM max delay 1027 per bram
-- TODO implement a TDP version that can get 2*width at 1/2 DELAY per bram
entity sdp_bram_delay is
generic(
  DELAY:integer:=1027; -- minimum 3
  WIDTH:integer:=18
);
port(
  clk:in std_logic;
  input:in std_logic_vector(WIDTH-1 downto 0);
  delayed:out std_logic_vector(WIDTH-1 downto 0)
);
end sdp_bram_delay;

architecture rtl of sdp_bram_delay is

constant ADDRWIDTH:integer:=ceilLog2(DELAY-3);

signal addr:unsigned(ADDRWIDTH-1 downto 0):=(others => '0');
signal dout_reg:std_logic_vector(WIDTH-1 downto 0);

type ram_t is array (natural range <>) of std_logic_vector(WIDTH-1 downto 0);
signal RAM:ram_t(0 to DELAY-3):=(others => (others => '0'));

begin

assert DELAY >= 3
report "minimum delay is 3" severity ERROR;
  
address:process(clk)
begin
  if rising_edge(clk) then
    if addr = to_unsigned(DELAY-3, ADDRWIDTH) then
      addr <= (others => '0');
    else
      addr <= addr + 1;
    end if;
  end if;
end process address;
  
memory:process (clk)
begin
  if rising_edge(clk) then
    RAM(to_integer(addr)) <= input;
    dout_reg <= RAM(to_integer(addr));
    delayed <= dout_reg;
  end if;
end process memory;

end rtl;
