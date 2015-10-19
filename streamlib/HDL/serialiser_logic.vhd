--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:19/06/2014 
--
-- Design Name: TES_digitiser
-- Module Name: ram_pipe_logic
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

entity serialiser_logic is
generic(
  -- 2 or 3 --TODO check latency=3 works correctly
  LATENCY:integer:=2
);
port(
  clk:in std_logic;
  reset:in std_logic;
  -- shift address
  address:out integer range 0 to LATENCY;
  --
  read_ram:out boolean;
  read_ram_pipe:in boolean_vector(1 to LATENCY);
  -- 
  read_stream:in boolean
  --shift_in:in boolean
);
end entity serialiser_logic;

architecture RTL of serialiser_logic is
  
signal new_addr,addr:integer range 0 to LATENCY;
signal LUT_in:std_logic_vector(5 downto 0);
signal LUT4_in:std_logic_vector(3 downto 0);
signal read_pipe:std_logic_vector(1 to LATENCY);
signal read:boolean;
begin
--
address <= addr;
read_ram <= read;
--------------------------------------------------------------------------------
-- address FSM
--------------------------------------------------------------------------------
LUT4_in <= to_std_logic(read_ram_pipe(LATENCY)) & 
           to_std_logic(to_unsigned(addr,2)) & to_std_logic(read_stream);
--
outputReg:process (clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      addr <= 0;
      --read_ram <= FALSE;
    else
    	--read_ram <= read;
      addr <= new_addr;
    end if;
  end if;
end process outputReg;
--
nextAddr:process(LUT4_in)
begin
if LATENCY=3 then
  --1:inc 2:addr 1:dec 
  case LUT4_in is
    -- addr=0
    when "0000" => new_addr <= 0;
    when "1000" => new_addr <= 1;
    when "0001" => new_addr <= 0;
    when "1001" => new_addr <= 0;
    -- addr=1
    when "0010" => new_addr <= 1;
    when "1010" => new_addr <= 2;
    when "0011" => new_addr <= 0;
    when "1011" => new_addr <= 1;
    -- addr=2
    when "0100" => new_addr <= 2;
    when "1100" => new_addr <= 3;
    when "0101" => new_addr <= 1;
    when "1101" => new_addr <= 2;
    -- addr=3
    when "0110" => new_addr <= 3;
    when "1110" => new_addr <= 3; -- should not happen
      report "serialiser logic addr:" & to_string(LUT4_in) severity FAILURE;
    when "0111" => new_addr <= 2;
    when "1111" => new_addr <= 3;
    when others  => new_addr <= 0; 
      report "serialiser logic undef:" & to_string(LUT4_in) severity WARNING;
  end case; 
elsif LATENCY=2 then
  case LUT4_in is
    -- addr=0
    when "0000" => new_addr <= 0;
    when "1000" => new_addr <= 1;
    when "0001" => new_addr <= 0;
    when "1001" => new_addr <= 0;
    -- addr=1
    when "0010" => new_addr <= 1;
    when "1010" => new_addr <= 2;
    when "0011" => new_addr <= 0;
    when "1011" => new_addr <= 1;
    -- addr=2
    when "0100" => new_addr <= 2;
    when "1100" => new_addr <= 2;
    when "0101" => new_addr <= 1;
    when "1101" => new_addr <= 2;
    -- addr=3 can't happen 
    when "0110" => new_addr <= 2;
      report "serialiser logic failure:" & to_string(LUT4_in) severity FAILURE;
    when "1110" => new_addr <= 2; 
      report "serialiser logic failure:" & to_string(LUT4_in) severity FAILURE;
    when "0111" => new_addr <= 2;
      report "serialiser logic failure:" & to_string(LUT4_in) severity FAILURE;
    when "1111" => new_addr <= 2;
      report "serialiser logic failure:" & to_string(LUT4_in) severity FAILURE;
    when others  => new_addr <= 0; 
      report "serialiser logic undef:" & to_string(LUT4_in) severity WARNING;
  end case; 
else
  report "LATENCY must be 2 or 3" severity FAILURE;
end if;
end process nextAddr;
--------------------------------------------------------------------------------
-- Logic for read ram should infer a LUT5 or LUT6 depending on latency 
--------------------------------------------------------------------------------
read_pipe <= to_std_logic(read_ram_pipe);
lutIn5:if LATENCY=2 generate
LUT_in <= '0' & read_pipe & to_std_logic(to_unsigned(addr,2)) & 
					to_std_logic(read_stream);
end generate;

lutIn6:if LATENCY=3 generate
LUT_in <= read_pipe & to_std_logic(to_unsigned(addr,2)) & 
					to_std_logic(read_stream);
end generate;
--
readRam:process(LUT_in) is
begin
if LATENCY=2 then 
  case LUT_in(4 downto 0) is
    --2: read_pipe :address: read_stream
    --  pending=0 : addr=0
    when "00000" => read <= TRUE;
    when "01000" => read <= TRUE;
    when "00001" => read <= TRUE;
    when "01001" => read <= TRUE;
    -- pending=0 : addr=1
    when "00010" => read <= TRUE;
    when "01010" => read <= FALSE;
    when "00011" => read <= TRUE;
    when "01011" => read <= TRUE;
    -- pending = 0 addr=2
    when "00100" => read <= FALSE;
    when "01100" => read <= FALSE; 
      --report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
      report "serialiser was failure:" & to_string(LUT_in) severity NOTE;
    when "00101" => read <= TRUE;
    when "01101" => read <= FALSE;
    -- pending=0 addr=3
    when "00110" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
    when "01110" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
    when "00111" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
    when "01111" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
    -- pending=1 addr=0
    when "10000" => read <= TRUE;
    -- pending=2 addr=0
    when "11000" => read <= FALSE; -- fails here 
      --report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
      report "was failure:" & to_string(LUT_in(4 downto 0)) severity NOTE;
    when "10001" => read <= TRUE;
    when "11001" => read <= TRUE;
    -- pending=1 addr=1
    when "10010" => read <= FALSE;
    when "11010" => read <= FALSE;
      --report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
      report "was failure:" & to_string(LUT_in(4 downto 0)) severity NOTE;
    when "10011" => read <= TRUE;
    when "11011" => read <= FALSE;
    -- pending=1 addr=2
    when "10100" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in(4 downto 0)) severity NOTE;
    when "11100" => read <= FALSE;  --here
      report "was failure:" & to_string(LUT_in(4 downto 0)) severity NOTE;
    when "10101" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in(4 downto 0)) severity FAILURE;
    when "11101" => read <= FALSE; -- here
      report "serialiser logic failure:" & to_string(LUT_in(4 downto 0)) severity NOTE;
    -- pending=1 addr=3
    when "10110" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in(4 downto 0)) severity FAILURE;
    when "11110" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in(4 downto 0)) severity FAILURE;
    when "10111" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in(4 downto 0)) severity FAILURE;
    when "11111" => read <= FALSE;
      report "serialiser logic failure:" & to_string(LUT_in(4 downto 0)) severity FAILURE;
    when others  => read <= FALSE;
      report "serialiser logic undef:" & to_string(LUT_in(4 downto 0)) severity WARNING;
  end case;
