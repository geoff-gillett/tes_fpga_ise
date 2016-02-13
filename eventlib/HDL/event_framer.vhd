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

library teslib;
use teslib.types.all;
use teslib.functions.all;

library streamlib;
use streamlib.stream.all;

use work.events.all;
--
-- FIXME use measurement and register types.
entity event_framer is
generic(
  CHANNEL:integer:=1;
  PEAK_COUNT_BITS:integer:=PEAK_COUNT_WIDTH;
  ADDRESS_BITS:integer:=9;
  BUS_CHUNKS:integer:=4;
  RELATIVETIME_BITS:integer:=16
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --
  height_form:in height_t;
  rel_to_min:in boolean;
  trigger:in trigger_t;
  area_threshold:in area_t;
  --
  signal_in:in signal_t;
  
  peak:in boolean;
  peak_start:in boolean;
  -- framer overflow
  overflow:out boolean;
  --! buffer overflow signal
  pulse_pos_xing:in boolean; -- from measurement
  pulse_neg_xing:in boolean;
  slope_threshold_xing:in boolean;
  cfd_low:in boolean;
  cfd_high:in boolean;
  cfd_error:in boolean;
  --minima:in signal_t;
  slope_area:in area_t;
  pulse_area:in area_t;
  --! to mux
  enqueue:out boolean;
  rise_time:out unsigned(RELATIVETIME_BITS-1 downto 0);
  dump:out boolean;
  commit:out boolean;
  peak_count:out unsigned(PEAK_COUNT_BITS-1 downto 0);
  height:out signal_t;
  --
  eventstream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity event_framer;

--
-- only records peaks as 8 byte event;
architecture peak_only of event_framer is
--
signal data:streambus_t;
signal free:unsigned(ADDRESS_BITS downto 0);
signal chunk_wr_en:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_int,dump_int:boolean;
signal peak_count_int:unsigned(PEAK_COUNT_BITS-1 downto 0); 

type FSMstate is (IDLE,STARTED,QUEUED);
signal state,nextstate:FSMstate;
signal start_signal:signal_t;
signal above_threshold:boolean;
signal enqueue_int:boolean;
signal max:boolean;
signal rise_time_int:unsigned(RELATIVETIME_BITS-1 downto 0);
--
signal peak_event:peakevent_t;
signal event_flags:eventflags_t;
signal tick_flags:tickflags_t;
signal height_form_reg:height_t;
signal trigger_reg:trigger_t;
signal rel_to_min_reg:boolean;
signal tick_lost_reg:boolean;
--

--
begin
event_flags.typeflags.tick <= FALSE;
event_flags.typeflags.area <= FALSE;
event_flags.typeflags.trace <= FALSE;
event_flags.typeflags.fixed <= TRUE;
event_flags.channel <= to_unsigned(CHANNEL,CHANNEL_WIDTH);
event_flags.height <= height_form_reg;
event_flags.trigger <= trigger_reg;
event_flags.rel_to_min <= rel_to_min_reg;
--
tick_flags.typeflags.tick <= TRUE;
tick_flags.typeflags.area <= FALSE;
tick_flags.typeflags.trace <= FALSE;
tick_flags.typeflags.fixed <= TRUE;
tick_flags.tick_lost <= tick_lost_reg;


--------------------------------------------------------------------------------
-- Buffers event frames and prepares stream 
--------------------------------------------------------------------------------
framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => BUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => to_unsigned(0,ADDRESS_BITS),
  chunk_we => chunk_wr_en,
  free => free,
  length => to_unsigned(1,ADDRESS_BITS),
  commit => commit_int,
  stream => eventstream,
  valid => valid,
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

timingPoint:process(trigger,state, pulse_pos_xing, slope_threshold_xing,
										cfd_low)
begin
	if state=STARTED then
		case trigger is
		when PULSE_THRESHOLD =>
			enqueue_int <= pulse_pos_xing;
		when SLOPE_THRESHOLD =>
			enqueue_int <= slope_threshold_xing;
		when CFD =>
			enqueue_int <= cfd_low;
		end case;
	end if;
end process timingPoint;


maximum:process(height_form,cfd_high,peak)
begin
	case height_form is
	when PEAK_HEIGHT =>
		max <= peak;
	when CFD_HEIGHT =>
		max <= cfd_high;
	when SLOPE_INTEGRAL =>
		max <= peak;
	end case;
end process maximum;

height <= peak_event.height; 

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

data <= to_streambus(peak_event);

--dump_int <= state=QUEUED and 
--            (cfd_error or (max and not above_threshold)); 
--commit_int <= state=QUEUED and not cfd_error and 
--							(max and above_threshold);

commit <= commit_int;
dump <= dump_int;
rise_time <= rise_time_int;
							
peak_event.reltimestamp <= (others => '0');
peak_event.flags.channel <= to_unsigned(CHANNEL,CHANNEL_WIDTH);
--peak_event.size <= to_unsigned(8,SIZE_BITS);

captureProcess:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	above_threshold <= FALSE;
  	enqueue <= FALSE;
  else
  	
  	if peak_start then
  		--peak_event.flags.peak_overflow <= FALSE;
  		start_signal <= signal_in;
	  	peak_event.flags.rel_to_min <= rel_to_min;
	  	peak_event.flags.height <= height_form;
  	end if;
  	
  	if pulse_pos_xing then -- pulse_start
	  	peak_count_int <= (others => '0');
  		above_threshold <= TRUE;
  		peak_event.flags.peak_count <= (others => '0');
  	end if;
  	
  	if pulse_neg_xing then
  		above_threshold <= FALSE;
  	end if;
  	
  	enqueue <= enqueue_int;
  	
  	if enqueue_int then
  		rise_time_int <= (others => '0');
  	else
  		rise_time_int <= rise_time_int+1;
  	end if;
  	
  	if max then
  		if peak_count_int=to_unsigned((2**PEAK_COUNT_BITS)-1,PEAK_COUNT_BITS) then
  			--peak_event.flags.peak_overflow <= TRUE;
  		else
  			peak_count_int <= peak_count_int+1;
  			--peak_event.flags.peak_overflow <= FALSE;
  		end if;
  		peak_event.flags.peak_count <= peak_count_int;
  		case height_form is 
  		when PEAK_HEIGHT | CFD_HEIGHT =>
        if peak_event.flags.rel_to_min then
          peak_event.height <= signal_in-start_signal;
        else
        	peak_event.height <= signal_in;
        end if;
  		when SLOPE_INTEGRAL =>
  			peak_event.height <= resize(slope_area,SIGNAL_BITS);
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
  					peak_count <= peak_event.flags.peak_count;
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