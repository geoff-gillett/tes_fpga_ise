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

entity axi_wr_chan is
generic(WIDTH:integer:=AXI_DATA_BITS);
port(
  clk:in std_logic;
  resetn:in std_logic;
  
  reg_value:in std_logic_vector(WIDTH-1 downto 0);
  go:in std_logic;
  done:out std_logic;
  --
  axi_data:out std_logic_vector(WIDTH-1 downto 0);
  axi_valid:out std_logic;
  axi_ready:in std_logic
  
);
end entity axi_wr_chan;

architecture RTL of axi_wr_chan is

type FSMstate is (VALID, IDLE);
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

FSMtransition:process(state,axi_ready,go)
begin
nextstate <= state;
case state is 
when VALID =>
	if axi_ready='1' then
		nextstate <= IDLE;
  end if;
when IDLE =>
	if go='1' then
		nextstate <= VALID;
  end if;
end case;
end process FSMtransition;
done <= '1' when state=IDLE else '0';
axi_valid <= '1' when state=VALID else '0';

outreg:process(clk)
begin
	if rising_edge(clk) then
		if state=IDLE and go='1' then
			axi_data <= reg_value;
		end if;
	end if;
end process outreg;

end architecture RTL;
