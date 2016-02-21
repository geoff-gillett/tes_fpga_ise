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
use work.protocol.all;
use work.types.all;
use work.functions.all;

entity mca_unit is
generic(
  CHANNEL_BITS:integer:=3;
  ADDRESS_BITS:integer:=14;
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICKCOUNT_BITS:integer:=MCA_TICKCOUNT_BITS;
  TICKPERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=2**CHUNK_DATABITS-1
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
  updated:out boolean; --high for 4 clks after the update is done (CPU interrupt)
  ------------------------------------------------------------------------------
  -- control signals
  ------------------------------------------------------------------------------
  registers:mca_registers_t;
  tick_period:unsigned(TICKPERIOD_BITS-1 downto 0);
  ------------------------------------------------------------------------------
  --! selects out to muxs
  ------------------------------------------------------------------------------
  channel_select:out std_logic_vector(2**CHANNEL_BITS-1 downto 0);
  value_select:out std_logic_vector(MCA_VALUE_SELECT_BITS-1 downto 0);
  trigger_select:out std_logic_vector(MCA_TRIGGER_SELECT_BITS-1 downto 0);
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

constant CHANNELS:integer:=2**CHANNEL_BITS;
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
signal registerstream,countstream:streambus_t;
signal registerstream_valid,registerstream_ready:boolean;
signal countstream_valid,countstream_ready:boolean;
signal header_registers:mca_header_registers;
signal header_measurements:mca_header_measurements;
signal size:unsigned(CHUNK_DATABITS-1 downto 0);
signal tick_pipe:boolean_vector(0 to TICKPIPE_DEPTH);
signal active:boolean;
signal updating:boolean;
signal ticks:unsigned(TICKCOUNT_BITS-1 downto 0);
signal update_reg:boolean;
begin
--
--------------------------------------------------------------------------------
-- Control processes and FSM
--------------------------------------------------------------------------------
save_registers <= update_asap or update_on_completion;
--updated <= update_int;
initialising <= control_state=INIT;
controlReg:process(clk)
begin 
if rising_edge(clk) then
	if reset='1' then
		next_registers.trigger <= DISABLED_MCA_TRIGGER;
		--current_registers.trigger <= DISABLED;
		--current_registers.tick_period 
			--<= to_unsigned(DEFAULT_TICK_PERIOD,TICK_PERIOD_WIDTH);
		--next_registers.ticks 
			--<= to_unsigned(DEFAULT_MCA_TICKS,MCA_TICK_COUNT_WIDTH);
		--enabled <= FALSE;
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
    	header_registers <= to_mca_header_registers(next_registers,size);
    	size <= resize(shift_left(saved_registers.last_bin,1),SIZE_BITS)+
    					2+MCA_PROTOCOL_HEADER_CHUNKS;
    	updating <= TRUE;
	    -- change the selectors ahead of tick to adjust for the selector latency.
    	trigger_select <= to_onehot(saved_registers.trigger);	
    	value_select <= to_onehot(saved_registers.value);
    end if;
    
    if update_reg then
    	channel_select <= to_onehot(next_registers.channel,CHANNELS);
    end if;
    
    if tick then
    	enabled <= next_registers.trigger/=DISABLED_MCA_TRIGGER;
    	ticks <= next_registers.ticks;
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
  TIMESTAMP_BITS => TIMESTAMP_BITS
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
    last_tick <= tick_count=(to_0IfX(ticks)-1);
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
			header_measurements.total <= total;
			header_measurements.most_frequent <= resize(most_frequent,CHUNK_DATABITS);
			header_measurements.start_time <= start_time;
			header_measurements.stop_time <= stop_time;
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
														countstream_valid,registerstream_ready,
														header_registers,active,header_measurements)
begin
stream_nextstate <= stream_state;
registerstream.keep_n <= (others => FALSE);
registerstream.last <= (others => FALSE);
case stream_state is 
when IDLE =>
	registerstream_valid <= FALSE;
	registerstream.data <= (others => '-');	
	countstream_ready <= FALSE;
  if readable and active then
    stream_nextstate <= HEADER0;
  end if;
when HEADER0 =>
		registerstream_valid <= TRUE;
		registerstream <= to_streambus(header_registers,header_measurements,0);
    if registerstream_ready then
      stream_nextstate <= HEADER1;
    end if;
when HEADER1 =>
		registerstream_valid <= TRUE;
		registerstream <= to_streambus(header_registers,header_measurements,1);
    if registerstream_ready then
      stream_nextstate <= HEADER2;
    end if;
when HEADER2 =>
		registerstream_valid <= TRUE;
		registerstream <= to_streambus(header_registers,header_measurements,2);
    if registerstream_ready then
      stream_nextstate <= HEADER3;
    end if;
when HEADER3 =>
		registerstream <= to_streambus(header_registers,header_measurements,3);
    if registerstream_ready then
      stream_nextstate <= HEADER4;
    end if;
when HEADER4 =>
		registerstream <= to_streambus(header_registers,header_measurements,4);
    if registerstream_ready then
      stream_nextstate <= DISTRIBUTION;
    end if;
when DISTRIBUTION =>
  	registerstream_valid <= countstream_valid;
    registerstream <= countstream;
    countstream_ready <= registerstream_ready;
    if countstream.last(0) and countstream_valid and registerstream_ready then
      stream_nextstate <= IDLE;
    end if;
end case;
end process streamFSMtransition;

-- the register values are internally saved each swap_buffer
-- swap_buffer when not enabled saves registers but does not swap_the internal
-- buffer and nothing will be counted
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
  bin_n => resize(next_registers.bin_n,ceilLog2(ADDRESS_BITS)), 
  last_bin => resize(next_registers.last_bin,ADDRESS_BITS),
  lowest_value => resize(next_registers.lowest_value,VALUE_BITS),
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
  axi_stream => to_std_logic(resize(unsigned(mca_axi_stream),2*CHUNK_DATABITS)),
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
