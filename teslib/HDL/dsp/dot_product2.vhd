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
entity dot_product2 is
generic(
  ADDRESS_BITS:natural:=11;
  TRACE_CHUNKS:natural:=512;
  WIDTH:natural:=16;
  ACCUMULATOR_WIDTH:natural:=36;
  ACCUMULATE_N:natural:=2
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  stop:in boolean;
  
  sample:in signed(WIDTH-1 downto 0);
  sample_valid:in boolean; --used for dot product with stride
  trace_start:in boolean;
  trace_last:in boolean;
  
  --FSM controls
  accumulate_start:in boolean; --FLAG starts 
  accumulate_done:out boolean;
  dp_start:in boolean;
  
  average:out signed(WIDTH-1 downto 0);
  average_start:out boolean;
  average_last:out boolean;
  
  dot_product:out signed(47 downto 0);
  dot_product_valid:out boolean
  
);
end entity dot_product2;

architecture SDP of dot_product2 is
subtype word is signed(ACCUMULATOR_WIDTH-1 downto 0);
type pulse_vector is array (0 to 2**ADDRESS_BITS-1) of word;

signal vector:pulse_vector:=(others => (others => '0'));
attribute ram_style:string;
attribute ram_style of vector:signal is "BLOCK";

signal dout,dout_reg:word;

subtype vector_address is unsigned(ADDRESS_BITS-1 downto 0);
type address_pipe is array (natural range <>) of vector_address;
type signal_pipe is array (natural range <>) of signed(WIDTH-1 downto 0);

constant RD_LAT:natural:=2;
constant DSP_LAT:natural:=2;
constant DEPTH:integer:=RD_LAT+DSP_LAT+1;

signal address:vector_address;
signal addr_pipe:address_pipe(1 to DEPTH);
signal sample_pipe:signal_pipe(1 to DEPTH);
signal accum_pipe,last_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal send_pipe,first_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
signal start_pipe:boolean_vector(0 to DEPTH):=(others => FALSE);
signal dp_valid_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);

-- DSP48E input signals
signal a:std_logic_vector(29 downto 0):=(others => '0');
signal b:std_logic_vector(17 downto 0);
signal c,p_out:std_logic_vector(47 downto 0);
signal opmode:std_logic_vector(6 downto 0):="0000011";
signal carryin:std_ulogic;

constant ONES:unsigned(47 downto 0):=(others => '1');
constant MASK_SHIFT:integer:=48 - ACCUMULATE_N + 1;
constant ROUND:std_logic_vector(47 downto 0)
         :=std_logic_vector(shift_right(ONES,MASK_SHIFT));

type FSMstate is (IDLE,ACCUM,WAITSAMPLE,SENDAVERAGE,DOTPRODUCT);
signal state:FSMstate;
signal send_last:boolean;
signal acc_count:unsigned(ACCUMULATE_N downto 0);
signal first_trace,write:boolean;
signal ram_in:std_logic_vector(ACCUMULATOR_WIDTH-1 downto 0);

--if dot then accumulate p=sample*RAM (a*b+p)
--if dot and start then p=sample*RAM (p=a*b)
--need to round at end

--if write and not accumulate write sample (b) to RAM
--elsif accumulate and write then write RAM+sample (c+b) to RAM 
--else round using divide_n

begin
average_last <= last_pipe(DEPTH);
dot_product <= signed(p_out);
dot_product_valid <= dp_valid_pipe(DEPTH);

--max ACCUMULATE_N?
writePort:process(clk)
begin
if rising_edge(clk) then
  write <= accum_pipe(DEPTH-1) or send_pipe(DEPTH-1);
  if write then
    vector(to_integer(addr_pipe(DEPTH))) <= signed(ram_in);
  end if;
end if;
end process writePort;

writeMux:process(clk)
begin
  if rising_edge(clk) then
    average <= signed(p_out(WIDTH+ACCUMULATE_N-1 downto ACCUMULATE_N));
    average_start <= send_pipe(DEPTH-2) and not send_pipe(DEPTH-1);
    accumulate_done <= send_pipe(1) and not send_pipe(2);
    if send_pipe(DEPTH-1) then
      ram_in <= resize(
        signed(p_out(WIDTH+ACCUMULATE_N-1 downto ACCUMULATE_N)),ACCUMULATOR_WIDTH
      );
    else
      ram_in <= p_out(ACCUMULATOR_WIDTH-1 downto 0);
    end if;
  end if;
end process writeMux;

readPort:process(clk)
begin
if rising_edge(clk) then
	dout_reg <= vector(to_integer(address));
  dout <= dout_reg; -- register output
end if;
end process readPort;

