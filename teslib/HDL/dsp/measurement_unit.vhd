--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: signal_processor
-- Project Name: tes (library)
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

use work.registers.all;
use work.types.all;
use work.functions.all;
use work.dsptypes.all;
use work.adc.all;
use work.events.all;
use work.measurements.all;

entity measurement_unit is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3;
	TIME_BITS:integer:=16;
	TIME_FRAC:integer:=0;
  BASELINE_BITS:integer:=10;
  BASELINE_COUNTER_BITS:integer:=18;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_MAX_AV_ORDER:integer:=6;
  CFD_BITS:integer:=18;
  CFD_FRAC:integer:=17;
  PEAK_COUNT_BITS:integer:=4;
  FRAMER_ADDRESS_BITS:integer:=10;
  CHANNEL:integer:=7;
  ENDIANNESS:string:="LITTLE"
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  adc_sample:in adc_sample_t;
  
  registers:in channel_registers_t;
  
  -- FIR filters AXI interfaces
  filter_config_data:in std_logic_vector(7 downto 0);
  filter_config_valid:in std_logic;
  filter_config_ready:out std_logic;
  filter_reload_data:in std_logic_vector(31 downto 0);
  filter_reload_valid:in std_logic;
  filter_reload_ready:out std_logic;
  filter_reload_last:in std_logic;
  filter_reload_last_missing:out std_logic;
  filter_reload_last_unexpected:out std_logic;
  dif_config_data:in std_logic_vector(7 downto 0);
  dif_config_valid:in std_logic;
  dif_config_ready:out std_logic;
  dif_reload_data:in std_logic_vector(31 downto 0);
  dif_reload_valid:in std_logic;
  dif_reload_ready:out std_logic;
  dif_reload_last:in std_logic;
  dif_reload_last_missing:out std_logic;
  dif_reload_last_unexpected:out std_logic;

  measurements:out measurement_t;
  
  mca_value_select:in std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
	mca_trigger_select:in std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
  mca_value:out signed(MCA_VALUE_BITS-1 downto 0);
  mca_value_valid:out boolean;

	mux_full:in boolean;
	
	start:out boolean;
  dump:out boolean;
  commit:out boolean;
  
  cfd_error:out boolean;
  time_overflow:out boolean;
  peak_overflow:out boolean;
  framer_overflow:out boolean;
	mux_overflow:out boolean;
  measurement_overflow:out boolean;
  baseline_underflow:out boolean;
  
  eventstream:out streambus_t;
  valid:out boolean;
  ready:in boolean
);
end entity measurement_unit;

architecture RTL of measurement_unit is
	
