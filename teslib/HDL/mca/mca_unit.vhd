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

use work.adc.all;
use work.events.all;
use work.registers.all;
--use work.protocol.all;
use work.types.all;
use work.functions.all;

entity mca_unit is
generic(
  CHANNELS:integer:=8;
  ADDRESS_BITS:integer:=14;
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICKCOUNT_BITS:integer:=MCA_TICKCOUNT_BITS;
  TICKPERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=2**CHUNK_DATABITS-1;
  TICKPIPE_DEPTH:integer:=2;
  ENDIANNESS:string:="LITTLE"
);
port(
  clk:in std_logic;
  reset:in std_logic;
  initialising:out boolean;
  -- update registers to current input values on next tick
  update_asap:in boolean; 
  -- update registers to current input values when ticks are complete
  update_on_completion:in boolean; 
  --FIXME add 4 clk hold
  updated:out boolean; --high for 4 clk after the update is done (CPU interrupt)
  ------------------------------------------------------------------------------
  -- control signals
  ------------------------------------------------------------------------------
  registers:in mca_registers_t;
  tick_period:in unsigned(TICKPERIOD_BITS-1 downto 0);
  ------------------------------------------------------------------------------
  --! selects out to muxs
  ------------------------------------------------------------------------------
  channel_select:out std_logic_vector(CHANNELS-1 downto 0);
  value_select:out std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
  trigger_select:out std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
  ------------------------------------------------------------------------------
  --! inputs from channels
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
end entity mca_unit;
--
architecture RTL of mca_unit is
component count_buffer
port(
  wr_clk:in std_logic;
  wr_rst:in std_logic;
  rd_clk:in std_logic;
  rd_rst:in std_logic;
  din:in std_logic_vector(32 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(65 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;

-- control registers -----------------------------------------------------------
signal tick_count:unsigned(TICKCOUNT_BITS-1 downto 0);
signal enabled:boolean;
-- component wiring ------------------------------------------------------------
signal readable:boolean;
signal total:unsigned(TOTAL_BITS-1 downto 0);
-- FSM signals -----------------------------------------------------------------
type controlFSMstate is (INIT,IDLE,ASAP,ON_COMPLETION);
signal control_state,control_nextstate:controlFSMstate;
type streamFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,HEADER3,HEADER4,
												DISTRIBUTION);
signal stream_state,stream_nextstate:streamFSMstate;
signal mca_axi_valid,mca_axi_ready:boolean;
signal mca_axi_stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal can_swap,ticks_complete,swap_buffer,last_tick:boolean;
signal save_registers:boolean;
signal tick,mca_axi_last,update_int:boolean;
signal max_count:unsigned(COUNTER_BITS-1 downto 0);
signal most_frequent:unsigned(ADDRESS_BITS-1 downto 0);
signal timestamp,start_time,stop_time:unsigned(TIMESTAMP_BITS-1 downto 0);
-- registers saved when update asserted
signal saved_registers:mca_registers_t;
-- registers that will be used for the next MCA frame
signal next_registers:mca_registers_t;
-- register values for the current MCA frame
signal outstream,countstream:streambus_t;
signal outstream_valid,outstream_ready:boolean;
signal countstream_valid,countstream_ready:boolean;
signal tick_pipe:boolean_vector(0 to TICKPIPE_DEPTH);
signal active:boolean;
signal updating:boolean;
signal ticks_m1:unsigned(TICKCOUNT_BITS-1 downto 0);
signal update_reg:boolean;
signal bin_n:unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0);
signal last_bin:unsigned(ADDRESS_BITS-1 downto 0);
signal lowest_value:signed(VALUE_BITS-1 downto 0);
signal buff_din:std_logic_vector(32 downto 0);
signal buff_wr_en:std_logic;
signal buff_rd_en:std_logic;
signal buff_dout:std_logic_vector(65 downto 0);
signal buff_full:std_logic;
signal buff_empty:std_logic;
signal counts_ready:boolean;
signal counts_valid:boolean;
signal counts:std_logic_vector(65 downto 0);
--------------------------------------------------------------------------------
-- MCA protocol
--------------------------------------------------------------------------------
-- header
--      packet                                  
-- word offset  |  16   |      16       |      32      |
-- 0    24      | size  |   last_bin    | lowest_value |
-- 1    32      | flags | most_frequent |    reserved  | 
-- 2    40      |                 total                |
-- 3    48      |             start_time               |
-- 4    56      |              stop_time               |
constant MCA_PROTOCOL_HEADER_WORDS:integer:=5; --FIXME why are these needed
--constant MCA_PROTOCOL_HEADER_CHUNKS:integer
--				 :=MCA_PROTOCOL_HEADER_WORDS*BUS_CHUNKS;
				 
type mca_flags_t is record  -- 32 bits
	value:mca_value_d; --4
	trigger:mca_trigger_d; --4
	bin_n:unsigned(MCA_BIN_N_BITS-1 downto 0); --4
	channel:unsigned(MCA_CHANNEL_WIDTH-1 downto 0); --4
end record;

function to_std_logic(f:mca_flags_t) return std_logic_vector is
begin
	return to_std_logic(f.value,4) &
	       to_std_logic(f.trigger,4) &
	       to_std_logic(f.bin_n) &
				 to_std_logic(f.channel);
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
	w:natural range 0 to MCA_PROTOCOL_HEADER_WORDS-1; -- word number
	e:string
) return std_logic_vector is
begin
	case w is 
	when 0 => 
		return set_endianness(h.size,e) &
					 set_endianness(h.last_bin,e) &
					 set_endianness(h.lowest_value,e);
	when 1 =>
		return to_std_logic(h.flags) &
					 set_endianness(h.most_frequent,e) &
					 to_std_logic(0,32); -- reserved
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
	w:natural range 0 to MCA_PROTOCOL_HEADER_WORDS-1; -- word number
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
constant DEBUG:string:="TRUE";

function to_std_logic(s:controlFSMstate;w:integer) return std_logic_vector is
begin
  return to_std_logic(controlFSMstate'pos(s),w);
end function;

function to_std_logic(s:streamFSMstate;w:integer) return std_logic_vector is
begin
  return to_std_logic(streamFSMstate'pos(s),w);
end function;

signal control_state_v:std_logic_vector(1 downto 0);
signal stream_state_v:std_logic_vector(2 downto 0);

attribute MARK_DEBUG:string;

attribute MARK_DEBUG of update_asap:signal is DEBUG;
attribute MARK_DEBUG of control_state_v:signal is DEBUG;
attribute MARK_DEBUG of stream_state_v:signal is DEBUG;
attribute MARK_DEBUG of mca_axi_valid:signal is DEBUG;
attribute MARK_DEBUG of mca_axi_ready:signal is DEBUG;
attribute MARK_DEBUG of tick_count:signal is DEBUG;


begin
--
--------------------------------------------------------------------------------
-- Control processes and FSM
--------------------------------------------------------------------------------
control_state_v <= to_std_logic(control_state,2);
stream_state_v <= to_std_logic(stream_state,3);

save_registers <= update_asap or update_on_completion;
initialising <= control_state=INIT;
controlReg:process(clk)
begin 
if rising_edge(clk) then
	if reset='1' then
		next_registers.trigger <= DISABLED_MCA_TRIGGER_D;
		channel_select <= (others => '0');
		value_select <= (others => '0');
		trigger_select <= (others => '0');
  	updating <= FALSE;
		enabled <= FALSE;
	else
		updated <= tick_pipe(TICKPIPE_DEPTH-1) and updating;
		update_reg <= update_int;
		
  	if save_registers then
  		saved_registers <= registers;
    end if;
    
    if update_int then -- 3 clocks before tick
    	next_registers <= saved_registers;
    	header.size 
    		<= resize(shift_right(saved_registers.last_bin,1),SIZE_BITS) +
    	  2 + -- number of counter words = (last_bin+1)*2
    	  (MCA_PROTOCOL_HEADER_WORDS);
    	header.flags.bin_n <= saved_registers.bin_n;
    	header.flags.channel <= saved_registers.channel;
    	header.flags.trigger <= saved_registers.trigger;
    	header.flags.value <= saved_registers.value;
    	header.last_bin <= resize(saved_registers.last_bin,CHUNK_DATABITS);
    	header.lowest_value 
    		<= resize(saved_registers.lowest_value,2*CHUNK_DATABITS);
    	--header. <= resize(saved_registers.most_frequent,CHUNK_DATABITS);
    					
    	--header_registers <= to_mca_header_registers(next_registers,size);
    	updating <= TRUE;
	    -- change the selectors ahead of tick to adjust for the selector latency.
    	trigger_select <= to_onehot(saved_registers.trigger);	
    	value_select <= to_onehot(saved_registers.value);
    end if;
    
    if update_reg then
    	channel_select <= to_onehot(next_registers.channel,CHANNELS);
    end if;
    
    if tick then
    	enabled <= next_registers.trigger/=DISABLED_MCA_TRIGGER_D;
    	ticks_m1 <= next_registers.ticks-1;
    	updating <= FALSE;
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
    control_state <= INIT;
  else
    control_state <= control_nextstate;
  end if;
end if;
end process controlFSMnextstate;

--enabled <= registers.trigger/=DISABLED;
--FIXME enabled not handled well if not enabled no need to wait on can swap
--FIXME perhaps should stay in control state till tick or ticks complete


controlFSMtransition:process(control_state,update_asap,update_on_completion,
                             enabled,update_int,can_swap,tick,ticks_complete, 
                             tick_pipe,last_tick)
begin
control_nextstate <= control_state;
case control_state is 
when INIT =>
  swap_buffer <= can_swap;
  update_int <= FALSE; 
	if can_swap then
		control_nextstate <= IDLE;
	end if;
when IDLE =>
  swap_buffer <= ticks_complete or (not enabled and tick);
  update_int <= FALSE;
  if update_asap then   
    control_nextstate <= ASAP;
  elsif update_on_completion then 
    if enabled then
      control_nextstate <= ON_COMPLETION;
    else
      control_nextstate <= ASAP;
    end if;
  end if;
when ASAP =>
  swap_buffer <= tick and can_swap; 
  update_int <= tick_pipe(0) and can_swap;
  if update_on_completion and enabled then
    control_nextstate <= ON_COMPLETION;
  elsif update_int and not (update_asap or update_on_completion) then 
    control_nextstate <= IDLE;
  end if;
when ON_COMPLETION => 
  swap_buffer <= ticks_complete and can_swap;
  update_int <= tick_pipe(0) and last_tick and can_swap;
  if update_int then
    control_nextstate <= IDLE;
  elsif not enabled or update_asap then
    control_nextstate <= ASAP;
  end if;
end case;
end process controlFSMtransition;

--------------------------------------------------------------------------------
-- Tick counter and timing
--------------------------------------------------------------------------------
ticks_complete <= last_tick and tick and can_swap and enabled;
ticker:entity work.tick_counter
generic map(
  MINIMUM_PERIOD => MIN_TICK_PERIOD,
  TICK_BITS => TICKPERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  INIT => -TICKPIPE_DEPTH
)
port map(
  clk => clk,
  reset => reset,
  tick => tick_pipe(0), --want to change selects on pre_tick
  time_stamp => timestamp,
  period => tick_period,
  current_period => open
);

tick <= tick_pipe(TICKPIPE_DEPTH);
tickPipe:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			tick_pipe(1 to TICKPIPE_DEPTH) <= (others => FALSE);	
		else
			tick_pipe(1 to TICKPIPE_DEPTH) <= tick_pipe(0 to TICKPIPE_DEPTH-1);
		end if;
	end if;
end process tickPipe;

tickCounter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    tick_count <= (others => '0');
  else
  	--swap_buffer_reg <= swap_buffer;
  	-- FIXME remove current_registers
    last_tick <= tick_count=to_0IfX(ticks_m1);
    if swap_buffer then
      tick_count <= (others => '0');
      stop_time <= timestamp;
      start_time <= stop_time+1;
    elsif tick and not last_tick then
      tick_count <= tick_count+1;
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
		if readable then
			header.total <= total;
			header.most_frequent <= resize(most_frequent,CHUNK_DATABITS);
			header.start_time <= start_time;
			header.stop_time <= stop_time;
		end if;
	end if;
end process protocolHeader;

startup:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			active <= FALSE;
		else
			if swap_buffer then
				active <= TRUE;
			end if;
		end if;
	end if;
end process startup;

streamFSMtransition:process(stream_state,readable,countstream,
														countstream_valid,outstream_ready,
														header,active)
begin
stream_nextstate <= stream_state;
outstream.discard <= (others => FALSE);
outstream.last <= (others => FALSE);
case stream_state is 
when IDLE =>
	outstream_valid <= FALSE;
	outstream.data <= (others => '-');	
	countstream_ready <= FALSE;
  if readable and active then
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
    if countstream.last(0) and countstream_valid and outstream_ready then
      stream_nextstate <= IDLE;
    end if;
end case;
end process streamFSMtransition;

-- the register values are internally saved each swap_buffer
-- swap_buffer when not enabled saves registers but does not swap_the internal
-- buffer and nothing will be counted
bin_n <= resize(next_registers.bin_n,ceilLog2(ADDRESS_BITS)); 
last_bin <= resize(next_registers.last_bin,ADDRESS_BITS);
lowest_value <= resize(next_registers.lowest_value,VALUE_BITS);
MCA:entity mcalib.mapped_mca
generic map(
  ADDRESS_BITS => ADDRESS_BITS,
  TOTAL_BITS => TOTAL_BITS,
  VALUE_BITS => VALUE_BITS,
  COUNTER_BITS => COUNTER_BITS
)
port map(
  clk => clk,
  reset => reset,
  can_swap => can_swap,
  value => value,
  value_valid => value_valid,
  swap_buffer => swap_buffer,
  enabled => enabled,
  bin_n => bin_n, 
  last_bin => last_bin,
  lowest_value => lowest_value,
  readable => readable,
  total => total,
  max_count => max_count,
  most_frequent => most_frequent,
  stream => mca_axi_stream,
  valid => mca_axi_valid,
  ready => mca_axi_ready,
  last => mca_axi_last
);

mca_axi_ready <= buff_full='0';

buff_din <= to_std_logic(mca_axi_last) & 
  set_endianness(resize(unsigned(mca_axi_stream),32), ENDIANNESS);
  
buff_wr_en <= to_std_logic(mca_axi_valid);  

countBuffer:count_buffer
port map (
  wr_clk => clk,
  wr_rst => reset,
  rd_clk => clk,
  rd_rst => reset,
  din => buff_din,
  wr_en => buff_wr_en,
  rd_en => buff_rd_en,
  dout => buff_dout,
  full => buff_full,
  empty => buff_empty
);

buff_rd_en <= to_std_logic(counts_ready);
counts_valid <= buff_empty='0';

countstreamReg:entity streamlib.stream_register
generic map(WIDTH => 66)
port map(
  clk => clk,
  reset => reset,
  stream_in => buff_dout,
  ready_out => counts_ready,
  valid_in => counts_valid,
  stream => counts,
  ready => countstream_ready,
  valid => countstream_valid
);

countstream.data <= counts(64 downto 33) & counts(31 downto 0);
countstream.discard <= (others => FALSE);
countstream.last <= (
	0 => to_boolean(counts(32)),
	-- 2 => to_boolean(buff_dout(65)), 
	others => FALSE
);

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
