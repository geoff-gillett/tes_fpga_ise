--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: eventstream_mux
-- Project Name: eventlib 
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

use work.events.all;

--TODO optimise to remove wait states
-- merges instreams keeping temporal order and incorporates tickstream
entity eventstream_mux5 is
generic(
  --CHANNEL_BITS:integer:=3;
  CHANNELS:integer:=8;
  TIME_BITS:integer:=16;
  TIMESTAMP_BITS:integer:=64;
  TICKPERIOD_BITS:integer:=32;
  MIN_TICKPERIOD:integer:=2**16;
  TICKPIPE_DEPTH:integer:=2;
  ENDIANNESS:string:="LITTLE"
);
port(
  clk:in std_logic;
  reset:in std_logic;
  -- from channel captures
  start:in boolean_vector(CHANNELS-1 downto 0);
  commit:in boolean_vector(CHANNELS-1 downto 0);
  dump:in boolean_vector(CHANNELS-1 downto 0);
  --
  instreams:in streambus_array(CHANNELS-1 downto 0);
  instream_valids:in boolean_vector(CHANNELS-1 downto 0);
  instream_readys:out boolean_vector(CHANNELS-1 downto 0);
  full:out boolean;
  
  tick_period:in unsigned(TICKPERIOD_BITS-1 downto 0);
  cfd_errors:in boolean_vector(CHANNELS-1 downto 0);
  framer_overflows:in boolean_vector(CHANNELS-1 downto 0);
  framer_errors:in boolean_vector(CHANNELS-1 downto 0);
	
  window:in unsigned(TIME_BITS-1 downto 0);
  
  muxstream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity eventstream_mux5;
--
architecture RTL of eventstream_mux5 is
	
--constant CHANNELS:integer:=2**CHANNEL_BITS;

signal timestamp,eventtime:unsigned(TIMESTAMP_BITS-1 downto 0);
signal reltime:unsigned(CHUNK_DATABITS-1 downto 0);
signal reltime_stamp:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal started,commited,dumped:std_logic_vector(CHANNELS-1 downto 0);
signal req:std_logic_vector(CHANNELS-1 downto 0);
signal handled:std_logic_vector(CHANNELS downto 0);
signal sel:std_logic_vector(CHANNELS downto 0);

signal ticked,tick,time_valid,read_next:boolean;
--type FSMstate is (IDLE,HEAD,TAIL,NEXT_TIME);
--signal state,nextstate:FSMstate;
type arbFSMstate is (IDLE,ARBITRATE,SEL_STREAM,SEL_TICK,NEXT_TIME);
signal arb_state:arbFSMstate;
signal tickstream:streambus_t;
signal muxstream_int_valid,muxstream_last:boolean;
signal tickstream_valid:boolean;
signal tickstream_ready:boolean;

signal streams:streambus_array(CHANNELS downto 0);
signal muxstream_int,muxstream_reg,stream_int:streambus_t;
signal muxstream_reg_ready,muxstream_reg_valid:boolean;
signal valids,readys:boolean_vector(CHANNELS downto 0);
signal time_done:boolean;
signal muxstream_handshake:boolean;
signal pulses_done:boolean;
signal muxstream_last_handshake:boolean;
signal first_word:boolean;
signal new_window:boolean;
signal window_start:std_logic;
signal header:boolean;
signal valid_out:boolean;
signal muxstream_out:streambus_t;
signal time_full:boolean;
signal muxstream_int_ready:boolean;

signal reltime_reg:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal new_window_reg:boolean;
signal aux_data,aux_data_in:std_logic_vector(CHUNK_DATABITS+1 downto 0);
--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------
--constant DEBUG:string:="FALSE";
--signal tick_s_last,tick_s_ready,tick_s_valid:boolean;
--signal muxstream_out_last:boolean;
--attribute S:string;

--attribute MARK_DEBUG:string;
--attribute MARK_DEBUG of arb_state_v:signal is DEBUG;
----attribute MARK_DEBUG of valids:signal is DEBUG;
----attribute MARK_DEBUG of readys:signal is DEBUG;
--attribute MARK_DEBUG of tick_s_last,tick_s_ready,tick_s_valid:signal is DEBUG;
----attribute MARK_DEBUG of sel:signal is DEBUG;
--attribute MARK_DEBUG of tick:signal is DEBUG;

begin
--tick_s_last <= streams(0).last(0);
--tick_s_valid <= valids(0);
--tick_s_ready <= readys(0);
--muxstream_out_last <= muxstream_out.last(0);
--arb_state_v <= to_std_logic(arb_state,3);
valid <= valid_out;
muxstream <= muxstream_out;
full <= time_full;

tickstreamer:entity work.tickstream2
generic map(
  CHANNELS => CHANNELS,
  TICKPERIOD_BITS => TICKPERIOD_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  MINIMUM_PERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH
)
port map(
  clk => clk,
  reset => reset,
  tick => tick,
  timestamp => timestamp,
  tick_period => tick_period,
  mux_full => time_full,
  framer_overflows => framer_overflows,
  framer_errors => framer_errors,
  cfd_errors => cfd_errors,
  tickstream => tickstream,
  valid => tickstream_valid,
  ready => tickstream_ready
);

buffers:entity work.timing_buffer
generic map(
  --CHANNEL_BITS => CHANNEL_BITS,
  CHANNELS => CHANNELS,
  TIME_BITS => TIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset,
  start => start,
  commit => commit,
  dump => dump,
  tick => tick,
  window => window,
  timestamp => timestamp,
  eventtime => eventtime,
  reltime => reltime,
  new_window => new_window,
  started => started,
  ticked => ticked,
  commited => commited,
  dumped => dumped,
  valid => time_valid,
  read_next => read_next,
  full => time_full
);

inputRegGen:for i in CHANNELS downto 1 generate
begin
	inputReg:entity streamlib.streambus_register_slice
  port map(
    clk => clk,
    reset => reset,
    stream_in => instreams(i-1),
    ready_out => instream_readys(i-1),
    valid_in => instream_valids(i-1),
    stream => streams(i),
    ready => readys(i),
    valid => valids(i)
  );
--  streams(i) <= instreams(i-1);
--  instream_readys(i-1) <= readys(i);
--  valids(i) <= instream_valids(i-1);
end generate;

tickInputReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => tickstream,
  ready_out => tickstream_ready,
  valid_in => tickstream_valid,
  stream => streams(0),
  ready => readys(0),
  valid => valids(0)
);

