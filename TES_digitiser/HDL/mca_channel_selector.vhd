--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:30 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: mca_channel_select
-- Project Name: TES_digitiser
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

use work.protocol.all;
use work.registers.all;
use work.measurements.all;

entity mca_channel_selector is
generic (
	CHANNEL_BITS:integer:=3;
	VALUE_BITS:integer:=MCA_VALUE_BITS
);
port (
  clk:in std_logic;
  reset:in std_logic;
	channel_select:in std_logic_vector(2**CHANNEL_BITS-1 downto 0);
	values:in mca_value_array(2**CHANNEL_BITS-1 downto 0);
	valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
	value:out signed(VALUE_BITS-1 downto 0);
	valid:out boolean
);
end entity mca_channel_selector;

architecture RTL of mca_channel_selector is
constant CHANNELS:integer:= 2**CHANNEL_BITS;	
type input_array is array (natural range <>) 
										of std_logic_vector(CHANNELS-1 downto 0);
signal inputs:input_array(MCA_VALUE_BITS-1 downto 0);
signal unused:std_logic_vector(12-CHANNELS-1 downto 0):=(others => '0');
signal valid_int:std_logic;
signal value_int:signed(VALUE_BITS-1 downto 0);

begin
	
valueMuxGen:for b in 0 to MCA_VALUE_BITS-1 generate
begin
	inputGen:for c in 0 to CHANNELS-1 generate
	begin
		inputs(b)(c) <= values(c)(b);
	end generate;
	selector:entity teslib.select_1of12
		port map(
			input => unused & inputs(b),
			sel => unused & channel_select,
			output => value_int(b)
		);
end generate;

validSelector:entity teslib.select_1of12
port map(
  input => unused & to_std_logic(valids),
  sel => unused & channel_select,
  output => valid_int
);

outputReg:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			valid <= FALSE;
		else
			valid <= to_boolean(valid_int);
			value <= value_int;
		end if;
	end if;
end process outputReg;


end architecture RTL;
