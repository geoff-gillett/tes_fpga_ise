library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.FD;

library extensions;
use extensions.boolean_vector.all;

entity boolean_sync_2FF is
generic (
  INIT:bit_vector(1 downto 0) := "00"
);
port (
  out_clk:in std_logic; -- clock to be sync'ed to
  input:in boolean;               
  output:out boolean              
);
end boolean_sync_2FF;

architecture structural of boolean_sync_2FF is
signal data_sync:std_logic;
signal output_int:std_ulogic;
  -- These attributes will stop timing errors being reported in back annotated
  -- SDF simulation.
attribute ASYNC_REG:string;
attribute ASYNC_REG of input:signal is "TRUE";
attribute ASYNC_REG of data_sync:signal is "TRUE";

attribute RLOC:string;
attribute RLOC of sync1:label is "X0Y0";
attribute RLOC of sync2:label is "X0Y0";

begin
output <= to_boolean(output_int);

sync1:FD
generic map(
  INIT => INIT(0)
)
port map(
  C => out_clk,
  D => to_std_logic(input),
  Q => data_sync
);
sync2:FD
generic map (
  INIT => INIT(1)
)
port map (
  C => out_clk,
  D => data_sync,
  Q => output_int
);
end structural;


