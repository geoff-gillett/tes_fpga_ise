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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--use work.protocol.all;
use work.registers.all;
use work.measurements.all;
use work.types.all;
use work.functions.all;

entity mca_channel_selector is
generic (
	CHANNELS:integer:=8;
	VALUE_BITS:integer:=MCA_VALUE_BITS
);
port (
  clk:in std_logic;
  reset:in std_logic;
	channel_select:in std_logic_vector(CHANNELS-1 downto 0);
	values:in mca_value_array(CHANNELS-1 downto 0);
	valids:in boolean_vector(CHANNELS-1 downto 0);
	value:out signed(VALUE_BITS-1 downto 0);
	valid:out boolean
);
end entity mca_channel_selector;

architecture RTL of mca_channel_selector is
type input_array is array (natural range <>) of std_logic_vector(11 downto 0);
signal inputs:input_array(MCA_VALUE_BITS-1 downto 0);
signal valid_int:std_logic;
signal value_int:signed(VALUE_BITS-1 downto 0);
signal sel,valids_int:std_logic_vector(11 downto 0);

begin

sel <= resize(channel_select, 12);
valueMuxGen:for b in 0 to MCA_VALUE_BITS-1 generate
begin
	inputGen:for c in 0 to CHANNELS-1 generate
	begin
		inputs(b)(c) <= values(c)(b);
	end generate;
	selector:entity work.select_1of12
		port map(
			input => inputs(b),
			sel => sel,
			output => value_int(b)
		);
end generate;

valids_int <= resize(to_std_logic(valids), 12);
validSelector:entity work.select_1of12
port map(
  input => valids_int,
  sel => sel,
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
