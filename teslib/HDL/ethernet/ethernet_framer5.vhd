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
use work.types.all;
use work.functions.all;

--TODO handle event length field to allow variable length events
entity ethernet_framer5 is
generic(
	MTU_BITS:integer:=MTU_BITS;
	TICK_LATENCY_BITS:integer:=TICK_LATENCY_BITS;
	FRAMER_ADDRESS_BITS:integer:=11;
	DEFAULT_MTU:unsigned:=DEFAULT_MTU;
	DEFAULT_TICK_LATENCY:unsigned:=DEFAULT_TICK_LATENCY;
	ENDIANNESS:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  mtu:in unsigned(MTU_BITS-1 downto 0);
  -- maximum clocks without transmitting a tick before dumping buffer
  tick_latency:in unsigned(TICK_LATENCY_BITS-1 downto 0);
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
end entity ethernet_framer5;

architecture RTL of ethernet_framer5 is
	
--------------------------------------------------------------------------------
-- Signals used in input stage
--------------------------------------------------------------------------------
signal event_s:streambus_t;	 -- internal eventstream
signal event_s_ready,event_s_valid:boolean;
signal eventstream_ready_int:boolean; -- outgoing ready
signal buffer_full:boolean;
signal buffer_empty,flush_events:boolean;
signal mca_s:streambus_t; -- internal mcastream
signal mca_s_ready,mca_s_valid:boolean;

--------------------------------------------------------------------------------
-- Signals used by FSMs
--------------------------------------------------------------------------------

type arbiterFSMstate is (IDLE,MCA,EVENT);
signal arbiter_state,arbiter_nextstate:arbiterFSMstate;
type frameFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,PAYLOAD,TERMINATE,LENGTH);
signal frame_state,frame_nextstate:frameFSMstate;

--------------------------------------------------------------------------------
-- Signals used by framer
--------------------------------------------------------------------------------

signal framer_word:streambus_t;
signal framer_address,next_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal framer_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_frame:boolean;
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0):=
       to_unsigned(to_integer(DEFAULT_MTU/8),FRAMER_ADDRESS_BITS+1);
--signal frame_we:boolean;
signal mtu_int:unsigned(MTU_BITS-1 downto 0):=
			 to_unsigned(to_integer(DEFAULT_MTU/8),MTU_BITS);
--signal mtu_m1:unsigned(MTU_BITS-1 downto 0):=
--			 to_unsigned(to_integer(DEFAULT_MTU/8)-1,MTU_BITS);
signal tick_latency_count:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal tick_latency_int:unsigned(TICK_LATENCY_BITS-1 downto 0):=
			 DEFAULT_TICK_LATENCY;
signal wait_for_tick,tick_overdue:boolean;
--signal event_frame_full:boolean;
signal lookahead:streambus_t;
signal lookahead_valid:boolean;
--
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
--signal frame_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_free_m1:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_last:boolean;
signal frame_under:boolean;
signal inc_address:boolean;
signal framer_ready:boolean;
-- frame_size is the size of events in the current frame
signal event_s_size:unsigned(SIZE_BITS-1 downto 0);
signal size_change,type_change:boolean;
signal lookahead_head:boolean;
signal event_s_last_hs:boolean;
signal event_s_hs:boolean;
signal mca_s_hs:boolean;
signal last_frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal last_frame_word:streambus_t;
signal mca_last,trace_last:boolean;
--signal trace_last:boolean;
-- frame type switching
signal lookahead_size,frame_size:unsigned(SIZE_BITS-1 downto 0);
signal lookahead_type,event_s_type:event_type_t;
signal lookahead_trace_type,event_s_trace_type:trace_type_d;
signal event_head:boolean;