component cfd_threshold_queue
port( 
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(WIDTH-1 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(WIDTH-1 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;
	
constant CFD_DELAY_DEPTH:integer:=512;
constant CFD_DELAY:integer:=200;
constant FIR_DELAY:integer:=23+69;
constant BASELINE_AV_FRAC:integer:=SIGNAL_BITS-BASELINE_BITS;
constant MULT_PIPE_DEPTH:integer:=4;
constant NUM_FLAGS:integer:=7;
-- internal area accumulator width
constant AREA_SUM_BITS:integer:=TIME_BITS+WIDTH;

--------------------------------------------------------------------------------
-- Signals for DSP stage
--------------------------------------------------------------------------------
signal stage1_input,filtered_FIR,slope_FIR:signed(WIDTH-1 downto 0);	
signal sample:sample_t;
signal baseline_estimate:signal_t;
--signal baseline_range_error:boolean;

--------------------------------------------------------------------------------
-- Signals for pulse detector and CF calculation
--------------------------------------------------------------------------------
type peakFSMstate is (WAITING,ARMED);
signal pd_state,pd_nextstate:peakFSMstate;
type pulseFSMstate is (IDLE,FIRST_RISE,PEAKED);
signal pd_pulse_state,pd_pulse_nextstate:pulseFSMstate;

signal slope_threshold:signed(WIDTH-1 downto 0);
signal pulse_threshold:signed(WIDTH-1 downto 0);
signal slope_pos_0xing_pd,slope_neg_0xing_pd:boolean;
signal slope_zero_xing_pd,arming_pd:boolean;
signal slope_pd,filtered_pd:signed(WIDTH-1 downto 0);
signal peak_pd,minima_pd:boolean;
signal minima_value_pd,last_minima_value:signed(WIDTH-1 downto 0);
signal filtered_pos_threshxing_pd,filtered_neg_threshxing_pd:boolean;
signal slope_pos_thresh_xing_pd:boolean;
signal pulse_start_pd,pulse_stop_pd:boolean;

signal cf_of_peak,cf_of_peak_reg:signed(CFD_BITS+WIDTH-1 downto 0);
signal cf_of_peak_reg2:signed(CFD_BITS+WIDTH-1 downto 0);
signal cfd_low_thresh_pd,cfd_high_thresh_pd:signed(WIDTH-1 downto 0);
signal signal_for_cfd:signed(WIDTH-1 downto 0);
signal peak_pipe,first_rise_pipe:boolean_vector(1 to MULT_PIPE_DEPTH);
signal queue_overflow:boolean;
signal minima_for_cfd,maxima_for_cfd:signed(WIDTH-1 downto 0);
signal capture_pd:capture_registers_t;

--------------------------------------------------------------------------------
-- Signals for delay and FIFO stage
--------------------------------------------------------------------------------
signal filtered_cfd_delay,slope_cfd_delay:std_logic_vector(WIDTH-1 downto 0);
signal raw_cfd_delay:std_logic_vector(WIDTH-1 downto 0);
signal flags_pd,flags_cfd_delay:std_logic_vector(NUM_FLAGS-1 downto 0);
signal queue_rd_en:std_logic;
signal queue_full,queue_empty:std_logic;
signal queue_wr_en:std_logic;
signal cfd_low_queue_dout:std_logic_vector(WIDTH-1 downto 0);
signal cfd_high_queue_dout:std_logic_vector(WIDTH-1 downto 0);
signal minima_queue_dout:std_logic_vector(WIDTH-1 downto 0);

--------------------------------------------------------------------------------
-- Measurement Signals 
--------------------------------------------------------------------------------
signal m:measurement_t;
signal pulse_area:signed(AREA_SUM_BITS-1 downto 0);
signal raw_extrema,filtered_extrema:signed(WIDTH-1 downto 0);
signal slope_extrema,pulse_extrema:signed(WIDTH-1 downto 0);
signal filtered_area,slope_area:signed(AREA_SUM_BITS-1 downto 0);
signal filtered_zero_xing,slope_zero_xing:boolean;
signal trigger_cfd:boolean;
signal area_above_threshold:boolean;
signal peak_count_pd:unsigned(PEAK_COUNT_BITS-1 downto 0);
signal pulse_length:unsigned(TIME_BITS-TIME_FRAC-1 downto 0);
signal raw_area:signed(AREA_SUM_BITS-1 downto 0);
signal raw_zero_xing:boolean;

--------------------------------------------------------------------------------
-- Signals for CFD stage
--------------------------------------------------------------------------------
signal capture_cfd:capture_registers_t;
type cfdFSMstate is (IDLE,WAIT_MIN,WAIT_PEAK);
signal cfd_state,cfd_nextstate:cfdFSMstate;
signal filtered_cfd,slope_cfd,raw_cfd:signed(WIDTH-1 downto 0);
signal cfd_low_threshold:signed(WIDTH-1 downto 0);
signal minima_value_cfd:signed(WIDTH-1 downto 0);
signal slope_pos_thresh_xing_cfd:boolean;
signal slope_neg_0xing_cfd:boolean;
signal minima_cfd:boolean;

signal cfd_low,cfd_high,slope_pos_0xing_cfd,peak_cfd:boolean;
signal cfd_pulse_state,cfd_pulse_nextstate:pulseFSMstate;
signal pulse_end_cfd,pulse_start_cfd:boolean;
signal filtered_cfd_reg,filtered_cfd_reg2:signed(WIDTH-1 downto 0);
signal filtered_is_min:boolean;
signal cfd_low_xing,cfd_high_xing:boolean;
signal cfd_error_int:boolean;
signal minima_valid:boolean;
signal cfd_high_threshold:signed(WIDTH-1 downto 0);
signal cfd_reset:boolean;
signal cfd_low_crossed,cfd_high_crossed:boolean;
signal cfd_high_done,cfd_low_done:boolean;
signal peak_start_cfd:boolean;
signal peaks_full:boolean;
signal event_start_cfd:boolean;

--------------------------------------------------------------------------------
-- Signals framer stage
--------------------------------------------------------------------------------
-- FSM state
type frameFSMstate is (IDLE,STARTED,QUEUED);
signal event_state,event_nextstate:frameFSMstate;
signal pulse_end:boolean;

-- framer signals
signal frame_word:streambus_t;
signal framer_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal area_dump:boolean;
signal frame_length:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_word_reg:streambus_t;
signal frame_address_reg:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_we_reg:boolean_vector(BUS_CHUNKS-1 downto 0);
signal frame_length_reg:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal commit_frame_reg:boolean;
signal frame_overflow:boolean;
signal dump_int:boolean;
signal mux_overflow_int:boolean;
signal start_int:boolean;

-- fixed 8 byte events (single word)
--signal peak_event:datachunk_array_t(BUS_CHUNKS-1 downto 0); 
signal peak_event:peak_detection_t; 
signal area_event:area_detection_t;
signal peak_event_we,area_event_we:boolean_vector(BUS_CHUNKS-1 downto 0);

signal header_valid:boolean;
signal header_flags:detection_flags_t;
signal header_slope_threshold:unsigned(SIGNAL_BITS-1 downto 0);
signal header_pulse_threshold:unsigned(SIGNAL_BITS-1 downto 0);

--pulse events
type pulseEventFSMstate is (IDLE,PEAKS,HEADER0,HEADER1,CLEAR);
signal pulse_state,pulse_nextstate:pulseEventFSMstate;

signal pulse_header:pulse_detection_t;
signal pulse_peak:pulse_peak_t;
signal pulse_peak_bus,pulse_peak_bus_reg,pulse_peak_bus_mux:streambus_t;
signal pulse_peak_we,pulse_peak_we_reg:boolean_vector(BUS_CHUNKS-1 downto 0);
signal pulse_peak_we_mux:boolean_vector(BUS_CHUNKS-1 downto 0);
signal pulse_peak_lost,pulse_peak_last:boolean;
signal last_pulse_peak_addr:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal pulse_peak_addr:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);

--trace events
type traceFSMstate is (IDLE,HEADER0,HEADER1,HEADER2,PEAKS,TRACE,CLEAR);
signal trace_state,trace_nextstate:traceFSMstate;

signal trace0,trace1:datachunk_t;
signal trace_reg:datachunk_array_t(0 to BUS_CHUNKS-1);
signal trace0_count:unsigned(ceilLog2(BUS_CHUNKS)-1 downto 0);
signal trace1_count:unsigned(ceilLog2(BUS_CHUNKS)-1 downto 0);
signal dual_trace:boolean;
signal trace_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
--signal record_trace,
signal trace_start,trace_stop:boolean;
signal trace_peak:trace_peak_t;
signal trace_peak_bus,trace_peak_bus_reg,trace_peak_bus_mux:streambus_t;
signal trace_peak_we,trace_peak_we_reg:boolean_vector(BUS_CHUNKS-1 downto 0);
signal trace_peak_we_mux:boolean_vector(BUS_CHUNKS-1 downto 0);
signal trace_peak_lost:boolean;
signal trace_header:trace_detection_t;
signal trace_peak_clear_addr:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal capture_trace:boolean;
signal trace_done:boolean;
--signal trace_clear_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal trace_peak_addr:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal trace_peak_last:boolean;
signal last_trace_peak_addr:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal write_trace:boolean;
--signal trace_peak_full:boolean;

-- common signals
signal detection_flags:detection_flags_t;
signal pulse_peak_clear_addr:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal commit_peak_event,commit_area_event:boolean;
--signal last_peak:boolean;
--signal last_peak_count:unsigned(PEAK_COUNT_BITS-1 downto 0);
signal commit_frame:boolean;
--FIXME clear done is never assigned
signal clear_done:boolean;
signal event_lost:boolean;
--signal clear_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
--signal clear_count:unsigned(PEAK_COUNT_BITS-1 downto 0);

-- needs to live in a combinatorial process
procedure bus_we_mux(bus_reg:in streambus_t;
	signal chunk_we_reg:in boolean_vector;
	signal bus_in:in streambus_t;
	signal chunk_we_in:boolean_vector(BUS_CHUNKS-1 downto 0);
	signal mux_bus:out streambus_t;
	signal mux_we:out boolean_vector(BUS_CHUNKS-1 downto 0) 
) is
begin
	for c in BUS_CHUNKS-1 downto 0 loop
		if chunk_we_reg(c) then
			mux_bus.data((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS)
				<= bus_reg.data((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS);
			mux_bus.last(c) <= bus_reg.last(c);
			mux_bus.discard(c) <= bus_reg.last(c);
			mux_we(c) <= TRUE;
		else
			mux_bus.data((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS)
				 <= bus_in.data((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS);
			mux_bus.last(c) <= bus_in.last(c);
			mux_bus.discard(c) <= bus_in.last(c);
			mux_we(c) <= chunk_we_in(c);
		end if;	
	end loop;
end bus_we_mux;

-- needs to live in a sequential process
procedure bus_we_reg(
	signal bus_in:in streambus_t;
	signal chunk_we:in boolean_vector(BUS_CHUNKS-1 downto 0);
	signal bus_reg:inout streambus_t;
	signal chunk_we_reg:inout boolean_vector(BUS_CHUNKS-1 downto 0);
	signal lost:out boolean
) is
begin
	lost <= FALSE;
	for c in BUS_CHUNKS-1 downto 0 loop
    if chunk_we(c) then
      if chunk_we_reg(c) then
        lost <= TRUE;
      else
				bus_reg.data((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS)
					  <= bus_in.data((c+1)*CHUNK_DATABITS-1 downto c*CHUNK_DATABITS);
				chunk_we_reg(c) <= TRUE;
			end if;
		end if;
	end loop;
end bus_we_reg;

begin
measurements <= m; --are the measurements needed externally?
commit <= commit_frame_reg;
mux_overflow <= mux_overflow_int;
start <= start_int;
measurement_overflow <= event_lost;

valueMux:entity work.mca_value_selector
generic map(
  VALUE_BITS => MCA_VALUE_BITS,
  NUM_VALUES => NUM_MCA_VALUE_D,
  NUM_VALIDS => NUM_MCA_TRIGGER_D-1
)
port map(
  clk => clk,
  reset => reset,
  measurements => m,
  value_select => mca_value_select,
  trigger_select => mca_trigger_select,
  value => mca_value,
  valid => mca_value_valid
);

--------------------------------------------------------------------------------
-- Pulse and Peak detection stage
--------------------------------------------------------------------------------
sampleoffset:process(clk)
begin
if rising_edge(clk) then
	sample <= signed('0' & adc_sample) - 
						signed('0' & registers.baseline.offset);
end if;
end process sampleoffset;

baselineEstimator:entity work.baseline_estimator
generic map(
  BASELINE_BITS => BASELINE_BITS,
  COUNTER_BITS => BASELINE_COUNTER_BITS,
  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  MAX_AVERAGE_ORDER => BASELINE_MAX_AV_ORDER,
  OUT_BITS => BASELINE_BITS+BASELINE_AV_FRAC 
)
port map(
  new_only => TRUE,
  clk => clk,
  reset => reset,
  sample => sample,
  sample_valid => TRUE,
  timeconstant => registers.baseline.timeconstant,
  threshold => registers.baseline.threshold,
  count_threshold => registers.baseline.count_threshold,
  average_order => registers.baseline.average_order,
  baseline_estimate => baseline_estimate,
  range_error => baseline_underflow 
);
m.raw.baseline <= baseline_estimate;

baselineSubraction:process(clk)
begin
if rising_edge(clk) then
  if registers.baseline.subtraction then
    stage1_input <= reshape(sample,0,WIDTH,FRAC) - 
           reshape(to_0IfX(baseline_estimate),BASELINE_AV_FRAC,WIDTH,FRAC);		
  else
    stage1_input <= reshape(sample,0,WIDTH,FRAC);	
  end if;
end if;
end process baselineSubraction;

FIR:entity work.two_stage_FIR
generic map(
	WIDTH => 18
)
port map(
  clk => clk,
  sample_in => stage1_input,
  stage1_config_data => filter_config_data,
  stage1_config_valid => filter_config_valid,
  stage1_config_ready => filter_config_ready,
  stage1_reload_data => filter_reload_data,
  stage1_reload_valid => filter_reload_valid,
  stage1_reload_ready => filter_reload_ready,
  stage1_reload_last => filter_reload_last,
  stage1_reload_last_missing => filter_reload_last_missing,
  stage1_reload_last_unexpected => filter_reload_last_unexpected,
  stage2_config_data => dif_config_data,
  stage2_config_valid => dif_config_valid,
  stage2_config_ready => dif_config_ready,
  stage2_reload_data => dif_reload_data,
  stage2_reload_valid => dif_reload_valid,
  stage2_reload_ready => dif_reload_ready,
  stage2_reload_last => dif_reload_last,
  stage2_reload_last_missing => dif_reload_last_missing,
  stage2_reload_last_unexpected => dif_reload_last_unexpected,
  --w=18 f=3
  stage1 => filtered_FIR,
  --w=18 f=8
  stage2 => slope_FIR
);

--TODO add closest for threshxing? used to get slope threshold timiing
--FIXME closest 0xings not good for area						 
slope_threshold <= signed('0' & registers.capture.slope_threshold);
slopeXing:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  AREA_BITS => AREA_SUM_BITS
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_FIR,
  signal_out => slope_pd,
  threshold => slope_threshold,
  pos_threshxing => slope_pos_thresh_xing_pd,
  neg_threshxing => open,
  pos_0xing => open,
  neg_0xing => open,
  pos_0closest => slope_pos_0xing_pd,
  neg_0closest => slope_neg_0xing_pd,
  area => open,
  extrema => open,
  zero_xing => slope_zero_xing_pd
);

filteredXing:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  AREA_BITS => AREA_SUM_BITS
)
port map(
  clk => clk,
  reset => reset,
  signal_in => filtered_FIR,
  signal_out => filtered_pd,
  threshold => pulse_threshold,
  pos_threshxing => filtered_pos_threshxing_pd,
  neg_threshxing => filtered_neg_threshxing_pd,
  pos_0xing => open,
  neg_0xing => open,
  pos_0closest => open,
  neg_0closest => open,
  area => open,
  extrema => open,
  zero_xing => open
);

pdNextstate:process(clk)
begin
	if rising_edge(clk) then
		if cfd_reset then
			pd_state <= WAITING;
			pd_pulse_state <= IDLE;
		else
			pd_state <= pd_nextstate;
			pd_pulse_state <= pd_pulse_nextstate;
		end if;
	end if;
end process pdNextstate;

pdTransition:process(pd_state,slope_neg_0xing_pd,slope_pos_thresh_xing_pd)
begin
	pd_nextstate <= pd_state;
	case pd_state is 
		when WAITING =>
			if slope_pos_thresh_xing_pd then
				pd_nextstate <= ARMED;
			end if;
		when ARMED =>
			if slope_neg_0xing_pd then
				pd_nextstate <= WAITING;
			end if; 
	end case;
end process pdTransition;

pulseTransition:process(pd_pulse_state,filtered_pos_threshxing_pd,
												filtered_neg_threshxing_pd,slope_neg_0xing_pd)
begin
	pd_pulse_nextstate <= pd_pulse_state;
	case pd_pulse_state is 
	when IDLE =>
		if filtered_pos_threshxing_pd then
			pd_pulse_nextstate <= FIRST_RISE;
		end if;
	when FIRST_RISE =>
		if filtered_neg_threshxing_pd  then
			pd_pulse_nextstate <= IDLE;
		elsif slope_neg_0xing_pd then 
			pd_pulse_nextstate <= PEAKED;
		end if;
	when PEAKED =>
		if filtered_neg_threshxing_pd  then
			pd_pulse_nextstate <= IDLE;
		end if;
	end case;
end process pulseTransition;

pulse_start_pd <= pd_pulse_state=IDLE and filtered_pos_threshxing_pd;
pulse_stop_pd <= pd_pulse_state/=IDLE and filtered_neg_threshxing_pd; 
arming_pd <= pd_state=WAITING and slope_pos_thresh_xing_pd;
minima_pd <= slope_pos_0xing_pd and pd_state=WAITING;
peak_pd <= pd_state=ARMED and 
						 (pd_pulse_state/=IDLE or filtered_pos_threshxing_pd) and 
						 slope_neg_0xing_pd;

peakDectection:process(clk)
begin
if rising_edge(clk) then
  if cfd_reset then
    last_minima_value <= (others => '0');
    pulse_length <= to_unsigned(1,TIME_BITS-TIME_FRAC);
    queue_wr_en <= '0';
    peak_count_pd <= (others => '0');
    capture_pd <= registers.capture;
		pulse_threshold <= (WIDTH-1 => '0', others=>'1');
  else
    
    if minima_pd then	
      last_minima_value <= filtered_pd;	
      capture_pd <= registers.capture;
      if registers.capture.threshold_rel2min and pd_pulse_state=IDLE then
        pulse_threshold 
          <= filtered_pd + signed('0' & registers.capture.pulse_threshold);
      else
        pulse_threshold <= signed('0' & registers.capture.pulse_threshold);
      end if;
    end if;
    
    if arming_pd then 
    	minima_value_pd <= last_minima_value;
    end if;
    
    if peak_pd then
      minima_for_cfd <= minima_value_pd;
      maxima_for_cfd <= filtered_pd;
      if pd_pulse_state=FIRST_RISE and not capture_pd.cfd_rel2min then
        signal_for_cfd <= filtered_pd;
      else
        signal_for_cfd <= filtered_pd-minima_value_pd;
      end if;
    end if;
     
    -- multiplier pipeline
    peak_pipe <= shift(peak_pd,peak_pipe);
    first_rise_pipe <= shift(pd_pulse_state=FIRST_RISE,first_rise_pipe);
     -- absorbed into multiplier macro
    cf_of_peak_reg 
      <= signal_for_cfd*signed('0' & capture_pd.constant_fraction);
    cf_of_peak_reg2 <= cf_of_peak_reg;
    cf_of_peak <= cf_of_peak_reg2;
   
    if peak_pipe(MULT_PIPE_DEPTH) then
      if queue_full='0' then
        queue_overflow <= FALSE;
        queue_wr_en <= '1';
        --FIXME this will fail if pulse ends within 4 clocks of peak
        if first_rise_pipe(MULT_PIPE_DEPTH) and 
           not capture_pd.cfd_rel2min then
          cfd_low_thresh_pd 
            <= resize(shift_right(cf_of_peak,CFD_FRAC),WIDTH);
        else
          cfd_low_thresh_pd 
            <= resize(shift_right(cf_of_peak,CFD_FRAC),WIDTH)+minima_for_cfd;
        end if;
        cfd_high_thresh_pd 
          <= maxima_for_cfd-resize(shift_right(cf_of_peak,CFD_FRAC),WIDTH);
      else
        queue_overflow <= TRUE;
       end if;
    else
      queue_overflow <= FALSE;
      queue_wr_en <= '0';
    end if;
  end if;
end if;
end process peakDectection;

--------------------------------------------------------------------------------
-- Queues and delays to CFD stage
--------------------------------------------------------------------------------
cfdLowQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => to_std_logic(cfd_reset),
  din => to_std_logic(cfd_low_thresh_pd),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => cfd_low_queue_dout,
  full => queue_full,
  empty => queue_empty
);

cfdHighQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => to_std_logic(cfd_reset),
  din => to_std_logic(cfd_high_thresh_pd),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => cfd_high_queue_dout,
  full => open,
  empty => open
);

minimaQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => to_std_logic(cfd_reset),
  din => to_std_logic(minima_for_cfd),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => minima_queue_dout,
  full => open,
  empty => open
);

flagsReg:process (clk) is
begin
	if rising_edge(clk) then
    flags_pd <= (to_std_logic(minima_pd),
                 to_std_logic(slope_neg_0xing_pd), 
                 to_std_logic(pulse_start_pd),
                 to_std_logic(pulse_stop_pd),
                 to_std_logic(peak_pd),
                 to_std_logic(slope_pos_0xing_pd),
                 to_std_logic(slope_pos_thresh_xing_pd) 
                );
	end if;
end process flagsReg;


-- TODO make this break the delays up into 64 bit lots with a reg at the end 
flagsCFDdelay:entity work.dynamic_RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => NUM_FLAGS
)
port map(
  clk => clk,
  data_in => flags_pd,
  delay => CFD_DELAY+2, -- was +3 before flagsReg added
  delayed => flags_cfd_delay
);

minima_cfd <= to_boolean(flags_cfd_delay(6));
slope_neg_0xing_cfd <= to_boolean(flags_cfd_delay(5));
pulse_start_cfd <= to_boolean(flags_cfd_delay(4));
pulse_end_cfd <= to_boolean(flags_cfd_delay(3));
peak_cfd <= to_boolean(flags_cfd_delay(2));
slope_pos_0xing_cfd <= to_boolean(flags_cfd_delay(1));
-- FIXME make this a closest xing?
slope_pos_thresh_xing_cfd <= to_boolean(flags_cfd_delay(0));


--TODO change to sdp_ram_delay
signalCFDdelay:entity work.dynamic_RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => to_std_logic(filtered_pd),
  delay => CFD_DELAY,
  delayed => filtered_cfd_delay
);

