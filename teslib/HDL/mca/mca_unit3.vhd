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

--use work.adc.all;
use work.events.all;
use work.registers.all;
--use work.protocol.all;
use work.types.all;
use work.functions.all;

entity mca_unit3 is
generic(
  CHANNELS:integer:=8;
  ADDRESS_BITS:integer:=14;
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICKCOUNT_BITS:integer:=MCA_TICKCOUNT_BITS;
  TICKPERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=2**CHUNK_DATABITS-1;
  DEPTH:natural:=5;
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
  qualifier_select:out std_logic_vector(NUM_MCA_QUAL_D-1 downto 0);
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
end entity mca_unit3;
--
architecture RTL of mca_unit3 is
  
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
signal ticks_remaining:unsigned(TICKCOUNT_BITS-1 downto 0);
signal last_tick:boolean;
signal enabled:boolean;
-- component wiring ------------------------------------------------------------
signal readable:boolean;
signal total:unsigned(TOTAL_BITS-1 downto 0);
-- FSM signals -----------------------------------------------------------------
type controlFSMstate is (INIT,RUN,ASAP,ON_COMPLETION,DISABLED);
signal control_state,control_nextstate:controlFSMstate;
type streamFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,HEADER3,HEADER4,
												DISTRIBUTION);
--pipelining
signal update_pipe,swap_pipe:boolean_vector(0 to DEPTH);
signal tick_pipe:boolean_vector(0 to 2);

signal stream_state,stream_nextstate:streamFSMstate;
signal mca_axi_valid,mca_axi_ready:boolean;
signal mca_axi_stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal can_swap,swap_buffer:boolean;
signal update_registers:boolean;
signal tick,mca_axi_last:boolean;
signal max_count:unsigned(COUNTER_BITS-1 downto 0);
signal most_frequent:unsigned(ADDRESS_BITS-1 downto 0);
signal timestamp,start_time,stop_time:unsigned(TIMESTAMP_BITS-1 downto 0);
-- registers saved when update asserted
signal updated_reg,header_reg,current_reg:mca_registers_t;
-- register values for the current MCA frame
signal outstream,countstream:streambus_t;
signal outstream_valid,outstream_ready:boolean;
signal countstream_valid,countstream_ready:boolean;
signal active:boolean;
signal updating:boolean;
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
-- 1    32      | resvd | most_frequent |     flags    | 
-- 2    40      |                 total                |
-- 3    48      |             start_time               |
-- 4    56      |              stop_time               |
constant MCA_PROTOCOL_HEADER_WORDS:integer:=5; --FIXME why are these needed
--constant MCA_PROTOCOL_HEADER_CHUNKS:integer
--				 :=MCA_PROTOCOL_HEADER_WORDS*BUS_CHUNKS;
				 
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
constant DEBUG:string:="FALSE";
attribute MARK_DEBUG:string;
attribute MARK_DEBUG of update_asap:signal is DEBUG;
attribute MARK_DEBUG of mca_axi_valid:signal is DEBUG;
attribute MARK_DEBUG of mca_axi_ready:signal is DEBUG;
attribute MARK_DEBUG of ticks_remaining:signal is DEBUG;

begin
  
--------------------------------------------------------------------------------
-- Control processes and FSM
--------------------------------------------------------------------------------

update_registers <= update_asap or update_on_completion;
initialising <= control_state=INIT;

--FIXME the register assignment is hard to understand and probably broken
controlReg:process(clk)
begin 
if rising_edge(clk) then
	if reset='1' then
		current_reg.trigger <= DISABLED_MCA_TRIGGER_D;
		channel_select <= (others => '0');
		value_select <= (others => '0');
		trigger_select <= (others => '0');
		qualifier_select <= (0 => '1',others => '0');
  	updating <= FALSE;
  	enabled <= FALSE;
	else
		updated <= update_pipe(DEPTH-1) and updating;
		
  	if update_registers then
  		updated_reg <= registers;
  		if control_state=DISABLED then
  		  current_reg <= registers;
  		  header_reg <= registers;
        enabled <= updated_reg.trigger/=DISABLED_MCA_TRIGGER_D;
  		end if;
    end if;
    
    if update_pipe(DEPTH-1) then -- check
      if update_registers then  -- whats this
        current_reg <= registers; --current_reg valid after swap
        header_reg <= current_reg;
        enabled <= registers.trigger/=DISABLED_MCA_TRIGGER_D;
      else
    	  current_reg <= updated_reg;
        header_reg <= current_reg;
        enabled <= updated_reg.trigger/=DISABLED_MCA_TRIGGER_D;
    	end if;
    end if;
    
    if update_pipe(0) then
    	updating <= TRUE;
    	trigger_select <= to_onehot(updated_reg.trigger);	
    	value_select <= to_onehot(updated_reg.value);
    	qualifier_select <= to_onehot(updated_reg.qualifier);
    end if;
    
    if update_pipe(DEPTH-1) then 
    	channel_select <= to_onehot(current_reg.channel,CHANNELS);
    end if;
    
    if update_pipe(DEPTH-1) then
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

