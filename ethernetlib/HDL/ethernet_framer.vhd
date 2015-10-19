--------------------------------------------------------------------------------
--      Author: Geoff Gillett
--     Project: TES counter for ML605 development board with
--              FMC108 ADC mezzanine card
--        File: IO_control.vhd
-- Description: AXI arbiter/MUX for transmission of commands
--              and data to the host PC via the Virtex-6
--              embeded trimode ethernet MAC. 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.types.all;
use streamlib.functions.all;
--
--TODO this entity could be cleaned up
entity ethernet_framer is
generic(
	MCA_CHUNKS:integer:=2; --will only break a MCA frame every MCA_CHUNKS
	MTU_BITS:integer:=12;
  EVENT_LENGTH_BITS:integer:=SIZE_BITS;
  MIN_FRAME_LENGTH:integer:=32;
  ENDIANNESS:string:="LITTLE" --"BIG" or "LITTLE"
); 
port (
  clk:in std_logic;
  reset:in std_logic;
  LEDs:out std_logic_vector(7 downto 0);
  --
  MTU:in unsigned(MTU_BITS-1 downto 0); -- in chunks
  flush_events:in boolean; --flag
  eventbuffer_empty:in boolean;
  eventframe_sent:out boolean; 
  eventchunk:in std_logic_vector(CHUNK_BITS-1 downto 0);
  eventchunk_valid:in boolean;
  eventchunk_ready:out boolean;
  mcachunk:in std_logic_vector(CHUNK_BITS-1 downto 0);
  mcachunk_valid:in boolean;
  mcachunk_ready:out boolean;
  --!* outgoing stream interface  
  framechunk:out std_logic_vector(CHUNK_BITS-1 downto 0); 
  framechunk_valid:out boolean;
  framechunk_ready:in boolean
);
end ethernet_framer;
--
architecture frame_to_stream of ethernet_framer is
--------------------------------------------------------------------------------      
constant HEADER_LENGTH:integer:=12; --needs to be a multiple of MCA_CHUNKS
--
signal commit:boolean;
signal header_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal chunk,last_chunk:std_logic_vector(CHUNK_DATABITS-1 downto 0);
signal framer_free:unsigned(MTU_BITS downto 0);
type framestate is (IDLE,DEST1,DEST2,DEST3,SRC1,SRC2,SRC3,ETHERTYPE,SEQ,
	                  FRAMENUM,RESERVED1,RESERVED2,PAYLOAD,MCATERMINATE,
	                  FRAMELENGTH,PAD,LASTPAYLOAD);
type arbitorFSMstate is (IDLE,EVENT,MCA);
signal arbiter_state,arbiter_nextstate:arbitorFSMstate; 
--attribute keep:string;
--attribute keep of arbiter_state:signal is "TRUE";
signal frame_state:framestate;
--attribute keep of frame_state:signal is "TRUE";
signal sequence,mca_sequence,event_sequence:unsigned(CHUNK_DATABITS-1 downto 0);  
signal frame_free:signed(MTU_BITS downto 0);  
signal frame_under,framer_full:boolean;
signal payload_address,header_address,address:unsigned(MTU_BITS-1 downto 0);
signal last_address:unsigned(MTU_BITS-1 downto 0);
signal mcachunk_ready_int:boolean;
signal eventframe_full:boolean;
signal mca_last,framechunk_valid_int:boolean;
signal eventchunk_ready_reg,eventchunk_ready_reg1:boolean;
signal eventchunk_ready_out,eventchunk_valid_reg,eventchunk_valid_reg1:boolean;
signal framechunk_int:std_logic_vector(CHUNK_BITS-1 downto 0);
signal eventchunk_reg,eventchunk_reg1:std_logic_vector(CHUNK_BITS-1 downto 0);
signal eventchunk_last_reg:boolean;
signal eventchunk_first_reg,eventchunk_first,eventchunk_first_reg1:boolean;
signal end_eventframe:boolean;
signal event_length:unsigned(EVENT_LENGTH_BITS-1 downto 0);
signal chunk_last:boolean;
signal chunk_we:boolean;
signal mcaframe_full:boolean;
signal eventframe_last:boolean;
signal mcaframe_last:boolean;
signal lasts:std_logic_vector(0 downto 0);
signal we:boolean_vector(0 downto 0);
signal frame_length:unsigned(MTU_BITS-1 downto 0);
begin
--------------------------------------------------------------------------------
-- Testing
--------------------------------------------------------------------------------
LEDs <= (others => '0');
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
mcachunk_ready <= mcachunk_ready_int;
framechunk <= framechunk_int;
framechunk_valid <= framechunk_valid_int;
eventchunk_ready <= eventchunk_ready_out;
--------------------------------------------------------------------------------
-- event register pipeline and length lookahead
--------------------------------------------------------------------------------
eventLength:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    eventchunk_first <= TRUE;
    eventframe_sent <= FALSE;
  else
    eventframe_sent <= arbiter_state=EVENT and commit;
    if eventchunk_valid and eventchunk_ready_out then
      eventchunk_first  <= eventchunk(CHUNK_LASTBIT)='1'; 
    end if;
    if eventchunk_first and eventchunk_valid then
      event_length <= unsigned(
        eventchunk(CHUNK_DATABITS-1 downto CHUNK_DATABITS-EVENT_LENGTH_BITS)
      );
    end if;
  end if;
