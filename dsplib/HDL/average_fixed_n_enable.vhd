--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:14Apr.,2017
--
-- Design Name: TES_digitiser
-- Module Name: dot_product
-- Project Name: teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.DSP48E1;


library extensions;
use extensions.logic.all;
use extensions.boolean_vector.all;

--accumulate 2**n samples that are below threshold then divide by 2**n
entity average_fixed_n is
generic(
  WIDTH:integer:=16;
  DIVIDE_N:natural:=19
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  threshold:in signed(WIDTH-1 downto 0);
  sample:in signed(WIDTH-1 downto 0);
  
  average:out signed(WIDTH-1 downto 0)
);
end entity average_fixed_n;

architecture DSP48 of average_fixed_n is

signal count:unsigned(DIVIDE_N-1 downto 0);
signal threshold_reg:signed(WIDTH downto 0);
signal rel_threshold:signed(WIDTH-1 downto 0);
--signal n_reg:unsigned(DIVIDE_BITS-1 downto 0):=to_unsigned(3,DIVIDE_BITS);
signal valid,round_reg:boolean:=FALSE;
signal average_int,sample_reg,sample_reg2:signed(WIDTH-1 downto 0)
       :=(others => '0');
signal below_threshold:boolean:=TRUE;
signal thresh_sign:std_logic:='0';

-- DSP48E input signals
signal a:std_logic_vector(29 downto 0):=(others => '0');
signal b:std_logic_vector(17 downto 0);
signal ab,p_out:std_logic_vector(47 downto 0);
signal opmode:std_logic_vector(6 downto 0):="1011111";
signal carryinsel:std_logic_vector(2 downto 0):="000";

constant ONES:unsigned(47 downto 0):=(others => '1');
constant ROUNDING_C:std_logic_vector(47 downto 0)
         :=std_logic_vector(shift_right('0' & ONES(46 downto 0),48-DIVIDE_N));

type FSMstate is (START,ACCUMULATE,ROUND);
signal state,nextstate:FSMstate;

begin
average <= average_int;

fsmNextstate:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= START;
    else
      state <= nextstate;
    end if;
  end if;
end process fsmNextstate;

fsmTransition:process(state,below_threshold,count)
begin
  
  carryinsel <= "000";
  nextstate <= state;
  
  case state is 
    
  when START =>
    
    opmode <= "0000011"; -- x->A:B y->0 z->0
    nextstate <= ACCUMULATE;
    
  when ACCUMULATE =>
    if count=0 then
      nextstate <= ROUND;
    end if;
    
    if below_threshold then
      opmode <= "0100011"; -- x->A:B y->0 z->P
    else
      opmode <= "0100000"; -- x->0 y->0 z->P
    end if;

  when ROUND =>
    
    carryinsel <= "111";
    opmode <= "0101111"; -- x->A:B y->C z->P
    nextstate <= START;
    
  end case;
end process fsmTransition;

thresh_sign <= threshold_reg(WIDTH);
fsmOutput:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      average_int <= (others => '0');
      threshold_reg <= (WIDTH downto WIDTH-1 => '0', others => '1');
      rel_threshold <= (WIDTH-1 => '0', others => '1');
      count <= (others => '1');
    else
      if below_threshold then
        count <= count-1;
      end if;
      
      threshold_reg <= resize(average_int,WIDTH+1)+resize(threshold,WIDTH+1); 
      if thresh_sign/=threshold_reg(WIDTH-1) then
        rel_threshold <= (WIDTH-1 => thresh_sign,others => not thresh_sign);
      else
        rel_threshold <= threshold_reg(WIDTH-1 downto 0);
      end if;
      below_threshold <= sample <= rel_threshold;
      sample_reg <= sample;
     
      round_reg <= state=ROUND;
      valid <= round_reg;
      
      if valid then
        average_int <= signed(p_out(DIVIDE_N+WIDTH-1 downto DIVIDE_N));
      end if;
      
    end if;
  end if;
end process fsmOutput;
  
ab <= resize(sample_reg,48);
a <= ab(47 downto 18);
b <= ab(17 downto 0);

addRound:DSP48E1
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
  ACASCREG => 1,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  ADREG => 0,                        -- Number of pipeline stages for pre-adder (0 or 1)
  ALUMODEREG => 0,                   -- Number of pipeline stages for ALUMODE (0 or 1)
  AREG => 1,                         -- Number of pipeline stages for A (0, 1 or 2)
  BCASCREG => 1,                     -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  BREG => 1,                         -- Number of pipeline stages for B (0, 1 or 2)
  CARRYINREG => 1,                   -- Number of pipeline stages for CARRYIN (0 or 1)
  CARRYINSELREG => 1,                -- Number of pipeline stages for CARRYINSEL (0 or 1)
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
  CARRYINSEL => carryinsel,         -- 3-bit input: Carry select input
  CEINMODE => '0',             -- 1-bit input: Clock enable input for INMODEREG
  CLK => clk,                       -- 1-bit input: Clock input
  INMODE => "00000",                 -- 5-bit input: INMODE control input
  OPMODE => opmode,                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => a,                           -- 30-bit input: A data input
  B => b,                           -- 18-bit input: B data input
  C => ROUNDING_C,                  -- 48-bit input: C data input
  CARRYIN => '0',               -- 1-bit input: Carry input signal
  D => (others => '1'),                           -- 25-bit input: D data input
  -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  CEA1 => '1',                     -- 1-bit input: Clock enable input for 1st stage AREG
  CEA2 => '1',                     -- 1-bit input: Clock enable input for 2nd stage AREG
  CEAD => '0',                     -- 1-bit input: Clock enable input for ADREG
  CEALUMODE => '1',           -- 1-bit input: Clock enable input for ALUMODERE
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

end architecture DSP48;
