
architecture aligned of event_mux is
constant TIME_BITS:integer:=16;

constant CHANNELS:integer:=2**CHANNEL_BITS;
constant STREAM_BITS:integer:=EVENTSTREAM_CHUNKS*CHUNK_BITS;
--
signal timestamp:unsigned(TIMESTAMP_BITS-1 downto 0);
signal eventtime,last_eventtime,time_dif:unsigned(TIMESTAMP_BITS-1 downto 0);
signal relative_time:unsigned(TIME_BITS-1 downto 0);
--
--attribute keep:string;
type muxFSMstate is (WAITING,HEAD,TAIL);
--TODO rename to event_state
signal mux_state,mux_nextstate:muxFSMstate;
--attribute keep of mux_state:signal is "TRUE";
--
type FSMstate is (IDLE,HANDLETICK,HANDLEPULSE);
signal state,nextstate:FSMstate;
--attribute keep of state:signal is "TRUE";
type timeFSMstate is (INVALID,ISVALID);
signal time_state,time_nextstate:timeFSMstate;
--
signal grant,current_grant,next_grant:std_logic_vector(CHANNELS-1 downto 0);
signal index,next_index,current_index:integer range 0 to CHANNELS-1;
signal eventstream_last,eventstream_valid,ready_for_eventstream:boolean;
signal pulse_done,tick,granted,next_granted:boolean;
signal current_granted:boolean;
signal eventstream_int,tickstream,muxstream,pulsestream:eventbus_t;
signal tickstream_valid,tickstream_last,ready_for_tickstream,ticked:boolean;
signal muxstream_valid,muxstream_last,time_done:boolean;
signal pulse_handshake:boolean;
signal ready_for_pulsestream,pulsestream_valid:boolean;
signal pulsestream_last,ready_for_muxstream:boolean;
signal done:boolean;
signal started:std_logic_vector(CHANNELS-1 downto 0);
signal commited:std_logic_vector(CHANNELS-1 downto 0);
signal dumped:std_logic_vector(CHANNELS-1 downto 0);
signal request,next_request:std_logic_vector(CHANNELS-1 downto 0);
signal handled:std_logic_vector(CHANNELS-1 downto 0);
signal time_valid:boolean;
signal tickstream_handshake:boolean;
signal rel_timestamp:std_logic_vector(TIME_BITS-1 downto 0);
signal read_next_event:boolean;
signal relative_time_valid:boolean;
signal muxstream_handshake:boolean;
signal all_dumped:boolean;
signal no_starts:boolean;
signal time_rd_en1:boolean;
signal time_was_valid,new_time_valid,new_relativetime:boolean;
signal pulsestream_end:boolean;
signal muxstream_end:boolean;
signal tickstream_done:boolean;
signal tick_handled:boolean;
signal has_pulses:boolean;
signal dumped_only:boolean;
signal muxstream_done:boolean;
signal all_handled:boolean;
signal muxstream_complete:boolean;
--
begin
--
FSMnextstate:process(clk)
begin
if rising_edge(clk) then
  if reset2 = '1' then
    time_state <= INVALID;
    mux_state <= WAITING;
    state <= IDLE;
  else
    time_state <= time_nextstate;
    mux_state <= mux_nextstate;
    state <= nextstate;
  end if;
end if;
end process FSMnextstate;
--------------------------------------------------------------------------------
-- Time stamping
--------------------------------------------------------------------------------
tickUnit:entity work.tick_unit(aligned)
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  TICK_BITS => TICK_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  MINIMUM_TICK_PERIOD => MINIMUM_TICK_PERIOD,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => clk,
  reset => reset1,
  tick => tick,
  timestamp => timestamp,
  tick_period => tick_period,
  events_lost => events_lost,
  dirty => dirty,
  tickstream => tickstream,
  valid => tickstream_valid,
  last => tickstream_last,
  ready => ready_for_tickstream
);
tickstream_handshake <= tickstream_valid and ready_for_tickstream;
tickstream_done <= tickstream_handshake and tickstream_last;
--
reltimestamp:process(clk)
begin
if rising_edge(clk) then
  if reset2 = '1' then
    last_eventtime <= (others => '0');
    tick_handled <= FALSE;
  else
    time_was_valid <= time_valid;
    new_time_valid <= time_valid and not time_was_valid;
    new_relativetime <= new_time_valid or (time_rd_en1 and time_valid);
    time_rd_en1 <= read_next_event;
    if read_next_event then
      tick_handled <= FALSE;
    elsif tickstream_done then
      tick_handled <= TRUE;
    end if;
    if read_next_event and (not all_dumped or ticked) then
      last_eventtime <= eventtime;
    end if;
    time_dif <= eventtime-last_eventtime;
    if unaryOR(time_dif(TIMESTAMP_BITS-1 downto TIME_BITS)) then
      relative_time <= (others => '1');
    else
      relative_time <= time_dif(TIME_BITS-1 downto 0);
    end if;
  end if;