end if;
end process eventLength; 
--
eventReg1:entity streamlib.register_slice
generic map(STREAM_BITS => CHUNK_BITS)
port map(
  clk => clk,
  reset => reset,
  stream_in => eventchunk,
  ready_out => eventchunk_ready_out,
  valid_in => eventchunk_valid,
  last_in => eventchunk_first,
  stream => eventchunk_reg1,
  ready => eventchunk_ready_reg1,
  valid => eventchunk_valid_reg1,
  last => eventchunk_first_reg1
);
--
eventReg2:entity streamlib.register_slice
generic map(STREAM_BITS => CHUNK_BITS)
port map(
  clk => clk,
  reset => reset,
  stream_in => eventchunk_reg1,
  ready_out => eventchunk_ready_reg1,
  valid_in => eventchunk_valid_reg1,
  last_in => eventchunk_first_reg1,
  stream => eventchunk_reg,
  ready => eventchunk_ready_reg,
  valid => eventchunk_valid_reg,
  last => eventchunk_first_reg
);
eventchunk_last_reg <= eventchunk_reg(CHUNK_LASTBIT)='1' 
                        and eventchunk_valid_reg;
--------------------------------------------------------------------------------
-- RAM frame to stream interface
--------------------------------------------------------------------------------
we(0) <= chunk_we;
lasts(0) <= to_std_logic(chunk_last);
--
framer:entity streamlib.framer(serialiser)
generic map(
	BUS_CHUNKS => 1,
	ADDRESS_BITS => MTU_BITS
)
port map(
	clk => clk,
  reset => reset,
  data => chunk,
  address => address,
  lasts => lasts,
  keeps => "1",
  chunk_we => we, 
  wr_valid => open,
  length => frame_length,
  commit => commit,
  free => framer_free,
  stream => framechunk_int,
  valid => framechunk_valid_int,
  ready => framechunk_ready
);
--
commitMUX:process(frame_under,frame_state,chunk_we)
begin 
if frame_state=FRAMELENGTH or frame_state=PAD then
  commit <= not frame_under and chunk_we;
else
  commit <= FALSE;
end if;
end process commitMUX;
--------------------------------------------------------------------------------
-- frame FSM
--------------------------------------------------------------------------------
--frame_under <= payload_address < MIN_FRAME_LENGTH;
end_eventframe <= (eventchunk_first_reg or eventchunk_last_reg) 
                  and (eventbuffer_empty or eventframe_full)
                  and not eventchunk_valid_reg;
--TODO:register fulls
--eventframe_full <= frame_free < signed('0' & event_length);
--mcaframe_full <= frame_free < 2;
eventframe_last <= eventchunk_last_reg 
                   and (eventframe_full or eventbuffer_empty);
mca_last <= mcachunk(CHUNK_LASTBIT)='1' and mcachunk_valid;
mcaframe_last <= (address(0)='1' 
                  and (mcaframe_full or (flush_events and not frame_under))) 
                  or mca_last;
--
frameFSM:process(clk)
variable inc_payload_address,inc_mca_sequence,inc_event_sequence:boolean;
variable next_address:unsigned(MTU_BITS-1 downto 0)
                     :=to_unsigned(HEADER_LENGTH,MTU_BITS);
