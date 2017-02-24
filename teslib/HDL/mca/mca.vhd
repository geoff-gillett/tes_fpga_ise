--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:01/03/2014 
--
-- Design Name: TES_digitiser
-- Module Name: MCA_controller
-- Project Name: TES_digitiser
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

library mcalib;

use work.events.all;
use work.registers.all;

use work.types.all;
use work.functions.all;

entity mca is
generic(
  CHANNELS:integer:=8;
  ADDRESS_BITS:integer:=14;
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICKCOUNT_BITS:integer:=32;
  TICKPERIOD_BITS:integer:=32;
  VALUE_PIPE_DEPTH:natural:=1;
  MINIMUM_TICK_PERIOD:natural:=16;
  ENDIANNESS:string:="LITTLE"
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  updated:out boolean; --high for 4 clk after the update is done (CPU interrupt)
  ------------------------------------------------------------------------------
  -- control signals
  ------------------------------------------------------------------------------
  registers:in mca_registers_t;
  tick_period:in unsigned(TICKPERIOD_BITS-1 downto 0);
  
  ------------------------------------------------------------------------------
  -- selects out to muxs
  ------------------------------------------------------------------------------
  channel_select:out std_logic_vector(CHANNELS-1 downto 0);
  value_select:out std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
  trigger_select:out std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
  qualifier_select:out std_logic_vector(NUM_MCA_QUAL_D-1 downto 0);
  
  ------------------------------------------------------------------------------
  -- inputs from channels
  ------------------------------------------------------------------------------
  value:in signed(VALUE_BITS-1 downto 0);
  value_valid:in boolean;
  
  ------------------------------------------------------------------------------
  -- stream output (stream includes last and keep)
  ------------------------------------------------------------------------------
  stream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity mca;
--
architecture RTL of mca is
constant DEPTH:integer:=VALUE_PIPE_DEPTH+3;

-- control registers -----------------------------------------------------------
signal ticks_remaining:unsigned(TICKCOUNT_BITS-1 downto 0);
signal last_tick:boolean;
signal registers_enabled,updated_enabled,current_enabled,header_enabled:boolean;

-- FSM signals -----------------------------------------------------------------
type controlFSMstate is (IDLE,ASAP,ON_COMPLETION,RUN);
signal control_state,control_nextstate:controlFSMstate;
type streamFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,HEADER3,HEADER4,
												DISTRIBUTION);
--pipelining
signal update_pipe:boolean_vector(0 to DEPTH);
signal tick_pipe:boolean_vector(0 to DEPTH);
signal swap_pipe:boolean_vector(0 to DEPTH);

signal stream_state,stream_nextstate:streamFSMstate;
signal counts:std_logic_vector(COUNTER_BITS-1 downto 0);
signal can_swap:boolean;
signal update:boolean;
signal timestamp,start_time,stop_time:unsigned(TIMESTAMP_BITS-1 downto 0);
-- registers saved when update asserted
signal updated_reg,header_reg,current_reg:mca_registers_t;

-- register values for the current MCA frame
signal outstream,countstream:streambus_t;
signal outstream_valid,outstream_ready:boolean;
signal countstream_valid,countstream_ready:boolean;
signal countstream_handshake,countstream_empty,upper:boolean;

--------------------------------------------------------------------------------
-- MCA protocol
--------------------------------------------------------------------------------
-- header
--      packet                                  
-- word offset  |  16   |      16       |      32      |
-- 0    24      | size  |   last_bin    | lowest_value |
-- 1    32      | resvd | most_frequent |     flags    | 
-- 2    40      |                 total                |
-- 3    48      |             start_time               |
-- 4    56      |              stop_time               |
				 
type mca_flags_t is record  -- 32 bits
  qualifier:mca_qual_d;
	value:mca_value_d; --4
	trigger:mca_trigger_d; --4
	bin_n:unsigned(MCA_BIN_N_BITS-1 downto 0); --5
	channel:unsigned(MCA_CHANNEL_WIDTH-1 downto 0); --3
end record;

function to_std_logic(f:mca_flags_t) return std_logic_vector is
begin
	return resize(
	         to_std_logic(f.qualifier,4) &
	         to_std_logic(f.value,4) & --??
	         to_std_logic(f.trigger,4) &
	         to_std_logic(f.bin_n) &
				   to_std_logic(f.channel),
				   32
				 );
end function;

type mca_header_t is record
	size:unsigned(CHUNK_DATABITS-1 downto 0);
	last_bin:unsigned(CHUNK_DATABITS-1 downto 0);
	flags:mca_flags_t;
	lowest_value:signed(2*CHUNK_DATABITS-1 downto 0);
	most_frequent:unsigned(CHUNK_DATABITS-1 downto 0);
	total:unsigned(MCA_TOTAL_BITS-1 downto 0);
	start_time:unsigned(4*CHUNK_DATABITS-1 downto 0);
	stop_time:unsigned(4*CHUNK_DATABITS-1 downto 0);