end if;
end process reltimestamp;
--
timeFSMtransition:process(time_state,new_relativetime,dumped_only,all_handled)
begin
  time_nextstate <= time_state;
  case time_state is 
  when INVALID => --FIXME ?? this is crap
    if (new_relativetime and not dumped_only) then 
      time_nextstate <= ISVALID;
    end if;
  when ISVALID =>
    if all_handled then
      time_nextstate <= INVALID;
    end if;
  end case;
end process timeFSMtransition;
--
dumped_only <= read_next_event and all_dumped and not ticked; --FIXME??
rel_timestamp <= SetEndianness(resize(relative_time,16), ENDIANNESS)
                 when time_state=ISVALID else (others => '0'); 
relative_time_valid <= time_state=ISVALID;
--
timeRdEn:process(clk)
begin
if rising_edge(clk) then
  if reset2 = '1' then
    read_next_event <= FALSE;
  else
    case state is 
    when IDLE =>
      read_next_event <= all_dumped and not read_next_event and not ticked;
    when HANDLETICK =>
      read_next_event <= (no_starts or all_dumped) and tickstream_done;
    when HANDLEPULSE => 
      read_next_event <= time_done and not read_next_event 
                    and (muxstream_done or all_handled);
    end case;
  end if;
end if;
end process timeRdEn;
--------------------------------------------------------------------------------
-- stream arbitration and dump filtering
--------------------------------------------------------------------------------
buffers:entity work.event_arbiter_buffers
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS
)
port map(
  clk => clk,
  reset => reset2,
  start => start,
  commit => commit,
  dump => dump,
  tick => tick,
  timestamp => timestamp,
  eventtime => eventtime,
  started => started,
  ticked => ticked,
  time_valid => time_valid,
  commited => commited,
  dumped => dumped,
  read => read_next_event,--next_time,
  full => full
);
--
time_done <= started=handled and time_valid;
all_handled <= started=handled and not (ticked xor tick_handled);
all_dumped <= started=(dumped and started) and not no_starts;
no_starts <= unsigned(started)=0;
--TODO this arbiter can have problems if instream goes invalid without reading 
--check if this is against AXI spec
request <= started and commited and to_std_logic(instream_valid) and 
           not handled;
next_request <= started and commited and to_std_logic(instream_valid) and 
                not handled and not current_grant;
--new
arbiter:process (clk)
variable next_gnt,gnt:std_logic_vector(CHANNELS-1 downto 0);
begin
if rising_edge(clk) then
  if reset2 = '1' then
    next_grant <= (others => '0');
    grant <= (others => '0');
    current_grant <= (others => '0');
    handled <= (others => '0');
  else
    gnt:=request and std_logic_vector(unsigned(not request)+1);
    grant <= gnt;
    index <= onehotToInteger(gnt);
    granted <= unaryOR(gnt);
    next_gnt := next_request and std_logic_vector(unsigned(not next_request)+1);
    next_grant <= next_gnt;
    next_index <= onehotToInteger(next_gnt);
    next_granted <= unaryOR(next_gnt);
    if read_next_event then
      handled <= (others => '0');
      current_grant <= (others => '0');
      current_granted <= FALSE;
      current_index <= 0;
    else
      if pulse_done or not current_granted then
        current_grant <= next_grant;
        current_granted <= next_granted;
        current_index <= next_index;
      end if;
      if pulse_done then
        handled <= handled or (dumped and started) or current_grant;
      else
        handled <= handled or (dumped and started);
      end if;
    end if;
  end if;
