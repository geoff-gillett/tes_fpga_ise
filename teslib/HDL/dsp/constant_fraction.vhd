
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.DSP48E1;

library extensions;
use extensions.logic.all;
-- wrapper for DSP48E1
-- implements p=(sig-min)*cf symmetrically rounded towards 0 to 18 bits
-- 
-- cf is 17 signed fractional bits

entity constant_fraction is
generic(WIDTH:integer:=18); -- max 18
port (
  clk:in std_logic;
  reset:in std_logic; --synchronous 
  min:in signed(WIDTH-1 downto 0);
  cf:in signed(WIDTH-1 downto 0);
  sig:in signed(WIDTH-1 downto 0);
  p:out signed(WIDTH-1 downto 0)
);
end entity constant_fraction;

architecture wrapper of constant_fraction is
  
-- DSP48E1 signals
signal a:std_logic_vector(29 downto 0);
signal b:std_logic_vector(17 downto 0);
signal p_int,c:std_logic_vector(47 downto 0);
signal d:std_logic_vector(24 downto 0);

--signal round_up:std_ulogic;

-- rounding pattern

begin

assert WIDTH <= 18 
report "maximum width is 18" severity ERROR;

c <= (15 downto 0 => '1', others => '0');
a <= resize(min,a'length);
d <= resize(sig,d'length);
b <= resize(cf,b'length);
p <= signed(p_int(WIDTH+16 downto WIDTH-1));
-- FIXME add rounding
--carry_in <= 1 when round_up='1' else 0;
--round:process(clk)
--begin
--  if rising_edge(clk) then
--    if reset = '1' then
--      p_round <= (others => '0');
--    else
--      p_round <= signed(p_int(2*WIDTH-2 downto WIDTH-2)) + carry_in;
--    end if;
--  end if;
--end process round;
--p <= signed(p_int(2*WIDTH-2 downto WIDTH-1));

addMult:DSP48E1
generic map (
  -- Feature Control Attributes: Data Path Selection
  A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  USE_DPORT => TRUE,                 -- Select D port usage (TRUE or FALSE)
  USE_MULT => "MULTIPLY",            -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  -- Pattern Detector Attributes: Pattern Detection Configuration
  AUTORESET_PATDET => "NO_RESET",    -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  MASK => X"FFFFFFFF0000",           -- 48-bit mask value for pattern detect (1=ignore)
  PATTERN => X"00000000FFFF",        -- 48-bit pattern match for pattern detect
  SEL_MASK => "MASK",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  SEL_PATTERN => "PATTERN",          -- Select pattern value ("PATTERN" or "C")
  USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
  -- Register Control Attributes: Pipeline Register Configuration
  ACASCREG => 1,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  ADREG => 1,                        -- Number of pipeline stages for pre-adder (0 or 1)
  ALUMODEREG => 0,                   -- Number of pipeline stages for ALUMODE (0 or 1)
  AREG => 1,                         -- Number of pipeline stages for A (0, 1 or 2)
  BCASCREG => 2,                     -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  BREG => 2,                         -- Number of pipeline stages for B (0, 1 or 2)
  CARRYINREG => 0,                   -- Number of pipeline stages for CARRYIN (0 or 1)
  CARRYINSELREG => 0,                -- Number of pipeline stages for CARRYINSEL (0 or 1)
  CREG => 0,                         -- Number of pipeline stages for C (0 or 1)
  DREG => 1,                         -- Number of pipeline stages for D (0 or 1)
  INMODEREG => 0,                    -- Number of pipeline stages for INMODE (0 or 1)
  MREG => 1,                         -- Number of multiplier pipeline stages (0 or 1)
  OPMODEREG => 0,                    -- Number of pipeline stages for OPMODE (0 or 1)
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
  P => p_int,                           -- 48-bit output: Primary data output
  -- Cascade: 30-bit (each) input: Cascade Ports
  ACIN => (others => '0'),                     -- 30-bit input: A cascade data input
  BCIN => (others => '0'),                     -- 18-bit input: B cascade input
  CARRYCASCIN => '0',       -- 1-bit input: Cascade carry input
  MULTSIGNIN => '0',         -- 1-bit input: Multiplier sign input
  PCIN => (others => '0'),                     -- 48-bit input: P cascade input
  -- Control: 4-bit (each) input: Control Inputs/Status Bits
  ALUMODE => "0000",               -- 4-bit input: ALU control input
  CARRYINSEL => "011",         -- 3-bit input: Carry select input
  CEINMODE => '0',             -- 1-bit input: Clock enable input for INMODEREG
  CLK => clk,                       -- 1-bit input: Clock input
  INMODE => "01101",                 -- 5-bit input: INMODE control input
  OPMODE => "0110101",                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => a,                           -- 30-bit input: A data input
  B => b,                           -- 18-bit input: B data input
  C => c,                           -- 48-bit input: C data input
  CARRYIN => '0',               -- 1-bit input: Carry input signal
  D => D,                           -- 25-bit input: D data input
  -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  CEA1 => '1',                     -- 1-bit input: Clock enable input for 1st stage AREG
  CEA2 => '0',                     -- 1-bit input: Clock enable input for 2nd stage AREG
  CEAD => '1',                     -- 1-bit input: Clock enable input for ADREG
  CEALUMODE => '0',           -- 1-bit input: Clock enable input for ALUMODERE
  CEB1 => '1',                     -- 1-bit input: Clock enable input for 1st stage BREG
  CEB2 => '1',                     -- 1-bit input: Clock enable input for 2nd stage BREG
  CEC => '0',                       -- 1-bit input: Clock enable input for CREG
  CECARRYIN => '0',           -- 1-bit input: Clock enable input for CARRYINREG
  CECTRL => '0',                 -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  CED => '1',                       -- 1-bit input: Clock enable input for DREG
  CEM => '1',                       -- 1-bit input: Clock enable input for MREG
  CEP => '1',                       -- 1-bit input: Clock enable input for PREG
  RSTA => reset,                     -- 1-bit input: Reset input for AREG
  RSTALLCARRYIN => reset,   -- 1-bit input: Reset input for CARRYINREG
  RSTALUMODE => reset,         -- 1-bit input: Reset input for ALUMODEREG
  RSTB => reset,                     -- 1-bit input: Reset input for BREG
  RSTC => '0',                     -- 1-bit input: Reset input for CREG
  RSTCTRL => reset,               -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  RSTD => reset,                     -- 1-bit input: Reset input for DREG and ADREG
  RSTM => reset,                     -- 1-bit input: Reset input for MREG
  RSTP => reset                      -- 1-bit input: Reset input for PREG
);

end architecture wrapper;