slopeCFDdelay:entity work.dynamic_RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => to_std_logic(slope_pd),
  delay => CFD_DELAY,
  delayed => slope_cfd_delay
);

rawCDFdelay:entity work.dynamic_RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => to_std_logic(stage1_input),
  delay => CFD_DELAY+FIR_DELAY,
  delayed => raw_cfd_delay
);

--------------------------------------------------------------------------------
-- Measurements and crossing detectors @ CFD delay
--------------------------------------------------------------------------------
rawMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  AREA_BITS => AREA_SUM_BITS
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(raw_cfd_delay),
  signal_out => raw_cfd,
  threshold => (others => '0'),
  pos_threshxing => open,
  neg_threshxing => open,
  pos_0xing => open,
  neg_0xing => open,
  pos_0closest => open,
  neg_0closest => open,
  area => raw_area,
  extrema => raw_extrema,
  zero_xing => raw_zero_xing
);

filteredMeasurements:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  AREA_BITS => AREA_SUM_BITS
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(filtered_cfd_delay),
  threshold => (others => '0'),
  signal_out => filtered_cfd,
  pos_threshxing => open, --pulse_start,
  neg_threshxing => open, --pulse_stop,
  pos_0xing => open,
  neg_0xing => open,
  area => filtered_area,
  extrema => filtered_extrema,
  zero_xing => filtered_zero_xing
);

