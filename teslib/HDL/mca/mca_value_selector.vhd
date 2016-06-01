--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:29 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: distribution_select
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

use work.types.all;
use work.functions.all;
--use work.protocol.all;
use work.registers.all;
use work.measurements.all;

--1 clk latency
entity mca_value_selector is
generic (
	VALUE_BITS:integer:=MCA_VALUE_BITS;
	NUM_VALUES:integer:=NUM_MCA_VALUE_D;
	NUM_VALIDS:integer:=NUM_MCA_TRIGGER_D-1
);
	
port (
  clk:in std_logic;
  reset:in std_logic;
  measurements:in measurement_t;
  value_select:in std_logic_vector(NUM_VALUES-1 downto 0);
  trigger_select:in std_logic_vector(NUM_VALIDS-1 downto 0);
  value:out signed(MCA_VALUE_BITS-1 downto 0);
  valid:out boolean
);
end entity mca_value_selector;

architecture registered of mca_value_selector is
signal values:mca_value_array(NUM_VALUES-1 downto 0);
type input_array is array (natural range <> ) of std_logic_vector(11 downto 0);
signal inputs:input_array(VALUE_BITS-1 downto 0);
signal valids:std_logic_vector(NUM_VALIDS-1 downto 0);
signal measurement_int:signed(VALUE_BITS-1 downto 0);
signal valid_int:std_logic;

begin

values <= get_mca_values(measurements);

measurementMuxGen:for b in 0 to VALUE_BITS-1 generate
begin
  inputGen:for m in 0 to NUM_VALUES-1 generate
  begin
    inputs(b)(m) <= values(m)(b);
  end generate;
  
	selector:entity work.select_1of12
  port map(
    input => inputs(b),
    sel => resize(value_select, 12),
    output => measurement_int(b)
  );
end generate;

valids <= get_mca_triggers(measurements);

validSel:entity work.select_1of12
port map(
  input => resize(valids, 12),
  sel => resize(trigger_select, 12),
  output => valid_int
);

outputReg:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			valid <= FALSE;
		else
			valid <= to_boolean(valid_int);
			value <= measurement_int;
		end if;
	end if;
end process outputReg;

end architecture registered;
