--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:09/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: stream_framer_TDP arch
-- Project Name: streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;

entity framer is
generic(
  BUS_CHUNKS:integer:=4;
  ADDRESS_BITS:integer:=10
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --! data chunks to write to frame 
  data:in streambus_t;
  --! frame address
  address:in unsigned(ADDRESS_BITS-1 downto 0);
  chunk_we:in boolean_vector(BUS_CHUNKS-1 downto 0);
  length:in unsigned(ADDRESS_BITS downto 0);
  commit:in boolean;
  free:out unsigned(ADDRESS_BITS downto 0);
  --
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
  --last:out boolean -- true if any lasts set 
);
end entity framer;

architecture SDP of framer is
  
signal din:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal streamvector:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);

begin

din <= to_std_logic(data);
  
frameRam:entity work.frame_ram
generic map(
  CHUNKS => BUS_CHUNKS,
  CHUNK_BITS => CHUNK_BITS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  din => din,
  address => address,
  chunk_we => chunk_we,
  length => length,
  commit => commit,
  free => free,
  stream => streamvector,
  valid => valid,
  ready => ready
);

stream <= to_streambus(streamvector);

end architecture SDP;