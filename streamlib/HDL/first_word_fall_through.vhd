--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:21/03/2014 
--
-- Design Name: TES_digitiser
-- Module Name: ram_serialiser
-- Project Name: teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;

--! buffer from RAM to stream interface, handling ram read latency
entity first_word_fall_through is
generic(
  DATA_BITS:integer:=8
);
port(
  clk:in std_logic;
  -- synchronous reset
  reset:in std_logic;
  --
  ready_out:out boolean;
  --read_en:in boolean; 
  --last_read:in boolean; --change caller to use a ram word bit
  -- ram data
  data:in std_logic_vector(DATA_BITS-1 downto 0);
  data_valid:in boolean;
  pending:in boolean;
  --! stream interface
  stream:out std_logic_vector(DATA_BITS-1 downto 0);
  ready:in boolean;
  valid:out boolean
);
end entity first_word_fall_through;
--
architecture FSM of first_word_fall_through is
--

subtype ramword is std_logic_vector(DATA_BITS-1 downto 0);
signal reg1, reg2:ramword;
type FSMstate is (IDLE,REG_s,REG2_s);
signal state,nextstate:FSMstate;

signal valid_int,ready_int:boolean;
signal stream_int:ramword;
signal handshake:boolean;
begin


handshake <= valid_int and ready_int;
--ready_out <= not (state = FULL and not handshake);

FSMnextsate:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= IDLE;
    else
      state <= nextstate;
    end if;
  end if;
end process FSMnextsate;

FSMtransition:process(state,data,data_valid,handshake,reg1)
begin
  nextstate <= state;
  stream_int <= data;
  valid_int <= FALSE;
  case state is 
  when IDLE =>
    valid_int <= data_valid;
    if data_valid then 
      if not handshake then
        
        nextstate <= REG_s;
      end if;
    end if;
    
  when REG_s =>
    valid_int <= TRUE;
    stream_int <= reg1;
    if handshake then
      nextstate <= IDLE;
    end if;
  end case;
  
end process FSMtransition;

FSMoutput:process (clk) is
begin
  if rising_edge(clk) then
    if reset='1' then
      
    else
      case state is 
        when IDLE =>
          if data_valid then
            reg1 <= data;
          end if;
        when REG_s =>
          
        when REG2_s =>
          null;
      end case;
    end if;
  end if;
end process FSMoutput;

stream <= stream_int;
valid <= valid_int;
ready_int <= ready;

--outReg:entity work.stream_register
--generic map(
--  WIDTH => DATA_BITS
--)
--port map(
--  clk       => clk,
--  reset     => reset,
--  stream_in => stream_int,
--  ready_out => ready_int,
--  valid_in  => valid_int,
--  stream    => stream,
--  ready     => ready,
--  valid     => valid
--);

end architecture FSM;
