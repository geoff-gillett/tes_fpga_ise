library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.FD;

entity sync_level is
generic(INITIALISE:bit_vector(1 downto 0) := "00");
port (
  clk:in std_logic;                   -- clock to be sync'ed to
  data_in:in std_logic;               -- Data to be 'synced'
  data_out:out std_logic              -- synced data
);
end sync_level;

architecture structural of sync_level is
  -- Internal Signals
signal data_sync1:std_logic;
  -- These attributes will stop timing errors being reported in back annotated
  -- SDF simulation.
attribute ASYNC_REG:string;
attribute ASYNC_REG of data_sync1:signal is "TRUE";
attribute RLOC:string;
attribute RLOC of data_sync1:signal is "X0Y0";
attribute RLOC of data_out:signal is "X0Y0";
--
begin
data_sync:FD
generic map(INIT => INITIALISE(0))
port map(
  C => clk,
  D => data_in,
  Q => data_sync1
);
--
data_sync_reg:FD
generic map(INIT => INITIALISE(1))
port map(
  C => clk,
  D => data_sync1,
  Q => data_out
);
end structural;


