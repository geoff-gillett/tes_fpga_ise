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
  data:in streambus_t;
  --! frame address
  address:in unsigned(ADDRESS_BITS-1 downto 0);
  chunk_we:in boolean_vector(BUS_CHUNKS-1 downto 0);
  length:in unsigned(ADDRESS_BITS downto 0);
  commit:in boolean;
  free:out unsigned(ADDRESS_BITS downto 0);
  --
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
  --last:out boolean -- true if any lasts set 
);
end entity framer;

architecture SDP of framer is
--
--RAM read_latency is 2 but the address increments 1clk after read_ram asserted
constant LATENCY:integer:=2; -- LATENCY for serialiser
--
type frame_buffer is array (0 to 2**ADDRESS_BITS-1) of streamvector_t;
signal frame_ram:frame_buffer:=(others => (others => '0'));
signal input_word,ram_dout,ram_data,stream_vector:streamvector_t;
signal we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal rd_ptr,rd_ptr_next,wr_addr,wr_ptr:unsigned(ADDRESS_BITS downto 0);
signal free_ram,free_ram_next:unsigned(ADDRESS_BITS downto 0);
signal read_ram,read_en,read:boolean;
signal empty:boolean;
signal xor_ptr_msb,xor_ptr_msb_next:std_logic;
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
      frame_ram(to_integer(to_0IfX(wr_addr(ADDRESS_BITS-1 downto 0)))) 
      		((i+1)*CHUNK_BITS-1 downto i*CHUNK_BITS)
         <= input_word((i+1)*CHUNK_BITS-1 downto i*CHUNK_BITS);
    end if;
  end loop;
	ram_dout <= frame_ram(to_integer(to_0IfX(rd_ptr(ADDRESS_BITS-1 downto 0))));
  ram_data <= ram_dout; -- register output
end if;
end process framePortA;

--framePortB:process(clk)
--begin
--if rising_edge(clk) then
--	ram_dout <= frame_ram(to_integer(to_0IfX(rd_ptr)));
--	if read_en and read_ram then
--		frame_ram(to_integer(to_0Ifx(rd_ptr))):=(others => '0');
--	end if;
--  ram_data <= ram_dout; -- register output
--end if;
--end process framePortB;

xor_ptr_msb <= rd_ptr(ADDRESS_BITS) xor wr_ptr(ADDRESS_BITS);
xor_ptr_msb_next <= rd_ptr_next(ADDRESS_BITS) xor wr_ptr(ADDRESS_BITS);
ramPointers:process(clk)
--variable empty:boolean;
begin
if rising_edge(clk) then
  if reset = '1' then
    wr_addr <= (others => '-');
    rd_ptr <= (ADDRESS_BITS => '1', others => '0');
    rd_ptr_next(ADDRESS_BITS) <= '1';
    rd_ptr_next(ADDRESS_BITS-1 downto 0) <= (0 => '1',  others => '0');
    wr_ptr <= (others => '0');
    free_ram <= (ADDRESS_BITS => '1', others => '0');
    free_ram_next(ADDRESS_BITS) <= '1';
    free_ram_next(ADDRESS_BITS-1 downto 0) <= (0 => '1', others => '0');
    empty <= TRUE;
  else
  	--FIXME check removed to improve timing score	
--    if to_0ifX(free_ram) > ('0' & to_0IfX(address)) then
      we <= chunk_we;
--    else
--      we <= (others => FALSE);
--    end if;
    wr_addr <= wr_ptr + address;
    
    if commit then 
      if to_0IfX(length) <= to_0IfX(free_ram) then
      	wr_ptr <= wr_ptr + length; --only place wr_ptr can change
      	if read then
      		free_ram <= free_ram - length + 1;
      	else
      		free_ram <= free_ram - length;
      	end if;
      end if;
   	else
   		if read then
	    	free_ram <= rd_ptr_next - wr_ptr;
	    else
	    	free_ram <= rd_ptr - wr_ptr;
	    end if;
    end if;
    
    if read then
      empty <= rd_ptr_next(ADDRESS_BITS-1 downto 0) = 
               wr_ptr(ADDRESS_BITS-1 downto 0) and xor_ptr_msb_next='1';
      rd_ptr <= rd_ptr_next;
      rd_ptr_next <= rd_ptr_next + 1;
    else
      empty <= rd_ptr(ADDRESS_BITS-1 downto 0) = wr_ptr(ADDRESS_BITS-1 downto 0) 
      				 and xor_ptr_msb='1'; 
    end if;
  end if;
end if;
end process ramPointers;

--------------------------------------------------------------------------------
-- Streaming interface 
--------------------------------------------------------------------------------
read_en <= not empty;
read <= read_en and read_ram; 
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
end architecture SDP;