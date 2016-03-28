--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:7 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: output_mux
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

use work.events.all;
use work.registers.all;
use work.protocol.all;
use work.types.all;
use work.functions.all;

--TODO handle event length field to allow variable length events
entity ethernet_framer is
generic(
	MTU_BITS:integer:=MTU_BITS;
	TICK_LATENCY_BITS:integer:=TICK_LATENCY_BITS;
	FRAMER_ADDRESS_BITS:integer:=ETHERNET_FRAMER_ADDRESS_BITS;
	DEFAULT_MTU:integer:=DEFAULT_MTU;
	DEFAULT_TICK_LATENCY:integer:=DEFAULT_TICK_LATENCY;
	ENDIANNESS:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  mtu:in unsigned(MTU_BITS-1 downto 0);
  -- maximum clocks without transmitting a tick before dumping buffer
  tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
  --
  eventstream:in streambus_t;
  eventstream_valid:in boolean;
  eventstream_ready:out boolean;
  --
  mcastream:in streambus_t;
  mcastream_valid:in boolean;
  mcastream_ready:out boolean;
  --
  ethernetstream:out streambus_t;
  ethernetstream_valid:out boolean;
  ethernetstream_ready:in boolean
);
end entity ethernet_framer;

architecture RTL of ethernet_framer is
	
--------------------------------------------------------------------------------
-- Signals used in input stage
--------------------------------------------------------------------------------
signal event_s:streambus_t;	 -- internal eventstream
signal event_s_ready,event_s_valid:boolean;
signal eventstream_ready_int:boolean; -- outgoing ready
signal eventstream_hs,buffer_full:boolean;
signal buffer_empty,empty_the_buffer:boolean;
signal mca_s:streambus_t; -- internal mcastream
signal mca_s_ready,mca_s_valid:boolean;

--------------------------------------------------------------------------------
-- Signals used by FSMs
--------------------------------------------------------------------------------

type arbitorFSMstate is (IDLE,MCA,EVENT);
signal arbiter_state,arbiter_nextstate:arbitorFSMstate;
type frameFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,PAYLOAD,TERMINATE,LENGTH);
signal frame_state,frame_nextstate:frameFSMstate;

--------------------------------------------------------------------------------
-- Signals used by framer
--------------------------------------------------------------------------------

signal framer_word:streambus_t;
signal framer_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_chunk_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame:boolean;
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal ethernet_header:ethernet_header_t;
--signal frame_we:boolean;
signal frame_sequence,mca_sequence,event_sequence:unsigned(15 downto 0);
signal mtu_int:unsigned(MTU_BITS-1 downto 0);
signal tick_latency_count:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal tick_latency_int:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal wait_for_tick:boolean;
signal tick:boolean;
signal end_frame,frame_full:boolean;
signal lookahead:streambus_t;
signal lookahead_valid:boolean;
--
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal write:boolean;
signal framer_ready:boolean;
signal lookahead_tick:boolean;
signal lookahead_type:event_type_t;
signal lookahead_size:unsigned(SIZE_BITS-1 downto 0);
signal event_size:unsigned(SIZE_BITS-1 downto 0);
signal event_head:boolean;
signal event_s_last_hs:boolean;
signal event_s_hs:boolean;
signal mca_s_hs:boolean;
signal last_frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal last_frame_word : streambus_t;

begin

mtuCapture:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			mtu_int <= to_unsigned(DEFAULT_MTU/8,MTU_BITS)-1;
			tick_latency_int <= to_unsigned(DEFAULT_TICK_LATENCY,TICK_LATENCY_BITS);
		else
			if arbiter_state=IDLE then
				mtu_int <= resize(shift_right(mtu,3),MTU_BITS);
				tick_latency_int <= tick_latency;
			end if;
		end if;
	end if;
end process mtuCapture;

--register slice to break outgoing ready combinatorial path
mcaReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => mcastream,
  ready_out => mcastream_ready,
  valid_in => mcastream_valid,
  stream => mca_s,
  ready => mca_s_ready,
  valid => mca_s_valid
);

eventstream_ready <= eventstream_ready_int;
eventBuffer:entity streamlib.streambus_lookahead_buffer
port map(
  clk => clk,
  reset => reset,
  instream => eventstream,
  instream_valid => eventstream_valid,
  instream_ready => eventstream_ready_int,
  lookahead => lookahead,
  lookahead_valid => lookahead_valid,
  stream => event_s,
  valid => event_s_valid,
  ready => event_s_ready
);

buffer_full <= not eventstream_ready_int;
buffer_empty <= not event_s_valid and not lookahead_valid; -- questionable

lookahead_type <= to_event_type(lookahead);
lookahead_size <= unsigned(lookahead.data(63 downto 48));
lookahead_tick <= lookahead_type.tick and lookahead_valid;