end record;
signal header:mca_header_t;

function to_std_logic(
	h:mca_header_t;
	w:natural range 0 to 4; -- word number
	e:string
) return std_logic_vector is
begin
	case w is 
	when 0 => 
		return set_endianness(h.size,e) &
					 set_endianness(h.last_bin,e) &
					 set_endianness(h.lowest_value,e);
	when 1 =>
		return to_std_logic(0,16) &
					 set_endianness(h.most_frequent,e) &
					 set_endianness(to_std_logic(h.flags),endianness); 
	when 2 =>
		return set_endianness(h.total,e);
	when 3 =>
		return set_endianness(h.start_time,e);
	when 4 =>
		return set_endianness(h.stop_time,e);
	end case;
end function;

function to_streambus(
	h:mca_header_t;
	w:natural range 0 to 4; -- word number
	e:string
) return streambus_t is
	variable sb:streambus_t;
begin
	sb.data:=to_std_logic(h,w,e);
	sb.discard:=(others => FALSE);	
	sb.last:=(others => FALSE);	
	return sb;
end function;

--debug
--constant DEBUG:string:="FALSE";
--attribute MARK_DEBUG:string;
--attribute MARK_DEBUG of update_asap:signal is DEBUG;

signal swap:boolean;
signal total_in_bounds:unsigned(TOTAL_BITS-1 downto 0);
signal most_frequent_bin:unsigned(ADDRESS_BITS-1 downto 0);
signal new_most_frequent_bin:boolean;
signal most_frequent_count:unsigned(COUNTER_BITS-1 downto 0);
signal new_most_frequent:boolean;
signal swapped:boolean;
signal mca_stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal mca_valid:boolean;
signal mca_ready:boolean;
signal mca_last:boolean;
signal updated_int:boolean;
signal updated_count:integer range 0 to 4;
signal start:boolean;
signal bin_n:unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0);
signal last_bin:unsigned(ADDRESS_BITS-1 downto 0);

--attribute equivalent_register_removal:string;
--attribute equivalent_register_removal of :entity is "no";
begin
  
--------------------------------------------------------------------------------
-- Control processes and FSM
--------------------------------------------------------------------------------
updated <= updated_int;
update <= registers.update_asap or registers.update_on_completion;

controlReg:process(clk)
begin 
if rising_edge(clk) then
	if reset='1' then
		current_reg.trigger <= DISABLED_MCA_TRIGGER_D;
		current_reg.ticks <= (others => '0');
		channel_select <= (others => '0');
		value_select <= (others => '0');
		trigger_select <= (others => '0');
		qualifier_select <= (0 => '1',others => '0');
  	updated_int <= FALSE;
  	updated_count <= 0;
	else
	  
	  -- updated used for CPU interrupt needs to stay high for 4 clocks.
		if update_pipe(DEPTH-1) then
		  updated_count <= 4;
		elsif updated_count/=0 then
		  updated_count <= updated_count-1;
		end if;
		updated_int <= updated_count/=0;
		
  	if update then
  		updated_reg <= registers;
  		updated_enabled <= registers_enabled;
    end if;
    
    if update_pipe(0) then 
      current_reg <= updated_reg;
      current_enabled <= updated_enabled;
    end if;
   
    if swap_pipe(0) then
      header_reg <= current_reg;
      header_enabled <= current_enabled;
    end if;
--    if swapped then --??? check
--      if control_state=IDLE then
--        header_reg <= updated_reg;
--        header_enabled <= updated_enabled;
--      else
--        header_reg <= current_reg;
--        header_enabled <= current_enabled;
--      end if;
--    end if;
    
    if update_pipe(DEPTH-VALUE_PIPE_DEPTH-2) then
    	trigger_select <= to_onehot(current_reg.trigger);	
    	value_select <= to_onehot(current_reg.value);
    	qualifier_select <= to_onehot(current_reg.qualifier);
    end if;
    
    if update_pipe(DEPTH-1) then 
    	channel_select <= to_onehot(current_reg.channel,CHANNELS);
    end if;
    
  end if;
end if;
end process controlReg;

--------------------------------------------------------------------------------
-- control FSM 
--------------------------------------------------------------------------------
controlFSMnextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    control_state <= IDLE;
  else
    control_state <= control_nextstate;
  end if;
end if;
end process controlFSMnextstate;

registers_enabled 
  <= registers.trigger/=DISABLED_MCA_TRIGGER_D and registers.ticks/=0;

