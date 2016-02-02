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
use streamlib.stream.all;

entity eventstream_select is
generic(
	-- number of input streams (MAX 12)
  CHANNELS:integer:=9
);
port(
  --
  sel:in std_logic_vector(CHANNELS-1 downto 0);
  instreams:in streambus_array(CHANNELS-1 downto 0);
  valids:in boolean_vector(CHANNELS-1 downto 0);
  --
  mux_stream:out streambus_t;
	mux_valid:out boolean
);
end entity eventstream_select;

architecture combinatorial of eventstream_select is
	
type input_array is array(0 to BUS_BITS-1) of 
										std_logic_vector(CHANNELS-1 downto 0);
signal mux_inputs:input_array;
signal unused:std_logic_vector(12-CHANNELS-1 downto 0):=(others => '0');
signal valid_int:std_logic;
signal input_streamvectors:streamvector_array(CHANNELS-1 downto 0);
signal mux_streamvector:streamvector_t;
begin
	
mux_valid <= to_boolean(valid_int);
mux_stream <= to_streambus(mux_streamvector);

input_streamvectors <= to_std_logic(instreams);	
muxGen:for bit in 0 to BUS_BITS-1 generate
begin
	-- transpose streamvector_array 
	chanGen:for chan in 0 to CHANNELS-1 generate
	begin
		mux_inputs(bit)(chan) <= input_streamvectors(chan)(bit);
	end generate;
	
	selector:entity teslib.select_1of12
  port map(
    input=> (unused & mux_inputs(bit)),
    sel => (unused & sel),
    output => mux_streamvector(bit)
  );
end generate;

validMux:entity teslib.select_1of12
port map(
  input  => (unused & to_std_logic(valids)),
  sel    => (unused & sel),
  output => valid_int
);

--lastMux:entity teslib.select_1of12
--port map(
--  input  => (unused & to_std_logic(lasts)),
--  sel    => (unused & sel),
--  output => last_int
--);

end architecture combinatorial;
