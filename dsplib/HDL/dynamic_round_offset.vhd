library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.DSP48E1;

--library extensions;
--use extensions.logic.all;

--TODO this is only used after fir stages, write own fir stage instead of 

-- output is WIDTH_OUT+point-1 downto point symmetrically rounded
entity dynamic_round_offset is
generic(
  WIDTH_IN:integer:=48; -- max 48
  WIDTH_OUT:integer:=18;
  TOWARDS_INF:boolean:=FALSE
); 
port(
  clk:in std_logic;
  reset:in std_logic;
  msb:in integer range 0 to 47;
  -- rounding point 0 = none
  point:in integer range 0 to 47;
  input:in std_logic_vector(WIDTH_IN-1 downto 0);
  output:out std_logic_vector(WIDTH_OUT-1 downto 0)
);
end entity dynamic_round_offset;

architecture dsp48e of dynamic_round_offset is  

-- DSP48E1 signals
signal a_round,a_sat:std_logic_vector(29 downto 0);
signal b_round,b_sat:std_logic_vector(17 downto 0);
signal p_out,p_int,ab_round:std_logic_vector(47 downto 0);

constant ONES:unsigned(47 downto 0):=(others => '1');
signal overflow_mask,rounding_c:std_logic_vector(47 downto 0);
--
signal input_reg:signed(WIDTH_IN-1 downto 0);
signal round_shift,overflow_shift:integer range 0 to 48;    
signal carryin:std_logic;
signal pat:std_ulogic;
signal patb:std_ulogic;
signal saturate:std_logic;
signal output_reg:signed(47 downto 0);

signal msb_m1:integer range 0 to 47;
begin
  
assert WIDTH_IN <= 48 report "maximum WIDTH_IN is 48" severity ERROR;
assert WIDTH_OUT <= 48 report "maximum WIDTH_OUT is 48" severity ERROR;

saturate <= not (pat xor patb);

ab_round <= std_logic_vector(resize(signed(input_reg),48));
a_round <= ab_round(47 downto 18);
b_round <= ab_round(17 downto 0);

--ab_sat <= resize(signed(),48);
--a_sat <= p_int(47 downto 18);
--b_sat <= p_int(17 downto 0);

output <= std_logic_vector(output_reg(WIDTH_OUT-1 downto 0));

outputReg:process (clk) is
begin
  if rising_edge(clk) then
      
    round_shift <= 49-point;
    --FIXME could pipeline
    overflow_shift <= 48-msb;
    
    input_reg <= signed(input);
    rounding_c <= std_logic_vector(shift_right(ONES,round_shift));
    overflow_mask <= std_logic_vector(shift_right(ONES,overflow_shift));
    msb_m1 <= msb-1;
    
    if point=0 then
      carryin <= '0';
    else
      if TOWARDS_INF then
        carryin <= not input(WIDTH_IN-1);
      else
        carryin <= input(WIDTH_IN-1);
      end if;
    end if;
      
    if saturate='1' then 
      if p_out(47)='1' then
        output_reg <= signed(shift_left(ONES,msb));
      else
        if msb > 0 then
          output_reg <= (msb_m1 => '0', others => '1');
        else
          output_reg <= (others => '0');
        end if;
      end if;
    else
      output_reg <= shift_right(signed(p_out), point);
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
  MASK => X"000000000000",           -- 48-bit mask value for pattern detect (1=ignore)
  PATTERN => X"000000000000",        -- 48-bit pattern match for pattern detect
  SEL_MASK => "MASK",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  SEL_PATTERN => "PATTERN",          -- Select pattern value ("PATTERN" or "C")
  USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
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
  ACOUT => open,            -- 30-bit output: A port cascade output
  BCOUT => open,            -- 18-bit output: B port cascade output
  CARRYCASCOUT => open,     -- 1-bit output: Cascade carry output
  MULTSIGNOUT => open,       -- 1-bit output: Multiplier sign cascade output
  PCOUT => p_int,                   -- 48-bit output: Cascade output
  -- Control: 1-bit (each) output: Control Inputs/Status Bits
  OVERFLOW => open,             -- 1-bit output: Overflow in add/acc output
  PATTERNBDETECT => open, -- 1-bit output: Pattern bar detect output
  PATTERNDETECT => open,   -- 1-bit output: Pattern detect output
  UNDERFLOW => open,           -- 1-bit output: Underflow in add/acc output
  -- Data: 4-bit (each) output: Data Ports
  CARRYOUT => open,             -- 4-bit output: Carry output
  P => open,                           -- 48-bit output: Primary data output
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
  A => a_round,                           -- 30-bit input: A data input
  B => b_round,                           -- 18-bit input: B data input
  C => rounding_c,  -- 48-bit input: C data input
  CARRYIN => carryin,               -- 1-bit input: Carry input signal
  D => (others => '1'),             -- 25-bit input: D data input
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

