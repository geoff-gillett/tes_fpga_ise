
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;
use std.textio.all;


package debug is
  
function hexstr2vec(str:string) return std_logic_vector;
end package debug;

package body debug is

function hexstr2vec(str:string) return std_logic_vector is
	variable slv:std_logic_vector(str'length*4-1 downto 0):=(others => 'X');
begin
	for i in 0 to str'length-1 loop
		case str(i+1) is -- strings can't use index 0
		when '0' => 
			slv(4*(i+1)-1 downto (4*i)):="0000";
		when '1' => 
			slv(4*(i+1)-1 downto (4*i)):="0001";
		when character('2') => 
			slv(4*(i+1)-1 downto (4*i)):="0010";
		when character('3') => 
			slv(4*(i+1)-1 downto (4*i)):="0011";
		when character('4') => 
			slv(4*(i+1)-1 downto (4*i)):="0100";
		when character('5') => 
			slv(4*(i+1)-1 downto (4*i)):="0101";
		when character('6') => 
			slv(4*(i+1)-1 downto (4*i)):="0110";
		when character('7') => 
			slv(4*(i+1)-1 downto (4*i)):="0111";
		when character('8') => 
			slv(4*(i+1)-1 downto (4*i)):="1000";
		when character('9') => 
			slv(4*(i+1)-1 downto (4*i)):="1001";
		when character('a') => 
			slv(4*(i+1)-1 downto (4*i)):="1010";
		when character('b') => 
			slv(4*(i+1)-1 downto (4*i)):="1011";
		when character('c') => 
			slv(4*(i+1)-1 downto (4*i)):="1100";
		when character('d') => 
			slv(4*(i+1)-1 downto (4*i)):="1101";
		when character('e') => 
			slv(4*(i+1)-1 downto (4*i)):="1110";
		when character('f') => 
			slv(4*(i+1)-1 downto (4*i)):="1111";
		when others => 
			slv(4*(i+1)-1 downto (4*i)):="UUUU";
		end case;
	end loop;
	return slv;
end function;
end package body debug;
