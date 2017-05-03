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

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;
use extensions.boolean_vector.all;

-- accumulates pulse waveforms
-- reads out the average;
-- latency 5
entity pulse_accumulator is
generic(
  ADDRESS_BITS:integer:=11;
  WIDTH:integer:=16;
  ACCUMULATOR_WIDTH:integer:=36
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  divide_n:in unsigned(ceillog2(ACCUMULATOR_WIDTH-WIDTH)-1 downto 0);
  sample:in signed(WIDTH-1 downto 0);
  accumulate:in boolean;
  write:in boolean;
  address:in unsigned(ADDRESS_BITS-1 downto 0);
  
  data:out signed(WIDTH-1 downto 0)
  
);
end entity pulse_accumulator;

architecture SDP of pulse_accumulator is
subtype word is signed(ACCUMULATOR_WIDTH-1 downto 0);
type pulse_vector is array (0 to 2**ADDRESS_BITS-1) of word;

shared variable vector:pulse_vector;
attribute ram_style:string;
attribute ram_style of vector:variable is "BLOCK";

constant DIVIDE_BITS:integer:=ceillog2(ACCUMULATOR_WIDTH-WIDTH);

signal dout,dout_reg:word;
signal we:boolean;

subtype vector_address is unsigned(ADDRESS_BITS-1 downto 0);
signal wr_addr:vector_address;
type address_pipe is array (natural range <>) of vector_address;
type divide_pipe is array (natural range <>) 
                    of unsigned(DIVIDE_BITS-1 downto 0);
type signal_pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

constant DEPTH:integer:=6;
signal rd_addr_pipe:address_pipe(1 to DEPTH);
signal div_pipe:divide_pipe(1 to DEPTH);
signal sample_pipe:signal_pipe(1 to DEPTH);
signal write_pipe,accum_pipe:boolean_vector(1 to DEPTH);

-- DSP48E input signals
signal a:std_logic_vector(29 downto 0):=(others => '0');
signal b:std_logic_vector(17 downto 0);
signal c,p_out:std_logic_vector(47 downto 0);
signal mask_shift:unsigned(4 downto 0);
signal mask:unsigned(47 downto 0);
signal carryin:std_ulogic;

constant ONES:unsigned(47 downto 0):=(others => '1');
--if accumulate and write  then  write dout+sample (c+b) back to ram
--else round using divide_n
-- latency 5?
begin
  
writePort:process(clk)
begin
if rising_edge(clk) then
  if we then
    vector(to_integer(wr_addr)):=signed(p_out(ACCUMULATOR_WIDTH-1 downto 0));
  end if;
end if;
end process writePort;

readPort:process(clk)
begin
if rising_edge(clk) then
	dout_reg <= vector(to_integer(address(ADDRESS_BITS-1 downto 0)));
  dout <= dout_reg; -- register output
end if;
end process readPort;

b <= resize(sample_pipe(3),18);
control:process(clk)
begin
  if rising_edge(clk) then
    rd_addr_pipe <= address & rd_addr_pipe(1 to DEPTH-1);
    write_pipe <= write & write_pipe(1 to DEPTH-1);
    accum_pipe <= accumulate & accum_pipe(1 to DEPTH-1);
    div_pipe <= divide_n & div_pipe(1 to DEPTH-1);
    sample_pipe <= sample & sample_pipe(1 to DEPTH-1);
    
    if divide_n = 0 then
      mask_shift <= to_unsigned(48,DIVIDE_BITS);
    else
      mask_shift <= 48 - divide_n-1;
    end if;
    mask <= shift_right(ONES,to_integer(mask_shift));
    
    if write_pipe(2) then
      if accum_pipe(2) then --FIXME use opmode
        c <= resize(dout, 48);
      else
        c <= (others => '0');
      end if;
      carryin <= '0'; 
    else
      c <= to_std_logic(mask);
      if divide_n=0 then
        carryin <= '0';
      else
        carryin <= dout(WIDTH-1);
      end if;
    end if;
    
    data <= resize(
      shift_right(signed(p_out),to_integer(div_pipe(DEPTH))),WIDTH
    );
  end if;
end process control;

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
  SEL_MASK => "MASK",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  SEL_PATTERN => "C",          -- Select pattern value ("PATTERN" or "C")
  USE_PATTERN_DETECT => "PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")
  -- Register Control Attributes: Pipeline Register Configuration
  ACASCREG => 1,                     -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  ADREG => 0,                        -- Number of pipeline stages for pre-adder (0 or 1)
  ALUMODEREG => 1,                   -- Number of pipeline stages for ALUMODE (0 or 1)
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
  INMODE => "00000",                 -- 5-bit input: INMODE control input
  OPMODE => "0001111",                 -- 7-bit input: Operation mode input
  RSTINMODE => reset,           -- 1-bit input: Reset input for INMODEREG
  -- Data: 30-bit (each) input: Data Ports
  A => a,                           -- 30-bit input: A data input
  B => b,                           -- 18-bit input: B data input
  C => c,--OVERFLOW_VALUE,                           -- 48-bit input: C data input
  CARRYIN => carryin,               -- 1-bit input: Carry input signal
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

end architecture SDP;