end if;
end process arbiter;
--
muxGen2chan:if CHANNEL_BITS=1 generate
begin
mux2chan:process(clk)
begin
	if rising_edge(clk) then
		if reset2='1' then
			pulsestream <= (others => '-');
		else
			case grant is
			when "01" =>
				pulsestream <= instream(0);
			when "10" =>
				pulsestream <= instream(1);
			when others =>
				pulsestream <= (others => '-');
			end case;
		end if;
	end if;		
end process mux2chan;
end generate muxGen2chan;

muxGen4chan:if CHANNEL_BITS=2 generate
begin
mux4chan:process(clk)
begin
	if rising_edge(clk) then
		if reset2='1' then
			pulsestream <= (others => '-');
		else
			case grant is
			when "0001" =>
				pulsestream <= instream(0);
			when "0010" =>
				pulsestream <= instream(1);
			when "0100" =>
				pulsestream <= instream(2);
			when "1000" =>
				pulsestream <= instream(3);
			when others =>
				pulsestream <= (others => '-');
			end case;
		end if;
	end if;		
end process mux4chan;
end generate muxGen4chan;

muxGen8chan:if CHANNEL_BITS=3 generate
begin
mux8chan:process(clk)
begin
	if rising_edge(clk) then
		if reset2='1' then
			pulsestream <= (others => '-');
		else
			case grant is
			when "00000001" =>
				pulsestream <= instream(0);
			when "00000010" =>
				pulsestream <= instream(1);
			when "00000100" =>
				pulsestream <= instream(2);
			when "00001000" =>
				pulsestream <= instream(3);
			when "00010000" =>
				pulsestream <= instream(4);
			when "00100000" =>
				pulsestream <= instream(5);
			when "01000000" =>
				pulsestream <= instream(6);
			when "10000000" =>
				pulsestream <= instream(7);
			when others =>
				pulsestream <= (others => '-');
			end case;
		end if;
	end if;		
end process mux8chan;
end generate muxGen8chan;


--
pulsestream <= instream(current_index) when current_granted 
               else (others => '-');
pulsestream_valid <= instream_valid(current_index) and current_granted;
pulsestream_last <= instream_last(current_index) and current_granted;
ready_for_instream <= to_boolean(current_grant) when ready_for_pulsestream 
                      else (others => FALSE);
pulsestream_end <= pulsestream_last and not next_granted; 
--
muxstreamReg:entity streamlib.streambus_register_slice
generic map(STREAM_BITS => STREAM_BITS)
port map(
  clk => clk,
  reset => reset2,
  stream_in => pulsestream,
  valid_in => pulsestream_valid,
  last_in => pulsestream_end,
  ready_out => ready_for_pulsestream,
  stream => muxstream,
  valid => muxstream_valid,
  last => muxstream_end,
  ready => ready_for_muxstream
);
--
muxstream_last <= busLast(muxstream,EVENTSTREAM_CHUNKS) and muxstream_valid;
pulse_handshake <= pulsestream_valid and ready_for_pulsestream;
pulse_done <= pulsestream_last and pulse_handshake;
muxstream_handshake <= muxstream_valid and ready_for_muxstream;
muxstream_done <= muxstream_handshake and busLast(muxstream,EVENTSTREAM_CHUNKS);
--
muxstreamstate:process(clk)
begin
if rising_edge(clk) then
  if reset2 = '1' then
    muxstream_complete <= FALSE;   
  else
    if muxstream_done then
      muxstream_complete <= TRUE;
    elsif muxstream_valid then
      muxstream_complete <= FALSE;
    end if; 
  end if;
end if;
end process muxstreamstate;
--------------------------------------------------------------------------------
-- FSM
--------------------------------------------------------------------------------
--has_pulses <= unsigned(started and (commited and not handled))/=0;
has_pulses <= unsigned(started)/=0;
FSMtransition:process(state,ticked,time_valid,read_next_event,tickstream_done,
                      has_pulses,all_dumped,tick_handled,all_handled,
                      muxstream_complete,muxstream_done)
