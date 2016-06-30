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
	CHANNELS:integer:=2;
	FRAMER_ADDRESS_BITS:integer:=14;
	ENDIANNESS:string:="LITTLE";
  MIN_TICK_PERIOD:integer:=2**16;
  MCA_ADDRESS_BITS:integer:=14;
	CONFIG_BITS:integer:=8;
	CONFIG_WIDTH:integer:=8;
	--bits in a filter coefficient
	COEF_BITS:integer:=25; 
	--width in the filter reload axi-stream
	COEF_WIDTH:integer:=32
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
signal sample_reset:std_logic:='1';	
signal io_reset:std_logic:='1';	
constant SAMPLE_CLK_PERIOD:time:=4 ns;
constant IO_CLK_PERIOD:time:=8 ns;

signal measurements:measurement_array(CHANNELS-1 downto 0);
signal dumps,commits:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams_valid:boolean_vector(CHANNELS-1 downto 0);
signal eventstreams_ready:boolean_vector(CHANNELS-1 downto 0);
signal adc_delayed:adc_sample_array(CHANNELS-1 downto 0);
signal adc_sample:adc_sample_t;
signal registers:channel_register_array(CHANNELS-1 downto 0);

-- discrete types as unsigned for reading into settings file
type height_type_array is array (natural range <>) of
		 unsigned(HEIGHT_D_BITS-1 downto 0);
signal height_types:height_type_array(CHANNELS-1 downto 0);
type detection_type_array is array (natural range <>) of
		 unsigned(DETECTION_D_BITS-1 downto 0);
signal detection_types:detection_type_array(CHANNELS-1 downto 0);
type trigger_type_array is array (natural range <>) of
		 unsigned(TIMING_D_BITS-1 downto 0);
signal trigger_types:trigger_type_array(CHANNELS-1 downto 0);
signal mca_value_type:unsigned(ceilLog2(NUM_MCA_VALUE_D)-1 downto 0);
signal mca_trigger_type:unsigned(ceilLog2(NUM_MCA_TRIGGER_D)-1 downto 0);
-- error signals
signal mux_overflows:boolean_vector(CHANNELS-1 downto 0);
signal mux_overflows_u:unsigned(CHANNELS-1 downto 0);
signal framer_overflows:boolean_vector(CHANNELS-1 downto 0);
signal framer_overflows_u:unsigned(CHANNELS-1 downto 0);
signal measurement_overflows:boolean_vector(CHANNELS-1 downto 0);
signal measurement_overflows_u:unsigned(CHANNELS-1 downto 0);
signal mux_full:boolean;
signal time_overflows,cfd_errors:boolean_vector(CHANNELS-1 downto 0);
signal time_overflows_u,cfd_errors_u:unsigned(CHANNELS-1 downto 0);
signal baseline_errors:boolean_vector(CHANNELS-1 downto 0);
signal baseline_errors_u:unsigned(CHANNELS-1 downto 0);
signal peak_overflows:boolean_vector(CHANNELS-1 downto 0);
signal peak_overflows_u:unsigned(CHANNELS-1 downto 0);
--
signal eventstreams:streambus_array(CHANNELS-1 downto 0);
signal tick_period:unsigned(TICK_PERIOD_BITS-1 downto 0);
signal starts:boolean_vector(CHANNELS-1 downto 0);
signal muxstream:streambus_t;
signal muxstream_valid:boolean;
signal muxstream_ready:boolean;
signal mcastream:streambus_t;
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
signal mtu:unsigned(MTU_BITS-1 downto 0);
signal tick_latency:unsigned(TICK_LATENCY_BITS-1 downto 0);
signal window:unsigned(TIME_BITS-1 downto 0);
--mca
signal mca_initialising:boolean;
signal update_asap:boolean:=FALSE;
signal update_on_completion:boolean:=FALSE;
signal updated:boolean;
signal mca_registers:mca_registers_t;
signal channel_select:std_logic_vector(CHANNELS-1 downto 0);
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
-- don't need bit for mca_trigger_d 0=DISABLED
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal mca_values:mca_value_array(CHANNELS-1 downto 0);
signal mca_value_valid:boolean;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
signal mca_value_valids:boolean_vector(CHANNELS-1 downto 0);
signal mca_value:signed(MCA_VALUE_BITS-1 downto 0);
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

signal clk_count:integer:=0;


type int_file is file of integer;
file bytestream_file,trace_file:int_file;

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
sample_reset <= '0' after 2*IO_CLK_PERIOD; 
io_reset <= '0' after 2*IO_CLK_PERIOD; 
bytestream_ready <= TRUE after 2*IO_CLK_PERIOD;

