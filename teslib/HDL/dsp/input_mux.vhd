
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
  CHANNELS:natural:=2;
  DEPTH:integer:=1 --minimum 1
);
port (
  clk:std_logic;
  
  samples_in:in adc_sample_array(CHANNELS-1 downto 0);
  sel:in std_logic_vector(CHANNELS-1 downto 0);
  sample_out:out adc_sample_t
);
end entity input_mux;

architecture RTL of input_mux is
--constant DEPTH:integer:=4;

type pipe is array (1 to DEPTH) of adc_sample_t;
signal output_pipe:pipe;
attribute equivalent_register_removal:string;
attribute equivalent_register_removal of output_pipe:signal is "no";
attribute shreg_extract:string;
attribute shreg_extract of output_pipe:signal is "no";

type bit_array is array (ADC_BITS-1 downto 0) of std_logic_vector(11 downto 0);
signal bits:bit_array:=(others => (others => '0'));
signal output:adc_sample_t;

--type sel_array is array (ADC_BITS-1 downto 0) of std_logic_vector(11 downto 0);
--signal input:sel_array;
signal s:std_logic_vector(11 downto 0);

begin
  
sample_out <= output;
pipeline:process (clk) is
begin
  if rising_edge(clk) then
     output_pipe <= output & output_pipe(1 to DEPTH-1); 
--      pipes(2 to DEPTH) <= pipes(1 to DEPTH-1);
  end if;
end process pipeline;

s <= resize(sel,12);
bitGen:for b in ADC_BITS-1 downto 0 generate

  chanGen:for c in CHANNELS-1 downto 0 generate
    bits(b)(c) <= samples_in(c)(b);
  end generate chanGen;
  
  selector:entity work.select_1of12
    port map(
      input => bits(b),
      sel => s,
      output => output(b)
    );
    
end generate bitGen;
  
end architecture RTL;