controlFSMtransition:process(
  control_state,registers.update_asap,registers.update_on_completion,can_swap,
  swap,last_tick,tick_pipe,update_pipe,current_enabled
)
begin
  
control_nextstate <= control_state;

case control_state is 
  
when IDLE =>
  swap_pipe(0) <= FALSE;
  update_pipe(0) <= FALSE;
  
  if registers.update_asap then
    control_nextstate <= ASAP;
  elsif registers.update_on_completion then
    control_nextstate <= ON_COMPLETION;
  end if;
	
when RUN =>
  swap_pipe(0) <= last_tick and tick_pipe(0) and can_swap;
  update_pipe(0) <= FALSE;
  if registers.update_asap then   
    control_nextstate <= ASAP;
  elsif registers.update_on_completion then 
    control_nextstate <= ON_COMPLETION;
  elsif update_pipe(DEPTH) and not current_enabled then
    control_nextstate <= IDLE;
  end if;
  
when ASAP =>
  update_pipe(0) <= tick_pipe(0) and can_swap;
  swap_pipe(0) <= tick_pipe(0) and can_swap;
  if registers.update_on_completion then
    control_nextstate <= ON_COMPLETION;
  elsif update_pipe(DEPTH) then 
    if current_enabled then
      control_nextstate <= RUN;
    else
      control_nextstate <= IDLE;
    end if;
  end if;
  
when ON_COMPLETION => 
  update_pipe(0) <= tick_pipe(0) and last_tick;
  swap_pipe(0) <= tick_pipe(0) and last_tick;
  if tick_pipe(0) and last_tick and can_swap then
    control_nextstate <= RUN; 
  elsif registers.update_asap then
    control_nextstate <= ASAP;
  elsif swap and not current_enabled then
    control_nextstate <= IDLE;
  end if;
  
end case;
end process controlFSMtransition;

--------------------------------------------------------------------------------
-- Tick counter and timing
--------------------------------------------------------------------------------
ticker:entity work.tick_counter
generic map(
  MINIMUM_PERIOD => MINIMUM_TICK_PERIOD,
  TICK_BITS => TICKPERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  INIT => -DEPTH
)
port map(
  clk => clk,
  reset => reset,
  tick => tick_pipe(0), 
  time_stamp => timestamp,
  period => tick_period,
  current_period => open
);

-- the 0 of each pipe is not a register in the pipeline but the next signal
-- to be shifted in.
piplines:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			tick_pipe(1 to DEPTH) <= (others => FALSE);	
			update_pipe(1 to DEPTH) <= (others => FALSE);	
			swap_pipe(1 to DEPTH) <= (others => FALSE);	
		else
			tick_pipe(1 to DEPTH) <= tick_pipe(0) & tick_pipe(1 to DEPTH-1);
			update_pipe(1 to DEPTH) <= update_pipe(0) & update_pipe(1 to DEPTH-1);
			swap_pipe(1 to DEPTH) <= swap_pipe(0) & swap_pipe(1 to DEPTH-1);
		end if;
	end if;
end process piplines;

tickCounter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    ticks_remaining <= (others => '0');
    last_tick <= TRUE;
  else
    if swap_pipe(DEPTH) then
      ticks_remaining <= current_reg.ticks-1;
      last_tick <= current_reg.ticks=1;
    elsif tick_pipe(DEPTH) and not last_tick then
      last_tick <= ticks_remaining=1;
      ticks_remaining <= ticks_remaining-1;
    end if;
  end if;
end if;
end process tickCounter;

--------------------------------------------------------------------------------
-- Stream processes and FSM
--------------------------------------------------------------------------------
streamFSMnextstate:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      stream_state <= IDLE;
    else
      stream_state <= stream_nextstate;
    end if;
  end if;
end process streamFSMnextstate;

protocolHeader:process (clk) is
begin
	if rising_edge(clk) then

	  if swap_pipe(0) then --coincident with tick
			stop_time <= timestamp;
		end if;
	
	  start <= swap_pipe(0);
		
		if start then
			header.start_time <= start_time;
			header.stop_time <= stop_time;
			start_time <= timestamp;
		end if;
	  
		if swapped then --becomes readable after swap
			header.total <= total_in_bounds;
			header.most_frequent <= resize(most_frequent_bin,CHUNK_DATABITS);
		
    	header.size <= shift_right(resize(header_reg.last_bin,SIZE_BITS),1) + 7;
    	               
    	header.flags.bin_n <= header_reg.bin_n;
    	header.flags.qualifier <= header_reg.qualifier;
    	header.flags.channel <= header_reg.channel;
    	header.flags.trigger <= header_reg.trigger;
    	header.flags.value <= header_reg.value;
    	header.last_bin <= resize(header_reg.last_bin,CHUNK_DATABITS);
    	header.lowest_value 
    		<= resize(header_reg.lowest_value,2*CHUNK_DATABITS);
		end if;
	end if;
