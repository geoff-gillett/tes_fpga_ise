--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:2 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: axi_adapter
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

use work.stream.all;
-- resizes an input axi stream to streambus_t
-- initial version only works with AXI_CHUNKS = 2 and BUS_CHUNKS = 4
-- for converting the mca stream to streambus_t;
-- TODO generalise
entity axi_adapter is
generic(
	AXI_CHUNKS:integer:=2
);
port (
  clk:in std_logic;
  reset:in std_logic;
  -- input axi stream
  axi_stream:in std_logic_vector(AXI_CHUNKS*CHUNK_DATABITS-1 downto 0);
  axi_valid:in boolean;
  axi_ready:out boolean;
  axi_last:in boolean;
  --
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity axi_adapter;

architecture RTL of axi_adapter is
constant NUM_BLOCKS:integer:=BUS_CHUNKS/AXI_CHUNKS;

signal block_count:integer range 0 to NUM_BLOCKS-1;
--signal streambus_ready,streambus_valid:boolean;
signal axi_handshake,axi_ready_int,axi_valid_int,axi_last_int:boolean;
--signal streambus_handshake:boolean;

subtype axi_block is std_logic_vector(AXI_CHUNKS*CHUNK_BITS-1 downto 0);
type block_array is array (natural range <>) of axi_block;
signal blocks:block_array(0 to NUM_BLOCKS-1);
signal last_block,full:boolean;
signal streamvector:streamvector_t;
signal streamvector_valid,streamvector_handshake:boolean;

function to_streamvector(ba:block_array) return streamvector_t is
variable sv:streamvector_t;
constant BLOCK_BITS:integer:=ba(0)'length;
begin
	for b in 0 to ba'high loop
		sv(((b+1)*BLOCK_BITS)-1 downto b*BLOCK_BITS):=ba(b);
	end loop;
	return sv;
end function;

constant INPUT_WIDTH:integer:=AXI_CHUNKS*CHUNK_DATABITS+1; 
signal stream_in,axi_stream_reg:std_logic_vector(INPUT_WIDTH-1 downto 0);
signal axi_stream_int:std_logic_vector(INPUT_WIDTH-2 downto 0);
signal blocks_valid:boolean;

begin
	
-- input register slice to break ready combinatorial path
stream_in <= to_std_logic(axi_last) & axi_stream;
inputReg:entity work.register_slice
generic map(
  WIDTH => AXI_CHUNKS*CHUNK_DATABITS+1
)
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_in,
  ready_out => axi_ready,
  valid_in => axi_valid,
  stream => axi_stream_reg,
  ready => axi_ready_int,
  valid => axi_valid_int
);
axi_stream_int <= axi_stream_reg(INPUT_WIDTH-2 downto 0);
axi_last_int <= to_boolean(axi_stream_reg(INPUT_WIDTH-1));

axi_handshake <= axi_valid_int and axi_ready_int;
streamvector_handshake <= ready and streamvector_valid;
last_block <= block_count=0;
--streambus_handshake <= ready and streambus_valid;	
--full <= state=REGISTERS_FULL;
axi_ready_int <= not full;	


outputReg:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			block_count <= NUM_BLOCKS-1;	
		else
      if axi_handshake then
        if last_block then
          block_count <= NUM_BLOCKS-1;
          blocks_valid <= TRUE;
          full <= streamvector_valid;
        else
          blocks_valid <= FALSE;
          block_count <= block_count-1;
        end if;
        blocks(block_count) <= to_chunks(axi_stream_int,axi_last_int);
      end if;
      if streamvector_handshake then
				full <= FALSE;
      end if;
			if blocks_valid and not (streamvector_valid and not ready) then
				streamvector_valid <= TRUE;
				streamvector <= to_streamvector(blocks);
			elsif streamvector_handshake then
				streamvector_valid <= FALSE;
			end if;	
		end if;
	end if;
end process outputReg;

stream <= to_streambus(streamvector);
valid <= streamvector_valid;
--valid <= streambus_valid;

end architecture RTL;