fsm:process (clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= IDLE;
    else
      
      send_last <= FALSE;
      
      case state is 
      when IDLE =>
        acc_count <= (ACCUMULATE_N => '1',others => '0');
        if not stop then
          if accumulate_start then
            state <= WAITSAMPLE;
            first_trace <= TRUE;
          elsif dp_start then
            state <= DOTPRODUCT;
          end if;
        end if;
        
      when WAITSAMPLE => --WAITING for framer
        if stop then
          state <= IDLE;
        elsif acc_count=0 then
          state <= SENDAVERAGE;
          address <= (others => '0');
        elsif trace_start then
          acc_count <= acc_count-1;
          address <= (others => '0');
          state <= ACCUM;
        end if;
        
      when ACCUM =>
        if stop then
          state <= IDLE;
        else
          if trace_last then
            state <= WAITSAMPLE;
            first_trace <= FALSE;
            address <= (others => '0');
          else
            address <= address+1;
          end if;
        end if;
        
      when SENDAVERAGE =>
        address <= address+1;
        send_last <= address=(TRACE_CHUNKS*4)-2;
        if send_last then
          state <= IDLE;
        end if;
        
      when DOTPRODUCT =>
        if stop then
          state <= IDLE;
        elsif trace_start then
          address <= (others => '0');
        else
          address <= address+1;
        end if;
        
      end case;
    end if;
  end if;
end process fsm;

pipeline:process(clk)
begin
  if rising_edge(clk) then
    addr_pipe <= address & addr_pipe(1 to DEPTH-1);
--    valid_pipe <= send_valid & valid_pipe(1 to DEPTH-1);
    last_pipe <= send_last & last_pipe(1 to DEPTH-1);
    accum_pipe <= (state=ACCUM) & accum_pipe(1 to DEPTH-1);
    first_pipe <= first_trace & first_pipe(1 to DEPTH-1);
    send_pipe <= (state=SENDAVERAGE) & send_pipe(1 to DEPTH-1);
    sample_pipe <= sample & sample_pipe(1 to DEPTH-1);
    start_pipe <= trace_start & start_pipe(0 to DEPTH-1);
    dp_valid_pipe <= trace_last & dp_valid_pipe(1 to DEPTH-1);
  end if;
end process pipeline;

c <= resize(dout,48);
inputMux:process(
  accum_pipe,dout,first_pipe,sample_pipe,send_pipe,state,start_pipe
)
begin
  b <= resize(sample_pipe(RD_LAT),18);
  a <= (others => '0');
  carryin <= '0';
  opmode <= "0000011"; 
  if state=DOTPRODUCT then
    a <= resize(dout,30);
    if start_pipe(RD_LAT) then
      opmode <= "0000101"; --axb
    else
      opmode <= "0100101"; --accumulate axb
    end if;
  elsif send_pipe(RD_LAT) then --read average
    b <= resize(ROUND,18);
    opmode <= "0001111"; --A:B + C (sample + rounding mask)
    if ACCUMULATE_N/=0 then
      carryin <= dout(ACCUMULATOR_WIDTH-1);
    end if;
  elsif accum_pipe(RD_LAT) then --write average
    if first_pipe(RD_LAT) then
      opmode <= "0000011"; -- A:B + 0 (sample)
    else
      opmode <= "0001111"; --A:B + C (sample + dout)
    end if;
  end if;
  --need dot product mux muxstate pipe?
end process inputMux;

addRound:DSP48E1
generic map (
  -- Feature Control Attributes: Data Path Selection
  A_INPUT => "DIRECT",               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  B_INPUT => "DIRECT",               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  USE_DPORT => FALSE,                 -- Select D port usage (TRUE or FALSE)
  USE_MULT => "DYNAMIC",            -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  -- Pattern Detector Attributes: Pattern Detection Configuration
  AUTORESET_PATDET => "NO_RESET",    -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  MASK => X"000000000000",           -- 48-bit mask value for pattern detect (1=ignore)
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
  CARRYINSEL => "000",         -- 3-bit input: Carry select input
  CEINMODE => '0',             -- 1-bit input: Clock enable input for INMODEREG
  CLK => clk,                       -- 1-bit input: Clock input
  INMODE => "00000",                 -- 5-bit input: INMODE control input
  OPMODE => opmode,                 -- 7-bit input: Operation mode input
  RSTINMODE => '0',           -- 1-bit input: Reset input for INMODEREG
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
  CEALUMODE => '0',           -- 1-bit input: Clock enable input for ALUMODERE
  CEB1 => '1',                     -- 1-bit input: Clock enable input for 1st stage BREG
  CEB2 => '1',                     -- 1-bit input: Clock enable input for 2nd stage BREG
  CEC => '1',                       -- 1-bit input: Clock enable input for CREG
  CECARRYIN => '1',           -- 1-bit input: Clock enable input for CARRYINREG
  CECTRL => '1',                 -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  CED => '0',                       -- 1-bit input: Clock enable input for DREG
  CEM => '1',                       -- 1-bit input: Clock enable input for MREG
  CEP => '1',                       -- 1-bit input: Clock enable input for PREG
  RSTA => reset,                     -- 1-bit input: Reset input for AREG
  RSTALLCARRYIN => reset,   -- 1-bit input: Reset input for CARRYINREG
  RSTALUMODE => '0',         -- 1-bit input: Reset input for ALUMODEREG
  RSTB => reset,                     -- 1-bit input: Reset input for BREG
  RSTC => reset,                     -- 1-bit input: Reset input for CREG
  RSTCTRL => reset,               -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  RSTD => '0',                     -- 1-bit input: Reset input for DREG and ADREG
  RSTM => reset,                     -- 1-bit input: Reset input for MREG
  RSTP => '0' --to_std_logic(start_pipe(RD_LAT))  -- 1-bit input: Reset input for PREG
);

end architecture SDP;
