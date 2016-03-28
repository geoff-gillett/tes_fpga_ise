--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:7 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: streambus_buffer
-- Project Name: streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

use work.types.all;

entity streambus_buffer is
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  instream:in streambus_t;
  instream_valid:in boolean;
  instream_ready:out boolean;
  --
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity streambus_buffer;

architecture fifo_gen of streambus_buffer is

component streambus_fifo
port (
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(71 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(71 downto 0);
  full:out std_logic;
  almost_full:out std_logic;
  empty:out std_logic;
  almost_empty:out std_logic
);
end component;

signal instream_ready_int:boolean;
signal full:std_logic;
signal almost_full:std_logic;
signal empty:std_logic;
signal almost_empty:std_logic;
signal outstream_vector:std_logic_vector(71 downto 0);
signal instream_handshake,outstream_handshake:boolean;
signal outstream_valid_int:boolean;
	
begin
	
instream_ready <= instream_ready_int;
valid <= outstream_valid_int;
--stream <= to_streambus(outstream_vector);
	
fifo:streambus_fifo
port map (
  clk => clk,
  srst => reset,
  din => to_std_logic(instream),
  wr_en => to_std_logic(instream_handshake),
  rd_en => to_std_logic(outstream_handshake),
  dout => outstream_vector,
  full => full,
  almost_full => almost_full,
  empty => empty,
  almost_empty => almost_empty
);

instream_handshake <= instream_valid and instream_ready_int;
outstream_handshake <= outstream_valid_int and ready;
stream <= to_streambus(outstream_vector); 

input:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			instream_ready_int <= FALSE;
			outstream_valid_int <= FALSE;
		else
			-- TODO check if the almost_flags goes low when full
			if instream_handshake then
				instream_ready_int <= to_boolean(not almost_full);
			else
				instream_ready_int <= to_boolean(not full);
			end if;
			if outstream_handshake then
				outstream_valid_int <= to_boolean(not almost_empty);
			else 
				outstream_valid_int <= to_boolean(not empty);
			end if;
		end if;
	end if;
end process input;

end architecture fifo_gen;