selector:entity work.eventstream_select
generic map(
  CHANNELS => CHANNELS+1
)
port map(
  sel => sel,
  instreams => streams,
  valids => valids,
  mux_stream => muxstream_int,
 	mux_valid => muxstream_int_valid
);

muxstream_last <= muxstream_int.last(0);
muxstream_handshake <= muxstream_int_valid and muxstream_int_ready;
muxstream_last_handshake <= muxstream_handshake and muxstream_last;

firstWord:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      first_word <= TRUE;
    else
      if muxstream_handshake then
        first_word <= muxstream_last;
      end if;
    end if;
  end if;
end process firstWord;

aux_data_in <= reltime_reg & to_std_logic(new_window_reg) & 
               to_std_logic(first_word);

muxStreamReg:entity streamlib.streambus_register_slice_user
generic map(USER_WIDTH => CHUNK_DATABITS+2)
port map(
  clk => clk,
  reset => reset,
  user_in => aux_data_in,
  stream_in => muxstream_int,
  ready_out => muxstream_int_ready,
  valid_in => muxstream_int_valid,
  user => aux_data,
  stream => muxstream_reg,
  ready => muxstream_reg_ready,
  valid => muxstream_reg_valid
);

pulses_done <= (started = handled(CHANNELS downto 1)); -- and time_valid; 
time_done <= pulses_done and to_std_logic(ticked) = handled(0);
read_next <= arb_state=NEXT_TIME;