slopeMeasurements:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  AREA_BITS => AREA_SUM_BITS
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(slope_cfd_delay),
  threshold => (others => '0'),
  signal_out => slope_cfd,
  pos_0xing => open,
  neg_0xing => open,
  pos_threshxing => open,
  neg_threshxing => open,
  pos_0closest => open,
  neg_0closest => open,
  area => slope_area,
  extrema => slope_extrema,
  zero_xing => slope_zero_xing
);


-- FIXME are these going to have the correct latency?
cfdLowXing:entity work.closest_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  signal_in => signed(filtered_cfd_delay),
  threshold => cfd_low_threshold,
  signal_out => open,
  pos => cfd_low_xing,
  neg => open
);

cfdHighXing:entity work.closest_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  signal_in => signed(filtered_cfd_delay),
  threshold => cfd_high_threshold,
  signal_out => open,
  pos => cfd_high_xing,
  neg => open
);

--------------------------------------------------------------------------------
-- CFD stage
--------------------------------------------------------------------------------
-- signal_cfd_reg2 is 1 clock before signal_cfd
-- equivalent register removal should optimise this and equate with the 
-- registers inside fiteredMeasurement and cfdXing.
signalCFDreg:process(clk)
begin
	if rising_edge(clk) then
		filtered_cfd_reg <= signed(filtered_cfd_delay);
		filtered_cfd_reg2 <= filtered_cfd_reg;
		filtered_is_min <= to_0ifX(filtered_cfd_reg2)=to_0IfX(minima_value_cfd);
	end if;
end process signalCFDreg;

cfdFSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if cfd_reset then
			cfd_state <= IDLE;
			cfd_pulse_state <= IDLE;
		else
			cfd_state <= cfd_nextstate;
			cfd_pulse_state <= cfd_pulse_nextstate;
		end if;
	end if;
end process cfdFSMnextstate;

cfdFSMtransition:process(peak_cfd,queue_empty,cfd_state,minima_valid)
begin
	cfd_nextstate <= cfd_state;
	case cfd_state is 
	when IDLE =>
		if queue_empty='0' then
			cfd_nextstate <= WAIT_MIN;
		end if;
	when WAIT_MIN =>
		if minima_valid then
			cfd_nextstate <= WAIT_PEAK;
		end if;
	when WAIT_PEAK =>
		if peak_cfd then
			cfd_nextstate <= IDLE;
		end if;
	end case;
end process cfdFSMtransition;

cfdPulseFSMtransition:process(cfd_pulse_state,peak_cfd,pulse_end_cfd,
															peak_start_cfd)
begin
	cfd_pulse_nextstate <= cfd_pulse_state;
	case cfd_pulse_state is 
	when IDLE =>
		if peak_start_cfd then
			cfd_pulse_nextstate <= FIRST_RISE;
		end if;
	when FIRST_RISE =>
		if peak_cfd then
			cfd_pulse_nextstate <= PEAKED;
		end if;
	when PEAKED =>
		if pulse_end_cfd then
			cfd_pulse_nextstate <= IDLE;
		end if;
	end case;
end process cfdPulseFSMtransition;

