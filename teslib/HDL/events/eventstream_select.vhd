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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

entity eventstream_select is
generic(
	-- number of input streams (MAX 12)
  CHANNELS:integer:=9
);
port(
  sel:in std_logic_vector(CHANNELS-1 downto 0);
  instreams:in streambus_array(CHANNELS-1 downto 0);
  valids:in boolean_vector(CHANNELS-1 downto 0);
  
  mux_stream:out streambus_t;
	mux_valid:out boolean
);
end entity eventstream_select;

architecture combinatorial of eventstream_select is
	
type input_array is array(0 to BUS_BITS-1) of std_logic_vector(11 downto 0);
signal mux_inputs:input_array;
signal valid_int:std_logic;
signal input_streamvectors:streamvector_array(CHANNELS-1 downto 0);
signal mux_streamvector:streamvector_t;
signal sel_int,valids_int:std_logic_vector(11 downto 0);
begin
	
mux_valid <= to_boolean(valid_int);
mux_stream <= to_streambus(mux_streamvector);
input_streamvectors <= to_std_logic(instreams);	
sel_int <= resize(sel,12);
muxGen:for bit in 0 to BUS_BITS-1 generate
begin
	-- transpose streamvector_array 
	chanGen:for chan in 0 to CHANNELS-1 generate
	begin
		mux_inputs(bit)(chan) <= input_streamvectors(chan)(bit);
	end generate;
	
	selector:entity work.select_1of12
  port map(
    input => mux_inputs(bit),
    sel => sel_int,
    output => mux_streamvector(bit)
  );
end generate;

valids_int <= resize(to_std_logic(valids),12);
validMux:entity work.select_1of12
port map(
  input => valids_int,
  sel => sel_int,
  output => valid_int
);

end architecture combinatorial;
