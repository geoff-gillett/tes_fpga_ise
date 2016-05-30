library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.FD;

entity sync_pulse_3FF is
generic (
  INIT:bit_vector(2 downto 0) := "000"
);
port (
  out_clk:in std_logic; 
  input:in std_logic;   
  pulse_out:out std_logic 
);

end sync_pulse_3FF;

architecture structural of sync_pulse_3FF is
signal sync_out:std_logic;
signal edge_out:std_logic;

attribute ASYNC_REG:string;
attribute ASYNC_REG of input:signal is "TRUE";

begin
	
sync:entity work.sync_2FF
generic map(INIT => INIT(2 downto 1))
port map(
  out_clk => out_clk,
  input   => input,
  output  => sync_out
);	
	
edgeDetect:FD
generic map(
  INIT => INIT(0)
)
port map(
  C => out_clk,
  D => sync_out,
  Q => edge_out
);

pulse_out <= sync_out and not edge_out;
end structural;


