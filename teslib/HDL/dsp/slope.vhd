--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:10/01/2014 
--
-- Design Name: TES_digitiser
-- Module Name: sample_history
-- Project Name: channel
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
use work.functions.all;

entity slope is
generic(
  ADDRESS_BITS:integer:=6;
  DATA_BITS:integer:=14
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  data:signed(DATA_BITS-1 downto 0);
  slope_n:in unsigned(ceilLog2(ADDRESS_BITS) downto 0); --difference over 2^n
  slope_n_updated:in boolean;
  --
  slope_y:out signed(DATA_BITS-1 downto 0);
  slope:out signed(DATA_BITS-1 downto 0);
  valid:out boolean
);
end entity slope;
--

architecture ring_buffer of slope is
--
signal slope_y_int:signed(DATA_BITS-1 downto 0);
signal delay:unsigned(ADDRESS_BITS downto 0);
signal current:std_logic_vector(DATA_BITS-1 downto 0);
signal delayed:std_logic_vector(DATA_BITS-1 downto 0);
signal valid_int,valid_reg:boolean;
--
begin
delay <= shift_left(to_unsigned(1,ADDRESS_BITS+1),to_integer(slope_n));
--
outputReg:process (clk) is
begin
if rising_edge(clk) then
  slope_y_int <= signed(current)-signed(delayed);
  slope_y <= slope_y_int;
  slope <= shift_right(slope_y_int,to_integer(slope_n));
  valid_reg <= valid_int;
  valid <= valid_reg;
end if;
end process outputReg;
--FIXME use dual port ring
slopeBuffer:entity work.ring_buffer
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  DATA_BITS => DATA_BITS
)
port map(
  clk => clk,
  reset => reset,
  data_in => to_std_logic(data),
  wr_en => TRUE,
  delay => delay,
  delay_updated => slope_n_updated,
  zerodelay => current,
  delayed => delayed,
  newvalue => open,
  valid => valid_int
);
end architecture ring_buffer;