elsif LATENCY=3 then
  case LUT_in is
    --pending:address:out:in --FIXME maybe pending is wrong
    --  pending=0 : addr=0
    when "000000" => read <= TRUE;
    when "001000" => read <= TRUE;
    when "000001" => read <= TRUE;
    when "001001" => read <= TRUE;
    -- pending=0 : addr=1
    when "000010" => read <= TRUE;
    when "001010" => read <= TRUE;
    when "000011" => read <= TRUE;
    when "001011" => read <= TRUE;
    -- pending = 0 addr=2
    when "000100" => read <= TRUE;
    when "001100" => read <= FALSE; 
    when "000101" => read <= TRUE;
    when "001101" => read <= TRUE;
    -- pending = 0 addr=3 
    when "000110" => read <= FALSE;
    when "001110" => read <= FALSE;
    when "000111" => read <= TRUE;
    when "001111" => read <= TRUE;
    -- pending=1 addr=0
    when "010000" => read <= TRUE;
    when "011000" => read <= TRUE;
    when "010001" => read <= TRUE;
    when "011001" => read <= TRUE;
    -- pending=1 addr=1
    when "010010" => read <= TRUE;
    when "011010" => read <= FALSE;
    when "010011" => read <= TRUE;
    when "011011" => read <= TRUE;
    -- pending=1 addr=2
    when "010100" => read <= FALSE;
    when "011100" => read <= FALSE;
    when "010101" => read <= TRUE;
    when "011101" => read <= TRUE;
    -- pending=1 addr=3
    when "010110" => read <= FALSE;
      --report "serialiser logic failure:" & to_string(LUT_in) severity FAILURE;
    when "011110" => read <= FALSE;
    when "010111" => read <= FALSE;
    when "011111" => read <= FALSE;
    -- pending=2 addr=0
    when "100000" => read <= TRUE;
    when "101000" => read <= TRUE;
    when "100001" => read <= TRUE;
    when "101001" => read <= TRUE;
    -- pending=2 addr=1
    when "100010" => read <= TRUE;
    when "101010" => read <= FALSE;
    when "100011" => read <= TRUE;
    when "101011" => read <= TRUE;
    -- pending=2 addr=2
    when "100100" => read <= FALSE;
    when "101100" => read <= FALSE;
    when "100101" => read <= TRUE;
    when "101101" => read <= FALSE;
    -- pending=2 addr=3 -- this should not happen
    when "100110" => read <= FALSE;
    when "101110" => read <= FALSE;
    when "100111" => read <= FALSE;
    when "101111" => read <= FALSE;
    -- pending=3 addr=0 
    when "110000" => read <= TRUE;
    when "111000" => read <= FALSE;
    when "110001" => read <= TRUE;
    when "111001" => read <= TRUE;
    -- pending=3 addr=1 
    when "110010" => read <= FALSE;
    when "111010" => read <= FALSE;
    when "110011" => read <= TRUE;
    when "111011" => read <= FALSE;
    -- pending=3 addr=2 should not happen
    when "110100" => read <= FALSE;
    when "111100" => read <= FALSE;
    when "110101" => read <= FALSE;
    when "111101" => read <= FALSE;
    -- pending=3 addr=3 should not happen
    when "110110" => read <= FALSE;
    when "111110" => read <= FALSE;
    when "110111" => read <= FALSE;
    when "111111" => read <= FALSE;
    when others  => read <= FALSE;
      report "serialiser logic undef:" & to_string(LUT_in) severity WARNING;
  end case;
end if;
end process readRam;
  
end architecture RTL;