--req <= started and commited and not handled(CHANNELS downto 1);

arbiter:process(clk)
variable handledv:std_logic_vector(CHANNELS downto 0);
begin
if rising_edge(clk) then
  if reset = '1' then 
  	handled <= (others => '0');
--  	gnt <= (others => '0');
  else
  	
    if arb_state=IDLE then
    	handledv:=(others => '0');		
    elsif muxstream_last_handshake then
      handledv(CHANNELS downto 1):=handled(CHANNELS downto 1) or 
                                   sel(CHANNELS downto 1) or 
      														 (dumped and started);
    else
      handledv(CHANNELS downto 1):=handled(CHANNELS downto 1) or 
      														 (dumped and started);
    end if;
    handled <= handledv;			
    --FIXME do started and commited in time_buffer										
    req <= started and commited and not handledv(CHANNELS downto 1);
--	  gnt <= req and std_logic_vector(unsigned(not req)+1);
    													  
  end if;
end if;
end process arbiter;


readys <= (others => FALSE) when not muxstream_int_ready else
          (0 => TRUE, others => FALSE) when arb_state=SEL_TICK else
          to_boolean(sel);
          
arbFSMtransition:process(clk)
begin
  if rising_edge(clk) then
    if reset='1' then
      arb_state <= IDLE;
      sel <= (others => '0');
    else
      case arb_state is 
      when IDLE =>
        if time_valid then 
          arb_state <= ARBITRATE;
          sel <= (others => '0');
          reltime_reg <= set_endianness(reltime,ENDIANNESS);
          new_window_reg <= new_window;
        end if;
        
      when ARBITRATE =>
        if pulses_done then 
          if ticked then
            arb_state <= SEL_TICK;
            sel <= (0 => '1', others => '0');
          else
            arb_state <= NEXT_TIME;
            sel <= (others => '0');
          end if;
        elsif unaryOR(req) then
          arb_state <= SEL_STREAM;
          --sel <= gnt & '0';
	        sel <= (req and std_logic_vector(unsigned(not req)+1)) & '0';
        end if;
        
      when SEL_STREAM =>
        if pulses_done then
          if ticked then
            arb_state <= SEL_TICK;
            sel <= (0 => '1', others => '0');
          else
            arb_state <= NEXT_TIME;
            sel <= (others => '0');
          end if;
        else
          if muxstream_last_handshake then
            reltime_reg <= (others => '0');
            new_window_reg <= FALSE;
            arb_state <= ARBITRATE;
            sel <= (others => '0');
          end if;
        end if;
        
      when SEL_TICK =>
        if muxstream_last_handshake then
          arb_state <= NEXT_TIME;
          sel <= (others => '0');
        end if;
        
      when NEXT_TIME =>
        arb_state <= IDLE;
        sel <= (others => '0');
      end case;
    end if;
  end if;
end process arbFSMtransition;

reltime_stamp <= aux_data(CHUNK_DATABITS+1 downto 2);
window_start <= aux_data(1);
header <= aux_data(0)='1';

--bigEndian:if endianness="BIG" generate
stream_int.data <= muxstream_reg.data(63 downto 17) & window_start & 
                   reltime_stamp
                   when header
                   else muxstream_reg.data;
--end generate;

--littleEndian:if endianness="LITTLE" generate
--  stream_int.data <= muxstream_int.data(63 downto 25) &
--                     to_std_logic(window_start) &
--                     muxstream_int.data(23 downto 16) &
--                     reltime_stamp
--                  when out_state=HEAD
--                  else muxstream_int.data;
--end generate;
 
-- FIXME new_window when not first_event:
									 
stream_int.last <= muxstream_reg.last;
stream_int.discard <= muxstream_reg.discard;

outStreamReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_int,
  ready_out => muxstream_reg_ready,
  valid_in => muxstream_reg_valid,
  stream => muxstream_out,
  ready => ready,
  valid => valid_out
);
end architecture RTL;
