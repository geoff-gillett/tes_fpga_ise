library ieee;
use ieee.std_logic_1164.all;

library extensions;
use extensions.boolean_vector.all;

use work.types.all;

entity streambus_register_slice is
port (
  clk:in std_logic;
  reset:in std_logic;
  -- Input interface
  stream_in:in streambus_t;
  ready_out:out boolean;
  valid_in:in boolean;
  --last_in:boolean;
  -- Output interface
  stream:out streambus_t;
  ready:in boolean;
  valid:out boolean
  --last:out boolean
);
end entity streambus_register_slice;
--
architecture wrapper of streambus_register_slice is
signal streamvector:streamvector_t;
begin
	
registers:entity work.register_slice
generic map(
  WIDTH => BUS_BITS
)
port map(
  clk => clk,
  reset => reset,
  stream_in => to_std_logic(stream_in),
  ready_out => ready_out,
  valid_in => valid_in,
  stream => streamvector,
  ready => ready,
  valid => valid
);
stream <= to_streambus(streamvector);
end architecture wrapper;
