--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:10 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: streambus_lookahead_buffer
-- Project Name: streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;

use work.stream.all;

entity streambus_lookahead_buffer is
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  instream:in streambus_t;
  instream_valid:in boolean;
  instream_ready:out boolean;
  --
  lookahead:out streambus_t;
  lookahead_valid:out boolean;
  --
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity streambus_lookahead_buffer;

architecture wrapper of streambus_lookahead_buffer is
	
signal bufferstream_valid,bufferstream_ready:boolean;
signal lookahead_vector:std_logic_vector(BUS_BITS-1 downto 0);
signal stream_vector:std_logic_vector(BUS_BITS-1 downto 0);
signal bufferstream:streambus_t;
begin

lookahead <= to_streambus(lookahead_vector);
stream <= to_streambus(stream_vector);

streambuffer:entity work.streambus_buffer
port map(
  clk => clk,
  reset => reset,
  instream => instream,
  instream_valid => instream_valid,
  instream_ready => instream_ready,
  stream => bufferstream,
  valid => bufferstream_valid,
  ready => bufferstream_ready
);

lookaheadSlice:entity work.lookahead_slice
generic map(
  WIDTH => BUS_BITS
)
port map(
  clk => clk,
  reset => reset,
  stream_in => to_std_logic(bufferstream),
  ready_out => bufferstream_ready,
  valid_in => bufferstream_valid,
  lookahead => lookahead_vector,
  lookahead_valid => lookahead_valid,
  stream => stream_vector,
  ready => ready,
  valid => valid
);

end architecture wrapper;