sat:DSP48E1
generic map (
  -- Feature Control Attributes: Data Path Selection
  A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  USE_DPORT => FALSE,                 -- Select D port usage (TRUE or FALSE)
  USE_MULT => "NONE",            -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  -- Pattern Detector Attributes: Pattern Detection Configuration
  AUTORESET_PATDET => "NO_RESET",    -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  MASK => X"000000000000",           -- 48-bit mask value for pattern detect (1=ignore)
  PATTERN => X"000000000000",        -- 48-bit pattern match for pattern detect
  SEL_MASK => "C",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  SEL_PATTERN => "PATTERN",          -- Select pattern value ("PATTERN" or "C")
  USE_PATTERN_DETECT => "PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
  -- Register Control Attributes: Pipeline Register Configuration
  ACASCREG => 0,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  ADREG => 0,                        -- Number of pipeline stages for pre-adder (0 or 1)
  ALUMODEREG => 0,                   -- Number of pipeline stages for ALUMODE (0 or 1)
  AREG => 0,                         -- Number of pipeline stages for A (0, 1 or 2)
  BCASCREG => 0,                     -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  BREG => 0,                         -- Number of pipeline stages for B (0, 1 or 2)
  CARRYINREG => 0,                   -- Number of pipeline stages for CARRYIN (0 or 1)
  CARRYINSELREG => 0,                -- Number of pipeline stages for CARRYINSEL (0 or 1)
  CREG => 1,                         -- Number of pipeline stages for C (0 or 1)
  DREG => 0,                         -- Number of pipeline stages for D (0 or 1)
  INMODEREG => 0,                    -- Number of pipeline stages for INMODE (0 or 1)
  MREG => 0,                         -- Number of multiplier pipeline stages (0 or 1)
  OPMODEREG => 0,                    -- Number of pipeline stages for OPMODE (0 or 1)
  PREG => 1,                         -- Number of pipeline stages for P (0 or 1)
  USE_SIMD => "ONE48"                -- SIMD selection ("ONE48", "TWO24", "FOUR12")
)
port map (
  -- Cascade: 30-bit (each) output: Cascade Ports
  ACOUT => open,            -- 30-bit output: A port cascade output
  BCOUT => open,            -- 18-bit output: B port cascade output
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
  PCIN => p_int,                     -- 48-bit input: P cascade input
  -- Control: 4-bit (each) input: Control Inputs/Status Bits
  ALUMODE => "0000",               -- 4-bit input: ALU control input
  CARRYINSEL => "011",         -- 3-bit input: Carry select input
  CEINMODE => '0',             -- 1-bit input: Clock enable input for INMODEREG
  CLK => clk,                       -- 1-bit input: Clock input
  INMODE => "00000",                 -- 5-bit input: INMODE control input
  OPMODE => "0010011",                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => (others => '0'),                           -- 30-bit input: A data input
  B => (others => '0'),                           -- 18-bit input: B data input
  C => overflow_mask,  -- 48-bit input: C data input
  CARRYIN => '0',               -- 1-bit input: Carry input signal
  D => (others => '0'),             -- 25-bit input: D data input
  -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  CEA1 => '0',                     -- 1-bit input: Clock enable input for 1st stage AREG
  CEA2 => '0',                     -- 1-bit input: Clock enable input for 2nd stage AREG
  CEAD => '0',                     -- 1-bit input: Clock enable input for ADREG
  CEALUMODE => '0',           -- 1-bit input: Clock enable input for ALUMODERE
  CEB1 => '0',                     -- 1-bit input: Clock enable input for 1st stage BREG
  CEB2 => '0',                     -- 1-bit input: Clock enable input for 2nd stage BREG
  CEC => '1',                       -- 1-bit input: Clock enable input for CREG
  CECARRYIN => '0',           -- 1-bit input: Clock enable input for CARRYINREG
  CECTRL => '1',                 -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  CED => '0',                       -- 1-bit input: Clock enable input for DREG
  CEM => '0',                       -- 1-bit input: Clock enable input for MREG
  CEP => '1',                       -- 1-bit input: Clock enable input for PREG
  RSTA => reset,                     -- 1-bit input: Reset input for AREG
  RSTALLCARRYIN => reset,   -- 1-bit input: Reset input for CARRYINREG
  RSTALUMODE => '0',         -- 1-bit input: Reset input for ALUMODEREG
  RSTB => reset,                     -- 1-bit input: Reset input for BREG
  RSTC => reset,                     -- 1-bit input: Reset input for CREG
  RSTCTRL => reset,               -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  RSTD => '0',                     -- 1-bit input: Reset input for DREG and ADREG
  RSTM => '0',                     -- 1-bit input: Reset input for MREG
  RSTP => reset                      -- 1-bit input: Reset input for PREG
);

