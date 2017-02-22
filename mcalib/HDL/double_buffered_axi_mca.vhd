--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: double_buffered_axi_mca
-- Project Name: mcalib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

-- Streaming double buffered Multi-channel analyser
entity double_buffered_axi_mca is
generic(
  --number of bins (channels) = 2**ADDRESS_BITS
  ADDRESS_BITS:integer:=14;
  --width of counters and stream
  --STREAM_CHUNKS:integer:=2;
  COUNTER_BITS:integer:=32;
  TOTAL_BITS:integer:=64
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  bin:in unsigned(ADDRESS_BITS-1 downto 0);
  bin_valid:in boolean;
  out_of_bounds:in boolean;
  
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0);
  -- values are counted in the new buffer *after* swap_buffer is asserted.
  swap:in boolean; -- strobe:swap and stream contents of current buffer.
  stop:in boolean; -- stop and stream contents of current buffer.
  can_swap:out boolean;
  
  -- probability distribution statistics
  total_in_bounds:out unsigned(TOTAL_BITS-1 downto 0);
  most_frequent_bin:out unsigned(ADDRESS_BITS-1 downto 0);
  new_most_frequent_bin:out boolean;
  most_frequent_count:out unsigned(COUNTER_BITS-1 downto 0);
  new_most_frequent:out boolean;
  swapped:out boolean; --strobe indicating when to capture stats after swap
  
  stream:out std_logic_vector(COUNTER_BITS-1 downto 0);
  valid:out boolean;
  last:out boolean;
  ready:in boolean
);
end entity double_buffered_axi_mca;
--
architecture SDP of double_buffered_axi_mca is
--------------------------------------------------------------------------------
--constant STREAM_BITS:integer:=STREAM_CHUNKS*CHUNK_DATABITS;
--------------------------------------------------------------------------------
type FSMstate is (IDLE,BUFF0,BUFF1,WAIT0,WAIT1);
type statFSMstate is (IDLE,BUFF0,BUFF1);
signal state,nextstate:FSMstate;
signal stat_state,stat_nextstate:statFSMstate;

-- stream register signals
signal stream_in:std_logic_vector(COUNTER_BITS downto 0);
signal ready_out:boolean;
signal valid_in:boolean;
-- buffer signals
signal swap0,swap0_reg,swap1,swap1_reg,idle0,idle1:boolean;
signal most_frequent_bin0,most_frequent_bin1:unsigned(ADDRESS_BITS-1 downto 0);
signal most_frequent_count0:unsigned(COUNTER_BITS-1 downto 0);
signal most_frequent_count1:unsigned(COUNTER_BITS-1 downto 0);
signal new_most_frequent_bin0,new_most_frequent_bin1:boolean;
signal new_most_frequent0,new_most_frequent1:boolean;
signal total_in_bounds0,total_in_bounds1:unsigned(TOTAL_BITS-1 downto 0);
signal swapped0,swapped1:boolean;
signal stream0,stream1:std_logic_vector(COUNTER_BITS-1 downto 0);
signal valid0,valid1,ready0,ready1,last0,last1:boolean;
signal stream_int:std_logic_vector(COUNTER_BITS downto 0);
signal bin_reg:unsigned(ADDRESS_BITS-1 downto 0);
signal oob_reg:boolean;
signal can_swap_int,swapped_int:boolean;
signal bin_valid0,bin_valid1:boolean;
--------------------------------------------------------------------------------

begin
  
stream <= stream_int(COUNTER_BITS-1 downto 0);
last <= to_boolean(stream_int(COUNTER_BITS));

buffer0:entity work.axi_mca_buffer
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS   => TOTAL_BITS
)
port map(
  clk => clk,
  reset => reset,
  last_bin => last_bin,
  swap => swap0_reg,
  mca_idle => idle0,
  bin => bin_reg,
  bin_valid => bin_valid0,
  out_of_bounds => oob_reg,
  most_frequent_bin => most_frequent_bin0,
  new_most_frequent_bin => new_most_frequent_bin0,
  most_frequent_count => most_frequent_count0,
  new_most_frequent => new_most_frequent0,
  total_in_bounds => total_in_bounds0,
  swapped => swapped0,
  stream => stream0,
  valid => valid0,
  ready => ready0,
  last => last0
);

buffer1:entity work.axi_mca_buffer
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TOTAL_BITS   => TOTAL_BITS
)
port map(
  clk => clk,
  reset => reset,
  last_bin => last_bin,
  swap => swap1_reg,
  mca_idle => idle1,
  bin => bin_reg,
  bin_valid => bin_valid1,
  out_of_bounds => oob_reg,
  most_frequent_bin => most_frequent_bin1,
  new_most_frequent_bin => new_most_frequent_bin1,
  most_frequent_count => most_frequent_count1,
  new_most_frequent => new_most_frequent1,
  total_in_bounds => total_in_bounds1,
  swapped => swapped1,
  stream => stream1,
  valid => valid1,
  ready => ready1,
  last => last1
);

--------------------------------------------------------------------------------
-- FSM 
--------------------------------------------------------------------------------
fsmNextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    state <= IDLE;    
    stat_state <= IDLE;
  else
    state <= nextstate;
    stat_state <= stat_nextstate;
  end if;
end if;
end process fsmNextstate;

