library ieee;
use ieee.std_logic_1164.all;

library extensions;
use extensions.boolean_vector.all;

use work.types.all;

-- used to break combinatorial path of the ready signal
entity stream_register_user is
generic(
	WIDTH:natural:=CHUNK_BITS*BUS_CHUNKS;
	USER_WIDTH:natural:=16
);
port (
  clk:in std_logic;
  reset:in std_logic;
  -- Input interface
  stream_in:in std_logic_vector(WIDTH-1 downto 0);
  user_in:std_logic_vector(USER_WIDTH-1 downto 0);
  ready_out:out boolean;
  valid_in:in boolean;
  --last_in:boolean;
  -- Output interface
  user:out std_logic_vector(USER_WIDTH-1 downto 0);
  stream:out std_logic_vector(WIDTH-1 downto 0);
  ready:in boolean;
  valid:out boolean
  --last:out boolean
);
end entity stream_register_user;
--
architecture RTL of stream_register_user is

attribute clock_signal:string;
attribute clock_signal of clk:signal is "YES";

signal stream_reg:std_logic_vector(WIDTH+USER_WIDTH-1 downto 0);
signal valid_int,store_valid,ready_int:boolean;
signal input_handshake,output_handshake:boolean;

begin
ready_out <= ready_int;
valid <= valid_int; --valid1 when read_sel='0' else valid2;

input_handshake <= ready_int and valid_in;
output_handshake <= ready and valid_int;

regSlice:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			ready_int <= TRUE;
			valid_int <= FALSE;
		else
			
      if input_handshake then
        if output_handshake or not valid_int then
          stream <= stream_in;
          user <= user_in;
          valid_int <= TRUE;
          ready_int <= TRUE;
        elsif not store_valid then
          stream_reg <= stream_in & user_in;
          store_valid <= TRUE;
          ready_int <= FALSE;
        else 
        	ready_int <= FALSE;
        end if;
      else
        if output_handshake then
          stream <= stream_reg(WIDTH+USER_WIDTH-1 downto USER_WIDTH);
          user <= stream_reg(USER_WIDTH-1 downto 0);
          valid_int <= store_valid;
          store_valid <= FALSE;
          ready_int <= TRUE;
        else
        	ready_int <= not store_valid;
        end if;
      end if;
			
		end if;
	end if;
end process regSlice;

end architecture RTL;
