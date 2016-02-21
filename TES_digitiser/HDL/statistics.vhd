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
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.types.all;
use streamlib.functions.all;
--
library adclib;
use adclib.adc.all;
--
library mcalib;
use mcalib.all;
--
entity statistics is
generic(
  CHANNEL_BITS:integer:=3;
  ADDRESS_BITS:integer:=ADC_BITS;
  COUNTER_BITS:integer:=32;
  VALUES:integer:=8;
  VALUE_BITS:integer:=AREA_BITS+1;
  TOTAL_BITS:integer:=64;
  TICK_COUNT_BITS:integer:=32;
  TICK_PERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=2**ADC_BITS+100;
  STREAM_CHUNKS:integer:=2;
  ENDIANNESS:string:="BIG" -- BIG or LITTLE
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
  bin_n:in unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0);
  lowest_value:in signed(VALUE_BITS-1 downto 0);
  last_bin:in unsigned(ADDRESS_BITS-1 downto 0);
  --number of ticks to sum over
  ticks:in unsigned(TICK_COUNT_BITS-1 downto 0);
  tick_period:in unsigned(TICK_PERIOD_BITS-1 downto 0);
  --tick_period_updated:in boolean;
  ------------------------------------------------------------------------------
  --! selects
  ------------------------------------------------------------------------------
  channel_select:in unsigned(CHANNEL_BITS-1 downto 0);
  value_select:in boolean_vector(VALUES-1 downto 0);
  ------------------------------------------------------------------------------
  --! inputs from channels
  ------------------------------------------------------------------------------
  -- values
  samples:in sample_array(2**CHANNEL_BITS-1 downto 0);
  baselines:in sample_array(2**CHANNEL_BITS-1 downto 0);
  extremas:in sample_array(2**CHANNEL_BITS-1 downto 0);
  areas:in area_array(2**CHANNEL_BITS-1 downto 0);
  derivative_extremas:in sample_array(2**CHANNEL_BITS-1 downto 0);
  pulse_areas:in area_array(2**CHANNEL_BITS-1 downto 0);
  pulse_lengths:in time_array(2**CHANNEL_BITS-1 downto 0);
  -- valids
  max_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --min_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  sample_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  derivative_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  pulse_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  ------------------------------------------------------------------------------
  -- stream output (stream includes last and keep)
  ------------------------------------------------------------------------------
  stream:out std_logic_vector(STREAM_CHUNKS*CHUNK_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean
);
end entity statistics;
--
architecture RTL of statistics is
-- control registers -----------------------------------------------------------
signal channel_next,channel_cur:unsigned(CHANNEL_BITS-1 downto 0);
signal bin_n_next,bin_n_cur:unsigned(ceilLog2(ADDRESS_BITS)-1 downto 0);
signal lowest_value_next,lowest_value_cur:signed(VALUE_BITS-1 downto 0);
signal last_bin_next,last_bin_cur:unsigned(ADDRESS_BITS-1 downto 0);
signal ticks_next,ticks_cur:unsigned(TICK_COUNT_BITS-1 downto 0);
signal value_next,value_cur:boolean_vector(VALUES-1 downto 0);
signal tick_count:unsigned(TICK_COUNT_BITS-1 downto 0);
signal enabled,swap_buffer1:boolean;
-- component wiring ------------------------------------------------------------
signal value:signed(VALUE_BITS-1 downto 0);
signal value_valid,readable:boolean;
signal total:unsigned(TOTAL_BITS-1 downto 0);
-- FSM signals -----------------------------------------------------------------
type controlFSMstate is (IDLE,ASAP,ON_COMPLETION);
signal control_state,control_nextstate:controlFSMstate;
type streamFSMstate is (IDLE,HEADER,DISTRIBUTION);
signal stream_state,stream_nextstate:streamFSMstate;
signal head_stream:std_logic_vector(STREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal head_valid,mca_valid,ready_for_head,ready_for_mca,head_last:boolean;
signal mca_stream:std_logic_vector(COUNTER_BITS-1 downto 0);
signal can_swap,ticks_complete,swap_buffer,last_tick:boolean;
signal register_controls:boolean;
signal tick,mca_last,swap_buffer_reg,updated_int:boolean;
signal max_count:unsigned(COUNTER_BITS-1 downto 0);
signal most_frequent:unsigned(ADDRESS_BITS-1 downto 0);
signal timestamp,start_time,stop_time:unsigned(TIMESTAMP_BITS-1 downto 0);
signal stream_in:std_logic_vector(STREAM_CHUNKS*CHUNK_BITS-1 downto 0);
signal valid_in,ready_out:boolean;
signal test_LEDs:std_logic_vector(7 downto 0);
begin
--
--valid <= valid_int;
--------------------------------------------------------------------------------
-- Test points
--------------------------------------------------------------------------------
--LEDs(0) <= to_std_logic(stream_state=IDLE);
--LEDs(7 downto 1) <= test_LEDs(7 downto 1);
--LEDs <= mca_unit_LEDs;
test:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    test_LEDs <= (others => '0');
  else
    if stream_state=IDLE and stream_nextstate=HEADER then
      test_LEDs(1) <= not test_LEDs(1);
    end if;
    if stream_state=HEADER and stream_nextstate=DISTRIBUTION then
      test_LEDs(2) <= not test_LEDs(2);
    end if;
    if update_asap then
      test_LEDs(3) <= not test_LEDs(3);
    end if;
    if update_on_completion then
      test_LEDs(4) <= not test_LEDs(4);
    end if;
    if mca_last then
    	test_LEDs(5) <= '1';
    end if;
    if ready then
      test_LEDs(6) <= '1';
    end if;
    if busLast(stream_in,STREAM_CHUNKS) then
      test_LEDs(7) <= not test_LEDs(7);
    end if;
  end if;
end if;
end process test;
--------------------------------------------------------------------------------
-- Control processes and FSM
--------------------------------------------------------------------------------
register_controls <= update_asap or update_on_completion;
updated <= updated_int;
controlReg:process(clk)
begin 
if rising_edge(clk) then
  if reset='1' then
    value_next <= (others => FALSE);
    value_cur <= (others => FALSE);
    channel_next <= (others => '0');
    channel_next <= (others => '0');
  else
    if register_controls then
      channel_next <= channel_select;
      value_next <= value_select;
      bin_n_next <= bin_n;
      lowest_value_next <= lowest_value;
      last_bin_next <= last_bin;
      ticks_next <= ticks;
    end if;
    if updated_int then
      channel_cur <= channel_next;
      value_cur <= value_next;
      bin_n_cur <= bin_n_next;
      lowest_value_cur <= lowest_value_next;
      last_bin_cur <= last_bin_next;
      ticks_cur <= ticks_next;
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
  when ASAP =>
    swap_buffer <= tick and can_swap;
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
  period => tick_period,
  current_period => open
);
--
tickCounter:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    tick_count <= (others => '0');
  else
    swap_buffer_reg <= swap_buffer;
    last_tick <= tick_count=(to_0IfX(ticks_cur)-1);
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
streamFSMtransition:process(stream_state,readable,ready_out,valid_in,head_last,
                            mca_last)
