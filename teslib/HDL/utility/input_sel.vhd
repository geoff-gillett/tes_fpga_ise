--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:1 Jun 2016
--
-- Design Name: TES_digitiser
-- Module Name: input_sel
-- Project Name: teslib
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
use work.adc.all;

entity input_sel is
generic(
	CHANNELS:integer:=8;
	PIPE_DEPTH:integer:=2
);
port (
  clk:in std_logic;
  reset:in std_logic;
  inputs:in adc_sample_array(CHANNELS-1 downto 0);
  sel:in std_logic_vector(CHANNELS-1 downto 0);
  output:out adc_sample_t
);
end entity input_sel;

architecture RTL of input_sel is
type input_bits is array (ADC_BITS-1 downto 0) of 
	std_logic_vector(CHANNELS-1 downto 0);
type bit_pipe is array (PIPE_DEPTH-1 downto 0) of input_bits;
signal pipe:bit_pipe;
signal inbits:input_bits;
signal sel_reg:std_logic_vector(11 downto 0);
signal output_int:adc_sample_t;
signal input_int:std_logic_vector(11 downto 0);

begin

selReg:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			sel_reg <= (others => '0');
		else
			sel_reg <= resize(sel, 12);
		end if;
	end if;
end process selReg;


bitGen:for b in ADC_BITS-1 downto 0 generate
	chanGen:for c in CHANNELS-1 downto 0 generate
		inbits(b)(c) <= inputs(c)(b);
	end generate chanGen;
	input_int <= resize(pipe(PIPE_DEPTH-1)(b),12);
	chanSelect:entity work.select_1of12
  port map(
    input => input_int,
    sel => sel_reg,
    output => output_int(b)
  ); 
end generate bitGen;

inPipe:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			pipe <= (others => (others => (others => '0')));
			output <= (others => '0');
		else
			pipe(0) <= inbits;
			pipe(PIPE_DEPTH-1 downto 1) <= pipe(PIPE_DEPTH-2 downto 0);
			output <= output_int;
		end if;
	end if;
end process inPipe;

end architecture RTL;
