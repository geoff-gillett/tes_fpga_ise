library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

package types is
	
--! Width of the output stream (an stream output word)
constant OUTSTREAM_DATA_BITS:integer:=8; 
constant OUTSTREAM_BITS:integer:=OUTSTREAM_DATA_BITS;
--! Number of control bits per output word (last, keep)  
constant OUTSTREAM_CONTROL_BITS:integer:=1;
constant STREAM_WORD_BITS:integer:=OUTSTREAM_DATA_BITS+OUTSTREAM_CONTROL_BITS;
--! Number of output words in a control chunk
constant CHUNK_WORDS:integer:=2; 
--constant CHUNK_BYTES:integer:=2;
--! Width of the buffer FIFO output words 
--! Deprecated use WORD_BITS instead TODO replace FIFO_BITS with WORD_BITS
--constant FIFO_BITS:integer:=STREAM_DATA_BITS+STREAM_CONTROL_BITS;           
--! Total bits in a stream output word including control bit(s)
--constant WORD_BITS:integer:=STREAM_DATA_BITS+STREAM_CONTROL_BITS;
--! The trace and event buses are divided into chunks, each chunk has an enable
--! bit that determines whether it will be put on the output stream.
--! each chunk also has a last bit, indication the last chunk in a stream object.
--! TODO change INTERSTAGE to more functionally descriptive CHUNK in the 
--! downstream entities.
constant CHUNK_BITS:integer:=CHUNK_WORDS*STREAM_WORD_BITS;
--! Number of bits in a chunk that contain data
constant CHUNK_DATABITS:integer:=CHUNK_WORDS*OUTSTREAM_DATA_BITS;
--! The bit in the chunk that indicates that the chunk should be kept
--! NOTE this is assuming downto indexing -control bits are always leftmost
constant CHUNK_KEEPBIT:integer:=CHUNK_DATABITS;
--! The bit in the chunk that indicates the last chunk in the stream
--! NOTE this is assuming downto indexing -control bits are always leftmost
constant CHUNK_LASTBIT:integer:=CHUNK_DATABITS+1;
constant CHUNK_CONTROLBITS:integer:=CHUNK_BITS-CHUNK_DATABITS;

-- Was in events 
-- Number of chunks in the eventbus SEE TES.stream library
constant EVENTBUS_CHUNKS:integer:=4;
-- total bits in the eventbus (including control bits)
constant EVENTBUS_BITS:integer:=CHUNK_BITS*EVENTBUS_CHUNKS;
-- data only bits of the eventbus
constant EVENTBUS_DATA_BITS:integer:=CHUNK_DATABITS*EVENTBUS_CHUNKS;
subtype eventbus_t is std_logic_vector(EVENTBUS_CHUNKS*CHUNK_BITS-1 downto 0);
type eventbus_array is array (natural range <>) of eventbus_t;

type streambus is record
	keeps:std_logic_vector(EVENTBUS_CHUNKS-1 downto 0);
	lasts:std_logic_vector(EVENTBUS_CHUNKS-1 downto 0);
	data:std_logic_vector(EVENTBUS_CHUNKS*CHUNK_DATABITS-1 downto 0);
end record;


end package types;

package body types is
	
end package body types;