begin
stream_nextstate <= stream_state;
case stream_state is 
  when IDLE =>
    if readable then
      stream_nextstate <= HEADER;
    end if;
  when HEADER =>
    if ready_out and head_last and valid_in then
      stream_nextstate <= DISTRIBUTION;
    end if;
  when DISTRIBUTION =>
    if mca_last and valid_in and ready_out then
      stream_nextstate <= IDLE;
    end if;
end case;
end process streamFSMtransition;
streamReg:entity streamlib.streambus_register_slice
generic map(STREAM_BITS => STREAM_CHUNKS*CHUNK_BITS)
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_in,
  ready_out => ready_out,
  valid_in => valid_in,
  last_in => FALSE,
  stream => stream,
  ready => ready,
  valid => valid,
  last => open
);
streamFSMoutput:process(stream_state,head_stream,head_valid,mca_last,mca_stream,
                        mca_valid,ready_out)
variable data:std_logic_vector(STREAM_CHUNKS*CHUNK_DATABITS-1 downto 0);
begin
case stream_state is 
when IDLE =>
  stream_in <= (others => '-');
  valid_in <= FALSE;
  --last_in <= FALSE;
  ready_for_head <= FALSE;
  ready_for_mca <= FALSE;
when HEADER =>
  stream_in <= head_stream;
  valid_in <= head_valid;
  --last_in <= FALSE;
  ready_for_head <= ready_out;
  ready_for_mca <= FALSE;
when DISTRIBUTION =>
  data := SetEndianness(mca_stream,ENDIANNESS);
  stream_in <= "01" & data(31 downto 16) &
               to_std_logic(mca_last) & '1' & data(15 downto 0);
  valid_in <= mca_valid;
  --last_in <= mca_last;
  ready_for_head <= FALSE;
  ready_for_mca <= ready_out;
end case;
end process streamFSMoutput;
--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
-- FIXME replace this with a framer?
headerFSM:entity work.statistics_header_FSM
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  ADDRESS_BITS => ADDRESS_BITS,
  VALUES => VALUES,
  VALUE_BITS => VALUE_BITS,
  TOTAL_BITS => TOTAL_BITS,
  STREAM_CHUNKS => STREAM_CHUNKS,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset,
  go => readable,
  swap_buffer => swap_buffer,
  channel_sel => channel_cur,
  value_sel => value_cur,
  bin_n => bin_n_cur,
  lowest_value => lowest_value_cur,
  last_bin => last_bin_cur,
  start_time => start_time,
  stop_time => stop_time,
  total => total,
  max_count => max_count,
  most_frequent => most_frequent,
  stream => head_stream,
  valid => head_valid,
  ready => ready_for_head,
  last => head_last
);
mux:entity work.statistics_mux
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  VALUE_BITS => VALUE_BITS
)
port map(
  clk => clk,
  reset => reset,
  swap_buffer => swap_buffer,
  swap_buffer_out => swap_buffer1,
  channel_select => channel_cur,
  value_select => value_cur,
  samples => samples,
  baselines => baselines,
  extremas => extremas,
  areas => areas,
  derivative_extremas => derivative_extremas,
  pulse_areas => pulse_areas,
  pulse_lengths => pulse_lengths,
  max_valids => max_valids,
  --min_valids => min_valids,
  sample_valids => sample_valids,
  derivative_valids => derivative_valids,
  pulse_valids => pulse_valids,
  enabled => enabled,
  value => value,
  value_valid => value_valid
);

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
  bin_n => bin_n_cur, 
  last_bin => last_bin_cur,
  lowest_value => lowest_value_cur,
  readable => readable,
  total => total,
  max_count => max_count,
  most_frequent => most_frequent,
  stream => mca_stream,
  valid => mca_valid,
  ready => ready_for_mca,
  last => mca_last
);
end architecture RTL;
