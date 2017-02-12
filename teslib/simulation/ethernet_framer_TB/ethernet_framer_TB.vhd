--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:4 Jun 2016
--
-- Design Name: TES_digitiser
-- Module Name: ethernet_framer_TB
-- Project Name: teslib	
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;
use work.events.all;
use work.registers.all;

entity ethernet_framer_TB is
generic(
	MTU_BITS:integer:=16;
	TICK_LATENCY_BITS:integer:=16;
	FRAMER_ADDRESS_BITS:integer:=10;
	DEFAULT_MTU:unsigned:=to_unsigned(128,16);
	DEFAULT_TICK_LATENCY:unsigned:=to_unsigned(512,16);
	ENDIANNESS:string:="LITTLE"
);
end entity ethernet_framer_TB;

architecture testbench of ethernet_framer_TB is
  
component enet_cdc_fifo
port (
  wr_clk:in std_logic;
  wr_rst:in std_logic;
  rd_clk:in std_logic;
  rd_rst:in std_logic;
  din:in std_logic_vector(71 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(8 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;

signal signal_clk:std_logic:='1';	
signal io_clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant SIGNAL_PERIOD:time:=4 ns;
constant IO_PERIOD:time:=8 ns;

signal mtu:unsigned(MTU_BITS-1 downto 0);
signal tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal eventstream:streambus_t;
signal eventstream_valid:boolean;
signal eventstream_ready:boolean;
signal mcastream:streambus_t;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal mcalast:boolean;
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:boolean;
signal bytestream_last:boolean;

signal event_count:integer;
signal mca_count:integer;
signal tick_count:integer range 0 to 2;
signal tick:boolean:=FALSE;

constant MCALEN:integer:=2048;

signal cdc_din:std_logic_vector(71 downto 0);
signal cdc_wr_en:std_logic;
signal cdc_rd_en:std_logic;
signal cdc_dout:std_logic_vector(8 downto 0);
signal cdc_full:std_logic;
signal cdc_empty:std_logic;
signal cdc_valid:boolean;
signal cdc_ready:boolean;
signal bytestream_int:std_logic_vector(8 downto 0);
signal clk_count:integer;


signal tick_event:tick_event_t;
signal peak_event:peak_detection_t;

type int_file is file of integer;
file bytestream_file:int_file;

begin
  
signal_clk <= not signal_clk after SIGNAL_PERIOD/2;
io_clk <= not io_clk after IO_PERIOD/2;


tick_event.flags <= (FALSE, (PEAK_DETECTION_D, TRUE));
tick_event.period <= to_unsigned(clk_count,TICK_PERIOD_BITS);
tick_event.rel_timestamp <= to_unsigned(clk_count,TIME_BITS);
tick_event.full_timestamp <= to_unsigned(clk_count,TIMESTAMP_BITS);
tick_event.events_lost <= to_boolean(to_unsigned(clk_count,8));
tick_event.framer_overflows <= to_boolean(to_unsigned(clk_count,8));
tick_event.measurement_overflows <= to_boolean(to_unsigned(clk_count,8));
tick_event.mux_overflows <= to_boolean(to_unsigned(clk_count,8));
tick_event.framer_errors <= to_boolean(to_unsigned(clk_count,8));
tick_event.time_overflows <= to_boolean(to_unsigned(clk_count,8));
tick_event.baseline_underflows <= to_boolean(to_unsigned(clk_count,8));
tick_event.cfd_errors <= to_boolean(to_unsigned(clk_count,8));

peak_event.height <= to_signed(event_count,SIGNAL_BITS); 
peak_event.minima <= to_signed(event_count,SIGNAL_BITS); 
peak_event.flags <= (
  "0000",FALSE,PEAK_HEIGHT_D,CFD_LOW_TIMING_D,"000",
  (PEAK_DETECTION_D,FALSE),TRUE
);


eventstreamSim:process(tick,peak_event,tick_count,tick_event)
begin
  if tick then
    eventstream <= to_streambus(tick_event,tick_count,ENDIANNESS);
  else
    eventstream <= to_streambus(peak_event,ENDIANNESS);
  end if;
end process eventstreamSim;

mcastream.data <= to_std_logic(mca_count,64);
mcastream.discard <= (others => FALSE);
mcastream.last <= (0 => mcalast, others => FALSE);
mcalast <= mca_count=to_unsigned(MCALEN,32);

sim:process(signal_clk)
begin
  if rising_edge(signal_clk) then
    if reset = '1' then
      clk_count <= 0; 
      tick <= FALSE;
      tick_count <= 0;
      event_count <= 0;
      mca_count <= 0;
    else
      
      clk_count <= clk_count+1;
      
      if clk_count mod 25000=0 then 
        tick <= TRUE;
        tick_count <= 0;
      end if;
      
      if (eventstream_valid and eventstream_ready) then 
        if tick then
          if tick_count=2 then
            tick <= FALSE;
          else
            tick_count <= tick_count+1;
          end if;
        else
          event_count <= event_count+1;
        end if;
      end if;
      
      if (mcastream_valid and mcastream_ready) then
        if mcalast then
          mca_count <= 0;
        else
          mca_count <= mca_count+1;
        end if;
      end if;
      
    end if;
  end if;
end process sim;


UUT:entity work.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  TICK_LATENCY_BITS => TICK_LATENCY_BITS,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => signal_clk,
  reset => reset,
  mtu => mtu,
  tick_latency => tick_latency,
  eventstream => eventstream,
  eventstream_valid => eventstream_valid,
  eventstream_ready => eventstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

cdc_din <= '0' & ethernetstream.data(63 downto 56) &
           '0' & ethernetstream.data(55 downto 48) &
           '0' & ethernetstream.data(47 downto 40) &
           '0' & ethernetstream.data(39 downto 32) &
           '0' & ethernetstream.data(31 downto 24) &
           '0' & ethernetstream.data(23 downto 16) &
           '0' & ethernetstream.data(15 downto 8) &
           to_std_logic(ethernetstream.last(0)) & 
           ethernetstream.data(7 downto 0);
           
ethernetstream_ready <= cdc_full='0';
cdc_wr_en <= to_std_logic(ethernetstream_valid); 

cdcFIFO:enet_cdc_fifo
port map (
  wr_clk => signal_clk,
  wr_rst =>	reset,
  rd_clk => io_clk,
  rd_rst => reset,
  din => cdc_din,
  wr_en => cdc_wr_en,
  rd_en => cdc_rd_en,
  dout => cdc_dout,
  full => cdc_full,
  empty => cdc_empty
);
cdc_valid <= cdc_empty='0';
cdc_rd_en <= to_std_logic(cdc_ready);

bytestreamReg:entity streamlib.stream_register
generic map(
  WIDTH => 9
)
port map(
  clk => io_clk,
  reset => reset,
  stream_in => cdc_dout,
  ready_out => cdc_ready,
  valid_in => cdc_valid,
  stream => bytestream_int,
  ready => bytestream_ready,
  valid => bytestream_valid
);

bytestream <= bytestream_int(7 downto 0);
bytestream_last <= bytestream_int(8)='1';

file_open(bytestream_file,"../bytestream",WRITE_MODE);
byteStreamWriter:process
begin
	while TRUE loop
    wait until rising_edge(io_clk);
    if bytestream_valid and bytestream_ready then
    	write(bytestream_file, to_integer(unsigned(bytestream)));
      if bytestream_last then
    		write(bytestream_file, -clk_count); 
    	else
    		write(bytestream_file, clk_count);
    	end if;
    end if;
	end loop;
end process byteStreamWriter;

--mcastream_valid <= clk_count mod 23=0;
mcastream_valid <= TRUE;
eventstream_valid <= clk_count mod 15=0;


stimulus:process
begin
mtu <= to_unsigned(1496,MTU_BITS);
tick_latency <= to_unsigned(25000, TICK_LATENCY_BITS);
wait for IO_PERIOD;
reset <= '0';
bytestream_ready <= TRUE;
wait;
end process stimulus;


end architecture testbench;