mca_value_type 
	<= unsigned(to_std_logic(mca_registers.value,ceilLog2(NUM_MCA_VALUE_D)));
mca_trigger_type 
	<= unsigned(to_std_logic(mca_registers.value,ceilLog2(NUM_MCA_TRIGGER_D)));

chanGen:for c in 0 to CHANNELS-1 generate
begin	
	
	--FIXME	move delay into measurement_unit so that it acts on the signal after
	-- baseline
	delay:entity work.RAM_delay
  generic map(
    DEPTH => 2**DELAY_BITS,
    DATA_BITS => ADC_BITS
  )
  port map(
    clk => sample_clk,
    data_in => adc_sample,
    delay => to_integer(registers(c).capture.delay),
    delayed => adc_delayed(c)
  );

--	regs:entity work.channel_registers
--  generic map(
--    CHANNEL => c,
--    CONFIG_BITS => CONFIG_BITS,
--    CONFIG_WIDTH => CONFIG_WIDTH,
--    COEF_BITS => COEF_BITS,
--    COEF_WIDTH => COEF_WIDTH
--  )
--  port map(
--    clk => sample_clk,
--    reset => sample_reset,
--    data => (others => '0'),
--    address => (others => '0'),
--    write => '0',
--    value => open,
--    axis_done => open,
--    axis_error => open,
--    registers => registers(c),
--    filter_config_data => open,
--    filter_config_valid => open,
--    filter_config_ready => '0',
--    filter_data => open,
--    filter_valid => open,
--    filter_ready => '0',
--    filter_last => open,
--    filter_last_missing => '0',
--    filter_last_unexpected => '0',
--    dif_config_data => open,
--    dif_config_valid => open,
--    dif_config_ready => '0',
--    dif_data => open,
--    dif_valid => open,
--    dif_ready => '0',
--    dif_last => open,
--    dif_last_missing => '0',
--    dif_last_unexpected => '0'
--  );

	measurementUnit:entity work.measurement_unit
  generic map(
    FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
    CHANNEL => c,
    ENDIANNESS => ENDIANNESS
  )
  port map(
    clk => sample_clk,
    reset => sample_reset,
    adc_sample => adc_delayed(c),
    registers => registers(c),
    filter_config_data => (others => '0'),
    filter_config_valid => '0',
    filter_config_ready => open,
    filter_reload_data => (others => '0'),
    filter_reload_valid => '0',
    filter_reload_ready => open,
    filter_reload_last => '0',
    dif_config_data => (others => '0'),
    dif_config_valid => '0',
    dif_config_ready => open,
    dif_reload_data => (others => '0'),
    dif_reload_valid => '0',
    dif_reload_ready => open,
    dif_reload_last => '0',
    measurements => measurements(c),
    mca_value_select => value_select,
    mca_trigger_select => trigger_select,
    mca_value => mca_values(c),
    mca_value_valid => mca_value_valids(c),
    mux_full => mux_full,
    start => starts(c),
    dump => dumps(c),
    commit => commits(c),
    cfd_error => cfd_errors(c),
    time_overflow => time_overflows(c),
    peak_overflow => peak_overflows(c),
    framer_overflow => framer_overflows(c),
    mux_overflow => mux_overflows(c),
    measurement_overflow => measurement_overflows(c),
    baseline_underflow => baseline_errors(c),
    eventstream => eventstreams(c),
    valid => eventstreams_valid(c),
    ready => eventstreams_ready(c)
  );
  
  detection_types(c) 
  	<= unsigned(to_std_logic(registers(c).capture.detection,DETECTION_D_BITS));
  height_types(c) 
  	<= unsigned(to_std_logic(registers(c).capture.height,HEIGHT_D_BITS));
  trigger_types(c) 
  	<= unsigned(to_std_logic(registers(c).capture.timing,TIMING_D_BITS));
end generate chanGen;

-- unsigned value for writing to file
baseline_errors_u <= to_unsigned(baseline_errors);
cfd_errors_u <= to_unsigned(cfd_errors);
time_overflows_u <= to_unsigned(time_overflows);
peak_overflows_u <= to_unsigned(peak_overflows);
framer_overflows_u <= to_unsigned(framer_overflows);
mux_overflows_u <= to_unsigned(mux_overflows);
measurement_overflows_u <= to_unsigned(measurement_overflows);

-- each channel sees same adc_sample delayed by its channel number

