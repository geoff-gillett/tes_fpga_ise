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
	DEFAULT_TICK_LATENCY:integer:=DEFAULT_TICK_LATENCY
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
signal event_stream:streambus_t;	
signal eventstream_ready_int:boolean;
signal event_stream_ready,event_stream_valid:boolean;
signal tick_body,just_reset,event_stream_handshake,buffer_full:boolean;
signal buffer_empty,empty_buffer:boolean;
signal mca_stream:streambus_t;
signal mca_stream_ready:boolean;
signal mca_stream_valid:boolean;

--------------------------------------------------------------------------------
-- Signals used by FSMs
--------------------------------------------------------------------------------

type arbitorFSMstate is (IDLE,MCA,EVENT);
signal arbiter_state,arbiter_nextstate:arbitorFSMstate;
type frameFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,PAYLOAD,LENGTH);
signal frame_state,frame_nextstate:frameFSMstate;

--------------------------------------------------------------------------------
-- Signals used by framer
--------------------------------------------------------------------------------

signal frame_word:streambus_t;
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
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
signal payload_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal write:boolean;
signal framer_ready,frame_last:boolean;
signal lookahead_tick:boolean;
signal first:boolean;
signal tick_end:boolean;

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

mcaReg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => mcastream,
  ready_out => mcastream_ready,
  valid_in => mcastream_valid,
  stream => mca_stream,
  ready => mca_stream_ready,
  valid => mca_stream_valid
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
  stream => event_stream,
  valid => event_stream_valid,
  ready => event_stream_ready
);

event_stream_handshake <= event_stream_ready and event_stream_valid;
buffer_full <= not just_reset and not eventstream_ready_int;
buffer_empty <= not event_stream_valid;
tick <= event_stream.data(TICK_BIT)='1' and not tick_body;
tick_end <= tick_body and event_stream.last(0);
lookahead_tick <= lookahead.data(TICK_BIT)='1';

tickFinder:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			tick_body <= FALSE;
			tick_latency_count <= (others => '0');
		else
			if tick_latency_count=tick_latency_int then
				wait_for_tick <= TRUE;
			end if;
			
			if not eventstream_ready_int then
				empty_buffer <= TRUE;
			end if;
			
			if not event_stream_valid then 
				empty_buffer <= FALSE;
			end if;
			
			if event_stream_handshake then
				if tick then
					tick_body <= TRUE;
				end if;
				if tick_body and event_stream.last(0) then
					tick_body <= FALSE;
				end if;
			end if;
			
      if tick and event_stream_handshake then
        tick_latency_count <= (others => '0');
        wait_for_tick <= FALSE;
      else
        tick_latency_count <= tick_latency_count+1;
      end if;
			
		end if;
	end if;
end process tickFinder;

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

muxFSMtransition:process(arbiter_state,empty_buffer,mcastream_valid,
												 eventstream_valid,frame_state,wait_for_tick)
begin
	arbiter_nextstate <= arbiter_state;
  
	case arbiter_state is 
		
	when IDLE =>
		if empty_buffer or wait_for_tick then
			arbiter_nextstate <= EVENT;
		elsif mcastream_valid then
			arbiter_nextstate <= MCA;
		elsif eventstream_valid then
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

frameFSMtransition:process(frame_state,arbiter_nextstate,end_frame,
													 arbiter_state,ethernet_header,
													 framer_ready,mca_stream,event_stream.data,
													 mca_stream_valid,event_stream.keep_n, 
													 payload_address,frame_last,empty_buffer,
													 event_stream_valid, lookahead_tick, lookahead_valid, 
													 write,tick_end)
begin
	frame_nextstate <= frame_state;
	write <= FALSE;
	commit_frame <= FALSE;
	event_stream_ready <= FALSE;
	mca_stream_ready <= FALSE;
	frame_address <= payload_address;
	frame_word.data <= (others => '-');
	frame_word.last <= (others => FALSE);
	frame_word.keep_n <= (others => FALSE);
	frame_chunk_we <= (others => write);
	case frame_state is 
	when IDLE =>
		write <= FALSE;
		if arbiter_nextstate /= IDLE then
			frame_nextstate <= HEADER0;
		end if;	
	when HEADER0 =>
		frame_word.data <= to_std_logic(ethernet_header,0);
		if end_frame then
			frame_nextstate <= IDLE;
		elsif framer_ready then
			write <= TRUE;
			frame_nextstate <= HEADER1;
		end if;
	when HEADER1 =>
		frame_word.data <= to_std_logic(ethernet_header,1);
		if end_frame then
			frame_nextstate <= IDLE;
		elsif framer_ready then
			write <= TRUE;
			frame_nextstate <= HEADER2;
		end if;
	when HEADER2 =>
		frame_word.data <= to_std_logic(ethernet_header,2);
		if end_frame then
			frame_nextstate <= IDLE;
		elsif framer_ready then
			write <= TRUE;
			frame_nextstate <= PAYLOAD;
		end if;
	when PAYLOAD =>
    if arbiter_state=MCA then
    	frame_word.data <= mca_stream.data;
    	frame_word.keep_n <= mca_stream.keep_n;
    	if mca_stream_valid then
        write <= TRUE;
        mca_stream_ready <= TRUE;
        if frame_last or empty_buffer or mca_stream.last(0) then
          frame_word.last <= (0 => TRUE,others => FALSE);
          frame_nextstate <= LENGTH;
        else
        	frame_word.last <= (others => FALSE);
        end if;
      end if;
    else -- must be event    	
    	frame_word.data <= event_stream.data;
    	if event_stream_valid then
    		frame_word.data <= event_stream.data;
    		frame_word.keep_n <= event_stream.keep_n;
        write <= TRUE;
        event_stream_ready <= TRUE;
        if frame_last or empty_buffer or (not lookahead_valid) or 
           lookahead_tick or tick_end then
          frame_word.last <= (0 => TRUE,others => FALSE);
          frame_nextstate <= LENGTH;
        else
        	frame_word.last <= (others => FALSE);
        end if;
      end if;
		end if;
	when LENGTH =>
		commit_frame <= TRUE;
    frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
    frame_nextstate <= IDLE;
    frame_chunk_we <= (0 => TRUE, others => FALSE);
    frame_word.data <= to_std_logic(resize(payload_address,BUS_DATABITS));
    frame_word.last <= (others => FALSE);
	end case;
end process frameFSMtransition;

payloadAddress:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			payload_address <= (others => '0');
			frame_free <= resize(shift_right(mtu,3),FRAMER_ADDRESS_BITS+1);
			first <= TRUE;
		else
			if commit_frame then
				first <= TRUE;
				payload_address <= (others => '0');
				frame_free <= resize(shift_right(mtu,3),FRAMER_ADDRESS_BITS+1);
			elsif write then
				first <= FALSE;
        payload_address <= payload_address+1;
        frame_free <= frame_free-1;
			end if;
		end if;
	end if;
end process payloadAddress;

frame_full <= frame_free=0;
frame_last <= frame_free=to_unsigned(1,FRAMER_ADDRESS_BITS+1);
framer_ready <= framer_free > payload_address;
--framer_ready <= not framer_full;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => BUS_CHUNKS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => frame_word,
  address => frame_address,
  chunk_we => frame_chunk_we,
  success => open,
  length => payload_address,
  commit => commit_frame,
  free => framer_free,
  stream => ethernetstream,
  valid => ethernetstream_valid,
  ready => ethernetstream_ready
);

end architecture RTL;