--------------------------------------------------------------------------------
-- Ethernet Header
--------------------------------------------------------------------------------
constant ETHERNET_HEADER_WORDS:integer:=3;
constant MIN_FRAME:integer:=8;
constant SEQUENCE_BITS:integer:=16;
type ethernet_header_t is record
	destination_address:unsigned(47 downto 0);
	source_address:unsigned(47 downto 0);
	ethernet_type:unsigned(15 downto 0);
	frame_sequence:unsigned(SEQUENCE_BITS-1 downto 0);
	length:unsigned(15 downto 0);
	protocol_sequence:unsigned(SEQUENCE_BITS-1 downto 0);
	event_type:event_type_t;
	trace_type:trace_type_d;
	event_size:unsigned(15 downto 0);
end record;

signal header:ethernet_header_t;
signal mca_sequence,event_sequence,trace_sequence
       :unsigned(SEQUENCE_BITS-1 downto 0);
--signal trace_sequence:unsigned(SEQUENCE_BITS-1 downto 0);

function to_std_logic(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1;
											endianness:string)
 											return std_logic_vector is 
variable slv:std_logic_vector(BUS_DATABITS-1 downto 0);
begin
	case w is
	when 0 => 
    slv := to_std_logic(e.source_address) &
           to_std_logic(e.destination_address(47 downto 32));
	when 1 =>
		slv := to_std_logic(e.destination_address(31 downto 0)) &
					 to_std_logic(e.ethernet_type) &
           to_std_logic(0,16); --length added later
	when 2 => 
    slv := set_endianness(e.frame_sequence,endianness) &
           set_endianness(e.protocol_sequence,endianness) &
           set_endianness(e.event_size,endianness) &
--           to_std_logic(0,8) &
           to_std_logic(e.trace_type,8) &
           "0000" &
           to_std_logic(e.event_type) & '0';
	when others => 
		assert FALSE report "bad word number in ethernet_header to_streambus()"	
						 severity ERROR;
	end case;
	return slv;
end function;

function to_streambus(e:ethernet_header_t;
											w:natural range 0 to ETHERNET_HEADER_WORDS-1;
											endianness:string)
 											return streambus_t is 
variable sb:streambus_t;
begin
	sb.discard := (others => FALSE); 
	sb.last := (others => FALSE);
  sb.data := to_std_logic(e,w,endianness);
	return sb;