end process protocolHeader;

streamFSMtransition:process(
  stream_state,swapped,countstream,countstream_valid,outstream_ready,header,
  countstream_handshake,header_enabled
)
begin
stream_nextstate <= stream_state;
outstream.discard <= (others => FALSE);
outstream.last <= (others => FALSE);
case stream_state is 
when IDLE =>
	outstream_valid <= FALSE;
	outstream.data <= (others => '-');	
	countstream_ready <= FALSE;
  if swapped and header_enabled then
    stream_nextstate <= HEADER0;
  end if;
when HEADER0 =>
		outstream_valid <= TRUE;
		outstream <= to_streambus(header,0,ENDIANNESS);
		countstream_ready <= FALSE;
    if outstream_ready then
      stream_nextstate <= HEADER1;
    end if;
when HEADER1 =>
		outstream_valid <= TRUE;
		outstream <= to_streambus(header,1,ENDIANNESS);
		countstream_ready <= FALSE;
    if outstream_ready then
      stream_nextstate <= HEADER2;
    end if;
when HEADER2 =>
		outstream_valid <= TRUE;
		outstream <= to_streambus(header,2,ENDIANNESS);
		countstream_ready <= FALSE;
    if outstream_ready then
      stream_nextstate <= HEADER3;
    end if;
when HEADER3 =>
		outstream_valid <= TRUE;
		outstream <= to_streambus(header,3,ENDIANNESS);
		countstream_ready <= FALSE;
    if outstream_ready then
      stream_nextstate <= HEADER4;
    end if;
when HEADER4 =>
		outstream_valid <= TRUE;
		outstream <= to_streambus(header,4,ENDIANNESS);
		countstream_ready <= FALSE;
    if outstream_ready then
      stream_nextstate <= DISTRIBUTION;
    end if;
when DISTRIBUTION =>
  	outstream_valid <= countstream_valid;
    outstream <= countstream;
    countstream_ready <= outstream_ready;
    if countstream.last(0) and countstream_handshake then
      stream_nextstate <= IDLE;
    end if;
end case;
end process streamFSMtransition;

swap <= swap_pipe(4);
bin_n <= resize(current_reg.bin_n,ceilLog2(ADDRESS_BITS));
last_bin <= resize(current_reg.last_bin,ADDRESS_BITS);

mca:entity mcalib.axi_mca
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  TOTAL_BITS => TOTAL_BITS,
  VALUE_BITS => VALUE_BITS,
  COUNTER_BITS => COUNTER_BITS
)
port map(
  clk => clk,
  reset => reset,
  value => value,
  value_valid => value_valid,
  swap => swap,
  enabled => current_enabled,
  can_swap => can_swap,
  bin_n => bin_n,
  last_bin => last_bin,
  lowest_value => current_reg.lowest_value,
  total_in_bounds => total_in_bounds,
  most_frequent_bin => most_frequent_bin,
  new_most_frequent_bin => new_most_frequent_bin,
  most_frequent_count => most_frequent_count,
  new_most_frequent => new_most_frequent,
  swapped => swapped,
  stream => mca_stream,
  valid => mca_valid,
  ready => mca_ready,
  last => mca_last
);

mca_ready <= upper or countstream_empty;
countRegister:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      countstream.data <= (others => '-');
      countstream.last  <= (others => FALSE); 
      countstream.discard  <= (others => FALSE); 
      countstream_valid <= FALSE;
      upper <= TRUE;
    else
      if mca_valid then
        if upper then
          counts <=  mca_stream; 
          upper  <= FALSE; 
          if countstream_handshake then
            countstream_valid <= FALSE;
          end if;
        elsif countstream_empty then
          countstream.data(31 downto 0) 
            <= set_endianness(mca_stream,ENDIANNESS);
          countstream.data(63 downto 32) <= set_endianness(counts,ENDIANNESS);
          countstream.last(0) <= mca_last;
          upper <= TRUE;
          countstream_valid <= TRUE;
        end if;
      else
          if countstream_handshake then
            countstream_valid <= FALSE;
          end if;
      end if;
          
    end if;
  end if;
end process countRegister;
countstream_handshake <= countstream_valid and countstream_ready;
countstream_empty <= not countstream_valid or countstream_handshake;

outstreamReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => outstream,
  ready_out => outstream_ready,
  valid_in => outstream_valid,
  stream => stream,
  ready => ready,
  valid => valid
);

end architecture RTL;
