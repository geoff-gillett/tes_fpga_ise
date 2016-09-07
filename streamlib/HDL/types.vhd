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
library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--TODO add adapter that outputs a chunk stream and removes chunks with keep_n

package types is
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

--TODO generalise -- remove BUS_CHUNKS and add parameter to functions.
constant BUS_CHUNKS:integer:=4;
-- total bits in the bus (including control bits)
constant BUS_BITS:integer:=CHUNK_BITS*BUS_CHUNKS;
-- data only bits of the bus
constant BUS_DATABITS:integer:=CHUNK_DATABITS*BUS_CHUNKS;

--TODO remove these discard a last subtypes
subtype streambus_discard_t is boolean_vector(BUS_CHUNKS-1 downto 0);
subtype streambus_last_t is boolean_vector(BUS_CHUNKS-1 downto 0);

subtype streamvector_t is std_logic_vector(BUS_BITS-1 downto 0);
type streambus_t is record
	discard:boolean_vector(BUS_CHUNKS-1 downto 0); -- keep chunk if set to 0
	last:boolean_vector(BUS_CHUNKS-1 downto 0); -- end of frame
	data:std_logic_vector(BUS_DATABITS-1 downto 0);
end record;
type streambus_array is array (natural range <>) of streambus_t;
type streamvector_array is array (natural range <>) of streamvector_t;
subtype datachunk_t is std_logic_vector(CHUNK_DATABITS-1 downto 0);
type datachunk_array_t is array (natural range <>) of datachunk_t;

function busLast(slv:std_logic_vector) return boolean;
function busLast(sb:streambus_t) return boolean;
function SwapEndianness(data:std_logic_vector) return std_logic_vector;
function SwapEndianness(data:unsigned) return std_logic_vector;
function SwapEndianness(data:signed) return std_logic_vector;
function set_endianness(d:std_logic_vector;e:string) return std_logic_vector;
function set_endianness(u:unsigned;e:string) return std_logic_vector;
function set_endianness(s:signed;e:string) return std_logic_vector;
function SetEndianness(sb:streambus_t;e:string) return streambus_t;
function to_streambus(slv:std_logic_vector) return streambus_t;
function to_streambus(sva:streamvector_array) return streambus_array;
function to_streambus(chunks:datachunk_array_t;k:streambus_discard_t;
											l:streambus_last_t) return streambus_t;
function to_streambus(data:std_logic_vector;k:streambus_discard_t;
											l:streambus_last_t) return streambus_t;
function to_std_logic(sb:streambus_t) return std_logic_vector;
function to_std_logic(sba:streambus_array) return streamvector_array;
--function to_datachunks(bd:streambus_t) return datachunk_array;
function to_chunks(slv:std_logic_vector;last:boolean) return std_logic_vector;
	
end package types;

package body types is

function to_streambus(slv:std_logic_vector) return streambus_t is
variable sb:streambus_t;
begin
	for chunk in 0 to BUS_CHUNKS-1 loop
		sb.last(chunk):=to_boolean(slv(chunk*CHUNK_BITS+CHUNK_LASTBIT));
		sb.discard(chunk):=to_boolean(slv(chunk*CHUNK_BITS+CHUNK_KEEPBIT));
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

function to_streambus(chunks:datachunk_array_t;k:streambus_discard_t;
											l:streambus_last_t) return streambus_t is
variable sb:streambus_t;
begin
	sb.data:=chunks(0) & chunks(1) & chunks(2) & chunks(3);
	sb.discard:=k;
	sb.last:=l;
	return sb;
end function;
	
function to_streambus(data:std_logic_vector;k:streambus_discard_t;
											l:streambus_last_t) return streambus_t is
variable sb:streambus_t;
begin
	sb.data:=data;
	sb.discard:=k;
	sb.last:=l;
	return sb;
end function;
	
function to_std_logic(sba:streambus_array) return streamvector_array is
variable sva:streamvector_array(sba'range);
begin
	for i in sva'range loop
		sva(i):=to_std_logic(sba(i));
	end loop;
	return sva;
end function;

function to_std_logic(sb:streambus_t) return std_logic_vector is
variable slv:streamvector_t;
begin
	for chunk in 0 to BUS_CHUNKS-1 loop
		slv(CHUNK_KEEPBIT+(CHUNK_BITS*chunk)):=to_std_logic(sb.discard(chunk));
		slv(CHUNK_LASTBIT+(CHUNK_BITS*chunk)):=to_std_logic(sb.last(chunk));
		slv((CHUNK_BITS*chunk)+CHUNK_DATABITS-1 downto CHUNK_BITS*chunk):=
			sb.data(CHUNK_DATABITS+(CHUNK_DATABITS*chunk)-1 
				downto CHUNK_DATABITS*chunk
			);
	end loop;
	return slv;
end function;
	
function to_chunks(slv:std_logic_vector;last:boolean) return std_logic_vector is 
	constant CHUNKS:integer:=slv'length/CHUNK_DATABITS;
	variable output:std_logic_vector(CHUNKS*CHUNK_BITS-1 downto 0);
begin
	for c in 0 to CHUNKS-1 loop
		if c = 0 then
      output((c+1)*CHUNK_BITS-1 downto c*CHUNK_BITS) 
        := to_std_logic(last) & '0' &
        	 slv((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS);
    else
      output((c+1)*CHUNK_BITS-1 downto c*CHUNK_BITS) 
        := '0' & '0' & 
        	 slv((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS);
    end if;
	end loop;
	return output;
end function;
	
function busLast(slv:std_logic_vector) return boolean is
variable sb:streambus_t;
begin
	sb:=to_streambus(slv);
  return unaryOr(sb.last);
end function;

function busLast(sb:streambus_t) return boolean is
begin
  return unaryOr(sb.last);
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

function set_endianness(d:std_logic_vector;e:string) return std_logic_vector is
begin
	if e="LITTLE" then
		return SwapEndianness(d);
	else
		return d;
	end if;
end function;

function set_endianness(u:unsigned;e:string) return std_logic_vector is
begin
	if e="LITTLE" then
		return SwapEndianness(to_std_logic(u));
	else
		return to_std_logic(u);
	end if;
end function;

function set_endianness(s:signed;e:string) return std_logic_vector is
begin
	if e="LITTLE" then
		return SwapEndianness(to_std_logic(s));
	else
		return to_std_logic(s);
	end if;
end function;

function SetEndianness(sb:streambus_t;e:string) return streambus_t is
variable o:streambus_t;
begin
	if e="LITTLE" then
		o.discard := sb.discard; 
		o.last := sb.last;
		o.data := SwapEndianness(sb.data);
		return o;
	else 
		return sb;
	end if;
end function;

end package body types;