cfd_low <= cfd_low_xing and cfd_state/=IDLE;
cfd_high <= cfd_high_xing and cfd_state/=IDLE;
cfd_high_done <= cfd_high_crossed or (peak_cfd and cfd_high_xing);
cfd_low_done <= cfd_high_crossed or (peak_cfd and cfd_high_xing);
cfd_error_int <= (peak_cfd and not (cfd_low_done and cfd_high_done)) 
									or queue_overflow;
									
peaks_full <= m.peak_count > '0' & capture_cfd.max_peaks;
--FIXME this has problems when peaks_full
--clear_done <= clear_count >= '0' & capture_cfd.max_peaks;
--FIXME The CFD process will not work properly on arbitrary signals. With some 
--further thought I think it could. Meanwhile this should be OK for TES signals.
minima_valid <= minima_cfd and filtered_is_min;
peak_start_cfd <= minima_valid and cfd_state=WAIT_MIN;
event_start_cfd <= peak_start_cfd and cfd_pulse_state=IDLE; --FIXME is this correct?
pulse_end <= m.pulse.neg_threshxing and cfd_pulse_state=PEAKED;

triggerMux:process(
	capture_cfd.timing,cfd_low,pulse_start_cfd,slope_pos_thresh_xing_cfd,
	cfd_pulse_state,event_start_cfd
) 
begin
	case capture_cfd.timing is
	when PULSE_THRESH_TIMING_D => 
		if cfd_pulse_state=FIRST_RISE then
			trigger_cfd <= pulse_start_cfd;
		else
			trigger_cfd <= cfd_low;
		end if;

  when SLOPE_THRESH_TIMING_D =>
  	trigger_cfd <= slope_pos_thresh_xing_cfd;
  	
  when CFD_LOW_TIMING_D =>
  	trigger_cfd <= cfd_low;
  	
  when CFD_HIGH_TIMING_D =>
  	trigger_cfd <= event_start_cfd;
  	
	end case;
end process triggerMux;

constantFraction:process(clk)
begin
	if rising_edge(clk) then
    if cfd_state=IDLE and queue_empty='0' then
      queue_rd_en <= '1';
      cfd_low_threshold <= signed(cfd_low_queue_dout);
      cfd_high_threshold <= signed(cfd_high_queue_dout);
      minima_value_cfd <= signed(minima_queue_dout);
    else
      queue_rd_en <= '0';
    end if;
   
    if cfd_state=IDLE then
      cfd_low_crossed <= FALSE;
      cfd_high_crossed <= FALSE;
    end if;

    if cfd_low then
      cfd_low_crossed <= TRUE;
    end if;

    if cfd_high then
      cfd_high_crossed <= TRUE;
    end if; 

    cfd_error <= cfd_error_int;
    cfd_reset <= cfd_error_int or reset='1';
  end if;
end process constantFraction;