mux:entity work.eventstream_mux
generic map(
  CHANNELS => CHANNELS,
  TIME_BITS => TIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICKPERIOD => 2**14,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
  start => starts,
  commit => commits,
  dump => dumps,
  instreams => eventstreams,
  instream_valids => eventstreams_valid,
  instream_readys => eventstreams_ready,
  full => mux_full,
  tick_period => tick_period,
  window => window,
  cfd_errors => cfd_errors,
  framer_overflows => framer_overflows,
  mux_overflows => mux_overflows,
  measurement_overflows => measurement_overflows,
  peak_overflows => peak_overflows,
  time_overflows => time_overflows,
  baseline_underflows => baseline_errors,
  muxstream => muxstream,
  valid => muxstream_valid,
  ready => muxstream_ready
);

mcaChanSel:entity work.mca_channel_selector
generic map(
  CHANNELS => CHANNELS,
  VALUE_BITS   => MCA_VALUE_BITS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
  channel_select => channel_select,
  values => mca_values,
  valids => mca_value_valids,
  value => mca_value,
  valid => mca_value_valid
);

mca:entity work.mca_unit
generic map(
  CHANNELS => CHANNELS,
  ADDRESS_BITS => MCA_ADDRESS_BITS,
  COUNTER_BITS => MCA_COUNTER_BITS,
  VALUE_BITS => MCA_VALUE_BITS,
  TOTAL_BITS => MCA_TOTAL_BITS,
  TICKCOUNT_BITS => MCA_TICKCOUNT_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICK_PERIOD => MIN_TICK_PERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
  initialising => mca_initialising,
  update_asap => update_asap,
  update_on_completion => update_on_completion,
  updated => updated,
  registers => mca_registers,
  tick_period => tick_period,
  channel_select => channel_select,
  value_select => value_select,
  trigger_select => trigger_select,
  value => mca_value,
  value_valid => mca_value_valid,
  stream => mcastream,
  valid => mcastream_valid,
  ready => mcastream_ready
);
--
enet:entity work.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  FRAMER_ADDRESS_BITS => FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => sample_clk,
  reset => sample_reset,
  mtu => mtu,
  tick_latency => tick_latency,
  eventstream => muxstream,
  eventstream_valid => muxstream_valid,
  eventstream_ready => muxstream_ready,
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
  wr_clk => sample_clk,
  wr_rst =>	sample_reset,
  rd_clk => io_clk,
  rd_rst => io_reset,
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
  reset => io_reset,
  stream_in => cdc_dout,
  ready_out => cdc_ready,
  valid_in => cdc_valid,
  stream => bytestream_int,
  ready => bytestream_ready,
  valid => bytestream_valid
);

bytestream <= bytestream_int(7 downto 0);
bytestream_last <= bytestream_int(8)='1';

-- all channels see same register settings
--stimulus:process is
--begin
mtu <= to_unsigned(1500,MTU_BITS);
tick_period <= to_unsigned(2**16,TICK_PERIOD_BITS);
window <= to_unsigned(2,TIME_BITS);
tick_latency <= to_unsigned(2**16,TICK_PERIOD_BITS);

-- register settings common to all channels
registers(0).capture.pulse_threshold 
  <= to_unsigned(300,DSP_BITS-DSP_FRAC-1) & to_unsigned(0,DSP_FRAC);
registers(1).capture.pulse_threshold 
  <= to_unsigned(300,DSP_BITS-DSP_FRAC-1) & to_unsigned(0,DSP_FRAC);
