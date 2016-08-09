--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:18 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: measurement_unit_TB
-- Project Name: tes library (teslib)
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;
use std.textio.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.types.all;
use work.registers.all;
use work.events.all;
use work.measurements.all;
use work.adc.all; --TODO move to types
use work.dsptypes.all; --TODO move to types

entity measurement_subsystem_TB is
generic(
	CHANNELS:integer:=2; -- need to adjust stimulus if changed
	ENET_FRAMER_ADDRESS_BITS:integer:=11;
	EVENT_FRAMER_ADDRESS_BITS:integer:=11;
  MCA_ADDRESS_BITS:integer:=14;
	ENDIANNESS:string:="LITTLE";
  MIN_TICKPERIOD:integer:=2**16;
	PACKET_GEN:boolean:=FALSE
);
end entity measurement_subsystem_TB;

architecture testbench of measurement_subsystem_TB is

--constant CHANNELS:integer:=2**CHANNEL_BITS;
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
			
signal sample_clk:std_logic:='1';	
signal io_clk:std_logic:='1';	
signal reset0:std_logic:='1';	
signal reset1:std_logic:='1';	
signal reset2:std_logic:='1';	
constant SAMPLE_CLK_PERIOD:time:=4 ns;
constant IO_CLK_PERIOD:time:=8 ns;

signal mca_initialising:boolean;
signal measurements:measurement_array(CHANNELS-1 downto 0);
signal adc_samples:adc_sample_array(CHANNELS-1 downto 0);
signal sample_reg:adc_sample_t;
signal registers:channel_register_array(CHANNELS-1 downto 0);

-- discrete types as unsigned for reading into settings file
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
--mca
signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:boolean:=FALSE;
signal bytestream_last:boolean;
signal cdc_din:std_logic_vector(71 downto 0);
signal cdc_ready:boolean;
signal cdc_valid:boolean;
signal cdc_wr_en:std_logic;
signal cdc_rd_en:std_logic;
signal cdc_dout:std_logic_vector(8 downto 0);
signal cdc_full:std_logic;
signal cdc_empty:std_logic;
signal bytestream_int:std_logic_vector(8 downto 0);
signal global:global_registers_t;
signal clk_count:integer:=0;

type int_file is file of integer;
file bytestream_file,trace_file:int_file;

--signals for vcd dump
signal bytestream_valid_v,bytestream_ready_v:std_logic;
signal ethernetstream_v:std_logic_vector(63 downto 0);
signal ethernetstream_valid_v,ethernetstream_ready_v:std_logic;
signal ethernetstream_last_v:std_logic;

