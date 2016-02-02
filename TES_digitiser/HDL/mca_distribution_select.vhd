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
--
library teslib;
use teslib.types.all;
use teslib.functions.all;

use work.channel.all;
use work.mca.all;

--1 clk latency
entity mca_distribution_select is
generic (
	MEASUREMENT_BITS:integer:=MCA_VALUE_BITS;
	NUM_VALUES:integer:=NUM_MCA_VALUES;
	NUM_VALIDS:integer:=NUM_MCA_TRIGGERS
);
	
port (
  clk:in std_logic;
  reset:in std_logic;
  measurements:in channel_measurements;
  measurement_select:in std_logic_vector(NUM_VALUES-1 downto 0);
  valid_select:in std_logic_vector(NUM_VALIDS-1 downto 0);
  value:out mca_value_t;
  valid:out boolean
);
end entity mca_distribution_select;

architecture registered of mca_distribution_select is
signal values:mca_value_array(NUM_VALUES-1 downto 0);
signal unused_measurements:std_logic_vector(12-NUM_VALUES-1 downto 0)
													:=(others => '0');
signal unused_valids:std_logic_vector(12-NUM_VALIDS-1 downto 0);

type input_array is array (natural range <> ) of std_logic_vector(11 downto 0);
signal inputs:input_array(MEASUREMENT_BITS-1 downto 0);
signal valids:std_logic_vector(NUM_VALIDS-1 downto 0);
signal measurement_int:signed(MEASUREMENT_BITS-1 downto 0);
signal valid_int:std_logic;

begin

values <= get_values(measurements);

measurementMuxGen:for b in 0 to MEASUREMENT_BITS-1 generate
begin
  inputGen:for m in 0 to NUM_VALUES-1 generate
  begin
    inputs(b)(m) <= values(m)(b);
  end generate;
  
	selector:entity teslib.select_1of12
  port map(
    input => unused_measurements & inputs(b),
    sel => measurement_select,
    output => measurement_int(b)
  );
end generate;

valids <= get_valids(measurements);

validSel:entity teslib.select_1of12
port map(
  input => unused_valids & valids,
  sel => valid_select,
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