begin
if rising_edge(clk) then
  if reset='1' then
    sequence <= (others => '0');
    event_sequence <= (others => '0');
    mca_sequence <= (others => '0');
    payload_address <= to_unsigned(HEADER_LENGTH,MTU_BITS);
    next_address:=to_unsigned(HEADER_LENGTH+1,MTU_BITS);
    header_address <= (others => '0');
  else
    frame_free <= signed('0' & MTU)-signed('0' & next_address);
    eventframe_full <= to_0IfX(frame_free) 
      <= signed('0' & to_0IfX(event_length));
    mcaframe_full <= frame_free <= 2;
    inc_payload_address:=FALSE;
    inc_mca_sequence:=FALSE;
    inc_event_sequence:=FALSE;
    if eventchunk_valid_reg and eventchunk_ready_reg then
      last_chunk <= eventchunk_reg(CHUNK_DATABITS-1 downto 0);
      last_address <= address;
    end if;
    case frame_state is 
    when IDLE =>
      if arbiter_state/=IDLE and not framer_full then
        frame_state <= DEST1;
        header_chunk <= x"DA01";
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when DEST1 =>
      if not framer_full then
        frame_state <= DEST2;
        header_chunk <= x"0203";
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when DEST2 =>
      if not framer_full then
        frame_state <= DEST3;
        header_chunk <= x"0405";
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when DEST3 =>
      if not framer_full then
        frame_state <= SRC1;
        header_chunk <= x"5A01";
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when SRC1 =>
      if not framer_full then
        frame_state <= SRC2;
        header_chunk <= x"0203";
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when SRC2 =>
      if not framer_full then
        frame_state <= SRC3;
        header_chunk <= x"0405";
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when SRC3 =>
      if not framer_full then
        frame_state <= ETHERTYPE;
        address <= header_address;
        header_address <= header_address+1;
        if arbiter_state=EVENT then
          header_chunk <= x"88B5";
        else
          header_chunk <= x"88B6";
        end if;
      end if;
    when ETHERTYPE =>
      if not framer_full then
        frame_state <= SEQ;
        header_chunk <= SetEndianness(sequence,ENDIANNESS);
        sequence <= sequence+1;
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when SEQ =>
      if not framer_full then
        frame_state <= FRAMENUM;
        address <= header_address;
        header_address <= header_address+1;
        if arbiter_state=EVENT then
          header_chunk <= SetEndianness(event_sequence,ENDIANNESS);
          inc_event_sequence := TRUE;
        else
          header_chunk <= SetEndianness(mca_sequence,ENDIANNESS);
          inc_mca_sequence := TRUE;
        end if;
      end if;
    when FRAMENUM =>
      if not framer_full then
        header_chunk <= (others => '0');
        frame_state <= RESERVED1;
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when RESERVED1 =>       -- address 10 
      if not framer_full then
        header_chunk <= (others => '0');
        frame_state <= RESERVED2;
        address <= header_address;
        header_address <= header_address+1;
      end if;
    when RESERVED2 =>       --LSB used to signal a terminal frame
      if not framer_full then
        frame_state <= PAYLOAD;
        header_address <= (others => '0');
        address <= payload_address;
        inc_payload_address:=TRUE;
      end if;
    when PAYLOAD =>
      if frame_under then
        frame_length <= to_unsigned(MIN_FRAME_LENGTH,MTU_BITS);
      else
        frame_length <= payload_address;
      end if;
      if not framer_full then
        if arbiter_state=EVENT then
          if eventframe_full and eventchunk_first_reg then
            frame_state <= LASTPAYLOAD;
            header_chunk <= last_chunk;
            address <= last_address;
          elsif eventframe_last then
            frame_state <= FRAMELENGTH;
            header_chunk 
              <= SetEndianness(resize(payload_address,CHUNK_DATABITS),ENDIANNESS);
            address <= to_unsigned(11,MTU_BITS);
          else
            if eventchunk_valid_reg then
              address <= payload_address;
              inc_payload_address:=TRUE;
            end if;
          end if;
        else
          if mca_last then
            frame_state <= MCATERMINATE;
            header_chunk <= x"0001";
            address <= to_unsigned(10,MTU_BITS);
            mca_sequence <= (others => '0');
          elsif mcaframe_last then
            frame_state <= FRAMELENGTH;
            header_chunk 
              <= SetEndianness(resize(payload_address,CHUNK_DATABITS),ENDIANNESS);
            address <= to_unsigned(11,MTU_BITS);
          else
            address <= payload_address;
            inc_payload_address:=TRUE;
          end if;
        end if;
      end if;
    when LASTPAYLOAD  => 
      frame_state <= FRAMELENGTH;
      header_chunk 
        <= SetEndianness(resize(last_address+1,CHUNK_DATABITS),ENDIANNESS);
      frame_length <= last_address+1;
      address <= to_unsigned(11,MTU_BITS);
    when MCATERMINATE => 
      frame_state <= FRAMELENGTH;
      header_chunk 
        <= SetEndianness(resize(payload_address,CHUNK_DATABITS),ENDIANNESS);
      address <= to_unsigned(11,MTU_BITS);
    when FRAMELENGTH =>
      if frame_under then
        frame_state <= PAD;
        header_chunk <= (others => '-');
        address <= payload_address;
        inc_payload_address:=TRUE;
      else
        frame_state <= IDLE;
        payload_address <= to_unsigned(HEADER_LENGTH,MTU_BITS);
        next_address:=to_unsigned(HEADER_LENGTH+1,MTU_BITS);
      end if;
    when PAD =>
      if not framer_full then 
        header_chunk <= (others => '-');
        if not frame_under then
          frame_state <= IDLE;
          payload_address <= to_unsigned(HEADER_LENGTH,MTU_BITS);
          next_address:=to_unsigned(HEADER_LENGTH+1,MTU_BITS);
        else
          address <= payload_address;
          inc_payload_address:=TRUE;
        end if;
      end if;
    end case;
    framer_full <= framer_free <= next_address;
    if inc_payload_address and chunk_we then
      frame_under <= next_address < MIN_FRAME_LENGTH;
      payload_address <= next_address;
      next_address:=next_address+1;
    end if;  
    if mca_last then
      mca_sequence <= (others => '0');
    elsif inc_mca_sequence then
      mca_sequence <= mca_sequence+1;
    end if;
    if inc_event_sequence then
      event_sequence <= event_sequence+1;
    end if;
  end if;
