--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:03/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: moving_average
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
use work.types.all;
use work.functions.all;
--------------------------------------------------------------------------------
--! ring buffer single clock domain 
--! max delay is 2**address_bits
--------------------------------------------------------------------------------
--FIXME use CE in series 7 part
entity ring_buffer is
generic(
  ADDRESS_BITS:integer:=6; --max ring size 2**ADDRESS_BITS
  DATA_BITS:integer:=14
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  data_in:in std_logic_vector(DATA_BITS-1 downto 0);
  wr_en:in boolean; 
  delay:in unsigned(ADDRESS_BITS downto 0);
  delay_updated:in boolean;
  --! data_in with ring LATENCY
  zerodelay:out std_logic_vector(DATA_BITS-1 downto 0); 
  delayed:out std_logic_vector(DATA_BITS-1 downto 0);
  newvalue:out boolean;
  valid:out boolean
);
end entity ring_buffer;
--
architecture ram of ring_buffer is
-- ram signals
subtype word is std_logic_vector(DATA_BITS-1 downto 0);
type ram is array (0 to 2**ADDRESS_BITS-1) of word;
signal ring:ram:=(others => (others => '0'));
--
signal ring_addr,delay_addr:unsigned(ADDRESS_BITS-1 downto 0);
signal reset_count:unsigned(ADDRESS_BITS downto 0);
signal data_out_int,data_out,zerodelay_int
       :std_logic_vector(DATA_BITS-1 downto 0):=(others => '0');
signal data_in_reg:std_logic_vector(DATA_BITS-1 downto 0):=(others => '0');
signal valid_reg,newvalue_reg,newvalue_int:boolean;
begin
valid <= valid_reg;
-- infer RAM
ramInstance:process(clk)
begin
if rising_edge(clk) then
  data_out_int <= ring(to_integer(to_0IfX(ring_addr(ADDRESS_BITS-1 downto 0))));
  if wr_en then
    ring(to_integer(to_0IfX(delay_addr(ADDRESS_BITS-1 downto 0)))) <= data_in;
  end if;
  data_out <= data_out_int; --absorbed into RAM
end if;
end process ramInstance;
inputReg:process(clk)
begin
if rising_edge(clk) then
  zerodelay_int <= data_in_reg;
  zerodelay <= zerodelay_int;
  if wr_en then
    data_in_reg <= data_in;
  end if;
  if delay=0 then -- this could be a combinatorial mux
    delayed <= zerodelay_int;
  else
    delayed <= data_out;
  end if;
end if;
end process inputReg;
addrCount:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    ring_addr <= (others => '0');
    delay_addr <= delay(ADDRESS_BITS-1 downto 0);
  else
    if wr_en then
      ring_addr <= ring_addr+1;
      delay_addr <= ring_addr+delay(ADDRESS_BITS-1 downto 0)+1;
    end if;
  end if;
end if;
end process addrCount;
validCount:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    reset_count <= delay+2;
    valid_reg <= FALSE;
    newvalue <= FALSE;
    newvalue_int <= FALSE;
    newvalue_reg <= FALSE;
  else
    newvalue_reg <= wr_en;
    newvalue_int <= newvalue_reg;
    newvalue <= newvalue_int;
    if delay_updated then
      reset_count <= delay+2;
      valid_reg <= FALSE;
    elsif to_0IfX(reset_count)/=0 and wr_en then
      valid_reg <= FALSE;
      reset_count <= reset_count-1;
    elsif wr_en then
      valid_reg <= TRUE;
    end if;
  end if;
end if;
end process validCount;
end architecture ram;
