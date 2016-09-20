library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.DSP48E1;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--use work.functions.all;
--TODO this is only used after fir stages, write own fir stage instead of 
-- using coregen could save 1 DSP slice by incorporating saturate slice into FIR
entity saturate_round2 is
generic(
  WIDTH_IN:integer:=48; -- max 48
  FRAC_IN:integer:=25;
  WIDTH_OUT:integer:=18;
  FRAC_OUT:integer:=3
); 
port(
  clk:in std_logic;
  reset:in std_logic;
  --gain:in natural range 0 to 3;
  input:in std_logic_vector(WIDTH_IN-1 downto 0);
  output:out std_logic_vector(WIDTH_OUT-1 downto 0)
);
end entity saturate_round2;

architecture RTL of saturate_round2 is  

-- DSP48E1 signals
signal in_reg:std_logic_vector(47 downto 0);
signal saturate:std_logic;

--signal ofl_value,round_constant:std_logic_vector(47 downto 0);
--signal ofl_mask:bit_vector(47 downto 0);

constant OVERFLOW_BITS:integer:=WIDTH_OUT+FRAC_IN-FRAC_OUT-1;

begin

assert WIDTH_IN <= 48 report "maximum WIDTH_IN is 48" severity ERROR;
assert WIDTH_OUT <= 48 report "maximum WIDTH_OUT is 48" severity ERROR;
assert FRAC_OUT < FRAC_IN 
report "FRAC_OUT must be less than FRAC_in" severity ERROR;

reg:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      in_reg <= (others => '0');
    else
      saturate <= to_std_logic(
        not unaryAnd(not input(WIDTH_IN-1 downto OVERFLOW_BITS)) and
        not unaryAnd(input(WIDTH_IN-1 downto OVERFLOW_BITS))
      );
      in_reg <= input; 
    end if;
  end if;
end process reg;

round:entity work.round
generic map(
  WIDTH_IN => WIDTH_IN,
  FRAC_IN => FRAC_IN,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT
)
port map(
  clk => clk,
  reset => reset,
  saturate => saturate,
  input => in_reg,
  output => output
);

end architecture RTL;
