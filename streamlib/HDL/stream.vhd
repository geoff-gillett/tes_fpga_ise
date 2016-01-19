--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: stream
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

package stream is
constant CHUNK_BITS:integer:=18;
--! Number of bits in a chunk that contain data
constant CHUNK_DATABITS:integer:=16;
--! The bit in the chunk that indicates that the chunk should be kept
--! NOTE this is assuming downto indexing -control bits are always leftmost
constant CHUNK_KEEPBIT:integer:=CHUNK_DATABITS;
--! The bit in the chunk that indicates the last chunk in the stream
--! NOTE this is assuming downto indexing -control bits are always leftmost
constant CHUNK_LASTBIT:integer:=CHUNK_DATABITS+1;
constant CHUNK_CONTROLBITS:integer:=CHUNK_BITS-CHUNK_DATABITS;

-- Was in events 
-- Number of chunks in the eventbus SEE TES.stream library
constant BUS_CHUNKS:integer:=4;
-- total bits in the bus (including control bits)
constant BUS_BITS:integer:=CHUNK_BITS*BUS_CHUNKS;
-- data only bits of the bus
constant BUS_DATABITS:integer:=CHUNK_DATABITS*BUS_CHUNKS;

subtype streamvector is std_logic_vector(BUS_BITS-1 downto 0);
type streambus is record
	keeps:boolean_vector(BUS_CHUNKS-1 downto 0);
	lasts:boolean_vector(BUS_CHUNKS-1 downto 0);
	data:std_logic_vector(BUS_DATABITS-1 downto 0);
end record;
type streambus_array is array (natural range <>) of streambus;
type streamvector_array is array (natural range <>) of streamvector;

function busLast(slv:std_logic_vector) return boolean;
function busLast(sb:streambus) return boolean;
function SwapEndianness(data:std_logic_vector) return std_logic_vector;
function SwapEndianness(data:unsigned) return std_logic_vector;
function SwapEndianness(data:signed) return std_logic_vector;
function to_streambus(slv:std_logic_vector) return streambus;
function to_streambus(sva:streamvector_array) return streambus_array;
function to_std_logic(sb:streambus) return std_logic_vector;
function to_std_logic(sba:streambus_array) return streamvector_array;
	
end package stream;

package body stream is

function to_streambus(slv:std_logic_vector) return streambus is
variable sb:streambus;
begin
	for chunk in 0 to BUS_CHUNKS-1 loop
		sb.lasts(chunk):=to_boolean(slv(chunk*CHUNK_BITS+CHUNK_LASTBIT));
		sb.keeps(chunk):=to_boolean(slv(chunk*CHUNK_BITS+CHUNK_KEEPBIT));
		sb.data(CHUNK_DATABITS*(chunk+1)-1 downto CHUNK_DATABITS*chunk):=
			slv(CHUNK_DATABITS+(CHUNK_BITS*(chunk))-1 downto CHUNK_BITS*chunk);
	end loop;
	return sb;
end function;

function to_streambus(sva:streamvector_array) return streambus_array is
variable sba:streambus_array(sva'range);
begin
	for i in sva'range loop
		sba(i):=to_streambus(sva(i));
	end loop;
	return sba;
end function;

function to_std_logic(sba:streambus_array) return streamvector_array is
variable sva:streamvector_array(sba'range);
begin
	for i in sva'range loop
		sva(i):=to_std_logic(sba(i));
	end loop;
	return sva;
end function;

function to_std_logic(sb:streambus) return std_logic_vector is
variable slv:streamvector;
begin
	for chunk in 0 to BUS_CHUNKS-1 loop
		slv(CHUNK_KEEPBIT+(CHUNK_BITS*chunk)):=to_std_logic(sb.keeps(chunk));
		slv(CHUNK_LASTBIT+(CHUNK_BITS*chunk)):=to_std_logic(sb.lasts(chunk));
		slv((CHUNK_BITS*chunk)+CHUNK_DATABITS-1 downto CHUNK_BITS*chunk):=
			sb.data(CHUNK_DATABITS+(CHUNK_DATABITS*chunk)-1 
				downto CHUNK_DATABITS*chunk
			);
	end loop;
	return slv;
end function;
	
function busLast(slv:std_logic_vector) return boolean is
variable sb:streambus;
begin
	sb:=to_streambus(slv);
  return unaryOr(sb.lasts);
end function;

function busLast(sb:streambus) return boolean is
begin
  return unaryOr(sb.lasts);
end function;

-- assumes data is a multiple of 8 bits and big endian and downto 
function SwapEndianness(data:std_logic_vector) return std_logic_vector is
variable rev:std_logic_vector(data'range);
constant BYTES:integer:=(data'high-data'low+1)/8;
begin
  for i in 0 to BYTES-1 loop
    rev(data'high-i*8 downto data'high-(i+1)*8+1)
    	:=data((i+1)*8+data'low-1 downto i*8+data'low);
  end loop; 
  if (data'length>8*BYTES) then
    rev(data'length-8*BYTES-1 downto 0):=data(data'high downto 8*BYTES);
  end if;
  return rev;
end function;

-- assumes data is a multiple of 8 bits and big endian and downto
-- returns outlength-1 downto 0 
function SwapEndianness(data:unsigned) return std_logic_vector is
begin
  return(SwapEndianness(std_logic_vector(data)));
end function;

function SwapEndianness(data:signed) return std_logic_vector is
begin
  return(SwapEndianness(std_logic_vector(data)));
end function;

end package body stream;
