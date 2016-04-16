library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.FD;

entity sync_2FF is
generic (
  INITIALISE:bit_vector(2 downto 0) := "000"
);
port (
  out_clk:in std_logic;                -- clock to be sync'ed to
  input:in std_logic;               -- pulse to be synced
  output:out std_logic              -- synced pulse
);

end sync_2FF;

architecture structural of sync_2FF is
signal data_sync:std_logic;
  -- These attributes will stop timing errors being reported in back annotated
  -- SDF simulation.
attribute ASYNC_REG:string;
attribute ASYNC_REG of input:signal is "TRUE";

attribute RLOC:string;
attribute RLOC of sync1:label is "X0Y0";
attribute RLOC of sync2:label is "X0Y0";

begin
sync1:FD
generic map(
  INIT => INITIALISE(1)
)
port map(
  C => out_clk,
  D => input,
  Q => data_sync
);
sync2:FD
generic map (
  INIT => INITIALISE(2)
)
port map (
  C => out_clk,
  D => data_sync,
  Q => output
);
end structural;


