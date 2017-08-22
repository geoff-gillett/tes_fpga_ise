
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.DSP48E1;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

-- Saturating Area above between xings.
-- if AREA_ABOVE=TRUE returns area above threshold else area above 0.
-- TOWARDS_INF=TRUE symmetric round towards infinity else towards 0.
-- Uses one DSP48E latency 5 
-- NOTE: assumes signal has the same sign between crossings. 
--       rounding can be incorrect if this is not the case.
entity area_acc is
generic(
  WIDTH:integer:=16; -- max 18
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1;
  --TRUE calculates area above signal_threshold else area above 0
  AREA_ABOVE:boolean:=TRUE;
  -- symetricaly round towards infinity else 0
  TOWARDS_INF:boolean:=TRUE
); 
port (
  clk:in std_logic;
  reset:in std_logic; 
  sig:in signed(WIDTH-1 downto 0);
  signal_threshold:in signed(WIDTH-1 downto 0);
  xing:in boolean; -- crossing of signal threshold
  area_threshold:in signed(AREA_WIDTH-1 downto 0);
  above_area_threshold:out boolean;
  area:out signed(AREA_WIDTH-1 downto 0)
); 
end entity area_acc;

architecture DSP48E1x1 of area_acc is
constant MSB:integer:=AREA_WIDTH+(FRAC-AREA_FRAC);
constant MASK:std_logic_vector(47 downto 0)
             :=(MSB-2 downto 0 => '1', others => '0');  
constant ROUND:std_logic_vector(47 downto 0)
              :=(FRAC-AREA_FRAC-2 downto 0 => '1', others => '0');             
constant DEPTH:natural:=3;

signal area_int:signed(AREA_WIDTH-1 downto 0);
-- DSP48E1 signals
--signal c:std_logic_vector(47 downto 0);
signal a:std_logic_vector(29 downto 0);
signal d:std_logic_vector(24 downto 0);

signal p_int,c:std_logic_vector(47 downto 0);
signal accum_opmode:std_logic_vector(6 downto 0):="0001100";
signal carry_in_pipe:std_logic_vector(0 to DEPTH);
signal carry_in,carry_sign:std_logic;
signal patb,pat,saturate:std_ulogic;
signal x_pipe:boolean_vector(0 to DEPTH);
signal b:std_logic_vector(17 downto 0);

begin
  
assert WIDTH <= 18 report "maximum width is 18" severity FAILURE;

x_pipe(0) <= xing;

carry_sign <= not sig(WIDTH-1) when TOWARDS_INF else sig(WIDTH-1);
carry_in_pipe(0) <= carry_sign when xing else '0';
pipe:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      x_pipe(1 to DEPTH) <= (others => FALSE);
      carry_in_pipe(1 to DEPTH) <= (others => '0');
    else
      x_pipe(1 to DEPTH) <= x_pipe(0) & x_pipe(1 to DEPTH-1);
      carry_in_pipe(1 to DEPTH) 
        <= carry_in_pipe(0) & carry_in_pipe(1 to DEPTH-1);
    end if;
  end if;
end process pipe;

-- want ((d-a) x 1) + c + carry_in at xing, op mode 0110101 (init)
--      ((d-a) x 1)+ p otherwise           op mode 0000101 (accumulate)
b <= (0 => '1', others => '0');
a <= resize(signal_threshold,30) when AREA_ABOVE else (others => '0'); 
d <= resize(sig,25);  
c <= ROUND;

accum_opmode <= "0110101" when x_pipe(2) else "0100101";
--accum_opmode <= "0110101";-- when x_pipe(2) else "0000101";
carry_in <= carry_in_pipe(2);

