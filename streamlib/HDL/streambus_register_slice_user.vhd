library ieee;
use ieee.std_logic_1164.all;

library extensions;
use extensions.boolean_vector.all;

use work.types.all;

entity streambus_register_slice_user is
generic(USER_WIDTH:natural:=16);
port (
  clk:in std_logic;
  reset:in std_logic;
  -- Input interface
  user_in:in std_logic_vector(USER_WIDTH-1 downto 0);
  stream_in:in streambus_t;
  ready_out:out boolean;
  valid_in:in boolean;
  --last_in:boolean;
  -- Output interface
  user:out std_logic_vector(USER_WIDTH-1 downto 0);
  stream:out streambus_t;
  ready:in boolean;
  valid:out boolean
  --last:out boolean
);
end entity streambus_register_slice_user;
--
architecture wrapper of streambus_register_slice_user is
signal streamvector:streamvector_t;
begin
	
registers:entity work.stream_register_user
generic map(
  WIDTH => BUS_BITS,
  USER_WIDTH => USER_WIDTH
)
port map(
  clk => clk,
  reset => reset,
  user_in => user_in,
  stream_in => to_std_logic(stream_in),
  ready_out => ready_out,
  valid_in => valid_in,
  user => user,
  stream => streamvector,
  ready => ready,
  valid => valid
);
stream <= to_streambus(streamvector);
end architecture wrapper;
