library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.DSP48E1;

--TODO this is only used after fir stages, write own fir stage instead of 
-- using coregen could save 1 DSP slice by incorporating saturate slice into FIR
entity round is
generic(
  WIDTH_IN:integer:=48; -- max 48
  FRAC_IN:integer:=28;
  WIDTH_OUT:integer:=18;
  FRAC_OUT:integer:=3
); 
port(
  clk:in std_logic;
  reset:in std_logic;
  saturate:in std_logic;
  input:in std_logic_vector(WIDTH_IN-1 downto 0);
  output:out std_logic_vector(WIDTH_OUT-1 downto 0)
);
end entity round;

architecture dsp48e of round is  

-- DSP48E1 signals
signal in_reg:std_logic_vector(WIDTH_IN-1 downto 0);
signal a:std_logic_vector(29 downto 0);
signal b:std_logic_vector(17 downto 0);
signal p_out,ab:std_logic_vector(47 downto 0);
signal round_opmode:std_logic_vector(6 downto 0);
signal carry_in:std_ulogic;
--signal saturated:std_logic;
signal round_c:std_logic_vector(47 downto 0);

--signal ofl_value,round_constant:std_logic_vector(47 downto 0);
--signal ofl_mask:bit_vector(47 downto 0);

constant OVERFLOW_VALUE:std_logic_vector(47 downto 0)
         :=(WIDTH_OUT+FRAC_IN-FRAC_OUT-2 downto 0 => '1', others => '0');

constant OVERFLOW_MASK:bit_vector(47 downto 0)
         :=to_bitvector(OVERFLOW_VALUE);

constant ROUNDING:std_logic_vector(47 downto 0)
         :=(FRAC_IN-FRAC_OUT-1 downto 0 => '1', others => '0');
         
begin

assert WIDTH_IN <= 48 report "maximum WIDTH_IN is 48" severity ERROR;
assert WIDTH_OUT <= 48 report "maximum WIDTH_OUT is 48" severity ERROR;
assert FRAC_OUT < FRAC_IN 
report "FRAC_OUT must be less than FRAC_in" severity ERROR;

ab <= std_logic_vector(resize(signed(in_reg),48));
a <= ab(47 downto 18);
b <= ab(17 downto 0);

output <= p_out(WIDTH_OUT+FRAC_IN-FRAC_OUT-1 downto FRAC_IN-FRAC_OUT);

reg:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      round_c <= (others => '0');
      round_opmode <= "0110000";
      in_reg <= (others => '0');
      carry_in <= '0';
    else
      if saturate = '1' then
        round_c <= OVERFLOW_VALUE;
      elsif input(WIDTH_IN-1)='1' then 
        round_c <= ROUNDING;  
      else 
        round_c <= (others => '0');
      end if;
      carry_in <= input(WIDTH_IN-1) and saturate;
      round_opmode <= "011"  & "00" & not saturate & not saturate; --FIXME is this correct?
      in_reg <= input; 
    end if;
  end if;
end process reg;