fsmTransition:process(state,idle0,idle1,stop,swap)
begin
  nextstate <= state;
  can_swap_int <= FALSE;
  swap0 <= FALSE;
  swap1 <= FALSE;
  case state is 
    
  when IDLE =>
    can_swap_int <= TRUE;
    if swap then
      nextstate <= BUFF0;
      swap0 <= TRUE;
      can_swap_int <= idle1;
    end if;
      
  when BUFF0 =>
    if idle1 then
      can_swap_int <= TRUE;
      if swap then
        swap0 <= TRUE;
        swap1 <= TRUE;
        nextstate <= BUFF1;
        can_swap_int <= idle0;
      elsif stop then
        nextstate <= WAIT0;
        swap0 <= TRUE;
      end if;
    else
      can_swap_int <= FALSE;
      if stop then
        swap0 <= TRUE;
        nextstate <= WAIT1;
      end if;
    end if;
    
  when BUFF1 =>
    
    if idle0 then
      can_swap_int <= TRUE;
      if swap then
        swap0 <= TRUE;
        swap1 <= TRUE;
        nextstate <= BUFF0;
        can_swap_int <= idle1;
      elsif stop then
        nextstate <= WAIT1;
        swap1 <= TRUE;
      end if;
    else
      can_swap_int <= FALSE;
      if stop then
        nextstate <= WAIT0;
        swap1 <= TRUE;
      end if;
    end if;
    
  when WAIT0 => 
    can_swap_int <= FALSE;
    if idle0 then
      if idle1 then
        nextstate <= IDLE;
        can_swap_int <= TRUE;
      else
        nextstate <= WAIT1;
        can_swap_int <= idle1;
      end if;
    end if;
    
  when WAIT1 => 
    can_swap_int <= FALSE;
    if idle1 then
      if idle0 then
        nextstate <= IDLE;
        can_swap_int <= TRUE;
      else
        nextstate <= WAIT0;
      end if;
    end if;
  end case;
end process fsmTransition;

statTransition:process(stat_state,state,swapped0,swapped1,nextstate)
begin
  stat_nextstate <= stat_state;
  swapped_int <= FALSE;
  
  case stat_state is 
  when IDLE =>
    swapped_int <= FALSE;
    if state=BUFF0 then
      stat_nextstate <=  BUFF0;
    end if;
    if state=BUFF1 then
      stat_nextstate <= BUFF1;
    end if;
  when BUFF0 =>
    swapped_int <= swapped0;
    if nextstate=IDLE then
      stat_nextstate <= IDLE;
    elsif swapped0 then
      if state=BUFF1 or state=WAIT0 then
        stat_nextstate <= BUFF1;
      else
        stat_nextstate <= IDLE;
      end if;
    end if;
  when BUFF1 =>
    swapped_int <= swapped1;
    if nextstate=IDLE then
      stat_nextstate <= IDLE;
    elsif swapped1 then
      if state=BUFF0 or state=WAIT1 then
        stat_nextstate <= BUFF0;
      else
        stat_nextstate <= IDLE;
      end if;
    end if;
  end case;
  
end process statTransition;


streamMux:process(state,last0,last1,ready_out,stream0,stream1,valid0,valid1)
begin
  
  case state is 
  when IDLE =>
    valid_in <= FALSE;
    ready0 <= FALSE;
    ready1 <= FALSE;
    stream_in <= (others => '-');
      
  when BUFF0 | WAIT1 =>
    ready0 <= FALSE;
    ready1 <= ready_out;
    valid_in <= valid1;
    stream_in <= to_std_logic(last1) & stream1;
    
  when BUFF1 | WAIT0 =>
    ready0 <= ready_out;
    ready1 <= FALSE;
    valid_in <= valid0;
    stream_in <= to_std_logic(last0) & stream0;
    
  end case;
end process streamMux;

outputReg:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      oob_reg <= FALSE;
      bin_valid0 <= FALSE;
      bin_valid1 <= FALSE;
    else
      oob_reg <= out_of_bounds;
      bin_reg <= bin;
      swap0_reg <= swap0;
      swap1_reg <= swap1;
      swapped <= swapped_int;
      can_swap <= can_swap_int; 
      
      case state is 
        when BUFF0 =>
          bin_valid0 <= bin_valid;
          bin_valid1 <= FALSE;
        when BUFF1 =>
          bin_valid0 <= FALSE;
          bin_valid1 <= bin_valid;
        when others =>
          bin_valid0 <= FALSE;
          bin_valid1 <= FALSE;
      end case;
      
      case stat_state is
      when IDLE =>
        most_frequent_bin  <= (others => '-');
        new_most_frequent_bin <= FALSE;
        most_frequent_count <= (others => '-');
        new_most_frequent <= FALSE;
        total_in_bounds <= (others => '0');
          
      when BUFF0 =>
        most_frequent_bin <= most_frequent_bin0;
        new_most_frequent_bin <= new_most_frequent_bin0;
        most_frequent_count <= most_frequent_count0;
        new_most_frequent <= new_most_frequent0;
        total_in_bounds <= total_in_bounds0;
        
      when BUFF1 =>
        most_frequent_bin <= most_frequent_bin1;
        new_most_frequent_bin <= new_most_frequent_bin1;
        most_frequent_count <= most_frequent_count1;
        new_most_frequent <= new_most_frequent1;
        total_in_bounds <= total_in_bounds1;
        
      end case;
    end if;
  end if;
end process outputReg;

streamReg:entity streamlib.stream_register
generic map(
  WIDTH => COUNTER_BITS+1
)
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_in,
  ready_out => ready_out,
  valid_in => valid_in,
  stream => stream_int,
  ready => ready,
  valid => valid
);

end architecture SDP;
