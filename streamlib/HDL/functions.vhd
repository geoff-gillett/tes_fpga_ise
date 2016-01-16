library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

use work.types.all;

package functions is
function getChunkLast(busword:std_logic_vector;chunk:integer) return std_logic;
--! return keep bit of chunk--indexed left to right starting at 0
function getChunkKeep(busword:std_logic_vector;chunk:integer) return std_logic;
--! return a bit field from the bus NOTE:indexing is left to right starting at 0
--! Vector of lasts for each chunk in the bus. 
function getLast(busword:std_logic_vector;chunks:integer) 
         return std_logic_vector;
function setLast(busword,last:std_logic_vector;chunks:integer) 
         return std_logic_vector;
--! Vector of keeps for each chunk in the bus. 
function getKeep(busword:std_logic_vector;chunks:integer) 
         return std_logic_vector;
function setKeep(busword,keep:std_logic_vector;chunks:integer) 
         return std_logic_vector;
--! TRUE if any last is set
function busLast(busword:std_logic_vector;chunks:integer) return boolean;
--! TRUE if any keep is set
function busKeep(busword:std_logic_vector;chunks:integer) return boolean;
	
function SetEndianness(data:std_logic_vector;endianness:string) 
         return std_logic_vector;
function SetEndianness(data:unsigned;endianness:string) 
         return std_logic_vector;
function SetEndianness(data:signed;endianness:string) 
	return std_logic_vector;

function to_streambus(slv:std_logic_vector) return streambus;
function to_std_logic(sb:streambus) return std_logic_vector;
	
end package functions;

package body functions is

function to_streambus(slv:std_logic_vector) return streambus is
variable sb:streambus;
begin
	for chunk in 0 to EVENTBUS_CHUNKS-1 loop
		sb.keeps(chunk):=slv(chunk*CHUNK_DATABITS+CHUNK_LASTBIT);
		sb.lasts(chunk):=slv(chunk*CHUNK_DATABITS+CHUNK_KEEPBIT);
		sb.data(CHUNK_DATABITS*(chunk+1)-1 downto CHUNK_DATABITS*chunk):=
			slv(CHUNK_DATABITS+(CHUNK_BITS*(chunk+1))-1 downto CHUNK_BITS*chunk);
	end loop;
	return sb;
end function;

function to_std_logic(sb:streambus) return std_logic_vector is
variable slv:std_logic_vector(CHUNK_BITS*EVENTBUS_CHUNKS-1 downto 0);
begin
	for chunk in 0 to EVENTBUS_CHUNKS-1 loop
		slv(CHUNK_KEEPBIT+(CHUNK_BITS*chunk)):=sb.keeps(chunk);
		slv(CHUNK_LASTBIT+(CHUNK_BITS*chunk)):=sb.lasts(chunk);
		slv((CHUNK_BITS*chunk)+CHUNK_DATABITS-1 downto CHUNK_BITS*chunk):=
			sb.data(CHUNK_DATABITS*(chunk+1)-1 downto CHUNK_DATABITS*chunk);
	end loop;
	return slv;
end function;

function getChunkLast(busword:std_logic_vector;chunk:integer) 
         return std_logic is
variable slv:std_logic_vector(0 to busword'length-1);
begin
  slv:=busword;
  return slv(chunk*CHUNK_BITS+(CHUNK_BITS-CHUNK_LASTBIT-1));
end function;
--chunk keep bit--chunks are indexed left to right starting at 0
function getChunkKeep(busword:std_logic_vector;chunk:integer) 
         return std_logic is
variable slv:std_logic_vector(0 to busword'length-1);
begin
  slv:=busword;
  return slv(chunk*CHUNK_BITS+(CHUNK_BITS-CHUNK_KEEPBIT-1));
end function;
--Vector of lasts for each chunk in the bus, the leftmost last bit flags the 
--leftmost chunk as last chunk in the object.
--The left most chunk appears in the stream first. 
function getLast(busword:std_logic_vector;chunks:integer) 
return std_logic_vector is
variable lasts:std_logic_vector(0 to chunks-1);
begin
  for i in 0 to chunks-1 loop
    lasts(i):=getChunkLast(busword, i);
  end loop;
  return lasts;
end function;
--
function setLast(busword,last:std_logic_vector;chunks:integer) 
         return std_logic_vector is
variable lasts:std_logic_vector(0 to chunks-1);
variable busout:std_logic_vector(0 to chunks*CHUNK_BITS-1);
begin
  lasts:=last;
  busout:=busword;
  for i in 0 to chunks-1 loop
    busout(i*CHUNK_BITS+(CHUNK_BITS-CHUNK_LASTBIT-1)):=lasts(i);
  end loop;
  return busout;
end function;
--
function setKeep(busword,keep:std_logic_vector;chunks:integer) 
         return std_logic_vector is
variable keeps:std_logic_vector(0 to chunks-1);
variable busout:std_logic_vector(0 to chunks*CHUNK_BITS-1);
begin
  keeps:=keep;
  busout:=busword;
  for i in 0 to chunks-1 loop
    busout(i*CHUNK_BITS+(CHUNK_BITS-CHUNK_KEEPBIT-1)):=keeps(i);
  end loop;
  return busout;
end function;
-- Vector of keeps for each chunk in the bus. 
function getKeep(busword:std_logic_vector;chunks:integer) 
return std_logic_vector is
variable keeps:std_logic_vector(0 to chunks-1);
begin
  for i in 0 to chunks-1 loop
    keeps(i):=getChunkKeep(busword,i);
  end loop;
  return keeps;
end function;
--TRUE if any keep is set
function busKeep(busword:std_logic_vector;chunks:integer) return boolean is
begin
  return unaryOr(getKeep(busword,chunks));
end function;
--TRUE if any last is set
function busLast(busword:std_logic_vector;chunks:integer) return boolean is
begin
  return unaryOr(getLast(busword,chunks));
end function;

-- assumes data is a multiple of 8 bits and big endian and downto 
function SetEndianness(data:std_logic_vector;endianness:string) 
return std_logic_vector is
variable dataLE:std_logic_vector(data'range);
constant BYTES:integer:=(data'high-data'low+1)/8;
begin
  if endianness="LITTLE" then
    for i in 0 to BYTES-1 loop
      dataLE(data'high-i*8 downto data'high-(i+1)*8+1)
            := data((i+1)*8+data'low-1 downto i*8+data'low);
    end loop; 
    if (data'length>8*BYTES) then
      dataLE(data'length-8*BYTES-1 downto 0):=data(data'high downto 8*BYTES);
    end if;
    return dataLE;
  else
    return data;
  end if;
end function;
-- assumes data is a multiple of 8 bits and big endian and downto
-- returns outlength-1 downto 0 
function SetEndianness(data:unsigned;endianness:string) 
return std_logic_vector is
begin
  return(SetEndianness(std_logic_vector(data),endianness));
end function;
function SetEndianness(data:signed;endianness:string) 
return std_logic_vector is
begin
  return(SetEndianness(std_logic_vector(data),endianness));
end function;

end package body functions;