round:DSP48E1
generic map (
  -- Feature Control Attributes: Data Path Selection
  A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  USE_DPORT => FALSE,                 -- Select D port usage (TRUE or FALSE)
  USE_MULT => "NONE",            -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  -- Pattern Detector Attributes: Pattern Detection Configuration
  AUTORESET_PATDET => "NO_RESET",    -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  MASK => OVERFLOW_MASK,           -- 48-bit mask value for pattern detect (1=ignore)
  PATTERN => X"000000000000",        -- 48-bit pattern match for pattern detect
  SEL_MASK => "MASK",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  SEL_PATTERN => "PATTERN",          -- Select pattern value ("PATTERN" or "C")
  USE_PATTERN_DETECT => "PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
  -- Register Control Attributes: Pipeline Register Configuration
  ACASCREG => 1,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  ADREG => 0,                        -- Number of pipeline stages for pre-adder (0 or 1)
  ALUMODEREG => 0,                   -- Number of pipeline stages for ALUMODE (0 or 1)
  AREG => 1,                         -- Number of pipeline stages for A (0, 1 or 2)
  BCASCREG => 1,                     -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  BREG => 1,                         -- Number of pipeline stages for B (0, 1 or 2)
  CARRYINREG => 1,                   -- Number of pipeline stages for CARRYIN (0 or 1)
  CARRYINSELREG => 0,                -- Number of pipeline stages for CARRYINSEL (0 or 1)
  CREG => 1,                         -- Number of pipeline stages for C (0 or 1)
  DREG => 0,                         -- Number of pipeline stages for D (0 or 1)
  INMODEREG => 0,                    -- Number of pipeline stages for INMODE (0 or 1)
  MREG => 0,                         -- Number of multiplier pipeline stages (0 or 1)
  OPMODEREG => 1,                    -- Number of pipeline stages for OPMODE (0 or 1)
  PREG => 1,                         -- Number of pipeline stages for P (0 or 1)
  USE_SIMD => "ONE48"                -- SIMD selection ("ONE48", "TWO24", "FOUR12")
)
port map (
  -- Cascade: 30-bit (each) output: Cascade Ports
  ACOUT => open,                   -- 30-bit output: A port cascade output
  BCOUT => open,                   -- 18-bit output: B port cascade output
  CARRYCASCOUT => open,     -- 1-bit output: Cascade carry output
  MULTSIGNOUT => open,       -- 1-bit output: Multiplier sign cascade output
  PCOUT => open,                   -- 48-bit output: Cascade output
  -- Control: 1-bit (each) output: Control Inputs/Status Bits
  OVERFLOW => open,             -- 1-bit output: Overflow in add/acc output
  PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
  PATTERNDETECT => open,   -- 1-bit output: Pattern detect output
  UNDERFLOW => open,           -- 1-bit output: Underflow in add/acc output
  -- Data: 4-bit (each) output: Data Ports
  CARRYOUT => open,             -- 4-bit output: Carry output
  P => p_out,                           -- 48-bit output: Primary data output
  -- Cascade: 30-bit (each) input: Cascade Ports
  ACIN => (others => '0'),                     -- 30-bit input: A cascade data input
  BCIN => (others => '0'),                     -- 18-bit input: B cascade input
  CARRYCASCIN => '0',       -- 1-bit input: Cascade carry input
  MULTSIGNIN => '0',         -- 1-bit input: Multiplier sign input
  PCIN => (others => '0'),                     -- 48-bit input: P cascade input
  -- Control: 4-bit (each) input: Control Inputs/Status Bits
  ALUMODE => "0000",               -- 4-bit input: ALU control input
  CARRYINSEL => "000",         -- 3-bit input: Carry select input
  CEINMODE => '0',             -- 1-bit input: Clock enable input for INMODEREG
  CLK => clk,                       -- 1-bit input: Clock input
  INMODE => "00001",                 -- 5-bit input: INMODE control input
  OPMODE => round_opmode,                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => a,                           -- 30-bit input: A data input
  B => b,                           -- 18-bit input: B data input
  C => round_c,--OVERFLOW_VALUE,                           -- 48-bit input: C data input
  CARRYIN => carry_in,               -- 1-bit input: Carry input signal
  D => (others => '1'),                           -- 25-bit input: D data input
  -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  CEA1 => '1',                     -- 1-bit input: Clock enable input for 1st stage AREG
  CEA2 => '1',                     -- 1-bit input: Clock enable input for 2nd stage AREG
  CEAD => '0',                     -- 1-bit input: Clock enable input for ADREG
  CEALUMODE => '0',           -- 1-bit input: Clock enable input for ALUMODERE
  CEB1 => '1',                     -- 1-bit input: Clock enable input for 1st stage BREG
  CEB2 => '1',                     -- 1-bit input: Clock enable input for 2nd stage BREG
  CEC => '1',                       -- 1-bit input: Clock enable input for CREG
  CECARRYIN => '1',           -- 1-bit input: Clock enable input for CARRYINREG
  CECTRL => '1',                 -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  CED => '0',                       -- 1-bit input: Clock enable input for DREG
  CEM => '0',                       -- 1-bit input: Clock enable input for MREG
  CEP => '1',                       -- 1-bit input: Clock enable input for PREG
  RSTA => reset,                     -- 1-bit input: Reset input for AREG
  RSTALLCARRYIN => '0',   -- 1-bit input: Reset input for CARRYINREG
  RSTALUMODE => '0',         -- 1-bit input: Reset input for ALUMODEREG
  RSTB => reset,                     -- 1-bit input: Reset input for BREG
  RSTC => reset,                     -- 1-bit input: Reset input for CREG
  RSTCTRL => reset,               -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  RSTD => '0',                     -- 1-bit input: Reset input for DREG and ADREG
  RSTM => '0',                     -- 1-bit input: Reset input for MREG
  RSTP => reset                      -- 1-bit input: Reset input for PREG
);
end architecture dsp48e;