function hexstr2vec(str:string) return std_logic_vector is
	variable slv:std_logic_vector(str'length*4-1 downto 0):=(others => 'X');
begin
	for i in 0 to str'length-1 loop
		case str(i+1) is -- strings can't use index 0
		when '0' => 
			slv(4*(i+1)-1 downto (4*i)):="0000";
		when '1' => 
			slv(4*(i+1)-1 downto (4*i)):="0001";
		when character('2') => 
			slv(4*(i+1)-1 downto (4*i)):="0010";
		when character('3') => 
			slv(4*(i+1)-1 downto (4*i)):="0011";
		when character('4') => 
			slv(4*(i+1)-1 downto (4*i)):="0100";
		when character('5') => 
			slv(4*(i+1)-1 downto (4*i)):="0101";
		when character('6') => 
			slv(4*(i+1)-1 downto (4*i)):="0110";
		when character('7') => 
			slv(4*(i+1)-1 downto (4*i)):="0111";
		when character('8') => 
			slv(4*(i+1)-1 downto (4*i)):="1000";
		when character('9') => 
			slv(4*(i+1)-1 downto (4*i)):="1001";
		when character('a') => 
			slv(4*(i+1)-1 downto (4*i)):="1010";
		when character('b') => 
			slv(4*(i+1)-1 downto (4*i)):="1011";
		when character('c') => 
			slv(4*(i+1)-1 downto (4*i)):="1100";
		when character('d') => 
			slv(4*(i+1)-1 downto (4*i)):="1101";
		when character('e') => 
			slv(4*(i+1)-1 downto (4*i)):="1110";
		when character('f') => 
			slv(4*(i+1)-1 downto (4*i)):="1111";
		when others => 
			slv(4*(i+1)-1 downto (4*i)):="UUUU";
		end case;
	end loop;
	return slv;
end function;

begin
	
sample_clk <= not sample_clk after SAMPLE_CLK_PERIOD/2;
io_clk <= not IO_clk after IO_CLK_PERIOD/2;
reset0 <= '0' after 2*IO_CLK_PERIOD; 
reset1 <= '0' after 10*IO_CLK_PERIOD; 
reset2 <= '0' after 20*IO_CLK_PERIOD; 
bytestream_ready <= TRUE after 2*IO_CLK_PERIOD;

chanRegGen:for c in 0 to CHANNELS-1 generate
begin	
	
	regs:entity work.channel_registers
  generic map(
    CHANNEL => c,
    CONFIG_BITS => CONFIG_BITS,
    CONFIG_WIDTH => CONFIG_WIDTH,
    COEF_BITS => COEF_BITS,
    COEF_WIDTH => COEF_WIDTH
  )
  port map(
    clk => sample_clk,
    reset => reset2,
    data => (others => '0'),
    address => (others => '0'),
    write => '0',
    value => open,
    axis_done => open,
    axis_error => open,
    registers => registers(c),
    filter_config_data => open,
    filter_config_valid => open,
    filter_config_ready => '0',
    filter_data => open,
    filter_valid => open,
    filter_ready => '0',
    filter_last => open,
    filter_last_missing => '0',
    filter_last_unexpected => '0',
    dif_config_data => open,
    dif_config_valid => open,
    dif_config_ready => '0',
    dif_data => open,
    dif_valid => open,
    dif_ready => '0',
    dif_last => open,
    dif_last_missing => '0',
    dif_last_unexpected => '0'
  );

end generate chanRegGen;

UUT:entity work.measurement_subsystem_test
  generic map(
    DSP_CHANNELS => CHANNELS,
    EVENT_FRAMER_ADDRESS_BITS => EVENT_FRAMER_ADDRESS_BITS,
    ENET_FRAMER_ADDRESS_BITS => ENET_FRAMER_ADDRESS_BITS,
    MCA_ADDRESS_BITS => MCA_ADDRESS_BITS,
    ENDIANNESS => ENDIANNESS,
    MIN_TICKPERIOD => MIN_TICKPERIOD,
    PACKET_GEN => PACKET_GEN
  )
  port map(
    clk => sample_clk,
    reset1 => reset1,
    reset2 => reset2,
    mca_initialising => mca_initialising,
    samples => adc_samples,
    channel_reg => registers,
    global_reg  => global,
    filter_config_data => (others => (others => '0')),
    filter_config_valid => (others => '0'),
    filter_config_ready => open,
    filter_data => (others => (others => '0')),
    filter_valid => (others => '0'),
    filter_ready => open,
    filter_last => (others => '0'),
    filter_last_missing => open,
    filter_last_unexpected => open,
    dif_config_data => (others => (others => '0')),
    dif_config_valid => (others => '0'),
    dif_config_ready => open,
    dif_data => (others => (others => '0')),
    dif_valid => (others => '0'),
    dif_ready => open,
    dif_last => (others => '0'),
    dif_last_missing => open,
    dif_last_unexpected => open,
    measurements => measurements,
    ethernetstream => ethernetstream,
    ethernetstream_valid => ethernetstream_valid,
    ethernetstream_ready => ethernetstream_ready
  );

ethernetstream_v <= ethernetstream.data;
ethernetstream_valid_v <= to_std_logic(ethernetstream_valid);
ethernetstream_ready_v <= to_std_logic(ethernetstream_ready);
ethernetstream_last_v <= to_std_logic(ethernetstream.last(0));

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
  wr_clk => sample_clk,
  wr_rst =>	reset1,
  rd_clk => io_clk,
  rd_rst => reset1,
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
  reset => reset2,
  stream_in => cdc_dout,
  ready_out => cdc_ready,
  valid_in => cdc_valid,
  stream => bytestream_int,
  ready => bytestream_ready,
  valid => bytestream_valid
);

