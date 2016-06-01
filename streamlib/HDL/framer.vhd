--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:09/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: stream_framer_TDP arch
-- Project Name: streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;

--use stream.events.all;
-- random access writes frame converted to a stream
-- uses chunk lasts to set last output
--
entity framer is
generic(
  BUS_CHUNKS:integer:=4;
  ADDRESS_BITS:integer:=10
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --! data chunks to write to frame 
  data:streambus_t;
  --! frame address
  address:in unsigned(ADDRESS_BITS-1 downto 0);
  chunk_we:in boolean_vector(BUS_CHUNKS-1 downto 0);
  length:in unsigned(ADDRESS_BITS-1 downto 0);
  commit:in boolean;
  free:out unsigned(ADDRESS_BITS-1 downto 0);
  --
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
  --last:out boolean -- true if any lasts set 
);
end entity framer;
architecture TDP of framer is
--
--RAM read_latency is 2 but the address increments 1clk after read_ram asserted
constant LATENCY:integer:=2; -- LATENCY for serialiser
--
type frame_buffer is array (0 to 2**ADDRESS_BITS-1) of streamvector_t;
shared variable frame_ram:frame_buffer:=(others => (others => '0'));
signal input_word,ram_dout,ram_data,stream_vector:streamvector_t;
signal we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal rd_ptr,wr_addr,wr_ptr,wr_ptr_1:unsigned(ADDRESS_BITS-1 downto 0);
signal free_ram:unsigned(ADDRESS_BITS-1 downto 0);
signal read_ram,read_en:boolean;
signal empty:boolean;
--signal wr_valid_int:boolean;
begin
free <= free_ram;
--success <= wr_valid_int; 
--------------------------------------------------------------------------------
-- Frame buffer
--------------------------------------------------------------------------------
-- register input and map keeps and lasts
inputReg:process(clk)
begin
if rising_edge(clk) then
	input_word <=to_std_logic(data);
end if; 
end process inputReg;
--------------------------------------------------------------------------------
-- RAM 
--------------------------------------------------------------------------------
framePortA:process(clk)
begin
if rising_edge(clk) then
  for i in 0 to BUS_CHUNKS-1 loop
    if we(i) then
      frame_ram(to_integer(to_0IfX(wr_addr))) 
      		((i+1)*CHUNK_BITS-1 downto i*CHUNK_BITS)
        :=input_word((i+1)*CHUNK_BITS-1 downto i*CHUNK_BITS);
    end if;
  end loop;
end if;
end process framePortA;

framePortB:process(clk)
begin
if rising_edge(clk) then
	ram_dout <= frame_ram(to_integer(to_0IfX(rd_ptr)));
	if read_en and read_ram then
		frame_ram(to_integer(to_0Ifx(rd_ptr))):=(others => '0');
	end if;
  ram_data <= ram_dout; -- register output
end if;
end process framePortB;

ramPointers:process(clk)
--variable empty:boolean;
begin
if rising_edge(clk) then
  if reset = '1' then
    wr_addr <= (others => '-');
    rd_ptr <= (others => '0');
    wr_ptr <= (others => '0');
    wr_ptr_1 <= (others => '1');
    free_ram <= (others => '1');
  else
  	
    if to_0ifX(free_ram) > ('0' & to_0IfX(address)) then
      we <= chunk_we;
    else
      we <= (others => FALSE);
    end if;
    wr_addr <= wr_ptr + address;
    
    free_ram <= rd_ptr-wr_ptr-1;
    if commit then 
      if ('0' & to_0IfX(length)) <= to_0IfX(free_ram) then
      	wr_ptr <= wr_ptr + length;
      	wr_ptr_1 <= wr_ptr_1 + length;
      	--free_ram <= free_ram - length + to_unsigned(read_en and read_ram);
      end if;
    end if;
    
    if not empty and read_ram then
    	empty <= rd_ptr = wr_ptr_1;
    	rd_ptr <= rd_ptr + 1;
    else
    	empty <= rd_ptr = wr_ptr;
    end if;
  end if;
end if;
end process ramPointers;

--------------------------------------------------------------------------------
-- Streaming interface 
--------------------------------------------------------------------------------
read_en <= not empty;
serialiser:entity work.serialiser
generic map(
  LATENCY => LATENCY,
  DATA_BITS => BUS_BITS
)
port map(
  clk => clk,
  reset => reset,
  read => read_ram,
  read_en => read_en,
  last_read => FALSE,
  data => ram_data, 
  stream => stream_vector,
  ready => ready,
  valid => valid,
  last => open
);
stream <= to_streambus(stream_vector);
end architecture TDP;