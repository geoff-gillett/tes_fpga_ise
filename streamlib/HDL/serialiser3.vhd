--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:2Feb.,2017
--
-- Design Name: TES_digitiser
-- Module Name: fwft
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

entity serialiser3 is
generic(
  WIDTH:natural:=32
  --ADDRESS_BITS:natural:=14
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  --start:in boolean; 
  empty:in boolean; --equiv empty
  write:in boolean;
  
  last_address:in boolean;
  read:out boolean;
  -- move address outside
  -- address:out std_logic_vector(ADDRESS_BITS-1 downto 0);
  ram_data:in std_logic_vector(WIDTH-1 downto 0);
  
  stream:out std_logic_vector(WIDTH-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
  
  
);
end entity serialiser3;

architecture beh of serialiser3 is

signal one_pending,two_pending,none_pending,three_pending:boolean;
signal data_valid:boolean;
signal read_int:boolean;
signal shift:boolean;
signal data:std_logic_vector(WIDTH downto 0);
signal ram_valid,ram_used,last_int:boolean;

constant DEPTH:natural:=3;
type reg_pipe is array (1 to DEPTH) of std_logic_vector(WIDTH downto 0);
signal pipe:reg_pipe;
signal read_pipe,last_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);

type FSMstate is (RAM_S,REG1_S,REG2_S,REG3_S);
signal state,nextstate:FSMstate;

--output register signals
signal ready_int,valid_int,output_handshake,output_empty:boolean;

begin
read <= read_int;
  
FSMoutput:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= RAM_S;
    else
      
      state <= nextstate;
      
      read_pipe <= ((read_int and not empty) or (write and empty))  &
                   read_pipe(1 to DEPTH-1);
      last_pipe <= (read_int and not empty and last_address) & 
                   last_pipe(1 to DEPTH-1); 
                   
      if ram_used or not ram_valid then
        ram_valid <= read_pipe(DEPTH);
        last_int <= last_pipe(DEPTH);
      end if;
      
      if shift then 
        pipe <= (to_std_logic(last_int) & ram_data) & pipe(1 to DEPTH-1);
      end if;
      
    end if;
  end if;
end process FSMoutput;

--TODO replace with two output LUTS
none_pending <= not read_pipe(1) and not read_pipe(2) and not read_pipe(3);
one_pending  <= (read_pipe(1) and not read_pipe(2) and not read_pipe(3)) or
                (read_pipe(2) and not read_pipe(1) and not read_pipe(3)) or
                (read_pipe(3) and not read_pipe(1) and not read_pipe(2));
two_pending <= (read_pipe(1) and read_pipe(2) and not read_pipe(3)) or
               (read_pipe(2) and read_pipe(3) and not read_pipe(1)) or
               (read_pipe(1) and read_pipe(3) and not read_pipe(2));
three_pending <= read_pipe(1) and read_pipe(2) and read_pipe(3);

fsmTransition:process(
  state,ram_valid,ram_data,two_pending,none_pending,empty,pipe, 
  last_int,output_empty,one_pending,three_pending,read_pipe
)
begin
  
  nextstate <= state;
  shift <= FALSE;
  read_int <= FALSE;
  ram_used <= FALSE;
  
  case state is 
  when RAM_S =>
    
    data_valid <= ram_valid;
    data <= to_std_logic(last_int) & ram_data;
     
    if output_empty then
      read_int <= not empty;
      ram_used <= TRUE;
    else
      if ram_valid then
        read_int <= not three_pending and not empty;
      else
        read_int <= not empty;
      end if;
        
      if read_pipe(DEPTH) and ram_valid then
        nextstate <= REG1_S;
        shift <= TRUE;
        ram_used <= TRUE;
      end if;
    end if;
    
  when REG1_S =>
    
    data_valid <= TRUE;
    data <= pipe(1);
    --ram_used <= TRUE;
    
    if output_empty then
      if ram_valid then
        if read_pipe(DEPTH) then
          read_int <= not three_pending and not empty;
          shift <= TRUE;
          ram_used <= TRUE;
        else
          nextstate <= RAM_S;
          read_int <= not empty;
        end if;
      else
        read_int <= not empty;
        nextstate <= RAM_S;
      end if;
    else
      if ram_valid then
        read_int <= (none_pending or one_pending) and not empty;
        if read_pipe(DEPTH) then
          nextstate <= REG2_S;
          shift <= TRUE;
          ram_used <= TRUE;
        end if;
      else
        read_int <= not three_pending and not empty;
      end if;
    end if;
    
  when REG2_S =>
    
    data_valid <= TRUE;
    data <= pipe(2);
    
    if output_empty then
      if ram_valid then
        if read_pipe(DEPTH) then
          read_int <= (none_pending or one_pending) and not empty;
          shift <= TRUE;
          ram_used <= TRUE;
        else
          read_int <= (not three_pending) and not empty;
          nextstate <= REG1_S;
        end if;
      else
        read_int <= (not three_pending) and not empty;
        nextstate <= REG1_S;
      end if;
    else
      if ram_valid then
        if read_pipe(DEPTH) then
          read_int <= none_pending and not empty;
          nextstate <= REG3_S;
          shift <= TRUE;
          ram_used <= TRUE;
        else
          read_int <= (none_pending or one_pending) and not empty;
          --nextstate <= REG1_S;
        end if;
      else
        read_int <= (none_pending or one_pending) and not empty;
      end if;
    end if;
   
  when REG3_S =>
    
    data_valid <= TRUE;
    --ram_used <= output_empty;
    data <= pipe(3);
    
    if output_empty then
      if ram_valid then
        read_int <= none_pending and not empty;
        shift <= TRUE;
        ram_used <= TRUE;
      else
        read_int <= (none_pending or one_pending) and not empty;
        nextstate <= REG2_S;
      end if;
    else
      if read_pipe(DEPTH) and ram_valid then
        assert FALSE report "new ram data while full" severity FAILURE;
      end if;
      if not ram_valid then
        read_int <= none_pending and not empty;
      end if;
    end if;
    
  end case;
end process fsmTransition;

output_empty <= output_handshake or not valid_int;
output_handshake <= ready and valid_int;
outputReg:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			ready_int <= TRUE;
			valid_int <= FALSE;
		else
      if output_handshake or not valid_int then
        stream <= data(WIDTH-1 downto 0);
        last <= to_boolean(data(WIDTH)) and data_valid;
        valid_int <= data_valid;
			end if;
		end if;
	end if;
end process outputReg;
valid <= valid_int;

end architecture beh;