satOffset:DSP48E1
generic map (
  -- Feature Control Attributes: Data Path Selection
  A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  USE_DPORT => FALSE,                 -- Select D port usage (TRUE or FALSE)
  USE_MULT => "NONE",            -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  -- Pattern Detector Attributes: Pattern Detection Configuration
  AUTORESET_PATDET => "NO_RESET",    -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  MASK => X"000000000000",           -- 48-bit mask value for pattern detect (1=ignore)
  PATTERN => X"000000000000",        -- 48-bit pattern match for pattern detect
  SEL_MASK => "C",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  SEL_PATTERN => "PATTERN",          -- Select pattern value ("PATTERN" or "C")
  USE_PATTERN_DETECT => "PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
  -- Register Control Attributes: Pipeline Register Configuration
  ACASCREG => 0,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  ADREG => 0,                        -- Number of pipeline stages for pre-adder (0 or 1)
  ALUMODEREG => 0,                   -- Number of pipeline stages for ALUMODE (0 or 1)
  AREG => 0,                         -- Number of pipeline stages for A (0, 1 or 2)
  BCASCREG => 0,                     -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  BREG => 0,                         -- Number of pipeline stages for B (0, 1 or 2)
  CARRYINREG => 0,                   -- Number of pipeline stages for CARRYIN (0 or 1)
  CARRYINSELREG => 0,                -- Number of pipeline stages for CARRYINSEL (0 or 1)
  CREG => 1,                         -- Number of pipeline stages for C (0 or 1)
  DREG => 0,                         -- Number of pipeline stages for D (0 or 1)
  INMODEREG => 0,                    -- Number of pipeline stages for INMODE (0 or 1)
  MREG => 0,                         -- Number of multiplier pipeline stages (0 or 1)
  OPMODEREG => 0,                    -- Number of pipeline stages for OPMODE (0 or 1)
  PREG => 1,                         -- Number of pipeline stages for P (0 or 1)
  USE_SIMD => "ONE48"                -- SIMD selection ("ONE48", "TWO24", "FOUR12")
)
port map (
  -- Cascade: 30-bit (each) output: Cascade Ports
  ACOUT => open,            -- 30-bit output: A port cascade output
  BCOUT => open,            -- 18-bit output: B port cascade output
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
  PCIN => p_int,                     -- 48-bit input: P cascade input
  -- Control: 4-bit (each) input: Control Inputs/Status Bits
  ALUMODE => "0000",               -- 4-bit input: ALU control input
  CARRYINSEL => "011",         -- 3-bit input: Carry select input
  CEINMODE => '0',             -- 1-bit input: Clock enable input for INMODEREG
  CLK => clk,                       -- 1-bit input: Clock input
  INMODE => "00000",                 -- 5-bit input: INMODE control input
  OPMODE => "0010011",                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => (others => '0'),                           -- 30-bit input: A data input
  B => (others => '0'),                           -- 18-bit input: B data input
  C => overflow_mask,  -- 48-bit input: C data input
  CARRYIN => '0',               -- 1-bit input: Carry input signal
  D => (others => '0'),             -- 25-bit input: D data input
  -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  CEA1 => '0',                     -- 1-bit input: Clock enable input for 1st stage AREG
  CEA2 => '0',                     -- 1-bit input: Clock enable input for 2nd stage AREG
  CEAD => '0',                     -- 1-bit input: Clock enable input for ADREG
  CEALUMODE => '0',           -- 1-bit input: Clock enable input for ALUMODERE
  CEB1 => '0',                     -- 1-bit input: Clock enable input for 1st stage BREG
  CEB2 => '0',                     -- 1-bit input: Clock enable input for 2nd stage BREG
  CEC => '1',                       -- 1-bit input: Clock enable input for CREG
  CECARRYIN => '0',           -- 1-bit input: Clock enable input for CARRYINREG
  CECTRL => '1',                 -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  CED => '0',                       -- 1-bit input: Clock enable input for DREG
  CEM => '0',                       -- 1-bit input: Clock enable input for MREG
  CEP => '1',                       -- 1-bit input: Clock enable input for PREG
  RSTA => reset,                     -- 1-bit input: Reset input for AREG
  RSTALLCARRYIN => reset,   -- 1-bit input: Reset input for CARRYINREG
  RSTALUMODE => '0',         -- 1-bit input: Reset input for ALUMODEREG
  RSTB => reset,                     -- 1-bit input: Reset input for BREG
  RSTC => reset,                     -- 1-bit input: Reset input for CREG
  RSTCTRL => reset,               -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  RSTD => '0',                     -- 1-bit input: Reset input for DREG and ADREG
  RSTM => '0',                     -- 1-bit input: Reset input for MREG
  RSTP => reset                      -- 1-bit input: Reset input for PREG
);
end architecture dsp48e;