eventSize:process(clk)
begin
	if rising_edge(clk) then
    if reset ='1' then
    	event_size <= (others => '-');
    	event_head <= TRUE;
    else
    	if eventstream_hs then 
    		event_head <= event_s.last(0);
    	end if;
    	-- TODO test this
    	if lookahead_valid and 
    			(event_s_last_hs or
          (event_head and not event_s_valid)) then
        tick <= lookahead_type.tick;
        if lookahead_type.tick then
          event_size <= to_unsigned(2, SIZE_BITS);
        else
          case lookahead_type.detection_type is
          when PEAK_DETECTION_D =>
            event_size <= (0 =>'1', others => '0');
          when AREA_DETECTION_D =>
            event_size <= (0 =>'1', others => '0');
          when PULSE_DETECTION_D =>
            event_size <= lookahead_size;
          when TRACE_DETECTION_D =>
            event_size <= lookahead_size;
          end case;
        end if;
     	else
     		if eventstream_hs then
     			tick <= FALSE;
     		end if;
     	end if;
    end if;
  end if;
end process eventSize;

tickLatency:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			tick_latency_count <= (others => '0');
		else
			if tick_latency_count >= tick_latency_int then
				wait_for_tick <= TRUE;
			end if;
			
			--FIXME huh?
			if buffer_full then -- this must be the outgoing ready
				empty_the_buffer <= TRUE;
			end if;
			
			if buffer_empty then 
				empty_the_buffer <= FALSE;
			end if;
			
      if tick and event_s_last_hs then
        tick_latency_count <= (others => '0');
        wait_for_tick <= FALSE;
      else
        tick_latency_count <= tick_latency_count+1;
      end if;
			
		end if;
	end if;
end process tickLatency;

ethernetHeader:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			ethernet_header.source_address <= x"5A0102030405";
			ethernet_header.destination_address <= x"DA0102030405";
			frame_sequence <= (others => '0');
			event_sequence <= (others => '0');
			mca_sequence <= (others => '0');
		else
			if frame_state=IDLE then
				if arbiter_nextstate=MCA then
					ethernet_header.ethernet_type <= x"88B6";
					ethernet_header.frame_sequence <= frame_sequence;
					ethernet_header.protocol_sequence <= mca_sequence;
				elsif arbiter_nextstate=EVENT then
					ethernet_header.ethernet_type <= x"88B5";
					ethernet_header.frame_sequence <= frame_sequence;
					ethernet_header.protocol_sequence <= event_sequence;
				end if;
			elsif commit_frame then
				frame_sequence <= frame_sequence+1;
				if arbiter_state=MCA then
					mca_sequence <= mca_sequence+1;
				elsif arbiter_state=EVENT then
					event_sequence <= event_sequence+1;
				end if;
      end if;
		end if;
	end if;
end process ethernetHeader;

muxFSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			arbiter_state <= IDLE;
			frame_state <= IDLE;
		else
			arbiter_state <= arbiter_nextstate;
			frame_state <= frame_nextstate;
		end if;
	end if;
end process muxFSMnextstate;

muxFSMtransition:process(arbiter_state,empty_the_buffer,mca_s_valid,
												 event_s_valid,frame_state,wait_for_tick)
begin
	arbiter_nextstate <= arbiter_state;
	case arbiter_state is 
	when IDLE =>
		if empty_the_buffer or wait_for_tick then
			arbiter_nextstate <= EVENT;
		elsif mca_s_valid then
			arbiter_nextstate <= MCA;
		elsif event_s_valid then
			arbiter_nextstate <= EVENT;
		end if;
	when MCA =>
  	if frame_state=LENGTH then
    	arbiter_nextstate <= IDLE;
    end if;
  when EVENT =>
  	if frame_state=LENGTH then
  		arbiter_nextstate <= IDLE;
  	end if;
	end case;
end process muxFSMtransition;


event_s_hs <= event_s_valid and framer_ready;
mca_s_hs <= mca_s_valid and framer_ready;
event_s_last_hs <= event_s_hs and event_s.last(0);

--FIXME this is to complicated will be hard to meet timing
frameFSMtransition:process(frame_state,arbiter_nextstate,end_frame,
													 arbiter_state,ethernet_header,
													 framer_ready,event_s.data,
													 mca_s_valid,event_s.keep_n, 
													 frame_address,empty_the_buffer,
													 event_s_valid, lookahead_tick,
													 frame_free,frame_full, event_s.last(0), tick, 
													 mca_s.last(0), mca_s.data, mca_s.keep_n, 
													 last_frame_address,last_frame_word.data,
													 last_frame_word.keep_n)
