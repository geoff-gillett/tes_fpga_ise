library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.DSP48E1;

library extensions;
use extensions.logic.all;

entity round2 is
generic(
  WIDTH_IN:integer:=48; -- max 48
  FRAC_IN:integer:=28;
  WIDTH_OUT:integer:=18;
  FRAC_OUT:integer:=3
); 
port(
  clk:in std_logic;
  reset:in std_logic;
  input:in signed(WIDTH_IN-1 downto 0);
  output_threshold:in signed(WIDTH_OUT-1 downto 0);
  output:out signed(WIDTH_OUT-1 downto 0);
  above_threshold:out boolean
);
end entity round2;

architecture dsp48e of round2 is  

-- DSP48E1 signals
signal a:std_logic_vector(29 downto 0);
signal b:std_logic_vector(17 downto 0);
signal p_out,ab:std_logic_vector(47 downto 0);

constant NONZERO_MASKS:boolean:=FRAC_IN-FRAC_OUT > 2;

constant OVERFLOW_MASK:bit_vector(47 downto 0)
         :=(WIDTH_OUT-FRAC_OUT+FRAC_IN-2 downto 0 => '1', others => '0');

--constant ROUNDING_CONSTANT:std_logic_vector(47 downto 0)
         --:=(FRAC_IN-FRAC_OUT-2 downto 0 => '1', others => '0');
         
signal carryin:std_logic;
signal pat:std_ulogic;
signal patb:std_ulogic;
signal saturate:std_logic;
signal rounding:std_logic_vector(47 downto 0):=(others => '0');
--signal overflow_mask:bit_vector(47 downto 0):=(others => '0');

constant NO_ROUND:boolean:=FRAC_IN=FRAC_OUT;
begin
  
assert WIDTH_IN <= 48 report "maximum WIDTH_IN is 48" severity ERROR;
assert WIDTH_OUT <= 48 report "maximum WIDTH_OUT is 48" severity ERROR;
assert FRAC_OUT <= FRAC_IN 
report "FRAC_OUT must be less than or equal to FRAC_in" severity ERROR;

constantGen:if NONZERO_MASKS generate
  rounding <= (FRAC_IN-FRAC_OUT-2 downto 0 => '1', others => '0');
end generate;

--carryin_sel <= "101" when TOWARDS_INF else "111";
carryin <= '0' when NO_ROUND else input(WIDTH_IN-1);
saturate <= not (pat xor patb);

ab <= resize(input,48);
a <= ab(47 downto 18);
b <= ab(17 downto 0);

outputReg:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      output <= (others => '0'); 
    else
      
      if saturate='1' then 
        output <= (WIDTH_OUT-1 => p_out(47), others => not p_out(47));
        if p_out(47)='1' then
          above_threshold <= FALSE;
        else
          above_threshold <= TRUE; -- this is wrong when threshold = MAX
        end if;
      else
        output <= signed(
          p_out(WIDTH_OUT+FRAC_IN-FRAC_OUT-1 downto FRAC_IN-FRAC_OUT)
        );
        above_threshold <= signed(
          p_out(WIDTH_OUT+FRAC_IN-FRAC_OUT-1 downto FRAC_IN-FRAC_OUT)
        ) > output_threshold;
      end if;
    end if;
  end if;
end process outputReg;

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
  PATTERNBDETECT => patb, -- 1-bit output: Pattern bar detect output
  PATTERNDETECT => pat,   -- 1-bit output: Pattern detect output
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
  INMODE => "00000",                 -- 5-bit input: INMODE control input
  OPMODE => "0110011",                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => a,                           -- 30-bit input: A data input
  B => b,                           -- 18-bit input: B data input
  C => ROUNDING,--OVERFLOW_VALUE,                           -- 48-bit input: C data input
  CARRYIN => carryin,               -- 1-bit input: Carry input signal
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