controlFSMtransition:process(
  control_state,update_asap,update_on_completion,can_swap,tick,
  swap_buffer,updated_reg.trigger,last_tick
)
begin
  
control_nextstate <= control_state;

case control_state is 
  
when INIT =>
  swap_pipe(0) <= can_swap;
  update_pipe(0) <= FALSE; 
	if can_swap then
		control_nextstate <= DISABLED;
	end if;
	
when DISABLED => 
  swap_pipe(0) <= FALSE;
  update_pipe(0) <= FALSE;
  if update_asap then   
    control_nextstate <= ASAP;
  elsif update_on_completion then 
    control_nextstate <= ON_COMPLETION;
  end if;
  
when RUN =>
  swap_pipe(0) <= last_tick and tick and can_swap;
  update_pipe(0) <= FALSE;
  if update_asap then   
    control_nextstate <= ASAP;
  elsif update_on_completion then 
    control_nextstate <= ON_COMPLETION;
  elsif swap_buffer and updated_reg.trigger=DISABLED_MCA_TRIGGER_D then
    control_nextstate <= DISABLED;
  end if;
  
when ASAP =>
  swap_pipe(0) <= tick and can_swap; 
  update_pipe(0) <= tick and can_swap;
  if update_on_completion then
    control_nextstate <= ON_COMPLETION;
  elsif (tick and can_swap) and not update_asap then 
    control_nextstate <= RUN;
  elsif swap_buffer and updated_reg.trigger=DISABLED_MCA_TRIGGER_D then
    control_nextstate <= DISABLED;
  end if;
  
when ON_COMPLETION => 
  swap_pipe(0) <= last_tick and tick and can_swap;
  update_pipe(0) <= tick and last_tick and can_swap;
  if tick and last_tick and can_swap then
    control_nextstate <= RUN; 
  elsif update_asap then
    control_nextstate <= ASAP;
  elsif swap_buffer and updated_reg.trigger=DISABLED_MCA_TRIGGER_D then
    control_nextstate <= DISABLED;
  end if;
  
end case;
end process controlFSMtransition;

--------------------------------------------------------------------------------
-- Tick counter and timing
--------------------------------------------------------------------------------
ticker:entity work.tick_counter
generic map(
  MINIMUM_PERIOD => MIN_TICK_PERIOD,
  TICK_BITS => TICKPERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  INIT => -1
)
port map(
  clk => clk,
  reset => reset,
  tick => tick_pipe(0), 
  time_stamp => timestamp,
  period => tick_period,
  current_period => open
);

tick <= tick_pipe(1);
swap_buffer <= swap_pipe(DEPTH);
piplines:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			tick_pipe(1 to 2) <= (others => FALSE);	
			update_pipe(1 to DEPTH) <= (others => FALSE);	
			swap_pipe(1 to DEPTH) <= (others => FALSE);	
		else
			tick_pipe(1 to 2) <= tick_pipe(0 to 1);
			update_pipe(1 to DEPTH) <= update_pipe(0 to DEPTH-1);
			swap_pipe(1 to DEPTH) <= swap_pipe(0 to DEPTH-1);
		end if;
	end if;
end process piplines;

tickCounter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    ticks_remaining <= (others => '0');
  else
    if swap_pipe(1) then
      if updated_reg.ticks=1 or updated_reg.ticks=0 then
        ticks_remaining <= (others => '0');
        last_tick <= TRUE;
      else
        ticks_remaining <= updated_reg.ticks-1;
        last_tick <= FALSE;
      end if;
    elsif tick and not last_tick then
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
		
		if swap_pipe(1) then
			header.start_time <= start_time;
			header.stop_time <= stop_time;
			start_time <= timestamp;
		end if;
	  
		if readable then --becomes readable after swap
			header.total <= total;
			header.most_frequent <= resize(most_frequent,CHUNK_DATABITS);
		
    	header.size <= shift_right(resize(header_reg.last_bin,SIZE_BITS),1) +
    	               2 + MCA_PROTOCOL_HEADER_WORDS;
    	               
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

startup:process(clk)
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
bin_n <= resize(current_reg.bin_n,ceilLog2(ADDRESS_BITS)); 
last_bin <= resize(current_reg.last_bin,ADDRESS_BITS);
lowest_value <= resize(current_reg.lowest_value,VALUE_BITS);

--TODO make mca_buffer asymmetric with read port 64 bits
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
  set_endianness(resize(mca_axi_stream,32), ENDIANNESS);
  
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