registers(0).capture.slope_threshold 
  <= to_unsigned(10,DSP_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
registers(1).capture.slope_threshold 
  <= to_unsigned(10,DSP_BITS-SLOPE_FRAC-1) & to_unsigned(0,SLOPE_FRAC);
registers(0).baseline.timeconstant 
  <= to_unsigned(2**12,BASELINE_TIMECONSTANT_BITS);
registers(1).baseline.timeconstant 
  <= to_unsigned(2**12,BASELINE_TIMECONSTANT_BITS);
registers(0).baseline.threshold 
  <= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
registers(1).baseline.threshold 
  <= to_unsigned(2**(BASELINE_BITS-1)-1,BASELINE_BITS-1);
registers(0).baseline.count_threshold 
  <= to_unsigned(30,BASELINE_COUNTER_BITS);
registers(1).baseline.count_threshold 
  <= to_unsigned(30,BASELINE_COUNTER_BITS);
registers(0).baseline.average_order <= 4;
registers(1).baseline.average_order <= 4;
registers(0).baseline.offset <= to_std_logic(250,ADC_BITS);
registers(1).baseline.offset <= to_std_logic(250,ADC_BITS);
registers(0).baseline.subtraction <= TRUE;
registers(1).baseline.subtraction <= TRUE;
registers(0).capture.constant_fraction 
  <= to_unsigned((2**(CFD_BITS-1))/5,CFD_BITS-1); --20%
registers(1).capture.constant_fraction 
  <= to_unsigned((2**(CFD_BITS-1))/5,CFD_BITS-1); --20%
registers(0).capture.cfd_rel2min <= TRUE;
registers(1).capture.cfd_rel2min <= TRUE;
registers(0).capture.height <= CFD_HEIGHT_D;
registers(1).capture.height <= CFD_HEIGHT_D;
registers(0).capture.detection <= PEAK_DETECTION_D;
registers(1).capture.detection <= PEAK_DETECTION_D;
registers(0).capture.timing <= CFD_LOW_TIMING_D;
registers(1).capture.timing <= CFD_LOW_TIMING_D;
registers(0).capture.threshold_rel2min <= FALSE;
registers(1).capture.threshold_rel2min <= FALSE;
registers(0).capture.height_rel2min <= FALSE;
registers(1).capture.height_rel2min <= FALSE;
registers(0).capture.area_threshold <= to_signed(500,AREA_BITS);
registers(1).capture.area_threshold <= to_signed(500,AREA_BITS);
registers(0).capture.max_peaks <= (0 => '0', others => '0');
registers(1).capture.max_peaks <= (0 => '0', others => '0');
registers(0).capture.delay <= to_unsigned(2**(DELAY_BITS-1),DELAY_BITS);
registers(1).capture.delay <= to_unsigned(2**(DELAY_BITS-1)+1,DELAY_BITS);
registers(0).capture.full_trace <= TRUE;
registers(1).capture.full_trace <= TRUE;
registers(0).capture.trace0 <= NO_TRACE_D;
registers(1).capture.trace0 <= NO_TRACE_D;
registers(0).capture.trace1 <= NO_TRACE_D;
registers(1).capture.trace1 <= NO_TRACE_D;

--registers(1).capture.detection <= PULSE_DETECTION_D;
--registers(2).capture.detection <= PULSE_DETECTION_D;
--registers(2).capture.max_peaks <= (0 => '1', others => '0');
--registers(3).capture.detection <= TRACE_DETECTION_D;
--registers(3).capture.trace0 <= FILTERED_TRACE_D;
--registers(3).capture.trace1 <= RAW_TRACE_D;
--registers(4).capture.detection <= TRACE_DETECTION_D;
--registers(4).capture.trace0 <= FILTERED_TRACE_D;
--registers(4).capture.trace1 <= SLOPE_TRACE_D;
--registers(4).capture.full_trace <= FALSE;
--registers(7).capture.detection <= AREA_DETECTION_D;

mca_registers.channel <= (others => '0');
mca_registers.bin_n <= (others => '0');
mca_registers.last_bin <= (others => '1');
mca_registers.lowest_value <= to_signed(-1000, MCA_VALUE_BITS);
mca_registers.value <= MCA_FILTERED_SIGNAL_D;
mca_registers.trigger <= CLOCK_MCA_TRIGGER_D;
mca_registers.ticks <= (0 => '1', others => '0');
--
--update_on_completion <= FALSE;
--



mcaControlStimulus:process
begin
	wait for SAMPLE_CLK_PERIOD;
	wait until not mca_initialising;
	update_asap <= TRUE;
	wait for SAMPLE_CLK_PERIOD;
	update_asap <= FALSE;
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
	end loop;
end process traceWriter; 


clkCount:process is
begin
		wait until rising_edge(sample_clk);
		clk_count <= clk_count+1;
end process clkCount;

stimulus:process
	file sample_file:text is in "../input_signals/short";
	variable file_line:line; -- text line buffer 
	variable str_sample:string(4 downto 1);
	variable sample_in:std_logic_vector(15 downto 0);
begin
	while not endfile(sample_file) loop
		readline(sample_file, file_line);
		read(file_line, str_sample);
		sample_in:=hexstr2vec(str_sample);
		wait until rising_edge(sample_clk);
		adc_sample <= resize(sample_in, 14);
		if clk_count mod 10000 = 0 then
			report "clk " & integer'image(clk_count);
		end if;
		--assert false report str_sample severity note;
	end loop;
	wait;
end process stimulus;
	

end architecture testbench;
