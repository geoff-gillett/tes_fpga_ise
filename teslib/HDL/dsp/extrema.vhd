--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11Dec.,2016
--
-- Design Name: TES_digitiser
-- Module Name: extrema
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--

entity extrema is
generic(
  WIDTH:natural:=18
);
port (
  clk:in std_logic;
  reset:in std_logic;
  sig:in signed(WIDTH-1 downto 0);
  pos_0xing:in boolean;
  neg_0xing:in boolean;
  extrema:out signed(WIDTH-1 downto 0)
);
end entity extrema;

architecture RTL of extrema is
type extrema_state is (MAX_S,MIN_S);
signal state:extrema_state;

signal extreme_int:signed(WIDTH-1 downto 0);
signal gt:boolean;
  
begin
gt <= sig > extreme_int; 
extremeMeas:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    
    extreme_int <= (others => '0');
    state <= MAX_S; 
    extrema <= (others => '0');
    
  else
    extrema <= extreme_int;
    
    if pos_0xing then
      state <= MAX_S;
    elsif neg_0xing then
      state <= MIN_S;
    end if;
    
    if pos_0xing or neg_0xing then
      extreme_int <= sig;
    else
      if state=MAX_S and gt then
        extreme_int <= sig;
      end if;
      
      if (state=MIN_S and not gt) then
        extreme_int <= sig;
      end if;
    end if;
  end if;
end if;
end process extremeMeas;

end architecture RTL;
