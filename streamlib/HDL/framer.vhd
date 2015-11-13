--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:09/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: frame_to_stream
-- Project Name: channel
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
--
use work.types.all;
use work.all;

--use stream.events.all;
-- random access writes frame converted to a stream
-- uses chunk lasts to set last output
entity framer is
generic(
  BUS_CHUNKS:integer:=4;
  ADDRESS_BITS:integer:=9
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --! data chunks to write to frame 
  data:in std_logic_vector(BUS_CHUNKS*CHUNK_DATABITS-1 downto 0);
  --! frame address
  address:in unsigned(ADDRESS_BITS-1 downto 0);
  --! control bits for the dataword 
  -- FIXME: why are these SLV while chunk_we is boolean_vector?
  lasts:in std_logic_vector(BUS_CHUNKS-1 downto 0);
  keeps:in std_logic_vector(BUS_CHUNKS-1 downto 0);
  --! Chunk wise write enables
  chunk_we:in boolean_vector(BUS_CHUNKS-1 downto 0);
  wr_valid:out boolean; --Write success 1 clk after chunk_we
  -- length of frame to commit
  length:in unsigned(ADDRESS_BITS-1 downto 0);
  commit:in boolean;
  free:out unsigned(ADDRESS_BITS downto 0);
  --
  stream:out std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean
  --last:out boolean -- true if any lasts set 
);
end entity framer;
--
architecture serialiser of framer is
--
constant BUS_BITS:integer:=BUS_CHUNKS*CHUNK_BITS;
--RAM read_latency is 2 but the address increments 1clk after read_ram asserted
constant LATENCY:integer:=3; -- LATENCY for serialiser
--
subtype busword is std_logic_vector(BUS_BITS-1 downto 0);
type frame_buffer is array (0 to 2**ADDRESS_BITS-1) of busword;
signal frame_ram:frame_buffer:=(others => (others => '0'));
--signal last_int,valid_int,valid_reg,ready_int:boolean;
--signal stream_int:std_logic_vector(BUS_BITS-1 downto 0);
signal input_word,ram_dout,ram_data,ram_reg:busword;
signal we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal rd_ptr,wr_addr:unsigned(ADDRESS_BITS-1 downto 0);
signal free_ram:unsigned(ADDRESS_BITS downto 0);
signal read_ram,ram_empty,read_en:boolean;
--attribute keep:string;
--attribute keep of ram_data:signal is "TRUE";
signal wr_valid_int:boolean;
--attribute keep of wr_valid_int:signal is "TRUE";
--
begin
free <= free_ram;
wr_valid <= wr_valid_int; 
--------------------------------------------------------------------------------
-- Frame buffer
--------------------------------------------------------------------------------
-- register input and map keeps and lasts
inputReg:process(clk)
begin
if rising_edge(clk) then
  for chunk in 0 to BUS_CHUNKS-1 loop  
    input_word(chunk*CHUNK_BITS+CHUNK_DATABITS-1 downto chunk*CHUNK_BITS) <= 
      data((chunk+1)*CHUNK_DATABITS-1 downto chunk*CHUNK_DATABITS);
    input_word(chunk*CHUNK_BITS+CHUNK_KEEPBIT) <= keeps(chunk);
    input_word(chunk*CHUNK_BITS+CHUNK_LASTBIT) <= lasts(chunk);
  end loop;
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
        <= input_word((i+1)*CHUNK_BITS-1 downto i*CHUNK_BITS);
    end if;
  end loop;
end if;
end process framePortA;
framePortB:process(clk)
begin
if rising_edge(clk) then
  ram_dout <= frame_ram(to_integer(to_0IfX(rd_ptr)));
  ram_reg <= ram_dout; -- register output
end if;
end process framePortB;
ram_data <= ram_reg; --to keep name FIXME does not work
ramPointers:process(clk)
variable wr,rdNext:unsigned(ADDRESS_BITS-1 downto 0);
variable free,freeNext:unsigned(ADDRESS_BITS downto 0)
                      :=(ADDRESS_BITS => '1',others => '0');
variable empty:boolean;
variable sel:boolean_vector(1 downto 0);
begin
if rising_edge(clk) then
  if reset = '1' then
    wr_addr <= (others => '-');
    rd_ptr <= (others => '1');
    wr:=(others => '0');
    rdNext:=(others => '0');
    free:=(ADDRESS_BITS => '1',others => '0');
    freeNext:=(ADDRESS_BITS => '0',others => '1');
    free_ram <= (ADDRESS_BITS => '1',others => '0');
    ram_empty <= TRUE;
  else
    if ('0' & to_0IfX(address)) >= to_0IfX(free_ram) then
      we <= (others => FALSE);
      wr_valid_int <= FALSE;
    else
      we <= chunk_we;
      wr_valid_int <= TRUE;
    end if;
    wr_addr <= wr+address;
    empty:=free_ram(ADDRESS_BITS)='1';
    --TODO infer DSP for this adder subtractor;
    freeNext:=free_ram+1;
    sel:=(commit and (('0' & to_0IfX(length)) <= to_0IfX(free_ram))) & 
         (read_ram and not ram_empty);
    case sel is
      when (FALSE,FALSE) => free:=free_ram; 
      when (TRUE,FALSE) => free:=free_ram-length; 
      when (FALSE,TRUE) => free:=freeNext;
      when (TRUE,TRUE) => free:=freeNext-length;
    end case;
    ram_empty <= free(ADDRESS_BITS)='1';
    free_ram <= free;
    if read_ram and not ram_empty then
      rd_ptr <= rdNext;
      rdNext:=rdNext+1;
    end if;
    if commit then
      if ('0' & to_0IfX(length)) >= to_0IfX(free_ram) then
        wr_valid_int <= FALSE;
      else
        wr:=wr+length;
        wr_valid_int <= TRUE;
      end if;
    end if;
  end if;
end if;
end process ramPointers;
--------------------------------------------------------------------------------
-- Streaming interface 
--------------------------------------------------------------------------------
read_en <= not ram_empty;
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
  stream => stream,
  ready => ready,
  valid => valid,
  last => open
);
end architecture serialiser;