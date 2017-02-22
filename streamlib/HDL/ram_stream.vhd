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

--streams data from a RAM 
entity ram_stream is
generic(
  WIDTH:natural:=32;
  LATENCY:natural:=2 -- ram read latency
);
port (
  clk:in std_logic;
  reset:in std_logic;
 
  --the current RAM address is empty (data not valid) 
  empty:in boolean; 
  --a write when empty inserts a read in the pipeline
  --deassert empty when after writen data becomes valid
  write:in boolean; 
  
  last_incr_addr:in boolean; -- assert last with the data from the next address 
  incr_addr:out boolean; -- advance to the next address
  ram_data:in std_logic_vector(WIDTH-1 downto 0);
  
  --stream out
  stream:out std_logic_vector(WIDTH-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity ram_stream;

architecture beh of ram_stream is

signal one_pending,pipe_empty,pipe_full:boolean;
signal data_valid:boolean;
signal read_int:boolean;
signal shift:boolean;
signal data:std_logic_vector(WIDTH downto 0);
signal ram_valid,ram_used,last_int:boolean;

constant DEPTH:natural:=3; -- number of register stages DON'T change
type reg_pipe is array (1 to DEPTH) of std_logic_vector(WIDTH downto 0);
signal pipe:reg_pipe;
signal read_pipe,last_pipe:boolean_vector(1 to LATENCY):=(others => FALSE);

type FSMstate is (RAM_S,REG1_S,REG2_S,REG3_S);
signal state,nextstate:FSMstate;

--output register signals
signal valid_int,output_handshake,output_empty:boolean;

begin
assert LATENCY > 1 and LATENCY < 4 
       report "READ_LATENCY must be 2 or 3" severity FAILURE;

incr_addr <= read_int;
  
FSMoutput:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= RAM_S;
    else
      
      state <= nextstate;
      
      read_pipe <= ((read_int and not empty) or (write and empty))  &
                   read_pipe(1 to LATENCY-1);
      last_pipe <= (read_int and not empty and last_incr_addr) & 
                   last_pipe(1 to LATENCY-1); 
                   
      if ram_used or not ram_valid then
        ram_valid <= read_pipe(LATENCY);
        last_int <= last_pipe(LATENCY);
      end if;
      
      if shift then 
        pipe <= (to_std_logic(last_int) & ram_data) & pipe(1 to DEPTH-1);
      end if;
      
    end if;
  end if;
end process FSMoutput;

--TODO replace with two output LUTS
pipeOccupancy:process(read_pipe)
begin
  if LATENCY=3 then
    pipe_empty <= not read_pipe(1) and not read_pipe(2) and not read_pipe(3);
    one_pending  <= (read_pipe(1) and not read_pipe(2) and not read_pipe(3)) or
                    (read_pipe(2) and not read_pipe(1) and not read_pipe(3)) or
                    (read_pipe(3) and not read_pipe(1) and not read_pipe(2));
--    two_pending <= (read_pipe(1) and read_pipe(2) and not read_pipe(3)) or
--                   (read_pipe(2) and read_pipe(3) and not read_pipe(1)) or
--                   (read_pipe(1) and read_pipe(3) and not read_pipe(2));
    pipe_full <= read_pipe(1) and read_pipe(2) and read_pipe(3);
  else
    pipe_empty <= not read_pipe(1) and not read_pipe(2);
    one_pending  <= read_pipe(1) xor read_pipe(2);
    pipe_full <= read_pipe(1) and read_pipe(2);
  end if;
end process pipeOccupancy;


fsmTransition:process(
  state,ram_valid,ram_data,pipe_empty,empty,pipe,last_int,output_empty,
  one_pending,pipe_full,read_pipe
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
        read_int <= not pipe_full and not empty;
        nextstate <= REG1_S;
        shift <= TRUE;
        ram_used <= TRUE;
      else
        read_int <= not empty;
      end if;
        
--      if read_pipe(LATENCY) and ram_valid then
--        nextstate <= REG1_S;
--        shift <= TRUE;
--        ram_used <= TRUE;
--      end if;
    end if;
    
  when REG1_S =>
    
    data_valid <= TRUE;
    data <= pipe(1);
    --ram_used <= TRUE;
    
    if output_empty then
      if ram_valid then
--        if read_pipe(LATENCY) then
          read_int <= not pipe_full and not empty;
          shift <= TRUE;
          ram_used <= TRUE;
--        else
--          nextstate <= RAM_S;
--          read_int <= not empty;
--        end if;
      else
        read_int <= not empty;
        nextstate <= RAM_S;
      end if;
    else
      if ram_valid then
        read_int <= (pipe_empty or one_pending) and not empty;
--        if read_pipe(LATENCY) then
          nextstate <= REG2_S;
          shift <= TRUE;
          ram_used <= TRUE;
--        end if;
      else
        read_int <= not pipe_full and not empty;
      end if;
    end if;
    
  when REG2_S =>
    
    data_valid <= TRUE;
    data <= pipe(2);
    
    if output_empty then
      if ram_valid then
--        if read_pipe(LATENCY) then
          read_int <= (pipe_empty or one_pending) and not empty;
          shift <= TRUE;
          ram_used <= TRUE;
--        else
--          read_int <= (not pipe_full) and not empty;
--          nextstate <= REG1_S;
--        end if;
      else
        read_int <= (not pipe_full) and not empty;
        nextstate <= REG1_S;
      end if;
    else
      if ram_valid then
--        if read_pipe(LATENCY) then
          read_int <= pipe_empty and not empty;
          nextstate <= REG3_S;
          shift <= TRUE;
          ram_used <= TRUE;
--        else
--          read_int <= (pipe_empty or one_pending) and not empty;
--          --nextstate <= REG1_S;
--        end if;
      else
        read_int <= (pipe_empty or one_pending) and not empty;
      end if;
    end if;
   
  when REG3_S =>
    
    data_valid <= TRUE;
    --ram_used <= output_empty;
    data <= pipe(3);
    
    if output_empty then
      if ram_valid then
        read_int <= pipe_empty and not empty;
        shift <= TRUE;
        ram_used <= TRUE;
      else
        read_int <= (pipe_empty or one_pending) and not empty;
        nextstate <= REG2_S;
      end if;
    else
      if read_pipe(LATENCY) and ram_valid then
        assert FALSE report "new ram data while full" severity FAILURE;
      end if;
      if not ram_valid then
        read_int <= pipe_empty and not empty;
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
			--ready_int <= TRUE;
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
