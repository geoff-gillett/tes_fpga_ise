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

-- random access writes frame converted to a stream
-- uses chunk lasts to set last output
--
entity frame_ram2 is
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
end entity frame_ram2;

architecture SDP of frame_ram2 is
--
subtype word is std_logic_vector(CHUNKS*CHUNK_BITS-1 downto 0);
type frame_buffer is array (0 to 2**ADDRESS_BITS-1) of word;
signal frame_ram:frame_buffer;

signal input_word,ram_dout,ram_data,reg1,reg2,reg_stream:word;
signal reg_ready,reg_valid,reg1_w,reg2_w:boolean;
signal we:boolean_vector(CHUNKS-1 downto 0);
signal rd_ptr,rd_ptr_next,wr_addr,wr_ptr:unsigned(ADDRESS_BITS downto 0);
signal free_ram,wr_ptr_next,length_reg:unsigned(ADDRESS_BITS downto 0);
signal address_reg:unsigned(ADDRESS_BITS-1 downto 0);
signal read_next,empty,ram_valid,good_commit:boolean;
signal msb_xor,msb_xor_next,ptr_equal,will_empty:boolean;
signal ram_ready,one_pending,two_pending,none_pending,commit_reg:boolean;
signal read_pipe:boolean_vector(1 to 2);

type FSMstate is (EMPTY_S,REG1_S,REG2_S);
signal state,nextstate:FSMstate;

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
will_empty 
  <= wr_ptr(ADDRESS_BITS-1 downto 0) = rd_ptr_next(ADDRESS_BITS-1 downto 0);

ramPointers:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    rd_ptr <= (ADDRESS_BITS => '1',others => '0');
    rd_ptr_next(ADDRESS_BITS) <= '1';
    rd_ptr_next(ADDRESS_BITS-1 downto 0) <= (0 => '1',others => '0');
    wr_ptr <= (others => '0');
    wr_ptr_next <= (others => '0');
    free_ram <= (ADDRESS_BITS => '1', others => '0');
    empty <= TRUE;
  else
    
    commit_reg <= good_commit;
  	input_word <= din;
  	length_reg <= length;
  	address_reg <= address;
    we <= chunk_we;
    
    wr_addr <= wr_ptr + address; 
    --offset <= length + ('0' & address);
    
    if good_commit then
      if read_next then
        free_ram <= free_ram - length + 1;
      else
        free_ram <= free_ram - length;
      end if;
      wr_ptr_next <= wr_ptr + length;
    elsif commit_reg then
      wr_ptr <= wr_ptr_next; --only place wr_ptr can change
      wr_addr <= wr_ptr_next + address; 
      empty <= FALSE; 
      if read_next then
        free_ram <= free_ram - 1;
      end if;
    else
   		if read_next then
	    	free_ram <= rd_ptr_next - wr_ptr;
        empty <= rd_ptr_next(ADDRESS_BITS-1 downto 0) = 
                 wr_ptr(ADDRESS_BITS-1 downto 0) and msb_xor_next;
	    else
	    	free_ram <= rd_ptr - wr_ptr;
        empty 
          <= rd_ptr(ADDRESS_BITS-1 downto 0) = wr_ptr(ADDRESS_BITS-1 downto 0) 
      			 and msb_xor; 
	    end if;
    end if;
    
    if read_next then
      rd_ptr <= rd_ptr_next;
      rd_ptr_next <= rd_ptr_next + 1;
    end if;
    
    read_pipe(1) <= (read_next or (commit_reg and empty)) and not will_empty;
    read_pipe(2) <= read_pipe(1);

    if (ram_valid and ram_ready) or not ram_valid then
      ram_valid <= read_pipe(2);
    end if;
    
  end if;
end if;
end process ramPointers;

none_pending <= not read_pipe(1) and not read_pipe(2);
one_pending  <= read_pipe(1) xor read_pipe(2);
two_pending <= read_pipe(1) and read_pipe(2);

FSMoutput:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= EMPTY_S;
    else
      
      state <= nextstate;
      
      if reg1_w then
        reg1 <= ram_data;
      end if;
      
      if reg2_w then
        reg2 <= reg1;
      end if;
      
    end if;
  end if;
end process FSMoutput;

outMux:process(state,ram_valid,ram_data,reg1,reg2,two_pending,none_pending,
  empty,reg_ready
)
begin
  
  nextstate <= state;
  reg1_w <= FALSE;
  reg2_w <= FALSE;
  
  case state is 
  when EMPTY_S =>
    
    reg_valid <= ram_valid;
    reg_stream <= ram_data;
    ram_ready <= TRUE;
    
    if ram_valid then 
      if reg_ready then
        read_next <= not empty;
      else
        nextstate <= REG1_S;
        reg1_w <= TRUE;
        read_next <= not two_pending and not empty;
      end if;
    else
      read_next <= not empty;-- and not empty_commit;
    end if;
    
  when REG1_S =>
    
    reg_valid <= TRUE;
    reg_stream <= reg1;
    ram_ready <= TRUE;
    
    if ram_valid then
      if reg_ready then
        read_next <= not two_pending and not empty;
        reg1_w <= TRUE;
      else
        nextstate <= REG2_S;
        reg1_w <= TRUE;
        reg2_w <= TRUE;
        read_next <= none_pending and not empty;
      end if;
    else
      if reg_ready then
        nextstate <= EMPTY_S;
        read_next <= not empty;-- and not empty_commit;
      else
        read_next <= not two_pending and not empty;-- and not empty_commit;
      end if;
    end if;
    
  when REG2_S =>
    
    reg_valid <= TRUE;
    reg_stream <= reg2;
    ram_ready <= reg_ready;
    
    if ram_valid then
      if reg_ready then
        reg1_w <= TRUE;
        reg2_w <= TRUE;
        read_next <= none_pending and not empty;
      else
        read_next <= FALSE;
      end if;
    else
      if reg_ready then
        nextstate <= REG1_S;
        read_next <= not two_pending and not empty;
      else
        read_next <= none_pending and not empty;
      end if; 
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
  stream_in => reg_stream,
  ready_out => reg_ready,
  valid_in => reg_valid,
  stream => stream,
  ready => ready,
  valid => valid
);

end architecture SDP;