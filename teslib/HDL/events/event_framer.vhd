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

library extensions;
use extensions.boolean_vector.all;

library streamlib;
use streamlib.types.all;

use work.registers.all;
use work.events.all;
use work.types.all;
use work.measurements.all;

entity event_framer is
generic(
  CHANNEL:integer:=1;
  ADDRESS_BITS:integer:=9
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  registers:in capture_registers_t;
  measurements:in measurement_t;
  
  cfd_error:in boolean;
  overflow:out boolean;

  dump:out boolean;
  commit:out boolean;
  
  eventstream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity event_framer;

--
-- only records peaks as 8 byte event;
architecture RTL of event_framer is
--
signal data:streambus_t;
signal frame_free:unsigned(ADDRESS_BITS downto 0);
signal chunk_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_int,dump_int:boolean;

type FSMstate is (IDLE,STARTED,QUEUED);
signal state,nextstate:FSMstate;
--
signal peak_event:peakevent_t;
signal area_event:areaevent_t;
--
signal event_flags:eventflags_t;
signal event_type_reg:event_type_d;
--type peakFSMstate is (IDLE,STARTED,QUEUED);
--signal state,nextstate:peakFSMstate;
signal frame_length:unsigned(ADDRESS_BITS-1 downto 0);
signal framer_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_reg:boolean;
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal dump_reg:boolean;
signal overflow_int:boolean;

begin
commit <= commit_reg;
dump <= dump_reg;

event_flags.channel <= to_unsigned(CHANNEL,CHANNEL_WIDTH);
flagreg:process(clk)
begin
	if rising_edge(clk) then
		if measurements.peak_start then
			--FIXME do this in signal_processor
			event_type_reg <= registers.event_type; 
			case registers.event_type is
			when PEAK_EVENT_D =>
				event_flags.type_flags.tick <= FALSE;
				event_flags.type_flags.trace <= FALSE;
				event_flags.type_flags.fixed <= TRUE;
				event_flags.type_flags.area <= FALSE;
			when AREA_EVENT_D =>
				null;
			when PULSE_EVENT_D =>
				null;
			when TRACE_EVENT_D =>
				null;
			end case;		
		end if;
	end if;
end process flagreg;

event_flags.peak_count <= measurements.peak_count;
peak_event.flags <= event_flags;
peak_event.reltimestamp <= (others => '0');
peak_event.height <= measurements.height;
peak_event.rise_time <= measurements.pulse_time;
area_event.flags <= event_flags;
area_event.reltimestamp <= (others => '0');
area_event.area <= measurements.filtered.area;

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
	
FSMtransition:process(state,measurements.peak_start,
											measurements.trigger,cfd_error,commit_int, dump_int)
begin
nextstate <= state;
	case state is 
	when IDLE =>
		if measurements.trigger then
			nextstate <= QUEUED;
		elsif measurements.peak_start then
			nextstate <= STARTED;
		end if; 
	when STARTED =>
		if cfd_error then
			nextstate <= IDLE;
		elsif measurements.trigger then
			nextstate <= QUEUED;
		end if; 
	when QUEUED =>
		if commit_int or dump_int then
			nextstate <= IDLE;
		end if;
	end case;
end process FSMtransition;

frameControl:process(event_type_reg,frame_free,measurements.height_valid,state,
										 measurements.filtered.zero_xing)
begin
	commit_int <= FALSE;
	dump_int <= FALSE;
	overflow_int <= TRUE;
  chunk_we <= (others => FALSE);
  case event_type_reg is
  when PEAK_EVENT_D =>
  	--frame_address <= (others => '0');
  	if state=QUEUED then 
  		if measurements.height_valid then
  			if frame_free/=0 then 
  				commit_int <= TRUE;
  				chunk_we <= (others => TRUE);
  			else
  				dump_int <= TRUE;
  				overflow_int <= TRUE;
  			end if;
  		end if;
  	end if;
  when AREA_EVENT_D =>
  	--frame_address <= (others => '0');
  	if state=QUEUED then 
  		if measurements.filtered.zero_xing then
  			if frame_free/=0 then 
  				commit_int <= TRUE;
  				chunk_we <= (others => TRUE);
  			else
  				dump_int <= TRUE;
  				overflow_int <= TRUE;
  			end if;
  		end if;
  	end if;
    null;
  when PULSE_EVENT_D =>
    null;
  when TRACE_EVENT_D =>
    null;
  end case;		
end process frameControl;

frameControlReg:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			commit_reg <= FALSE;
			dump_reg <= FALSE;
			framer_we <= (others => FALSE);
		else
			overflow <= overflow_int;
			commit_reg <= commit_int;
			dump_reg <= dump_int;
			framer_we <= chunk_we;
			
      case event_type_reg is
      when PEAK_EVENT_D =>
      	data <= to_streambus(peak_event);
      	address <= (others => '0');
			  frame_length <= to_unsigned(1,ADDRESS_BITS);
      	
      when AREA_EVENT_D =>
      	data <= to_streambus(area_event);
      	address <= (others => '0');
			  frame_length <= to_unsigned(1,ADDRESS_BITS);
			  
      when PULSE_EVENT_D =>
        null;
      when TRACE_EVENT_D =>
        null;
      end case;		
			
		end if;
	end if;
end process frameControlReg;

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
  address => address,
  chunk_we => framer_we,
  free => frame_free,
  length => frame_length,
  commit => commit_reg,
  stream => eventstream,
  valid => valid,
  ready => ready
);

end architecture RTL;