pulseMeasurement:process(clk)
begin
if rising_edge(clk) then
	if reset = '1' then
		pulse_extrema <= (others => '0');
		pulse_area <= (others => '0');
 		m.pulse.start_time <= (others => '0');
		capture_cfd <= registers.capture;
		m.peak_count <= (others => '0');
	else
		
		m.event_start <= event_start_cfd;
		if event_start_cfd then --FIXME this should change on valid minima??
			capture_cfd <= capture_pd; -- FIXME this is not going to work correctly
																 -- use extra flags and delay
			--for framer
	    last_pulse_peak_addr 
    		<= resize(capture_pd.max_peaks+2,FRAMER_ADDRESS_BITS+1);
    	last_trace_peak_addr 
    		<= resize(capture_pd.max_peaks+3,FRAMER_ADDRESS_BITS+1);
			--last_peak_count <= capture_pd.max_peaks(PEAK_COUNT_BITS-1 downto 0);
		end if;
 		
		if trigger_cfd then 
			if mux_full then
				mux_overflow_int <= TRUE;
			else
				if capture_cfd.detection /= PEAK_DETECTION_D then
					start_int <= cfd_pulse_state = FIRST_RISE;
				else
					start_int <= TRUE;
				end if;
			end if;
		else
			start_int <= FALSE;
 		end if; 
  	m.trigger <= trigger_cfd;	
  	if trigger_cfd then
  		m.trigger_time <= (others => '0');
  	else
  		m.trigger_time <= m.trigger_time+1;
  	end if;
  	
  	time_overflow <= FALSE;	
  	if pulse_start_cfd then
      m.pulse.start_time <= (others => '0');
    else
      if m.pulse.start_time=to_unsigned(2**TIME_BITS-1,TIME_BITS) then
        time_overflow <= TRUE;
      else
        m.pulse.start_time <= m.pulse.start_time+1;
      end if;
    end if;
  	
  	--FIXME clean up the registration and delay lines
		m.peak <= peak_cfd;
    m.peak_start <= peak_start_cfd;
    if event_start_cfd then
    	m.event_time <= (others => '0');
    else
    	m.event_time <= m.event_time+1;
    end if;
  	
    case capture_cfd.height is
    when PEAK_HEIGHT_D =>
    	m.height_valid <= peak_cfd;

    when CFD_HEIGHT_D =>
    	m.height_valid <= cfd_high;

    when SLOPE_INTEGRAL_D =>
    	if slope_zero_xing and cfd_state=WAIT_PEAK then
    		m.height_valid <= TRUE;
        m.height <= reshape(slope_area,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
      else
    		m.height_valid <= FALSE;
      end if;
    end case;
  	
 		peak_overflow <= peak_cfd and peaks_full; 
  	if event_start_cfd then
  		m.peak_count <= (others => '0'); 
      pulse_peak_addr <= to_unsigned(2,FRAMER_ADDRESS_BITS);
      trace_peak_addr <= to_unsigned(3,FRAMER_ADDRESS_BITS);
  	else
  		if peak_cfd and not peaks_full then
  			if m.peak_count /= 
  					to_unsigned(2**PEAK_COUNT_BITS-1,PEAK_COUNT_BITS) then
  				m.peak_count <= m.peak_count + 1;	
  			end if;
      	if not peaks_full then
        	pulse_peak_addr <= resize(m.peak_count + 1 + 2,FRAMER_ADDRESS_BITS);
        	trace_peak_addr <= resize(m.peak_count + 1 + 3,FRAMER_ADDRESS_BITS);
        end if;
      end if;
  	end if;
  		
  	if pulse_start_cfd then
  		pulse_area <= resize(filtered_cfd,AREA_SUM_BITS);
  		pulse_extrema <= filtered_cfd; 
  	else
  		if filtered_cfd > pulse_extrema then
  			pulse_extrema <= filtered_cfd;
  		end if;
  		pulse_area <= pulse_area+filtered_cfd;
--  		area_above_threshold  --FIXME out of sync
--  			<= to_0ifX(pulse_area) < 
--  				 resize(capture_cfd.area_threshold,AREA_SUM_BITS);
  	end if;
  	
  	--FIXME these no longer need to registered	
    if capture_cfd.height_rel2min then 
      m.height <= reshape(filtered_cfd-minima_value_cfd,
                          FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    else
      m.height <= reshape(filtered_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    end if;
    
    m.cfd_low <= cfd_low;
    m.cfd_high <= cfd_high;
    
    --measurements.event_start <= min_valid and cfd_state=WAIT_MIN;
    m.pulse.area <= reshape(pulse_area,FRAC,AREA_BITS,AREA_FRAC);
    m.pulse.area_above_threshold <= area_above_threshold;
    m.pulse.extrema <= reshape(pulse_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    
    m.pulse.pos_threshxing <= pulse_start_cfd;
    m.pulse.neg_threshxing <= pulse_end_cfd;
  	
    m.raw.zero_xing <= raw_zero_xing;
    m.raw.area <= reshape(raw_area,FRAC,AREA_BITS,AREA_FRAC);
    m.raw.extrema <= reshape(raw_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    m.raw.sample <= reshape(raw_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    
    m.filtered.sample <= reshape(filtered_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    m.filtered.extrema 
    	<= reshape(filtered_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
  	m.filtered.area <= reshape(filtered_area,FRAC,AREA_BITS,AREA_FRAC);
  	m.filtered.zero_xing <= filtered_zero_xing;
  	
    m.slope.sample <= reshape(slope_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    m.slope.extrema <= reshape(slope_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
  	m.slope.area <= reshape(slope_area,AREA_FRAC,AREA_BITS,FRAC);
  	m.slope.zero_xing <= slope_zero_xing;	
    m.slope.neg_0xing <= slope_neg_0xing_cfd; 
    m.slope.pos_0xing <= slope_pos_0xing_cfd;
    m.slope.pos_threshxing <= slope_pos_thresh_xing_cfd;
  end if;
end if;
end process pulseMeasurement;

area_above_threshold 
	<= to_0ifX(pulse_area) >= 
		 reshape(capture_cfd.area_threshold,AREA_FRAC,AREA_SUM_BITS,FRAC);

--------------------------------------------------------------------------------
-- Framer stage
--------------------------------------------------------------------------------
-- NOTE if the frame is dumped old values are still in memory but not put in the 
-- stream, so need to make sure that old values don't propagate in next frame
-- by making sure that that each BUS_CHUNK is written to each frame.

-- flags common to all events
detection_flags.channel <= to_unsigned(CHANNEL,CHANNEL_BITS);
detection_flags.event_type.detection <= capture_cfd.detection;
detection_flags.event_type.tick <= FALSE;
detection_flags.peak_overflow <= capture_cfd.height_rel2min;
detection_flags.timing <= capture_cfd.timing;
detection_flags.peak_count <= m.peak_count(PEAK_COUNT_BITS-1 downto 0)-1;
detection_flags.height <= capture_cfd.height;
--peak event
peak_event.height <= m.height; 
peak_event_we(3) <= m.height_valid; 
peak_event.minima <= m.filtered.sample;
peak_event_we(2) <= m.peak_start;
peak_event.flags <= detection_flags;
peak_event_we(1) <= m.peak_start; 
peak_event_we(0) <= m.height_valid;
commit_peak_event <= m.height_valid;
--area event
area_event.area <= m.pulse.area;
area_event.flags <= detection_flags;
area_event_we <= (others => m.pulse.neg_threshxing);
commit_area_event <= m.pulse.neg_threshxing and m.pulse.area_above_threshold;
area_dump <= m.pulse.neg_threshxing and not m.pulse.area_above_threshold;
--pulse event
pulse_header.flags <= header_flags;
pulse_header.slope_threshold <= header_slope_threshold;
pulse_header.reserved <= header_pulse_threshold;
pulse_peak.height <= m.filtered.sample;
pulse_peak_we(3) <= m.height_valid;
pulse_peak.minima <= m.filtered.sample;
pulse_peak_we(2) <= m.peak_start;
pulse_peak.rise_time <= m.trigger_time;
pulse_peak_we(1) <= m.height_valid;
pulse_peak.rel_timestamp <= m.event_time; 
pulse_peak_we(0) <= m.trigger;
pulse_peak_bus <= to_streambus(pulse_peak,pulse_peak_last,ENDIANNESS);
--trace event
trace_header.detection_flags <= header_flags;
trace_header.slope_threshold <= header_slope_threshold;
trace_header.pulse_threshold <= header_pulse_threshold;
trace_header.trace_flags.trace0 <= capture_cfd.trace0;
trace_header.trace_flags.trace1 <= capture_cfd.trace1;
trace_header.trace_flags.max_peaks <= capture_cfd.max_peaks;
trace_header.trace_flags.full <= capture_cfd.full_trace;
trace_peak.min_idx <= m.event_time;
trace_peak_we(3) <= m.peak_start;
trace_peak.height_idx <= m.event_time;
trace_peak_we(2) <= m.height_valid;
trace_peak.peak_idx <= m.event_time;
trace_peak_we(1) <= m.peak;
trace_peak.trigger_idx <= m.event_time;
trace_peak_we(0) <= m.trigger;
trace_peak_bus <= to_streambus(trace_peak,ENDIANNESS);

--------------------------------------------------------------------------------
-- Framer FSMs
--------------------------------------------------------------------------------
FSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			event_state <= IDLE;
			pulse_state <= IDLE;
			trace_state <= IDLE;
		else
			event_state <= event_nextstate;
			pulse_state <= pulse_nextstate;
			trace_state  <= trace_nextstate;
		end if;
	end if;
end process FSMnextstate;

eventFSMtransition:process(event_state,m.peak_start,start_int,cfd_error_int,
												   commit_frame,dump_int
)
begin
	event_nextstate <= event_state;
	case event_state is 
	when IDLE =>
		if start_int then
			event_nextstate <= QUEUED;
		elsif m.peak_start then -- event_start???
			event_nextstate <= STARTED;
		end if; 
	when STARTED =>
		if cfd_error_int then
			event_nextstate <= IDLE;
		elsif start_int then
			event_nextstate <= QUEUED;
		end if; 
	when QUEUED =>
		if commit_frame or dump_int then
			event_nextstate <= IDLE;
		end if;
	end case;
end process eventFSMtransition;

headers:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			header_valid <= FALSE;
		else
			
			event_lost <= FALSE;
			
			if commit_frame or dump_int then 
				header_valid <= FALSE;
			end if;
		
			if capture_cfd.detection=PULSE_DETECTION_D or 
				 capture_cfd.detection=TRACE_DETECTION_D then
        if m.trigger then 
          
          if header_valid then
            event_lost <= TRUE; -- FIXME expose this
          else
            trace_header.offset <= m.event_time;
          end if;
          
        elsif m.pulse.neg_threshxing then

          if header_valid then 
            event_lost <= TRUE; --TODO: check if need to dump
            header_valid <= FALSE;
          elsif  m.pulse.area_above_threshold then
            header_valid <= TRUE;
            
            header_flags <= detection_flags;
            --FIXME threshold broken
            header_pulse_threshold <= reshape(
              capture_cfd.pulse_threshold,CFD_FRAC,SIGNAL_BITS,SIGNAL_FRAC
            );
            header_slope_threshold <= reshape(
              capture_cfd.slope_threshold,CFD_FRAC,SIGNAL_BITS,SIGNAL_FRAC
            );
            
            -- pulse header
            pulse_header.size <= resize(capture_cfd.max_peaks+3,SIZE_BITS);
            pulse_header.length <= m.event_time+1;
            pulse_header.area <= m.pulse.area;
            
            -- trace header
            trace_header.size <= resize(trace_address-1,SIZE_BITS);
            trace_header.length <= m.event_time+1;
            trace_header.area <= m.pulse.area;
          end if;
          
        end if;
        
      end if;
			
		end if;
	end if;
end process headers;

addressCounters:process(clk)
begin
	if rising_edge(clk) then
		
		if pulse_state=CLEAR then
			pulse_peak_clear_addr <= pulse_peak_clear_addr+1;
		else 
      pulse_peak_clear_addr <= pulse_peak_addr;
    end if;
    
		if trace_state=CLEAR then
			trace_peak_clear_addr <= trace_peak_clear_addr+1;
		else
			trace_peak_clear_addr <= resize(m.peak_count+3,FRAMER_ADDRESS_BITS);
		end if;
		
	end if;
end process addressCounters;

pulse_peak_last <= pulse_peak_clear_addr = last_pulse_peak_addr;
trace_peak_last <= trace_peak_clear_addr = last_trace_peak_addr;

--------------------------------------------------------------------------------
-- Pulse events
--------------------------------------------------------------------------------
-- interim registers for peak point data and pulse headers
pulsePeakreg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	pulse_peak_we_reg <= (others => FALSE);
  	pulse_peak_lost <= FALSE;
  else
  	
  	-- FIXME this may break on event_type change
  	if (capture_cfd.detection=PULSE_DETECTION_D and pulse_state=PEAKS) then 
	    pulse_peak_we_reg <= (others => FALSE);
	  	pulse_peak_lost <= FALSE;
  	else
  		
      -- NOTE this registration is to handle the case were a peak data point
      -- just after the end of a trace while clearing or writing the header.
  		
      bus_we_reg(
        pulse_peak_bus,
        pulse_peak_we,
        pulse_peak_bus_reg,
        pulse_peak_we_reg,
        pulse_peak_lost
      );
  		
  	end if;
  end if;
end if;
end process pulsePeakreg;

pulsePeakMux:process(pulse_peak_lost,pulse_peak_we,pulse_peak_we_reg,
	pulse_peak_bus,pulse_peak_bus_reg
)
begin
	
	if not pulse_peak_lost then
		
		bus_we_mux(
			pulse_peak_bus_reg,
			pulse_peak_we_reg,
			pulse_peak_bus,
			pulse_peak_we,
			pulse_peak_bus_mux,
			pulse_peak_we_mux
		);
		
	else
		pulse_peak_bus_mux.data <= (others  => '-');
		pulse_peak_bus_mux.last <= (others  => FALSE);
		pulse_peak_bus_mux.discard <= (others  => FALSE);
		pulse_peak_we_mux <= (others  => FALSE);
	end if;
end process pulsePeakMux;

pulseEventFSMtransition:process(pulse_state,header_valid,m.pulse.neg_threshxing,
	dump_int,peak_start_cfd,pulse_peak_last,peaks_full
)
begin
	pulse_nextstate <= pulse_state;
	case pulse_state is 
	when IDLE => 
		if peak_start_cfd then
			pulse_nextstate <= PEAKS;
		end if;
		
	when HEADER0 =>
		if header_valid then
			pulse_nextstate <= HEADER1;
		end if;

  when HEADER1 =>
  	pulse_nextstate <= IDLE;
  	--FIXME handle dump here too?
  	
  when PEAKS =>
  	if dump_int then
  		pulse_nextstate <= IDLE;
  	elsif m.pulse.neg_threshxing then
  		if peaks_full then
  			pulse_nextstate <= HEADER0;
  		else
  			pulse_nextstate <= CLEAR;
  		end if;
  	end if;
  	
  when CLEAR =>
  	if pulse_peak_last then
  		pulse_nextstate <= HEADER0;
  	end if;
	end case;
end process pulseEventFSMtransition;

--------------------------------------------------------------------------------
-- Trace events
--------------------------------------------------------------------------------
dual_trace <= capture_cfd.trace0/=NO_TRACE_D and capture_cfd.trace1/=NO_TRACE_D;

-- input mux for different trace signals
traceInputMux:process(capture_cfd.trace0,capture_cfd.trace1,
								 m.filtered.sample,m.raw.sample,m.slope.sample)
begin
	
  case capture_cfd.trace0 is
  when NO_TRACE_D =>
  	trace0 <= (others => '-');
  when FILTERED_TRACE_D =>
    trace0 <= set_endianness(m.filtered.sample,ENDIANNESS);
  when SLOPE_TRACE_D =>
    trace0 <= set_endianness(m.slope.sample,ENDIANNESS);
  when RAW_TRACE_D =>
    trace0 <= set_endianness(m.raw.sample,ENDIANNESS);
  end case;	
  
  case capture_cfd.trace1 is
  when NO_TRACE_D =>
  	trace1 <= (others => '-');
  when FILTERED_TRACE_D =>
    trace1 <= set_endianness(m.filtered.sample,ENDIANNESS);
  when SLOPE_TRACE_D =>
    trace1 <= set_endianness(m.slope.sample,ENDIANNESS);
  when RAW_TRACE_D =>
    trace1 <= set_endianness(m.raw.sample,ENDIANNESS);
  end case;	
  
end process traceInputMux;

-- interim registers for peak data
tracePeakreg:process(clk)
begin
if rising_edge(clk) then
	if reset = '1' then
		trace_peak_bus_reg.data <= (others => '-');
		trace_peak_bus_reg.discard <= (others => FALSE);
		trace_peak_bus_reg.last <= (others => FALSE);
  	trace_peak_we_reg <= (others => FALSE);
  	trace_peak_lost <= FALSE;
  else
  	
  	-- FIXME this may break on event_type change
  	if (capture_cfd.detection=TRACE_DETECTION_D and trace_state=PEAKS) then 
	    trace_peak_we_reg <= (others => FALSE);
	  	trace_peak_lost <= FALSE;
  	else
  		
      -- NOTE these registers handle the case were a peak data point
      -- occurs when writing a trace data word, or just after the end of a trace
      -- while clearing or writing the header.
      
  		bus_we_reg(
  			trace_peak_bus,
  			trace_peak_we,
  			trace_peak_bus_reg,
  			trace_peak_we_reg,
  			trace_peak_lost
  		);
  		
  	end if;
  end if;
end if;
end process tracePeakreg;

tracePeakMux:process(trace_peak_lost,trace_peak_we,trace_peak_we_reg,
	trace_peak_bus,trace_peak_bus_reg
)
begin
	
	if not trace_peak_lost then
		
		bus_we_mux(
			trace_peak_bus_reg,
			trace_peak_we_reg,
			trace_peak_bus,
			trace_peak_we,
			trace_peak_bus_mux,
			trace_peak_we_mux
		);
		
	else
		trace_peak_bus_mux.data <= (others  => '-');
		trace_peak_bus_mux.last <= (others  => FALSE);
		trace_peak_bus_mux.discard <= (others  => FALSE);
		trace_peak_we_mux <= (others  => FALSE);
	end if;
end process tracePeakMux;

traceStartStop:process(capture_cfd.full_trace,m.peak,peak_start_cfd,
	event_start_cfd,m.pulse.neg_threshxing
)
begin
	if capture_cfd.full_trace then
		trace_start <= event_start_cfd;
		trace_stop <= m.pulse.neg_threshxing;
	else
		trace_start <= peak_start_cfd;
		trace_stop <= m.peak;
	end if;
end process traceStartStop;

-- capture traces into a bus word
traceCapture:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    trace0_count <= (others => '0');
    trace1_count <= to_unsigned(1,ceilLog2(BUS_CHUNKS));
    trace_done <= FALSE;
    capture_trace <= FALSE;
  else
  	
  	if trace_start then
  		capture_trace <= TRUE;
  		trace_done <= FALSE;
  	elsif trace_stop then
  		capture_trace <= FALSE;
  	end if;
  	
  	if pulse_end_cfd then
  		trace_done <= TRUE;
  	end if;

  	if peak_start_cfd and cfd_pulse_state=IDLE then
  		trace_address <= resize(capture_cfd.max_peaks+4,FRAMER_ADDRESS_BITS);
      trace0_count <= (others => '0');
      trace1_count <= to_unsigned(1,ceilLog2(BUS_CHUNKS));
    else
    	
    	if trace_state=TRACE then
    		trace_address <= trace_address+1;
    	end if;
    		
    	if capture_trace then
	  		trace0_count <= trace0_count+1+to_unsigned(dual_trace);
	  		trace1_count <= trace1_count+2;
	  		
        if dual_trace then 
          trace_reg(to_integer(trace0_count)) <= trace0;
          trace_reg(to_integer(trace1_count)) <= trace1;
        else
          trace_reg(to_integer(trace0_count)) <= trace0;      
        end if;
        
      end if;
  	end if;
  	
  end if;
end if;
end process traceCapture;

write_trace <= capture_trace and (
	(not dual_trace and trace0_count=BUS_CHUNKS-1) or 
	(dual_trace and trace1_count=BUS_CHUNKS-1)	
);

--FIXME wire up dump properly
traceEventFSMtransition:process(peaks_full,clear_done,header_valid,dump_int, 
	trace_start, trace_state,trace_done,write_trace)
begin
	trace_nextstate <= trace_state;
	case trace_state is 
	when IDLE => 
		if trace_start then
			trace_nextstate <= PEAKS;
		end if;
		
	when HEADER0 =>
		if header_valid then
			trace_nextstate <= HEADER1;
		end if;
		
  when HEADER1 =>
  	trace_nextstate <= HEADER2;
  	
  when HEADER2 =>
  	trace_nextstate <= IDLE;
  	
  when PEAKS =>
  	if dump_int then
  		trace_nextstate <= IDLE;
  	elsif write_trace or trace_done then
  		trace_nextstate <= TRACE;
  	end if;
  	
  when TRACE =>
  	if dump_int then
  		trace_nextstate <= IDLE;
  	elsif trace_done then
      if peaks_full then
      	trace_nextstate <= HEADER0;
      else
  			trace_nextstate <= CLEAR;
  		end if;
  	else
  		trace_nextstate <= PEAKS; 
  	end if;
  	
  when CLEAR =>
  	if clear_done then
  		trace_nextstate <= HEADER0;
  	end if;
  	
	end case;
end process traceEventFSMtransition;

--------------------------------------------------------------------------------
-- Framer control registers
--------------------------------------------------------------------------------
framer_overflow <= frame_overflow;

--FIXME this needs to be registered

framerCtlMux:process(clk)
begin
	if rising_edge(clk) then
		if reset='1' then
			commit_frame <= FALSE;
			frame_word.data <= (others => '-');
			frame_word.last <= (others => FALSE);
			frame_word.discard <= (others => FALSE);
			frame_address <= (others => '-');
			frame_length <= (others => '-');
			frame_we <= (others => FALSE);
		else
      case capture_cfd.detection is
      when PEAK_DETECTION_D =>
        commit_frame <= commit_peak_event;
        frame_word <= to_streambus(peak_event,ENDIANNESS);
        frame_address <= (others => '0');
        frame_length <= (0 => '1', others => '0');
        frame_we <= peak_event_we;
        
      when AREA_DETECTION_D =>
        commit_frame <= commit_area_event;
        frame_word <= to_streambus(area_event,ENDIANNESS);
        frame_address <= (others => '0');
        frame_length <= (0 => '1', others => '0');
        frame_we <= area_event_we;
        
      when PULSE_DETECTION_D =>
        case pulse_state is
        when IDLE =>
          commit_frame <= FALSE;
          frame_word.data <= (others => '-');
          frame_word.discard <= (others => FALSE);
          frame_word.last <= (others => FALSE);
          frame_address <= (others => '-');
          frame_length <= (others => '-');
          frame_we <= (others => FALSE);
          
        when PEAKS =>
          commit_frame <= FALSE;
          frame_word <= pulse_peak_bus_mux; 
          frame_address <= pulse_peak_addr;
          if peaks_full then
            frame_we <= (others => FALSE);
          else
            frame_we <= pulse_peak_we_mux;
          end if;
          frame_length <= (others => '-');
          
        when HEADER0 =>
          commit_frame <= FALSE;
          frame_word <= to_streambus(pulse_header,0,ENDIANNESS);
          frame_address <= (others => '0');
          frame_we <= (others => header_valid);
          frame_length <= (others => '-');
          
        when HEADER1 =>
          commit_frame <= TRUE;
          frame_word <= to_streambus(pulse_header,1,ENDIANNESS);
          frame_address <= (0 => '1', others => '0');
          frame_we <= (others => TRUE);
          frame_length <= last_pulse_peak_addr + 1;
          
        when CLEAR =>
          commit_frame <= FALSE;
          frame_word.data <= (others => '-');
          frame_word.discard <= (others => FALSE);
          frame_word.last <= (0 => pulse_peak_last, others => FALSE);
          frame_address <= pulse_peak_clear_addr;
          frame_we <= (others => TRUE);
          frame_length <= (others => '-');
        end case;	
        
      when TRACE_DETECTION_D =>
        case trace_state is
        when IDLE =>
          commit_frame <= FALSE;
          frame_word.data <= (others => '-');
          frame_word.discard <= (others => FALSE);
          frame_word.last <= (others => FALSE);
          frame_address <= (others => '-');
          frame_length <= (others => '-');
          frame_we <= (others => FALSE);
          
        when HEADER0 =>
          commit_frame <= FALSE;
          frame_word <= to_streambus(trace_header,0,ENDIANNESS);
          frame_address <= (others => '0');
          frame_we <= (others => header_valid);
          frame_length <= (others => '-');
          
        when HEADER1 =>
          commit_frame <= FALSE;
          frame_word <= to_streambus(trace_header,1,ENDIANNESS);
          frame_address <= (0 => '1',others => '0');
          frame_we <= (others => TRUE);
          frame_length <= (others => '-');
          
        when HEADER2 =>
          commit_frame <= TRUE;
          frame_word <= to_streambus(trace_header,2,ENDIANNESS);
          frame_address <= (1 => '1',others => '0');
          frame_we <= (others => TRUE);
          frame_length <= '0' & trace_address;
          
        when PEAKS =>
          commit_frame <= FALSE;
          frame_word <= trace_peak_bus_mux; 
          frame_address <= trace_peak_addr;
          if peaks_full then
            frame_we <= (others => FALSE);
          else
            frame_we <= trace_peak_we_mux;
          end if;
          frame_length <= (others => '-');
          
        when TRACE =>
          commit_frame <= FALSE;
          frame_word <= to_streambus(trace_reg,
            (others => FALSE), 
            (0 => trace_done, others => FALSE)
          ); 
          frame_address <= trace_address;
          frame_we <= (others => TRUE);
          frame_length <= (others => '-');
          
        when CLEAR =>
          commit_frame <= FALSE;
          frame_word.data <= (others => '-');
          frame_word.discard <= (others => FALSE);
          frame_word.last <= (others => FALSE);
          frame_address <= trace_peak_clear_addr;
          frame_we <= (others => TRUE);
          frame_length <= (others => '-');
          
        end case;
      end case;
    end if;
  end if;
end process framerCtlMux;

dump_int <= frame_overflow or area_dump or cfd_error_int;
frameCtlreg:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			frame_we_reg <= (others => FALSE);
			commit_frame_reg <= FALSE;
			
		else
			frame_word_reg <= frame_word;
			if to_0ifX(frame_address) < framer_free then
				frame_address_reg <= frame_address;
				frame_we_reg <= frame_we;
				frame_length_reg <= frame_length;
				commit_frame_reg <= commit_frame;
				frame_overflow <= FALSE;
			else
				frame_address_reg <= (others => '-');
				frame_we_reg <= (others => FALSE);
				frame_length_reg <= (others => '-');
				commit_frame_reg <= FALSE;
				frame_overflow <= TRUE;
			end if;
			
			if event_state=QUEUED then
				dump <= frame_overflow or area_dump or cfd_error_int;
			else
				dump <= FALSE;
			end if;
			
		end if;
	end if;
end process frameCtlreg;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => BUS_CHUNKS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => frame_word_reg,
  address => frame_address_reg,
  chunk_we => frame_we_reg,
  free => framer_free,
  length => frame_length_reg,
  commit => commit_frame_reg, 
  stream => eventstream,
  valid => valid,
  ready => ready
);

end architecture RTL;