begin
nextstate <= state;
case state is 
  when IDLE =>
    if time_valid and not read_next_event then 
      if ticked and not tick_handled then
        nextstate <= HANDLETICK; 
      elsif has_pulses and not all_dumped then
        nextstate <= HANDLEPULSE;
      end if;
    end if;
  when HANDLETICK  => 
    if tickstream_done then
      if has_pulses then
        nextstate <= HANDLEPULSE;
      else
        nextstate <= IDLE;
      end if;
    end if;
  when HANDLEPULSE =>
    if all_handled and (muxstream_done or muxstream_complete) then
      nextstate <= IDLE;
    end if;
end case;
end process FSMtransition;
--
muxFSMtransition:process(mux_state,tickstream_handshake,nextstate,
                         muxstream_handshake)
begin
mux_nextstate <= mux_state;
case mux_state is 
  when WAITING => 
    if nextstate=HANDLETICK or nextstate=HANDLEPULSE then
      mux_nextstate <= HEAD;
    end if;
  when HEAD => 
    if tickstream_handshake or muxstream_handshake then
      mux_nextstate <= TAIL;
    end if;
  when TAIL =>
--    if time_done and (muxstream_done or tickstream_done) then
    if nextstate=IDLE then
      mux_nextstate <= WAITING;
    end if;
end case;
end process muxFSMtransition;
--
muxFSMoutput:process(mux_state,muxstream,muxstream_last,muxstream_valid,
                     tickstream,tickstream_last,tickstream_valid,
                     ready_for_eventstream,rel_timestamp,state,
                     relative_time_valid) 
begin
  done <= FALSE;
  ready_for_tickstream <= FALSE;
  ready_for_muxstream <= FALSE;
  case mux_state is 
  when WAITING =>
    eventstream_int <= (others => '-');
    eventstream_last <= FALSE;
    eventstream_valid <= FALSE;
  when HEAD =>
  	--FIXME the out going buffer should be a framer, can then just rewrite the TS
    if state=HANDLEPULSE then
      --  7            6            5       
      --710|98765|432|10|987654|32|10987654|3
      -- LK|size |chn|1P|time  |LK|time    |
      -- FIXME can this be parameterised? perhaps a function
      eventstream_int <= muxstream(71 downto 52) &
        rel_timestamp & 
        muxstream(35 downto 0);
      eventstream_last <= muxstream_last;
      if relative_time_valid then
        eventstream_valid <= muxstream_valid;
        ready_for_muxstream <= ready_for_eventstream;
      else
        eventstream_valid <= FALSE;
        ready_for_muxstream <= FALSE;
      end if;
    else
      -- tick data firstword
      --     6           5         4        3
      --6|32109|87654|32109876543210|98765432|
      -- |size |xxx0D| relative time|overflow| xxx=unused D=dirty flag
      -- | tick period 32 bits               |
      eventstream_int <= tickstream(71 downto 52) &
        rel_timestamp & 
        tickstream(35 downto 0);
      eventstream_last <= tickstream_last; 
      if relative_time_valid then
        eventstream_valid <= tickstream_valid;
        ready_for_tickstream <= ready_for_eventstream;
      else
        eventstream_valid <= FALSE;
        ready_for_tickstream <= FALSE;
      end if;
    end if;
  when TAIL =>
    if state=HANDLEPULSE then
      eventstream_int <= muxstream;
      eventstream_last <= muxstream_last;
      eventstream_valid <= muxstream_valid;
      ready_for_muxstream <= ready_for_eventstream;
    else
      eventstream_int <= tickstream;
      eventstream_last <= tickstream_last; 
      eventstream_valid <= tickstream_valid;
      ready_for_tickstream <= ready_for_eventstream;
    end if;
  end case;
end process muxFSMoutput;
--
eventstreamReg:entity streamlib.streambus_register_slice
generic map(STREAM_BITS => STREAM_BITS)
port map(
  clk => clk,
  reset => reset2,
  stream_in => eventstream_int,
  valid_in => eventstream_valid,
  last_in => eventstream_last,
  ready_out => ready_for_eventstream,
  stream => eventstream,
  valid => valid,
  last => last,
  ready => ready
);
--
end architecture aligned;