end if;
end process frameFSM;
--
streamMux:process(frame_state,arbiter_state,eventchunk_reg,mcachunk, 
                  header_chunk,framer_full,eventframe_last,mcaframe_last,
                  frame_under,eventchunk_valid_reg,mcachunk_valid,
                  eventchunk_first_reg,eventframe_full)
begin
  eventchunk_ready_reg <= FALSE;
  mcachunk_ready_int <= FALSE;
  chunk_we <= FALSE;
  chunk_last <= FALSE;
  chunk <= (others => '-');
  if frame_state=PAYLOAD then
    if arbiter_state=EVENT then
      chunk <= eventchunk_reg(CHUNK_DATABITS-1 downto 0);
      eventchunk_ready_reg <= not framer_full and 
                              not (eventframe_full and eventchunk_first_reg);
      chunk_last <= eventframe_last and not frame_under;
      chunk_we <= not framer_full and eventchunk_valid_reg;
    else
      chunk <= mcachunk(CHUNK_DATABITS-1 downto 0);
      mcachunk_ready_int <= not framer_full;
      chunk_last <= mcaframe_last and not frame_under; 
      chunk_we <= not framer_full and mcachunk_valid;
    end if;
  elsif frame_state=PAD then
    chunk_last <= not frame_under;
    chunk_we <= not framer_full;
  elsif frame_state=MCATERMINATE or frame_state=FRAMELENGTH then
    chunk_we <= TRUE;
    chunk <= header_chunk;
  elsif frame_state=LASTPAYLOAD then
    chunk_we <= TRUE;
    chunk <= header_chunk;
    chunk_last <= not frame_under;
  elsif frame_state/=IDLE then
    chunk <= header_chunk;
    chunk_we <= not framer_full;
  end if;
end process streamMux;
--------------------------------------------------------------------------------
-- Arbiter FSM
--------------------------------------------------------------------------------
arbiterNextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    arbiter_state <= IDLE;
  else
    arbiter_state <= arbiter_nextstate;
  end if;
end if;
end process arbiterNextstate;
--
arbitorTransition:process(arbiter_state,mcachunk_valid,
                          flush_events,eventbuffer_empty,commit)
begin
  arbiter_nextstate <= arbiter_state;
  case arbiter_state is 
  when IDLE =>
    if flush_events and not eventbuffer_empty then
      arbiter_nextstate <= EVENT;
    elsif mcachunk_valid then
      arbiter_nextstate <= MCA;
    end if;
  when EVENT | MCA => 
    if commit then
      if flush_events and not eventbuffer_empty then
        arbiter_nextstate <= EVENT;
      elsif mcachunk_valid then
        arbiter_nextstate <= MCA;
      else
      	arbiter_nextstate <= IDLE;
      end if;
    end if;
  end case;
end process arbitorTransition;
--------------------------------------------------------------------------------
end frame_to_stream;
