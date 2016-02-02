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
use ieee.math_real.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;

library adclib;
use adclib.types.all;

library mcalib;

library eventlib;
use eventlib.events.all;

use work.global.all;
use work.mca.all;

entity mca_unit is
generic(
  CHANNEL_BITS:integer:=3;
  ADDRESS_BITS:integer:=14;
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICK_COUNT_BITS:integer:=32;
  TICK_PERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=2**CHUNK_DATABITS-1
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  update_asap:in boolean; 
  update_on_completion:in boolean; --update after ticks
  --FIXME add 4 clk hold
  updated:out boolean; --high for 4 clks after the update is done (CPU interrupt)
  ------------------------------------------------------------------------------
  -- control signals
  ------------------------------------------------------------------------------
  registers:mca_registers;
  ------------------------------------------------------------------------------
  --! selects out to muxs
  ------------------------------------------------------------------------------
  channel_select:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  value_select:out std_logic_vector(NUM_MCA_VALUES-1 downto 0);
  trigger_select:out std_logic_vector(NUM_MCA_TRIGGERS-1 downto 0);
  ------------------------------------------------------------------------------
  --! inputs from channels
  ------------------------------------------------------------------------------
  value:in mca_value_t;
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

constant CHANNELS:integer:=2**CHANNEL_BITS;
-- control registers -----------------------------------------------------------
signal tick_count:unsigned(TICK_COUNT_BITS-1 downto 0);
signal enabled,swap_buffer1:boolean;
-- component wiring ------------------------------------------------------------
signal readable:boolean;
signal total:unsigned(TOTAL_BITS-1 downto 0);
-- FSM signals -----------------------------------------------------------------
type controlFSMstate is (IDLE,ASAP,ON_COMPLETION);
signal control_state,control_nextstate:controlFSMstate;
type streamFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,HEADER3,DISTRIBUTION);
signal stream_state,stream_nextstate:streamFSMstate;
signal mca_axi_valid,mca_axi_ready:boolean;
signal mca_axi_stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal can_swap,ticks_complete,swap_buffer,last_tick:boolean;
signal register_controls:boolean;
signal tick,mca_axi_last,swap_buffer_reg,updated_int:boolean;
signal max_count:unsigned(COUNTER_BITS-1 downto 0);
signal most_frequent:unsigned(ADDRESS_BITS-1 downto 0);
signal timestamp,start_time,stop_time:unsigned(TIMESTAMP_BITS-1 downto 0);
signal stream_in:streambus_t;
signal size:unsigned(CHUNK_BITS-1 downto 0);
signal current_registers,next_registers:mca_registers;
signal registerstream,countstream:streambus_t;
signal registerstream_valid,registerstream_ready:boolean;
signal countstream_valid,countstream_ready:boolean;
signal mca_header:mca_protocol_header;
begin
--
--------------------------------------------------------------------------------
-- Control processes and FSM
--------------------------------------------------------------------------------
register_controls <= update_asap or update_on_completion;
updated <= updated_int;
controlReg:process(clk)
begin 
if rising_edge(clk) then
	if reset='1' then
		next_registers.trigger <= DISABLED;
		current_registers.trigger <= DISABLED;
		enabled <= FALSE;
		size <= (others => '0');
  else
  	if register_controls then
  		next_registers <= registers;
    end if;
    if updated_int then
    	current_registers <= next_registers;
    	channel_select <= to_onehot(next_registers.channel,CHANNELS);
    	trigger_select <= to_onehot(next_registers.trigger);	
    	value_select <= to_onehot(next_registers.value);
    	enabled <= next_registers.trigger/=DISABLED;
    	size <= shift_left(next_registers.last_bin,1)+12;
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

--FIXME enabled not handled well if not enabled no need to wait on can swap
controlFSMtransition:process(control_state,update_asap,update_on_completion,
                             enabled,updated_int)
begin
control_nextstate <= control_state;
case control_state is 
when IDLE =>
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
  if update_on_completion and enabled then
    control_nextstate <= ON_COMPLETION;
  elsif updated_int and not (update_asap or update_on_completion) then 
    control_nextstate <= IDLE;
  end if;
