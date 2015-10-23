
--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:22/10/2015 
--
-- Design Name: TES_digitiser
-- Module Name: event_framer_fixed_aligned_arch
-- Project Name: TES_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--
-- Changed to enforce memory alignment of the event packets in the receive 
-- buffer on the PC.
-- Only one peak is recorded fixing the structure size at 16 bytes.
--------------------------------------------------------------------------------

architecture fixed_aligned of event_framer is
--
constant DATA_BITS:integer:=BUS_CHUNKS*CHUNK_DATABITS;
constant TIME_BITS:integer:=16;
--
signal relative_time,rel_time:unsigned(TIME_BITS-1 downto 0);
signal data,headerdata:std_logic_vector(DATA_BITS-1 downto 0);
signal frame_addr:unsigned(ADDRESS_BITS-1 downto 0);
signal free:unsigned(ADDRESS_BITS downto 0);
signal chunk_wr_en,lasts,keeps:std_logic_vector(EVENTBUS_CHUNKS-1 downto 0);
signal commit_int,commit_reg,dump_int,local_rollover,started:boolean;
signal peak_data:std_logic_vector(2*CHUNK_DATABITS-1 downto 0);
signal peak_detected:boolean;
signal peaks_lost,overflow:boolean;
signal eventstream_int:std_logic_vector(EVENTBUS_CHUNKS*CHUNK_BITS-1 downto 0);
signal valid_int,ready_int,last_int:boolean;
signal flags:std_logic_vector(CHUNK_DATABITS-1 downto 0);
--
begin
dump <= dump_int;
commit <= commit_int;
event_lost <= overflow;
--------------------------------------------------------------------------------
-- overflow handling
--------------------------------------------------------------------------------
--startFilter:process(clk)
--begin
--if rising_edge(clk) then
--  if reset = '1' then
--    started <= FALSE;
--  else
--    pulse_start <= FALSE;
--    if start and not mux_overflow then
--      started <= TRUE;
--      pulse_start <= TRUE;
--    end if;
--    if pulse_valid then
--      started <= FALSE;
--    end if;
--  end if;
--end if;
--end process startFilter;
--------------------------------------------------------------------------------
-- Buffers event frames and prepares stream 
--------------------------------------------------------------------------------
framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => EVENTBUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => data,
  address => frame_addr,
  lasts => lasts, 
  keeps => keeps,
  chunk_we => to_boolean(chunk_wr_en),
  free => free,
  length => to_unsigned(2, ADDRESS_BITS),
  commit => commit_int,
  stream => eventstream_int,
  valid => valid_int,
  ready => ready_int
);
last_int <= busLast(eventstream_int,EVENTBUS_CHUNKS);
streamreg:entity streamlib.register_slice
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
flags	<=	"1" & to_std_logic(peaks_lost) & "0000000000" & 
					to_std_logic(CHANNEL, 4);
measure:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    data <= (others => '-');
    chunk_wr_en <= (others => '0');
    dump_int <= FALSE;
    commit_int <= FALSE;
    commit_reg <= FALSE;
    overflow <= FALSE;
  else
    dump_int <= FALSE;
    commit_int <= commit_reg;
    commit_reg <= FALSE;
    start_mux <= FALSE;
    overflow <= FALSE;
    if start then
      if mux_full then
        overflow <= TRUE;
      elsif enabled then
        overflow <= FALSE;  
        started <= TRUE;
        start_mux <= TRUE;
      end if;
    end if;
    if pulse_valid and started then --rewrite last peak with last bit set
      started <= FALSE;
      -- TODO: improve alignment
      -- size 16 bits
      -- rel time 16 bits
      -- flags 16 bits, includes channel
      -- length 16
      --
      -- area 32 bits
      -- peak 32 bits
      -- more peaks -- packed to 64 bit boundary
      -- flags 
      -- bit 15 pulse=1 tick=0
      -- 		 14 multipeak = 1
      -- bit 3-0 channel 
      -- size|reltime|flags|length
      -- area | peak
      -- [peak | peak]	
      
      headerdata <= 
      	--chunk length
      	SetEndianness(to_std_logic(8,CHUNK_DATABITS),ENDIANNESS) & 
				--relative time-stamp 
      	to_std_logic(0,CHUNK_DATABITS) & 
      	--flags
      	SetEndianness(flags, ENDIANNESS) &
      	--pulse length
      	SetEndianness(
      		to_std_logic(resize(pulse_length,CHUNK_DATABITS)),ENDIANNESS
      	);
      							
      --FIXME move the space check to actual write point     
      if free < to_unsigned(2, ADDRESS_BITS+1) or overflow then 
        dump_int <= TRUE;
        overflow <= TRUE;
      else
        if pulse_area < area_threshold then
          dump_int <= TRUE;
        else
          commit_reg <= TRUE;
        end if;
      end if;
      frame_addr <= to_unsigned(1, ADDRESS_BITS); --resize(addr+1,ADDRESS_BITS);
      data <= SetEndianness(resize(pulse_area,2*CHUNK_DATABITS),ENDIANNESS) &
      				peak_data;
      chunk_wr_en <= "1111";
      keeps <= "1111";
      lasts <= "0001";
    elsif commit_reg then
      frame_addr <= (others => '0');
      data <= headerdata;  
      chunk_wr_en <= "1111";
      keeps <= "1111";
      lasts <= "0000";
    else
      chunk_wr_en <= "0000";
      keeps <= "0000";
      lasts <= "0000";
    end if;
  end if;
end if;
end process measure;
--------------------------------------------------------------------------------
-- Record peak value and time
--------------------------------------------------------------------------------
recordPeak:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    peak_detected <= FALSE;
    peak_data <= (others => '0');
  else
    if start then
    	peaks_lost <= FALSE;
    	peak_detected <= FALSE;
      if peak then
        peak_data <= to_std_logic(0,CHUNK_DATABITS) &
                     SetEndianness(resize(sample,CHUNK_DATABITS),ENDIANNESS);
      end if;
    else
      if peak then
        if not peak_detected then
          peak_data 
          	<= SetEndianness(resize(rel_time,CHUNK_DATABITS),ENDIANNESS) &
               SetEndianness(resize(sample,CHUNK_DATABITS),ENDIANNESS);
          peak_detected <= TRUE;
        else
          peaks_lost <= TRUE;
        end if;   
      end if;
    end if;
  end if;
end if;
end process recordPeak;
--------------------------------------------------------------------------------
-- Time
--------------------------------------------------------------------------------
rel_time <= (others => '0') when start else relative_time;
relativeTime:entity teslib.clock
generic map(TIME_BITS => TIME_BITS)
port map(
  clk => clk,
  reset => to_std_logic(start),
  te => TRUE,
  initialise_to_1 => TRUE,
  rolling_over => local_rollover,
  time_stamp => relative_time
);
end architecture fixed_aligned;