begin
	frame_nextstate <= frame_state;
	commit_frame <= FALSE;
	event_s_ready <= FALSE;
	mca_s_ready <= FALSE;
	framer_address <= frame_address; 
	framer_word.data <= (others => '-');
	framer_word.last <= (others => FALSE);
	framer_word.keep_n <= (others => FALSE);
	frame_chunk_we <= (others => FALSE); 
	write <= FALSE;
	case frame_state is 
	when IDLE =>
		frame_chunk_we <= (others => FALSE);
		if arbiter_nextstate /= IDLE then
			frame_nextstate <= HEADER0;
		end if;	
	when HEADER0 =>
		-- FIXME don't change the endianness of the ethernet header
		-- add separate record for protocol header
		framer_word.data <= to_std_logic(ethernet_header,0,ENDIANNESS);
		if end_frame then --FIXME end_frame not driven
			frame_nextstate <= IDLE;
		elsif framer_ready then
			write <= TRUE;
			frame_chunk_we <= (others => TRUE);
			frame_nextstate <= HEADER1;
		end if;
	when HEADER1 =>
		framer_word.data <= to_std_logic(ethernet_header,1,ENDIANNESS);
		if end_frame then
			frame_nextstate <= IDLE;
		elsif framer_ready then
			write <= TRUE;
			frame_chunk_we <= (others => TRUE);
			frame_nextstate <= HEADER2;
		end if;
	when HEADER2 =>
		framer_word.data <= to_std_logic(ethernet_header,2,ENDIANNESS);
		if end_frame then
			frame_nextstate <= IDLE;
		elsif framer_ready then
			write <= TRUE;
			frame_chunk_we <= (others => TRUE);
			frame_nextstate <= PAYLOAD;
		end if;
	when PAYLOAD =>
    if arbiter_state=MCA then
    	framer_word.data <= mca_s.data;
    	framer_word.keep_n <= mca_s.keep_n;
    	
    	if mca_s_valid and framer_ready then --FIXME ready = valid
	    	mca_s_ready <= TRUE;
				frame_chunk_we <= (others => TRUE);
				write <= TRUE;
        if frame_free=0  or empty_the_buffer or mca_s.last(0) then
          framer_word.last <= (0 => TRUE, others => FALSE);
          frame_nextstate <= LENGTH;
        else
        	framer_word.last <= (others => FALSE);
        end if;
      end if;
    else -- must be event    	
    	-- want to end frame if tick or if type changes
      framer_word.data <= event_s.data;
      framer_word.keep_n <= event_s.keep_n;
    	if framer_ready and event_s_valid then 
				frame_chunk_we <= (others => TRUE);
				write <= TRUE;
   			event_s_ready <= TRUE;
        if frame_full or (event_s.last(0) and tick) or lookahead_tick then 
          framer_word.last <= (0 => TRUE,others => FALSE);
          frame_nextstate <= LENGTH;
        else
        	framer_word.last <= (others => FALSE);
        end if;
      else
      	if lookahead_tick then
      		frame_nextstate <= TERMINATE;
      	end if;
      end if;
		end if;
	when TERMINATE =>  -- write last
		framer_word.data <= last_frame_word.data;
		framer_word.keep_n <= last_frame_word.keep_n;
		framer_word.last <= (0 => TRUE, others => FALSE);
		framer_address <= last_frame_address;
    frame_chunk_we <= (others => TRUE);
    frame_nextstate <= LENGTH;
	when LENGTH => -- commit frame
		commit_frame <= TRUE;
    framer_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
    frame_chunk_we <= (0 => TRUE, others => FALSE);
    framer_word.data(15 downto 0) 
    	<= set_endianness(resize(frame_address,16),ENDIANNESS);
    framer_word.last <= (others => FALSE);
    frame_nextstate <= IDLE;
	end case;
end process frameFSMtransition;

--frameTrasition:process(frame_state,frame_free,event_head)
--begin
--	
--end process frameTrasition;

payloadAddress:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			frame_address <= (others => '0');
			last_frame_address <= (others => '0');
			frame_free <= resize(mtu,FRAMER_ADDRESS_BITS+1);
		else
			if commit_frame then
				frame_address <= (others => '0');
				frame_free <= resize(mtu_int,FRAMER_ADDRESS_BITS+1);
			elsif write then
				last_frame_word <= framer_word;
				last_frame_address <= frame_address;
				frame_address <= frame_address+1;
        frame_free <= frame_free-1;
			end if;
		end if;
	end if;
end process payloadAddress;

frame_full <= frame_free < event_size;
--frame_last <= frame_free=to_unsigned(1,FRAMER_ADDRESS_BITS+1);
framer_ready <= framer_free > frame_address;
--framer_ready <= not framer_full;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => BUS_CHUNKS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => framer_word,
  address => framer_address,
  chunk_we => frame_chunk_we,
  success => open,
  length => frame_address, --TODO check this
  commit => commit_frame,
  free => framer_free,
  stream => ethernetstream,
  valid => ethernetstream_valid,
  ready => ethernetstream_ready
);

end architecture RTL;
