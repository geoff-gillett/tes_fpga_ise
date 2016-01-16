--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:08/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: event_framer
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
use work.types.all;
use work.functions.all;
use work.events.all;
--use streamlib.all;
--
entity event_capture is
generic(
  CHANNEL:integer:=1;
  PEAK_COUNT_BITS:integer:=4;
  ADDRESS_BITS:integer:=9;
  BUS_CHUNKS:integer:=4;
  ENDIANNESS:string:="LITTLE"
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  height_format:in height_form;
  rel_to_min:in boolean;
  --
  use_cfd_timing:in boolean;
  --area_threshold:in area_t;
  --
  signal_in:in signal_t;
  peak:in boolean;
  peak_start:in boolean;
  -- framer overflow
  overflow:out boolean;
  --! buffer overflow signal
  pulse_pos_xing:in boolean; -- from measurement
  pulse_neg_xing:in boolean;
  cfd_low:in boolean;
  cfd_high:in boolean;
  cfd_error:in boolean;
  
  --minima:in signal_t;
  slope_area:in area_t;
  --pulse_area:in area_t;
  --! to mux
  enqueue:out boolean;
  dump:out boolean;
  commit:out boolean;
  peak_count:out unsigned(MAX_PEAK_COUNT_BITS-1 downto 0);
  height:out signal_t;
  --
  eventstream:out eventbus_t;
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity event_capture;

--
-- only records peaks as 8 byte event;
architecture peak_only of event_capture is
--
constant DATA_BITS:integer:=BUS_CHUNKS*CHUNK_DATABITS;
--constant PEAK_COUNT_BITS:integer:=bits(MAX_PEAKS);
--
signal data:std_logic_vector(DATA_BITS-1 downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
signal chunk_wr_en:boolean_vector(EVENTBUS_CHUNKS-1 downto 0);
signal commit_int,dump_int:boolean;
signal peak_count_int:unsigned(PEAK_COUNT_BITS downto 0); 
signal eventstream_int:std_logic_vector(EVENTBUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal valid_int,ready_int,last_int:boolean;

type FSMstate is (IDLE,STARTED,QUEUED);
signal state,nextstate:FSMstate;
signal start_signal:signal_t;
signal header:event_header;
signal above_threshold:boolean;
signal enqueue_int:boolean;
signal max:boolean;
--
begin
--------------------------------------------------------------------------------
-- Buffers event frames and prepares stream 
--------------------------------------------------------------------------------
framer:entity work.framer
generic map(
  BUS_CHUNKS => EVENTBUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => to_unsigned(0,ADDRESS_BITS),
  lasts => "0001", 
  keeps => "1111",
  chunk_we => chunk_wr_en,
  free => free,
  length => to_unsigned(1,ADDRESS_BITS),
  commit => commit_int,
  stream => eventstream_int,
  valid => valid_int,
  ready => ready_int
);
last_int <= busLast(eventstream_int,EVENTBUS_CHUNKS);
streamreg:entity work.register_slice
generic map(STREAM_BITS => EVENTBUS_CHUNKS*CHUNK_BITS)
port map(
	clk => clk,
  reset => reset,
  stream_in => eventstream_int,
  valid_in => valid_int,
  last_in => last_int,
  ready_out => ready_int,
  stream => eventstream,
  valid => valid,
  last => last,
  ready => ready
);

--------------------------------------------------------------------------------
-- Record the event in the Frame Memory
--------------------------------------------------------------------------------

FSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			state <= IDLE;
		else
			state <= nextstate;
		end if;
	end if;
end process FSMnextstate;

enqueue_int <= state=STARTED and 
               (
                 (use_cfd_timing and cfd_low) or 
                 (not use_cfd_timing and pulse_pos_xing)
               );

maximum:process(height_format,cfd_high,peak)
begin
	case height_format is
	when PEAK_HEIGHT =>
		max <= peak;
		--height_int <= signal_in;
	when CFD_HEIGHT =>
		max <= cfd_high;
		--height_int <= signal_in;
	when SLOPE_INTEGRAL =>
		max <= peak;
		---height_int <= slope_area;
	end case;
end process maximum;

height <= header.height; 

FSMtrasition:process(state,cfd_error,enqueue_int,max,peak_start)
begin
	nextstate <= state;
	case state is 
	when IDLE =>
		if peak_start then
			nextstate <= STARTED;
		end if;
	when STARTED =>
		-- peak minima has been detected
		if cfd_error then
			nextstate <= IDLE;
		elsif enqueue_int then
			nextstate <= QUEUED;
		elsif max then
			nextstate <= IDLE;
		end if;
	when QUEUED =>
		if cfd_error or max then
			nextstate <= IDLE;
		end if;
	end case;
end process FSMtrasition;

data <= to_std_logic(header);

--dump_int <= state=QUEUED and 
--            (cfd_error or (max and not above_threshold)); 
--commit_int <= state=QUEUED and not cfd_error and 
--							(max and above_threshold);

commit <= commit_int;
dump <= dump_int;
							
captureProcess:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	peak_count_int <= (others => '0');
  	above_threshold <= FALSE;
 		header.flags.channel <= to_unsigned(CHANNEL,MAX_CHANNEL_BITS);
 		header.timestamp <= (others => '0');
  	enqueue <= FALSE;
  else
  	
  	if peak_start then
  		header.flags.peak_overflow <= FALSE;
  		header.flags.multipeak <= FALSE;
  		start_signal <= signal_in;
  		header.size <= to_unsigned(8,SIZE_BITS);
	  	peak_count_int <= (others => '0');
  	end if;
  	
  	if pulse_pos_xing then
  		above_threshold <= TRUE;
  		header.flags.peak_count <= (others => '0');
  	end if;
  	
  	if pulse_neg_xing then
  		above_threshold <= FALSE;
  	end if;
  	
  	enqueue <= enqueue_int;
  	
  	if max then
  		header.flags.peak_count <= header.flags.peak_count+1;
  		header.flags.multipeak <= TRUE;
  		case height_format is 
  		when PEAK_HEIGHT | CFD_HEIGHT =>
        if rel_to_min then
          header.height <= signal_in-start_signal;
        else
        	header.height <= signal_in;
        end if;
  		when SLOPE_INTEGRAL =>
  			header.height <= slope_area;
  		end case;	
  	end if;
  	
    overflow <= FALSE;
    chunk_wr_en <= (others => FALSE);
    dump_int <= FALSE;
    commit_int <= FALSE;
  	if state=QUEUED then
  		if above_threshold then
  			if cfd_error then
  				dump_int <= TRUE;
  			else
  				if max then
  					commit_int <= TRUE;
  					peak_count <= header.flags.peak_count;
  					if free=0 then
  						overflow <= TRUE;
						else
							chunk_wr_en <= (others => TRUE);
  					end if;
  				end if;
  			end if;
  		else
  			dump_int <= TRUE;
  		end if;
  	end if;
  end if;
end if;
end process captureProcess;

end architecture peak_only;