bytestream <= bytestream_int(7 downto 0);
bytestream_last <= bytestream_int(8)='1';
bytestream_valid_v <= to_std_logic(bytestream_valid);
bytestream_ready_v <= to_std_logic(bytestream_ready);

--globalreg:entity work.global_registers
--  generic map(
--    MIN_TICK_PERIOD => 2**16,
--    MIN_MTU => 64
--  )
--  port map(
--    clk => io_clk,
--    reset => reset1,
--    data => (others => '0'),
--    address => (others => '0'),
--    value => open,
--    write => FALSE,
--    registers => global
--  );

global.mtu <= to_unsigned(1500,MTU_BITS);
global.tick_latency <= to_unsigned(2**16,TICK_LATENCY_BITS);
global.tick_period <= to_unsigned(2**16,TICK_PERIOD_BITS);
global.mca.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
global.mca.bin_n <= (others => '0');
global.mca.channel <= (others => '0');
global.mca.last_bin <= (others => '1');
global.mca.lowest_value <= to_signed(-1000,MCA_VALUE_BITS);
--TODO normalise these type names
global.mca.trigger <= CLOCK_MCA_TRIGGER_D;
global.mca.value <= MCA_RAW_SIGNAL_D;

mcaControlStimulus:process
begin
  global.mca.update_asap <= FALSE;
  global.mca.update_on_completion <= FALSE;
	wait for SAMPLE_CLK_PERIOD;
	wait until not mca_initialising;
	global.mca.update_asap <= TRUE;
	wait for SAMPLE_CLK_PERIOD;
	global.mca.update_asap <= FALSE;
	wait;
end process mcaControlStimulus;	

file_open(bytestream_file,"../bytestream",WRITE_MODE);
byteStreamWriter:process
begin
	while TRUE loop
    wait until rising_edge(io_clk);
    if bytestream_valid and bytestream_ready then
    	write(bytestream_file, to_integer(unsigned(bytestream)));
      if bytestream_last then
    		write(bytestream_file, -clk_count); --identify last by -ve value
    	else
    		write(bytestream_file, clk_count);
    	end if;
    end if;
	end loop;
end process byteStreamWriter;

file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
	while TRUE loop
    wait until rising_edge(sample_clk);
	  write(trace_file, to_integer(measurements(0).raw.sample));
	  write(trace_file, to_integer(measurements(0).filtered.sample));
	  write(trace_file, to_integer(measurements(0).slope.sample));
	  write(trace_file, to_integer(measurements(0).raw.baseline));

	end loop;
end process traceWriter; 

clkCount:process is
begin
		wait until rising_edge(sample_clk);
		clk_count <= clk_count+1;
end process clkCount;

stimulus:process
	file sample_file:text is in "../input_signals/long";
	variable file_line:line; -- text line buffer 
	variable str_sample:string(4 downto 1);
	variable sample_in:std_logic_vector(15 downto 0);
begin
	while not endfile(sample_file) loop
		readline(sample_file, file_line);
		read(file_line, str_sample);
		sample_in:=hexstr2vec(str_sample);
		wait until rising_edge(sample_clk);
		adc_samples(0) <= resize(sample_in, 14);
		sample_reg <= resize(sample_in, 14);
		adc_samples(1) <= sample_reg;
		if clk_count mod 10000 = 0 then
			report "clk " & integer'image(clk_count);
		end if;
		--assert false report str_sample severity note;
	end loop;
	wait;
end process stimulus;

end architecture testbench;
