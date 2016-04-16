--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/01/2014 
--
-- Design Name: TES_digitiser
-- Module Name: channel_register_block
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
--
use work.KCPSM6_AXI.all;
--
entity register_IO_block is
port(
  clk:in std_logic; --IO_clk
  --!* byte wise register signals from/to channel CPU
  byte_in:in std_logic_vector(7 downto 0);
  byte_out:out std_logic_vector(7 downto 0);
  -- strobes
  byte_select:in std_logic_vector(3 downto 0);
  -- strobes
  address_wr:in boolean;
  data_wr:in boolean;
  --  
  address:out register_address_t;
  data:out register_data_t;
  -- current register data for address
  read_data:in register_data_t
);
end entity register_IO_block;
--
architecture RTL of register_IO_block is
  
signal address_int:register_address_t;
signal data_int:register_data_t;
begin 
address <= address_int;
data <= data_int;  
-- output byte mux
  with byte_select select byte_out <= 
    read_data(7 downto 0)  when "0001",
    read_data(15 downto 8) when "0010",
    read_data(23 downto 16) when "0100",
    read_data(31 downto 24) when "1000",
    (others => '-') when others;
--
writeToRegister:process(clk)
begin
if rising_edge(clk) then
  case byte_select is
  when "0001" => 
    if address_wr then
      address_int(7 downto 0) <= byte_in;
    end if;
    if data_wr then
      data_int(7 downto 0) <= byte_in;
    end if;
  when "0010" => 
    if address_wr then
      address_int(15 downto 8) <= byte_in;
    end if;
    if data_wr then
      data_int(15 downto 8) <= byte_in;
    end if;
  when "0100" => 
    if address_wr then
      address_int(23 downto 16) <= byte_in;
    end if;
    if data_wr then
      data_int(23 downto 16) <= byte_in;
    end if;
  when "1000" => 
    if data_wr then
      data_int(31 downto 24) <= byte_in;
    end if;
  when others => 
    null;
  end case;
end if;
end process writeToRegister;
end architecture RTL;