--FIXME try to bypass multiply?
accum:DSP48E1
generic map (
  -- Feature Control Attributes: Data Path Selection
  A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  USE_DPORT => TRUE,                 -- Select D port usage (TRUE or FALSE)
  USE_MULT => "MULTIPLY",            -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  -- Pattern Detector Attributes: Pattern Detection Configuration
  AUTORESET_PATDET => "NO_RESET",    -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  MASK => to_bitvector(MASK),           -- 48-bit mask value for pattern detect (1=ignore)
  PATTERN => X"000000000000",        -- 48-bit pattern match for pattern detect
  SEL_MASK => "MASK",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  SEL_PATTERN => "PATTERN",          -- Select pattern value ("PATTERN" or "C")
  USE_PATTERN_DETECT => "PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
  -- Register Control Attributes: Pipeline Register Configuration
  ACASCREG => 1,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  ADREG => 1,                        -- Number of pipeline stages for pre-adder (0 or 1)
  ALUMODEREG => 0,                   -- Number of pipeline stages for ALUMODE (0 or 1)
  AREG => 1,                         -- Number of pipeline stages for A (0, 1 or 2)
  BCASCREG => 1,                     -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  BREG => 1,                         -- Number of pipeline stages for B (0, 1 or 2)
  CARRYINREG => 1,                   -- Number of pipeline stages for CARRYIN (0 or 1)
  CARRYINSELREG => 0,                -- Number of pipeline stages for CARRYINSEL (0 or 1)
  CREG => 1,                         -- Number of pipeline stages for C (0 or 1)
  DREG => 1,                         -- Number of pipeline stages for D (0 or 1)
  INMODEREG => 0,                    -- Number of pipeline stages for INMODE (0 or 1)
  MREG => 1,                         -- Number of multiplier pipeline stages (0 or 1)
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
  PATTERNBDETECT => patb, -- 1-bit output: Pattern bar detect output
  PATTERNDETECT => pat,   -- 1-bit output: Pattern detect output
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
  ALUMODE => "0000",            -- 4-bit input: ALU control input
  CARRYINSEL => "000",         -- 3-bit input: Carry select input
  CEINMODE => '1',             -- 1-bit input: Clock enable input for INMODEREG
  CLK => clk,                       -- 1-bit input: Clock input
  INMODE => "01101",                 -- 5-bit input: INMODE control input
  OPMODE => accum_opmode,                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => a,                           -- 30-bit input: A data input
  B => b, --(0 => '0', others => '0'),           -- 18-bit input: B data input
  C => c, --cround,                           -- 48-bit input: C data input
  CARRYIN => carry_in,               -- 1-bit input: Carry input signal
  D => d,                           -- 25-bit input: D data input
  -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  CEA1 => '1',                     -- 1-bit input: Clock enable input for 1st stage AREG
  CEA2 => '1',                     -- 1-bit input: Clock enable input for 2nd stage AREG
  CEAD => '1',                     -- 1-bit input: Clock enable input for ADREG
  CEALUMODE => '0',           -- 1-bit input: Clock enable input for ALUMODERE
  CEB1 => '1',                     -- 1-bit input: Clock enable input for 1st stage BREG
  CEB2 => '1',                     -- 1-bit input: Clock enable input for 2nd stage BREG
  CEC => '1',                       -- 1-bit input: Clock enable input for CREG
  CECARRYIN => '1',           -- 1-bit input: Clock enable input for CARRYINREG
  CECTRL => '1',                 -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  CED => '1',                       -- 1-bit input: Clock enable input for DREG
  CEM => '1',                       -- 1-bit input: Clock enable input for MREG
  CEP => '1',                       -- 1-bit input: Clock enable input for PREG
  RSTA => reset,                     -- 1-bit input: Reset input for AREG
  RSTALLCARRYIN => reset,   -- 1-bit input: Reset input for CARRYINREG
  RSTALUMODE => reset,         -- 1-bit input: Reset input for ALUMODEREG
  RSTB => reset,                     -- 1-bit input: Reset input for BREG
  RSTC => reset,                     -- 1-bit input: Reset input for CREG
  RSTCTRL => reset,               -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  RSTD => reset,                     -- 1-bit input: Reset input for DREG and ADREG
  RSTM => reset,                     -- 1-bit input: Reset input for MREG
  RSTP => reset                      -- 1-bit input: Reset input for PREG
);

saturate <= not (pat xor patb);
area_int <= signed(p_int(AREA_WIDTH+FRAC-AREA_FRAC-1 downto FRAC-AREA_FRAC));
saturation:process (clk) is
begin
  if rising_edge(clk) then
    if saturate='1' then  
      if p_int(47)='1' then
        area <= (AREA_WIDTH-1 => '1', others => '0');
        above_area_threshold <= FALSE;
      else
        area <= (AREA_WIDTH-1 => '0', others => '1');
        above_area_threshold <= TRUE;
      end if;
    else
      area <= area_int;
      above_area_threshold <= area_int > area_threshold;
    end if;
  end if;
end process saturation;

end architecture DSP48E1x1;