when ON_COMPLETION => 
  if updated_int then
    control_nextstate <= IDLE;
  elsif not enabled or update_asap then
    control_nextstate <= ASAP;
  end if;
end case;
end process controlFSMtransition;

controlFSMoutput:process(control_state,can_swap,tick,ticks_complete,enabled)
begin
  case control_state is 
  when IDLE =>
    swap_buffer <= ticks_complete or (not enabled and tick);
    updated_int <= FALSE;
  --FIXME can make this go as soon as there is a clear buffer?
  when ASAP =>
    swap_buffer <= tick and can_swap; --FIXME make this really ASAP no tick
    updated_int <= tick and can_swap;
  when ON_COMPLETION =>
    swap_buffer <= ticks_complete and can_swap;
    updated_int <= ticks_complete and can_swap;
  end case;
end process controlFSMoutput;

--------------------------------------------------------------------------------
-- Tick counter and timing
--------------------------------------------------------------------------------
ticks_complete <= last_tick and tick and can_swap and enabled;
ticker:entity teslib.tick_counter
generic map(
  MINIMUM_PERIOD => MIN_TICK_PERIOD,
  TICK_BITS => TICK_PERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset,
  tick => tick,
  time_stamp => timestamp,
  period => current_registers.tick_period,
  current_period => open
);

tickCounter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    tick_count <= (others => '0');
  else
    swap_buffer_reg <= swap_buffer;
    last_tick <= tick_count=(to_0IfX(current_registers.ticks)-1);
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
			mca_header <= to_protocol_header(current_registers,max_count,
																			 most_frequent,start_time,stop_time
										);	
		end if;
	end if;
end process protocolHeader;


streamFSMtransition:process(stream_state,readable,countstream,
														countstream_valid,registerstream_ready,mca_header)
begin
stream_nextstate <= stream_state;
stream_in.keep_n <= (others => FALSE);
stream_in.last <= (others => FALSE);
case stream_state is 
when IDLE =>
	registerstream_valid <= FALSE;
	stream_in.data <= (others => '-');	
  if readable then
    stream_nextstate <= HEADER0;
  end if;
  when HEADER0 =>
		registerstream_valid <= TRUE;
		stream_in <= to_streambus(mca_header,0);
    if registerstream_ready then
      stream_nextstate <= HEADER1;
    end if;
  when HEADER1 =>
		registerstream_valid <= TRUE;
		stream_in <= to_streambus(mca_header,1);
    if registerstream_ready then
      stream_nextstate <= HEADER2;
    end if;
  when HEADER2 =>
		registerstream_valid <= TRUE;
		stream_in <= to_streambus(mca_header,2);
    if registerstream_ready then
      stream_nextstate <= HEADER3;
    end if;
  when HEADER3 =>
		stream_in <= to_streambus(mca_header,3);
    if registerstream_ready then
      stream_nextstate <= DISTRIBUTION;
    end if;
  when DISTRIBUTION =>
  	registerstream_valid <= countstream_valid;
    stream_in <= countstream;
    if countstream.last(0) and countstream_valid and registerstream_ready then
      stream_nextstate <= IDLE;
    end if;
end case;
end process streamFSMtransition;

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
  swap_buffer => swap_buffer1,
  enabled => enabled,
  bin_n => current_registers.bin_n, 
  last_bin => current_registers.last_bin,
  lowest_value => current_registers.lowest_value,
  readable => readable,
  total => total,
  max_count => max_count,
  most_frequent => most_frequent,
  stream => mca_axi_stream,
  valid => mca_axi_valid,
  ready => mca_axi_ready,
  last => mca_axi_last
);

mcaAdapter:entity streamlib.axi_adapter
generic map(
  AXI_CHUNKS => 2
)
port map(
  clk => clk,
  reset => reset,
  axi_stream => mca_axi_stream,
  axi_valid => mca_axi_valid,
  axi_ready => mca_axi_ready,
  axi_last => mca_axi_last,
  stream => countstream,
  valid => countstream_valid,
  ready => countstream_ready
);

outstreamReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => registerstream,
  ready_out => registerstream_ready,
  valid_in => registerstream_valid,
  stream => stream,
  ready => ready,
  valid => valid
);

end architecture RTL;
