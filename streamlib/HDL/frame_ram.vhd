--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:09/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: stream_framer_TDP arch
-- Project Name: streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--use work.types.all;

--use stream.events.all;
-- random access writes frame converted to a stream
-- uses chunk lasts to set last output
--
entity frame_ram is
generic(
  CHUNKS:integer:=4;
  CHUNK_BITS:integer:=18; -- 8,9,16 or 18
  ADDRESS_BITS:integer:=4
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  din:in std_logic_vector(CHUNKS*CHUNK_BITS-1 downto 0);
  
  address:in unsigned(ADDRESS_BITS-1 downto 0);
  chunk_we:in boolean_vector(CHUNKS-1 downto 0);
  
  length:in unsigned(ADDRESS_BITS downto 0);
  commit:in boolean;
  
  free:out unsigned(ADDRESS_BITS downto 0);
  
  stream:out std_logic_vector(CHUNKS*CHUNK_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean
);
end entity frame_ram;

architecture SDP of frame_ram is
--
subtype word is std_logic_vector(CHUNKS*CHUNK_BITS-1 downto 0);
type frame_buffer is array (0 to 2**ADDRESS_BITS-1) of word;
     
signal frame_ram:frame_buffer;
signal input_word,ram_dout,ram_data,reg1,reg2,stream_int:word;
signal we:boolean_vector(CHUNKS-1 downto 0);
signal rd_ptr,rd_ptr_next,wr_addr,wr_ptr:unsigned(ADDRESS_BITS downto 0);
signal free_ram:unsigned(ADDRESS_BITS downto 0);
signal read_next,empty,handshake,ram_valid,good_commit:boolean;
signal msb_xor,msb_xor_next,ptr_equal,ptr_equal_next:boolean;
signal read_pipe:boolean_vector(1 to 2);
signal write_pipe:boolean_vector(1 to 3);
signal reg_ready:boolean;

type FSMstate is (EMPTY_S,REG1_S,REG2_S);
signal state:FSMstate;
signal valid_int:boolean;
signal ram_ready,one_pending,two_pending,none_pending:boolean;


begin
free <= free_ram;

--------------------------------------------------------------------------------
-- infer RAM 
--------------------------------------------------------------------------------
frameRAM:process(clk)
begin
if rising_edge(clk) then
  for i in 0 to CHUNKS-1 loop
    if we(i) then
      frame_ram(to_integer(to_0IfX(wr_addr(ADDRESS_BITS-1 downto 0)))) 
      		     ((i+1)*CHUNK_BITS-1 downto i*CHUNK_BITS)
                 <= input_word((i+1)*CHUNK_BITS-1 downto i*CHUNK_BITS);
    end if;
  end loop;
	ram_dout <= frame_ram(to_integer(to_0IfX(rd_ptr(ADDRESS_BITS-1 downto 0))));
  ram_data <= ram_dout; -- register output
end if;
end process frameRAM;

good_commit <= commit and (to_0IfX(length) <= to_0IfX(free_ram)) and 
               length /= 0;
msb_xor <= (wr_ptr(ADDRESS_BITS) xor rd_ptr(ADDRESS_BITS))='1';
msb_xor_next <= (wr_ptr(ADDRESS_BITS) xor rd_ptr_next(ADDRESS_BITS))='1';
ptr_equal <= wr_ptr(ADDRESS_BITS-1 downto 0) = rd_ptr(ADDRESS_BITS-1 downto 0);
ptr_equal_next 
  <= wr_ptr(ADDRESS_BITS-1 downto 0) = rd_ptr_next(ADDRESS_BITS-1 downto 0);

ramPointers:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    rd_ptr <= (ADDRESS_BITS => '1',others => '0');
    rd_ptr_next(ADDRESS_BITS) <= '1';
    rd_ptr_next(ADDRESS_BITS-1 downto 0) <= (0 => '1',others => '0');
    wr_ptr <= (others => '0');
    free_ram <= (ADDRESS_BITS => '1', others => '0');
    empty <= TRUE;
  else

  	input_word <= din;
  	--if address < free_ram then --This check is causing problems
      we <= chunk_we;
      wr_addr <= wr_ptr + address;
    --else
      --we <= (others => FALSE);
    --end if;
    
    if good_commit then
      wr_ptr <= wr_ptr + length; --only place wr_ptr can change
      if read_next then
        free_ram <= free_ram - length + 1;
      else
        free_ram <= free_ram - length;
      end if;
      empty <= FALSE;
   	else
   		if read_next then
	    	free_ram <= rd_ptr_next - wr_ptr;
        empty <= rd_ptr_next(ADDRESS_BITS-1 downto 0) = 
                 wr_ptr(ADDRESS_BITS-1 downto 0) and msb_xor_next;
	    else
	    	free_ram <= rd_ptr - wr_ptr;
        empty 
          <= rd_ptr(ADDRESS_BITS-1 downto 0) = wr_ptr(ADDRESS_BITS-1 downto 0) 
      			 and msb_xor_next; 
	    end if;
    end if;
    
    if read_next then
      rd_ptr <= rd_ptr_next;
      rd_ptr_next <= rd_ptr_next + 1;
    end if;
    
    write_pipe(1) <= good_commit and empty;
    write_pipe(2 to 3) <= write_pipe(1 to 2); 
    read_pipe(1) <= read_next;
    read_pipe(2) <= read_pipe(1) and not empty;
    
    if handshake or not ram_valid then
      ram_valid <= read_pipe(2) or write_pipe(3);
    end if;
    
  end if;
end if;
end process ramPointers;

read_next <= ram_ready and not empty;
none_pending <= not read_pipe(1) and not read_pipe(2);
one_pending  <= read_pipe(1) xor read_pipe(2);
two_pending <= read_pipe(1) and read_pipe(2);
handshake <= ram_valid and ram_ready;

FSMoutput:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= EMPTY_S;
    else
      case state is 
      when EMPTY_S =>
        if ram_valid and not reg_ready then
          state <= REG1_S;
          reg1 <= ram_data;
        end if;
      when REG1_S =>
        if reg_ready then
          if ram_valid then
            reg1 <= ram_data;
          else
            state <= EMPTY_S;
          end if;
        else
          if ram_valid then
            reg1 <= ram_data;
            reg2 <= reg1;
            state <= REG2_S;
          end if;
        end if;
      when REG2_S =>
        if reg_ready then
          if ram_valid then
            reg1 <= ram_data;
            reg2 <= reg1;
          else
            state <= REG1_S;
          end if;
        end if;
      end case;
    end if;
    end if;
end process FSMoutput;

outMux:process(state,ram_valid,ram_data,reg_ready,reg1,reg2,two_pending)
begin
  case state is 
  when EMPTY_S =>
    valid_int <= ram_valid;
    stream_int <= ram_data;
    ram_ready <= ram_valid;
  when REG1_S =>
    valid_int <= TRUE;
    stream_int <= reg1;
    if reg_ready then
      ram_ready <= TRUE;
    else
      ram_ready <= not two_pending;
    end if;
  when REG2_S =>
    valid_int <= TRUE;
    stream_int <= reg2;
    if reg_ready then
      ram_ready <= not two_pending;
    else
      ram_ready <= FALSE;
    end if;
  end case;
end process outMux;

streamReg:entity work.stream_register
generic map(
  WIDTH => CHUNKS*CHUNK_BITS
)
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_int,
  ready_out => reg_ready,
  valid_in => valid_int,
  stream => stream,
  ready => ready,
  valid => valid
);

end architecture SDP;