end function;
--------------------------------------------------------------------------------
--signals for vcd dump (simulation only)
--synthesis translate_off
--attribute keep:string;
--attribute S:string;
--signal arbiter_state_v:std_logic_vector(1 downto 0);
--signal frame_state_v:std_logic_vector(2 downto 0);
--attribute keep of arbiter_state_v,frame_state_v:signal is "TRUE";
--attribute S of arbiter_state_v,frame_state_v:signal is "TRUE";
--function to_std_logic(s:arbiterFSMstate;w:integer) return std_logic_vector is
--begin
--  return to_std_logic(arbiterFSMstate'pos(s),w);
--end function;
--
--function to_std_logic(s:frameFSMstate;w:integer) return std_logic_vector is
--begin
--  return to_std_logic(frameFSMstate'pos(s),w);
--end function;

--signal framer_word_v:std_logic_vector(BUS_DATABITS-1 downto 0);
--signal commit_v:std_logic;
--signal framer_we_v:std_logic_vector(BUS_CHUNKS-1 downto 0);
--signal event_s_v:std_logic_vector(BUS_DATABITS-1 downto 0);
--signal event_s_ready_v,event_s_valid_v,event_s_last_v:std_logic;
--signal mca_s_v:std_logic_vector(BUS_DATABITS-1 downto 0);
--signal mca_s_ready_v,mca_s_valid_v,mca_s_last_v:std_logic;
--synthesis translate_on
--------------------------------------------------------------------------------
-- Debugging
--------------------------------------------------------------------------------
signal framestream:streambus_t;
signal framestream_firstbyte:std_logic_vector(7 downto 0);
signal framestream_last,new_frame,framestream_ready,framestream_valid:boolean;
signal lookahead_type_s:std_logic_vector(2 downto 0);
signal estream_s:std_logic_vector(BUS_DATABITS-1 downto 0);
signal estream_last:boolean;

constant DEBUG:string:="FALSE";
attribute MARK_DEBUG:string;

attribute MARK_DEBUG of lookahead_type_s:signal is DEBUG;
attribute MARK_DEBUG of lookahead_valid:signal is DEBUG;
attribute MARK_DEBUG of buffer_full:signal is DEBUG;
attribute MARK_DEBUG of lookahead_head:signal is DEBUG;
attribute MARK_DEBUG of estream_s:signal is DEBUG;
attribute MARK_DEBUG of event_s_valid:signal is DEBUG;
attribute MARK_DEBUG of event_s_ready:signal is DEBUG;
attribute MARK_DEBUG of estream_last:signal is DEBUG;

--attribute MARK_DEBUG of framestream_firstbyte:signal is DEBUG;
--attribute MARK_DEBUG of new_frame:signal is DEBUG;
--attribute MARK_DEBUG of framer_free:signal is DEBUG;
--attribute MARK_DEBUG of framer_ready:signal is DEBUG;
--attribute MARK_DEBUG of framestream_valid:signal is DEBUG;
--attribute MARK_DEBUG of framestream_ready:signal is DEBUG;

--attribute MARK_DEBUG of arbiter_state_v:signal is DEBUG;
--attribute MARK_DEBUG of frame_state_v:signal is DEBUG;
--attribute MARK_DEBUG of framer_free:signal is DEBUG;
--attribute MARK_DEBUG of frame_free:signal is DEBUG;
--attribute MARK_DEBUG of reset:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_valid:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_ready:signal is DEBUG;

begin
--------------------------------------------------------------------------------
 framestream_firstbyte <= framestream.data(63 downto 56);
 framestream_last <= framestream.last(0);
 lookahead_type_s <= to_std_logic(lookahead_type);
 estream_s <= event_s.data;
 estream_last <= event_s.last(0);
 
 frameStart:process (clk) is
 begin
   if rising_edge(clk) then
     if reset = '1' then
       new_frame <= FALSE;
     else
       if framestream_ready and framestream_valid then
         new_frame <= framestream_last;
       end if;
     end if;
   end if;
 end process frameStart;
 
--simulation only (for VCD dump)
--synthesis translate_off
--arbiter_state_v <= to_std_logic(arbiter_state,2);
--frame_state_v <= to_std_logic(frame_state,3);
--framer_word_v <= framer_word.data;
--commit_v <= to_std_logic(commit_frame);
--framer_we_v <= to_std_logic(framer_we);
--event_s_v <= event_s.data;
--event_s_ready_v <= to_std_logic(event_s_ready);
--event_s_valid_v <= to_std_logic(event_s_valid);
--event_s_last_v <= to_std_logic(event_s.last(0));
--mca_s_v <= mca_s.data;
--mca_s_ready_v <= to_std_logic(mca_s_ready);
--mca_s_valid_v <= to_std_logic(mca_s_valid);
--mca_s_last_v <= to_std_logic(mca_s.last(0));
--synthesis translate_on
--------------------------------------------------------------------------------

mtuCapture:process(clk)
begin
	if rising_edge(clk) then
    if arbiter_state=IDLE then
      mtu_int <= shift_right(mtu,3); --MTU in 8byte blocks
      tick_latency_int <= tick_latency;
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

event_s_ready <= arbiter_state=EVENT and frame_state=PAYLOAD and inc_address;
mca_s_ready <= arbiter_state=MCA and frame_state=PAYLOAD and framer_ready;
event_s_hs <= event_s_valid and event_s_ready;
mca_s_hs <= mca_s_valid and mca_s_ready;

buffer_full <= not eventstream_ready_int;
buffer_empty <= not event_s_valid; -- questionable

lookahead_type <= to_event_type_t(lookahead);
lookahead_trace_type <= to_trace_type_d(lookahead.data(39 downto 38));

-- swap back to big endian if needed
lookahead_size 
	<= unsigned(set_endianness(lookahead.data(63 downto 48),endianness));

event_s_last_hs <= event_s_hs and event_s.last(0);

eventLookahead:process(clk)
variable size:unsigned(SIZE_BITS-1 downto 0);
begin
	if rising_edge(clk) then
		
    if reset ='1' then
    	lookahead_head <= TRUE;
    	event_head <= TRUE;
    else
    	
    	if frame_state=HEADER0 then -- header0 is ethernet protocol
    		if arbiter_state=EVENT then
    		  header.event_type <= event_s_type;
    		  header.trace_type <= event_s_trace_type;
    		  header.event_size <= event_s_size;
        	frame_size <= event_s_size; --FIXME replace with header.size
        	type_change <= FALSE;
        	size_change <= FALSE;
        else -- must be MCA
        	frame_size <= (0 => '1', others => '0');
        	header.event_size <= (0 => '1', others => '0');
        end if;	
      end if;
    	
    	if lookahead_valid and (event_s_hs or not event_s_valid) then
    		
				lookahead_head <= lookahead.last(0);
    	
    		if lookahead_head then	
    			event_s_type <= lookahead_type;
    			event_s_trace_type <= lookahead_trace_type;
    			if frame_state=PAYLOAD then
    				type_change <= header.event_type/=lookahead_type;
    			end if;
        
          if lookahead_type.tick then
          	size := to_unsigned(3, SIZE_BITS);
          	size_change <= FALSE;
          else
            case lookahead_type.detection is
            when PEAK_DETECTION_D =>
            	size := (0 =>'1', others => '0');
            	size_change <= FALSE;
            when AREA_DETECTION_D =>
              size := (0 =>'1', others => '0');
            	size_change <= FALSE;
            when PULSE_DETECTION_D =>
              size := lookahead_size;
            	size_change <= frame_size/=lookahead_size;
            when TRACE_DETECTION_D =>
              if lookahead_trace_type=DOT_PRODUCT_D then
                size := lookahead_size;
              	size_change <= frame_size/=lookahead_size;
              else
                size := to_unsigned(1, SIZE_BITS); 
                size_change <= TRUE; --??
            	end if;
            end case;
          end if;
          
          event_s_size <= size;
          
    		end if;
    	end if;
    end if;
  end if;
end process eventLookahead;

tickLatency:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			tick_latency_count <= (others => '0');
		else
			if tick_overdue then
				wait_for_tick <= TRUE;
			end if;
			
			if buffer_full then 
				flush_events <= TRUE;
			end if;
			
			if buffer_empty then 
				flush_events <= FALSE;
			end if;
		
		  tick_overdue <= tick_latency_count >= tick_latency_int; 	
      if header.event_type.tick and event_s_last_hs then
        tick_latency_count <= (others => '0');
        wait_for_tick <= FALSE;
      elsif not tick_overdue then
        tick_latency_count <= tick_latency_count+1;
      end if;
			
		end if;
	end if;
end process tickLatency;

header.source_address <= x"5A0102030405";
header.destination_address <= x"DA0102030405";
seqNumbers:process(clk)
begin
	
	if rising_edge(clk) then
		if reset = '1' then
			header.frame_sequence <= (others => '0');
			header.length <= (others => '-');
			event_sequence <= (others => '0');
			trace_sequence <= (others => '0');
			mca_sequence <= (others => '0');
			mca_last <= FALSE;
		else

			if mca_s_hs and mca_s.last(0) then
				mca_last <= TRUE;
			end if;
			
			if event_s_last_hs and header.event_type.detection=TRACE_DETECTION_D then
			  trace_last <= TRUE;
			end if;
			
--			if event_s_ready and event_s_valid and event_s.last(0) 
--					and header.event_type.detection=TEST_DETECTION_D then 
--				trace_last <= TRUE;
--			end if;
			
			if arbiter_state=MCA then
        header.ethernet_type <= x"88B6";
        header.protocol_sequence <= mca_sequence;
			elsif arbiter_state=EVENT then
  			header.ethernet_type <= x"88B5";
  			if header.event_type.detection=TRACE_DETECTION_D and 
  			   header.trace_type/=DOT_PRODUCT_D then
          header.protocol_sequence <= trace_sequence;
				else
				  header.protocol_sequence <= event_sequence;
				end if;
			end if;
				
			if commit_frame then
				
				header.frame_sequence <= header.frame_sequence+1;
				
				if arbiter_state=MCA then
					if mca_last then
						mca_sequence <= (others => '0');
						mca_last <= FALSE;
					else
						mca_sequence <= mca_sequence+1;
					end if;
				end if;
				
				if arbiter_state=EVENT then
				  if header.event_type.detection=TRACE_DETECTION_D and 
				     header.trace_type/=DOT_PRODUCT_D then
				    if trace_last then
              trace_sequence <= (others => '0');
              trace_last <= FALSE;
				    else
  					  trace_sequence <= trace_sequence+1;
				    end if;
				  else
					  event_sequence <= event_sequence+1;
					end if;
				end if;
				
			end if;
			
		end if;
		
	end if;
end process seqNumbers;

FSMnextstate:process(clk)
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
end process FSMnextstate;

arbiterFSMtransition:process(arbiter_state,flush_events,mca_s_valid,
												 		 event_s_valid,frame_state,wait_for_tick)
begin
	arbiter_nextstate <= arbiter_state;
	case arbiter_state is 
	when IDLE =>
		if flush_events or wait_for_tick then
			arbiter_nextstate <= EVENT;
		elsif mca_s_valid then
			arbiter_nextstate <= MCA;
		elsif event_s_valid then
			arbiter_nextstate <= EVENT;
		end if;
	when MCA | EVENT =>
  	if frame_state=LENGTH then
  		arbiter_nextstate <= IDLE;
  	end if;
	end case;
end process arbiterFSMtransition;

--FIXME need registered output
--event_frame_full <= frame_free < to_0ifX(frame_size);
frameFSMtransition:process(frame_state,arbiter_nextstate,arbiter_state,
													 framer_ready,mca_s_valid,flush_events,
												   event_s_valid,frame_last,mca_s,event_s,event_head,
												   header.event_type,header,frame_address,
												   last_frame_address,last_frame_word,lookahead_valid,
												   size_change,type_change,frame_under)
begin
	frame_nextstate <= frame_state;
  framer_address <= frame_address; 
  framer_word.data <= (others => '-');
  framer_word.last <= (others => FALSE);
  framer_word.discard <= (others => FALSE);
  framer_we <= (others => FALSE); 
  inc_address <= FALSE;
	case frame_state is 
	when IDLE =>
		if arbiter_nextstate /= IDLE then
			frame_nextstate <= HEADER0;
		end if;	
		
	when HEADER0 =>
		framer_word <= to_streambus(header,0,ENDIANNESS);
		framer_we <= (others => framer_ready);
		inc_address <= framer_ready;
		if framer_ready then
			frame_nextstate <= HEADER1;
		end if;
		
	when HEADER1 =>
		framer_word <= to_streambus(header,1,ENDIANNESS);
		framer_we <= (others => framer_ready);
		inc_address <= framer_ready;
		if framer_ready then
			frame_nextstate <= HEADER2;
		end if;
		
	when HEADER2 =>
		framer_word <= to_streambus(header,2,ENDIANNESS);
		framer_we <= (others => framer_ready);
		inc_address <= framer_ready;
		if framer_ready then
			frame_nextstate <= PAYLOAD;
		end if;
		
	when PAYLOAD =>
		if arbiter_state=MCA then
			
      framer_word.data <= mca_s.data;
      framer_we <= (others => mca_s_valid and framer_ready);
      --inc_address <= mca_s_valid and framer_ready;
    	if mca_s_valid and framer_ready then 
    		inc_address <= TRUE;
    		if frame_last or flush_events or mca_s.last(0) then
    			--inc_address <= FALSE;
        	frame_nextstate <= LENGTH;
        	framer_word.last(0) <= TRUE;
        end if;
      end if;
      
    else -- must be event
    	
	    framer_word.data <= event_s.data;
      if event_head and (type_change or size_change) then
      	-- Want to keep one type and size in a frame so when it arrives at the 
      	-- the buffer can be addressed as a array
        frame_nextstate <= TERMINATE;
        framer_we <= (others => FALSE);
      elsif event_s_valid then 
      	if frame_last then
      		if event_s.last(0) then
      			framer_word.last(0) <= TRUE;
      			framer_we <= (others => framer_ready);
      			inc_address <= framer_ready;
						if framer_ready then
							frame_nextstate <= LENGTH;
						end if;
					elsif event_head then
						frame_nextstate <= TERMINATE;	
					else
						framer_we <= (others => framer_ready); --???
						inc_address <= framer_ready;
					end if;
				else
          framer_we <= (others => framer_ready);
          inc_address <= framer_ready;
					if header.event_type.detection=TRACE_DETECTION_D or --??
							header.event_type.tick then
						framer_word.last(0) <= event_s.last(0);
						if event_s.last(0) and framer_ready then
							frame_nextstate <= LENGTH;
						end if;
					end if;
				end if;
			else
				if not lookahead_valid and event_head and not frame_under and 
				    mca_s_valid then
					frame_nextstate <= TERMINATE;
				end if;
      end if;
    end if;
    
	when TERMINATE =>  -- write last
		framer_word <= last_frame_word;
		framer_address <= last_frame_address;
		framer_we <= (others => TRUE);
    frame_nextstate <= LENGTH;
    
	when LENGTH => -- commit frame
		framer_address <= (0 => '1', others => '0');
		framer_word.data(CHUNK_DATABITS-1 downto 0) 
			<= set_endianness(
				shift_left(resize(frame_address, CHUNK_DATABITS),3),
				ENDIANNESS
			);
		framer_word.discard <= (others => FALSE);
		framer_word.last <= (others => FALSE);
		framer_we <= (0 => TRUE, others => FALSE);
    frame_nextstate <= IDLE;
	end case;
end process frameFSMtransition;

payloadAddress:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			frame_address <= (others => '0');
			next_address <= (0 => '1', others => '0');
			last_frame_address <= (others => '0');
			--FIXME is the -1 correct for frame free?
--			frame_free 
--				<= to_unsigned(to_integer(DEFAULT_MTU/8),FRAMER_ADDRESS_BITS+1);
			frame_free_m1 
				<= to_unsigned(to_integer(DEFAULT_MTU/8)-1,FRAMER_ADDRESS_BITS+1);
			framer_ready <= FALSE;
		else
			framer_ready <= framer_free > next_address;
			if commit_frame then
				frame_address <= (others => '0');
				next_address <= (0 => '1', others => '0');
--				frame_free <= resize(mtu_int,FRAMER_ADDRESS_BITS+1);
				frame_free_m1 <= resize(mtu_int-1,FRAMER_ADDRESS_BITS+1);
			elsif inc_address then
				last_frame_word <= framer_word;
				last_frame_word.discard <= framer_word.discard;
				last_frame_word.last <= (0 => TRUE, others => FALSE);
				last_frame_address <= frame_address;
				next_address <= next_address+1;
				frame_address <= next_address;
				--framer_ready <= framer_free > next_address;
--        frame_free <= frame_free_m1;
        frame_free_m1 <= frame_free_m1-1;
        frame_last <= frame_free_m1 = 1;
        frame_under <= next_address < MIN_FRAME;
			end if;
		end if;
	end if;
end process payloadAddress;

commit_frame <= frame_state=LENGTH;
frame_length <= '0' & frame_address; --TODO check this
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
  chunk_we => framer_we,
  length => frame_length,
  commit => commit_frame,
  free => framer_free,
  stream => framestream,
  valid => framestream_valid,
  ready => framestream_ready
);

ethernetstream <= framestream;
ethernetstream_valid <= framestream_valid;
framestream_ready <= ethernetstream_ready;

end architecture RTL;
