library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.FD;

entity sync_pulse is
generic (
  INITIALISE:bit_vector(2 downto 0) := "000"
);
port (
  in_clk:in std_logic;                 -- clock to be sync'ed from 
  out_clk:in std_logic;                -- clock to be sync'ed to
  pulse_in:in std_logic;               -- pulse to be synced
  pulse_out:out std_logic              -- synced pulse
);

end sync_pulse;

architecture structural of sync_pulse is
signal flag:std_logic;
signal data_sync1:std_logic;
signal data_sync2:std_logic;
  -- These attributes will stop timing errors being reported in back annotated
  -- SDF simulation.
attribute ASYNC_REG:string;
attribute ASYNC_REG of flag:signal is "TRUE";

attribute RLOC:string;
attribute RLOC of sync1:label is "X0Y0";
attribute RLOC of sync2:label is "X0Y0";

begin
edgeDetect:FD
generic map(
  INIT => INITIALISE(0)
)
port map(
  C => in_clk,
  D => pulse_in,
  Q => flag
);
sync1:FD
generic map(
  INIT => INITIALISE(1)
)
port map(
  C => out_clk,
  D => flag,
  Q => data_sync1
);
sync2:FD
generic map (
  INIT => INITIALISE(2)
)
port map (
  C => out_clk,
  D => data_sync1,
  Q => data_sync2
);
pulse_out <= data_sync1 and not data_sync2;
end structural;


