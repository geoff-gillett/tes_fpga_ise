
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;

use work.registers.all;
use work.measurements.all;
use work.types.all;

entity input_mux is
generic(
  CHANNELS:natural:=2
);
port (
  clk:std_logic;
  
  samples_in:in adc_sample_array(CHANNELS-1 downto 0);
  sel:in std_logic_vector(CHANNELS-1 downto 0);
  sample_out:out adc_sample_t
);
end entity input_mux;

architecture RTL of input_mux is
constant DEPTH:integer:=4;

type pipelines is array (1 to DEPTH) of 
     adc_sample_array(CHANNELS-1 downto 0);
signal pipes:pipelines;
attribute equivalent_register_removal:string;
attribute equivalent_register_removal of pipes:signal is "no";
attribute shreg_extract:string;
attribute shreg_extract of pipes:signal is "no";

type bit_array is array (ADC_BITS-1 downto 0) of std_logic_vector(11 downto 0);
signal bits:bit_array:=(others => (others => '0'));
signal output:adc_sample_t;

--type sel_array is array (ADC_BITS-1 downto 0) of std_logic_vector(11 downto 0);
--signal input:sel_array;
signal s:std_logic_vector(11 downto 0);

begin

pipe:process (clk) is
begin
  if rising_edge(clk) then
    pipes(1) <= samples_in; 
    pipes(2 to DEPTH) <= pipes(1 to DEPTH-1);
    sample_out <= output;
  end if;
end process pipe;

s <= resize(sel,12);
bitGen:for b in ADC_BITS-1 downto 0 generate

  chanGen:for c in CHANNELS-1 downto 0 generate
    bits(b)(c) <= pipes(DEPTH)(c)(b);
  end generate chanGen;
  
  selector:entity work.select_1of12
    port map(
      input => bits(b),
      sel => s,
      output => output(b)
    );
    
end generate bitGen;
  
end architecture RTL;