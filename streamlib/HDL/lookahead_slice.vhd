library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

use work.types.all;

entity lookahead_slice is
generic(
	WIDTH:integer:=CHUNK_BITS*BUS_CHUNKS
);
port (
  clk:in std_logic;
  reset:in std_logic;
  -- Input interface
  stream_in:in std_logic_vector(WIDTH-1 downto 0);
  ready_out:out boolean;
  valid_in:in boolean;
  -- lookahead interface
  lookahead:out std_logic_vector(WIDTH-1 downto 0);
  lookahead_valid:out boolean;
  -- Output interface
  stream:out std_logic_vector(WIDTH-1 downto 0);
  ready:in boolean;
  valid:out boolean
  --last:out boolean
);
end entity lookahead_slice;
--
architecture RTL of lookahead_slice is
--
signal lookahead_int,stream_reg:std_logic_vector(WIDTH-1 downto 0);
signal valid_int,lookahead_valid_int,reg_ready:boolean;
signal input_handshake,output_handshake,shift:boolean;
signal reg_valid:boolean;

begin
--ready_out <= reg_ready;
valid <= valid_int; --valid1 when read_sel='0' else valid2;
lookahead_valid <= lookahead_valid_int;
lookahead <= lookahead_int;
--ready_out_int <= not lookahead_valid_int;

output_handshake <= ready and valid_int;
input_handshake <= reg_ready and reg_valid;
shift <= output_handshake or not valid_int;
reg_ready <= output_handshake or shift;

-- inefficient but need to break ready combinatorial path
inputReg:entity work.register_slice
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_in,
  ready_out => ready_out,
  valid_in  => valid_in,
  stream => stream_reg,
  ready => reg_ready,
  valid => reg_valid
);

reg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    lookahead_valid_int <= FALSE;
    lookahead_int <= (others => '-');
    stream <= (others => '-');
  else
  	
  	if input_handshake then
  		lookahead_int <= stream_reg;
			lookahead_valid_int <= TRUE;
  	end if;
		
  	if shift then
 			stream <= lookahead_int;
 			valid_int <= lookahead_valid_int;
 			lookahead_valid_int <= input_handshake;
  	end if;
  	
  end if;
end if;
end process reg;
end architecture RTL;
