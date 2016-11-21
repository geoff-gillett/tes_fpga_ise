--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:9 Oct 2016
--
-- Design Name: TES_digitiser
-- Module Name: mca_bin_map
-- Project Name: mca
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mca_bin_map is
generic(
  VALUE_BITS:natural:=32;
  ADDRESS_BITS:natural:=4
);
port (
  clk:in std_logic;
  reset:in std_logic;
  last_bin:unsigned(ADDRESS_BITS-1 downto 0); -- last bin is 2**hist_nm1-1
  bin_n:in natural range 0 to ADDRESS_BITS-1; --width 2**bin_n
  lowest_value:in signed(VALUE_BITS-1 downto 0);
  value:in signed(VALUE_BITS-1 downto 0);
  bin:out unsigned(ADDRESS_BITS-1 downto 0)
);
end entity mca_bin_map;

architecture RTL of mca_bin_map is
  
signal low:signed(VALUE_BITS-1 downto 0);
signal offset:signed(VALUE_BITS-1 downto 0);
signal offset_value:std_logic_vector(VALUE_BITS-1 downto 0);
signal bin_int:std_logic_vector(ADDRESS_BITS-1 downto 0);
signal msb:natural range 0 to VALUE_BITS;
signal point:natural range 0 to VALUE_BITS;
  
begin
  
valueOffset:process (clk)
begin
  if rising_edge(clk) then
    
    last_bin <= unsigned(to_stdlogicvector(BINONE sla last_bin));
    offset <= low-lowest_value+bin_n; --FIXME this is a problem implement in DSP
    offset_value <= std_logic_vector(value-lowest_value);
    point <= bin_n;
    msb <= last_bin;
    bin <= unsigned(
      resize(signed(bin_int),ADDRESS_BITS)-resize(low,ADDRESS_BITS)
    );
  end if;
end process valueOffset;

binWidth:entity work.dynamic_round
generic map(
  WIDTH_IN => VALUE_BITS,
  WIDTH_OUT => ADDRESS_BITS,
  TOWARDS_INF => FALSE
)
port map(
  clk => clk,
  reset => reset,
  msb => msb,
  point => point,
  input => offset_value,
  output => bin_int
);
end architecture RTL;
