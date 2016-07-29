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
	FRAMER_ADDRESS_BITS:integer:=8;
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
signal eventlast:boolean;
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

signal event_count:unsigned(31 downto 0);
signal mca_count:unsigned(31 downto 0);
signal etype:event_type_t;
signal ticktog:boolean;
signal tick:boolean;

constant TICKPERIOD:integer:=256;
constant MCALEN:integer:=256;
signal cdc_din:std_logic_vector(71 downto 0);
signal cdc_wr_en:std_logic;
signal cdc_rd_en:std_logic;
signal cdc_dout:std_logic_vector(8 downto 0);
signal cdc_full:std_logic;
signal cdc_empty:std_logic;
signal cdc_valid:boolean;
signal cdc_ready:boolean;
signal bytestream_int:std_logic_vector(8 downto 0);
signal clk_count:unsigned(31 downto 0);

type int_file is file of integer;
file bytestream_file:int_file;
begin
signal_clk <= not signal_clk after SIGNAL_PERIOD/2;
io_clk <= not io_clk after IO_PERIOD/2;

eventstream.data <= to_std_logic(event_count) & 
                    to_std_logic(0,12) &
                    to_std_logic(etype) & '0' &
                    to_std_logic(0,16);
                    
eventstream.discard <= (others => FALSE);
eventstream.last <= (0 => eventlast, others => FALSE);
eventlast <= not (tick or etype.tick) or (tick and ticktog);


mcastream.data <= to_std_logic(resize(mca_count,64));
mcastream.discard <= (others => FALSE);
mcastream.last <= (0 => mcalast, others => FALSE);
mcalast <= mca_count=to_unsigned(MCALEN,32);

etype.detection <= PEAK_DETECTION_D;
etype.tick <= event_count(7 downto 0)="000000000";

tickGen:process (signal_clk) is
begin
  if rising_edge(signal_clk) then
      
    if reset = '1' then
      tick <= FALSE;
    else
      if eventstream_ready and eventstream_valid then
        if etype.tick then
          tick <= TRUE;
          ticktog <= FALSE;
        end if;
        if tick then
          if ticktog then
            tick <= FALSE;
          else
            ticktog <= TRUE;
          end if;
        end if;
      end if;
    end if;
  end if;
end process tickGen;

simCount:process(signal_clk) is
begin
  if rising_edge(signal_clk) then
    if reset = '1' then
      event_count <= (others => '0');
      mca_count <= (others => '0');
    else
      if (eventstream_valid and eventstream_ready) then 
        event_count <= event_count+1;
      end if;
      if (mcastream_valid and mcastream_ready) then
        mca_count <= mca_count+1;
      end if;
    end if;
  end if;
end process simCount;

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
    		write(bytestream_file, -to_integer(clk_count)); --identify last by -ve value
    	else
    		write(bytestream_file, to_integer(clk_count));
    	end if;
    end if;
	end loop;
end process byteStreamWriter;

validSim:process(signal_clk)
begin
  if rising_edge(signal_clk) then
    if reset = '1' then
      clk_count <= (others => '0'); 
      eventstream_valid <= FALSE;
    else
      clk_count <= clk_count+1;
      if clk_count(3 downto 0)="0000" then
        eventstream_valid <= TRUE;
      elsif eventstream_valid and eventstream_ready then
        eventstream_valid <= FALSE;
      end if;
    end if;
  end if;
end process validSim;

mcastream_valid <= clk_count(0)='1' and mca_count(10)='1';
--eventstream_valid <= clk_count(3 downto 0)="0000";

stimulus:process
begin
mtu <= to_unsigned(128,MTU_BITS);
tick_latency <= to_unsigned(1000, TICK_LATENCY_BITS);
wait for IO_PERIOD;
reset <= '0';
bytestream_ready <= TRUE;
wait;
end process stimulus;


end architecture testbench;
