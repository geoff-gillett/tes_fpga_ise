--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:26 May 2016
--
-- Design Name: TES_digitiser
-- Module Name: axi_channel
-- Project Name: teslib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity axi_rd_chan is
generic(WIDTH:integer:=AXI_DATA_BITS);
port(
  clk:in std_logic;
  resetn:in std_logic;
  
  value:out std_logic_vector(WIDTH-1 downto 0);
  go:in boolean;
  value_valid:out boolean;
  --
  axi_data:in std_logic_vector(WIDTH-1 downto 0);
  axi_valid:in std_logic;
  axi_ready:out std_logic
  
);
end entity axi_rd_chan;

architecture RTL of axi_rd_chan is

type FSMstate is (READY, IDLE);
signal state,nextstate:FSMstate;
	
begin
	
FSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if resetn = '0' then
			state <= IDLE;
		else
			state <= nextstate;
		end if;
	end if;
end process FSMnextstate;

FSMtransition:process(state,axi_valid,go)
begin
nextstate <= state;
case state is 
when READY =>
	if axi_valid='1' then
		nextstate <= IDLE;
  end if;
when IDLE =>
	if go then
		nextstate <= READY;
  end if;
end case;
end process FSMtransition;
value_valid <= state=IDLE;
axi_ready <= '1' when state=READY else '0';

inreg:process(clk)
begin
	if rising_edge(clk) then
		if state=READY and axi_valid='1' then
			value <= axi_data;
		end if;
	end if;
end process inreg;

end architecture RTL;
