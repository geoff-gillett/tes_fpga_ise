--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: eventstream_select
-- Project Name: TES_digitiser 
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
--
library streamlib;
use streamlib.types.all;

entity eventstream_select is
generic(
	-- number of input streams (MAX 12)
  CHANNELS:integer:=9
);
port(
  --
  sel:in std_logic_vector(CHANNELS-1 downto 0);
  streams:in eventbus_array(CHANNELS-1 downto 0);
  lasts:in boolean_vector(CHANNELS-1 downto 0);
  valids:in boolean_vector(CHANNELS-1 downto 0);
  --
  stream:out eventbus_t;
  valid:out boolean;
  last:out boolean
);
end entity eventstream_select;

architecture combinatorial of eventstream_select is
constant BUS_BITS:integer:=CHUNK_BITS*BUS_CHUNKS;
type input_array is array(0 to BUS_BITS-1) of 
										std_logic_vector(CHANNELS-1 downto 0);
signal inputs:input_array;
signal unused:std_logic_vector(12-CHANNELS-1 downto 0):=(others => '0');
signal last_int,valid_int:std_logic;
begin
last <= to_boolean(last_int);
valid <= to_boolean(valid_int);
	
muxGen:for bit in 0 to BUS_BITS-1 generate
begin
	-- transpose stream array 
	chanGen:for chan in 0 to CHANNELS-1 generate
	begin
		inputs(bit)(chan) <= streams(chan)(bit);
	end generate;
	
	selector:entity teslib.select_1of12
  port map(
    input=> (unused & inputs(bit)),
    sel => (unused & sel),
    output => stream(bit)
  );
end generate;

validMux:entity teslib.select_1of12
port map(
  input  => (unused & to_std_logic(valids)),
  sel    => (unused & sel),
  output => valid_int
);

lastMux:entity teslib.select_1of12
port map(
  input  => (unused & to_std_logic(lasts)),
  sel    => (unused & sel),
  output => last_int
);

end architecture combinatorial;
