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
  hold:in boolean; --equiv empty
  
  last_read:in boolean;
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

architecture RTL of serialiser3 is

--constant LATENCY:natural:=2; --ram read latency
signal read_pipe,last_pipe:boolean_vector(1 to 2):=(others => FALSE);

signal one_pending,two_pending,none_pending:boolean;
signal reg_ready,reg_valid,reg1_w,reg2_w,reg3_w:boolean;
signal read_int:boolean;
signal reg1,reg2,reg3, shift:std_logic_vector(WIDTH downto 0);
signal reg_stream,stream_int:std_logic_vector(WIDTH downto 0);
signal ram_valid,ram_ready,last_int:boolean;

type reg_pipe is array (1 to 3) of std_logic_vector(WIDTH downto 0);
signal pipe:reg_pipe;


type FSMstate is (EMPTY_S,REG1_S,REG2_S);
signal state,nextstate:FSMstate;

begin
read <= read_int;
  
FSMoutput:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      state <= EMPTY_S;
    else
      
      state <= nextstate;
      read_pipe <= (read_int and not hold) & read_pipe(1);
      last_pipe <= (read_int and not hold and last_read) & last_pipe(1);
      
      if (ram_valid and ram_ready) or not ram_valid then
        ram_valid <= read_pipe(2);
        last_int <= last_pipe(2);
      end if;
      
      if reg1_w then
        reg1 <= to_std_logic(last_int) & ram_data;
      end if;
      
      if reg2_w then
        reg2 <= reg1;
      end if;
      
      if reg3_w then
        reg2 <= reg1;
      end if;
      
    end if;
  end if;
end process FSMoutput;

none_pending <= not read_pipe(1) and not read_pipe(2);
one_pending  <= read_pipe(1) xor read_pipe(2);
two_pending <= read_pipe(1) and read_pipe(2);

fsmTransition:process(
  state,ram_valid,ram_data,reg1,reg2,two_pending,none_pending,reg_ready, hold, 
  last_int
)
begin
  
  nextstate <= state;
  reg1_w <= FALSE;
  reg2_w <= FALSE;
  
  case state is 
  when EMPTY_S =>
    
    reg_valid <= ram_valid;
    reg_stream <= to_std_logic(last_int) & ram_data;
    ram_ready <= TRUE;
    
    if ram_valid then 
      if reg_ready then
        read_int <= not hold;
      else
        nextstate <= REG1_S;
        reg1_w <= TRUE;
        read_int <= none_pending and not hold; --not will_empty
      end if;
    else
      read_int <= not two_pending and not hold;-- and not empty_commit;
    end if;
    
  when REG1_S =>
    
    reg_valid <= TRUE;
    reg_stream <= reg1;
    ram_ready <= TRUE;
    
    if ram_valid then
      if reg_ready then
        read_int <= not two_pending and not hold;
        reg1_w <= TRUE;
      else
        nextstate <= REG2_S;
        reg1_w <= TRUE;
        reg2_w <= TRUE;
        read_int <= FALSE;
      end if;
    else
      if reg_ready then
        nextstate <= EMPTY_S;
        read_int <= not hold;-- and not empty_commit;
      else
        read_int <= none_pending and not hold;-- and not empty_commit;
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
        read_int <= none_pending and not hold;
      else
        read_int <= FALSE;
      end if;
    else
      if reg_ready then
        nextstate <= REG1_S;
        read_int <= none_pending and not hold;
      else
        read_int <= FALSE;
      end if; 
    end if;
  end case;
end process fsmTransition;

streamReg:entity work.stream_register
generic map(
  WIDTH => WIDTH+1 --add last as MSB
)
port map(
  clk => clk,
  reset => reset,
  stream_in => reg_stream,
  ready_out => reg_ready,
  valid_in => reg_valid,
  stream => stream_int,
  ready => ready,
  valid => valid
);
last <= stream_int(WIDTH)='1';
stream <= stream_int(WIDTH-1 downto 0);

end architecture RTL;
