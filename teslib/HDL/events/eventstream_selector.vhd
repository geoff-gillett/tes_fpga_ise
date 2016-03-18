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

--use work.types.all;
--use work.functions.all;

library streamlib;
use streamlib.types.all;

--reads the selected stream into registers until a last is set
-- changes to sel are ignored until the last is read into registers 
entity eventstream_selector is
generic(
	-- number of input streams (MAX 12)
  CHANNELS:integer:=9
);
port(
  sel:in boolean_vector(CHANNELS-1 downto 0);
  --mux sel stream until last read
 	-- last read into register slice (combinatorial)
  --done:out boolean;
  instreams:in streambus_array_t(CHANNELS-1 downto 0);
  valids:in boolean_vector(CHANNELS-1 downto 0);
  -- use sel for readys
  --readys:out boolean_vector(CHANNELS-1 downto 0);
  --
  stream:out streambus_t;
	valid:out boolean
);
end entity eventstream_selector;

architecture combinatorial of eventstream_selector is
	
type input_array is array(0 to BUS_BITS-1) of 
										std_logic_vector(CHANNELS-1 downto 0);
signal mux_inputs:input_array;
signal unused:std_logic_vector(12-CHANNELS-1 downto 0):=(others => '0');
signal muxstream_valid:std_logic;
signal input_streamvectors:streamvector_array(CHANNELS-1 downto 0);
signal muxstream_vector:streamvector_t;

--signal selected:boolean;

begin
valid <= to_boolean(muxstream_valid);
stream <= to_streambus(muxstream_vector);
--mux_valid <= to_boolean(mux_valid_int);
--mux_stream <= to_streambus(muxstream_vector);

input_streamvectors <= to_std_logic(instreams);	
muxGen:for bit in 0 to BUS_BITS-1 generate
begin
	-- transpose streamvector_array 
	chanGen:for chan in 0 to CHANNELS-1 generate
	begin
		mux_inputs(bit)(chan) <= input_streamvectors(chan)(bit);
	end generate;
	
	selector:entity work.select_1of12
  port map(
    input=> (unused & mux_inputs(bit)),
    sel => (unused & to_std_logic(sel)),
    output => muxstream_vector(bit)
  );
end generate;

validMux:entity work.select_1of12
port map(
  input => (unused & to_std_logic(valids)),
  sel => (unused & to_std_logic(sel)),
  output => muxstream_valid
);



end architecture combinatorial;
