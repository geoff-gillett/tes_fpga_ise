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
  -- max value is PEAK_COUNT_WIDTH
  --FIXME remove this
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
  filter_config_valid:in boolean;
  filter_config_ready:out boolean;
  filter_reload_data:in std_logic_vector(31 downto 0);
  filter_reload_valid:in boolean;
  filter_reload_ready:out boolean;
  filter_reload_last:in boolean;
  filter_reload_last_missing:out boolean;
  filter_reload_last_unexpected:out boolean;
  differentiator_config_data:in std_logic_vector(7 downto 0);
  differentiator_config_valid:in boolean;
  differentiator_config_ready:out boolean;
  differentiator_reload_data:in std_logic_vector(31 downto 0);
  differentiator_reload_valid:in boolean;
  differentiator_reload_ready:out boolean;
  differentiator_reload_last:in boolean;
  differentiator_reload_last_missing:out boolean;
  differentiator_reload_last_unexpected:out boolean;

  measurements:out measurement_t;
  
  mca_value_select:in std_logic_vector(NUM_MCA_VALUES-1 downto 0);
	mca_trigger_select:std_logic_vector(NUM_MCA_TRIGGERS-2 downto 0);
  mca_value:out signed(MCA_VALUE_BITS-1 downto 0);
  mca_value_valid:out boolean;

  dump:out boolean;
  commit:out boolean;
  
  baseline_range_error:out boolean;
  cfd_error:out boolean;
  time_overflow:out boolean;
  peak_overflow:out boolean;
  framer_overflow:out boolean;
  
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

--signal just_reset:boolean;
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
signal cfd_low_queue_dout,cfd_high_queue_dout:std_logic_vector(WIDTH-1 downto 0);
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
signal trigger:boolean;
signal area_below_threshold:boolean;
signal event_time:unsigned(TIME_BITS-1 downto 0);
signal peak_count_pd:unsigned(PEAK_COUNT_BITS-1 downto 0);
signal height_valid:boolean;
signal peak_overflow_int:boolean;
signal pulse_length:unsigned(TIME_BITS-TIME_FRAC-1 downto 0);
signal pulse_overflow:boolean;
signal peak_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0);
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

signal cfd_low,cfd_high,slope_pos_0xing_cfd,peak_cfd,max_at_cfd_reg:boolean;
signal cfd_pulse_state,cfd_pulse_nextstate:pulseFSMstate;
signal pulse_stop_cfd,pulse_start_cfd:boolean;
signal filtered_cfd_reg,filtered_cfd_reg2:signed(WIDTH-1 downto 0);
signal filtered_is_min:boolean;
signal cfd_low_xing,cfd_high_xing:boolean;
signal cfd_error_int:boolean;
signal minima_valid:boolean;
signal cfd_high_threshold:signed(WIDTH-1 downto 0);
signal cfd_reset:boolean;
signal cfd_low_crossed,cfd_high_crossed:boolean;
signal cfd_high_done,cfd_low_done:boolean;
signal peak_start:boolean;
signal peaks_full:boolean;
signal time_overflow_int:boolean;
signal fixed_length:boolean;
signal event_start:boolean;

--------------------------------------------------------------------------------
-- Signals framer stage
--------------------------------------------------------------------------------
-- FSM state
type frameFSMstate is (IDLE,STARTED,QUEUED);
signal event_state,event_nextstate:frameFSMstate;

type pulseEventFSMstate is (PEAKS,TRACE,HEADER0,HEADER1,CLEAR);
signal pulse_state,pulse_nextstate:pulseEventFSMstate;

-- framer signals
signal frame_word:streambus_t;
signal frame_free:unsigned(FRAMER_ADDRESS_BITS downto 0);
signal chunk_we,frame_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal commit_int,dump_int:boolean;
signal frame_length:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal frame_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);

-- fixed 8 byte events (single word)
--signal peak_event:datachunk_array_t(BUS_CHUNKS-1 downto 0); 
signal peak_event:peak_detection_t; 
signal area_event:area_detection_t;
signal peak_chunk_we,area_chunk_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal single_word_event:boolean;

-- variable length events
signal pulse_peak:datachunk_array_t(BUS_CHUNKS-1 downto 0);
signal pulse_peak_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal pulse_peak_reg:datachunk_array_t(BUS_CHUNKS-1 downto 0);
signal pulse_peak_we_reg:boolean_vector(BUS_CHUNKS-1 downto 0);
signal pulse_peak_mux:datachunk_array_t(BUS_CHUNKS-1 downto 0);
signal header0_chunk:datachunk_array_t(BUS_CHUNKS-1 downto 0);
signal header1_chunk:datachunk_array_t(BUS_CHUNKS-1 downto 0);
signal header_valid:boolean;
signal trace0,trace1:datachunk_t;
signal trace_reg:datachunk_array_t(BUS_CHUNKS-1 downto 0);
signal trace0_count:unsigned(ceilLog2(BUS_CHUNKS)-1 downto 0);
signal trace1_count:unsigned(ceilLog2(BUS_CHUNKS)-1 downto 0);
signal dual_trace,single_trace:boolean;
signal trace_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal trace_reg_valid:boolean;

-- common signals

signal detection_flags:detection_flags_t;
signal dump_reg:boolean;
signal frame_overflow_int:boolean;
signal pulse_peak_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal commit_peak,commit_area:boolean;
signal peak_start_reg:boolean;
signal last_peak:boolean;
signal last_peak_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0);
signal peaks_done:boolean;
signal frame_full:boolean;
signal commit_frame:boolean;
signal commit_reg:boolean;
signal last_clear_peak:boolean;
signal peak_lost:boolean;
signal event_lost:boolean;
signal clear_address:unsigned(FRAMER_ADDRESS_BITS-1 downto 0);
signal clear_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0);
signal last_clear:boolean;
signal pulse_peak_mux_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal rise_time:unsigned(TIME_BITS-1 downto 0);

begin
measurements <= m; --are the measurements needed externally?

valueMux:entity work.mca_value_selector
generic map(
  VALUE_BITS => MCA_VALUE_BITS,
  NUM_VALUES => NUM_MCA_VALUES,
  NUM_VALIDS => NUM_MCA_TRIGGERS-1
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
-- Peak detection stage
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
  range_error => baseline_range_error 
);

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
  stage2_config_data => differentiator_config_data,
  stage2_config_valid => differentiator_config_valid,
  stage2_config_ready => differentiator_config_ready,
  stage2_reload_data => differentiator_reload_data,
  stage2_reload_valid => differentiator_reload_valid,
  stage2_reload_ready => differentiator_reload_ready,
  stage2_reload_last => differentiator_reload_last,
  stage2_reload_last_missing => differentiator_reload_last_missing,
  stage2_reload_last_unexpected => differentiator_reload_last_unexpected,
  --w=18 f=3
  stage1 => filtered_FIR,
  --w=18 f=8
  stage2 => slope_FIR
);

--TODO add closest for threshxing? used to get slope threshold timiing
--FIXME closest 0xings not good for area						 
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
  threshold => signed('0' & registers.capture.slope_threshold),
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
												filtered_neg_threshxing_pd,pulse_overflow,
												slope_neg_0xing_pd, peak_overflow_int)
begin
	pd_pulse_nextstate <= pd_pulse_state;
	case pd_pulse_state is 
	when IDLE =>
		if filtered_pos_threshxing_pd then
			pd_pulse_nextstate <= FIRST_RISE;
		end if;
	when FIRST_RISE =>
		if filtered_neg_threshxing_pd or pulse_overflow or peak_overflow_int then
			pd_pulse_nextstate <= IDLE;
		elsif slope_neg_0xing_pd then 
			pd_pulse_nextstate <= PEAKED;
		end if;
	when PEAKED =>
		if filtered_neg_threshxing_pd or pulse_overflow or peak_overflow_int then
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
      if capture_pd.threshold_rel2min and pd_pulse_state=IDLE then
        pulse_threshold 
          <= filtered_pd+signed('0' & registers.capture.pulse_threshold);
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
-- Queues and delays
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

flags_pd <= (to_std_logic(minima_pd),
						 to_std_logic(slope_neg_0xing_pd), 
						 to_std_logic(pulse_start_pd),
						 to_std_logic(pulse_stop_pd),
						 to_std_logic(peak_pd),
						 to_std_logic(slope_pos_0xing_pd),
						 to_std_logic(slope_pos_thresh_xing_pd) 
				    );

-- TODO make this break the delays up into 64 bit lots with a reg at the end 
flagsCFDdelay:entity work.RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => NUM_FLAGS
)
port map(
  clk => clk,
  data_in => flags_pd,
  delay => CFD_DELAY+3,
  delayed => flags_cfd_delay
);

minima_cfd <= to_boolean(flags_cfd_delay(6));
slope_neg_0xing_cfd <= to_boolean(flags_cfd_delay(5));
pulse_start_cfd <= to_boolean(flags_cfd_delay(4));
pulse_stop_cfd <= to_boolean(flags_cfd_delay(3));
peak_cfd <= to_boolean(flags_cfd_delay(2));
slope_pos_0xing_cfd <= to_boolean(flags_cfd_delay(1));
-- FIXME make this a closest xing?
slope_pos_thresh_xing_cfd <= to_boolean(flags_cfd_delay(0));

signalCFDdelay:entity work.RAM_delay
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

slopeCFDdelay:entity work.RAM_delay
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

rawCDFdelay:entity work.RAM_delay
generic map(
  DEPTH     => CFD_DELAY_DEPTH,
  DATA_BITS => WIDTH
)
port map(
  clk     => clk,
  data_in => to_std_logic(stage1_input),
  delay   => CFD_DELAY+FIR_DELAY,
  delayed => raw_cfd_delay
);

--------------------------------------------------------------------------------
-- Measurements and crossing detectors
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

triggerMux:process(capture_cfd.timing,cfd_low,pulse_start_cfd,
									 slope_pos_thresh_xing_cfd,cfd_pulse_state) 
begin
	case capture_cfd.timing is
	when PULSE_THRESH_TIMING_D => 
		if cfd_pulse_state=FIRST_RISE then
			trigger <= pulse_start_cfd;
		else
			trigger <= cfd_low;
		end if;
  when SLOPE_THRESH_TIMING_D =>
    trigger <= slope_pos_thresh_xing_cfd;
  when CFD_LOW_TIMING_D =>
    trigger <= cfd_low;
  when RISE_START_TIMING_D =>
  	-- FIXME implement
  	null;
	end case;
end process triggerMux;

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

cfdPulseFSMtransition:process(cfd_pulse_state,peak_cfd,pulse_stop_cfd,
															peak_start)
begin
	case cfd_pulse_state is 
	when IDLE =>
		if peak_start then
			cfd_pulse_nextstate <= FIRST_RISE;
		end if;
	when FIRST_RISE =>
		if peak_cfd then
			cfd_pulse_nextstate <= PEAKED;
		end if;
	when PEAKED =>
		if pulse_stop_cfd then
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
--FIXME this cannot be right anymore
peaks_full <= unaryAnd(peak_count);
--FIXME The CFD process will not work properly on arbitrary signals. With some 
--further thought I think it could. Meanwhile this should be OK for TES signals.
minima_valid <= minima_cfd and filtered_is_min;
peak_start <= minima_valid and cfd_state=WAIT_MIN;
event_start <= minima_valid and cfd_pulse_state=IDLE;

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

--FIXME always fixed length now
fixed_length <= TRUE;
--fixed_length <= capture_pd.max_peaks(PEAK_COUNT_WIDTH)='0';

pulseMeasurement:process(clk)
begin
if rising_edge(clk) then
	if reset = '1' then
		pulse_extrema <= (others => '0');
		pulse_area <= (others => '0');
 		event_time <= (others => '0');
		capture_cfd <= registers.capture;
		peak_count <= (others => '0');
	else
		
		-- FIXME should be event start?	
		if event_start then --FIXME this should change on valid minima??
			capture_cfd <= capture_pd; -- FIXME this is not going to work correctly
																 -- use extra flags and delay
			if fixed_length then
				last_peak_count <= capture_pd.max_peaks(PEAK_COUNT_WIDTH-1 downto 0);
			else
				last_peak_count <= (others => '1');
			end if;
		end if;
  
  	m.trigger <= trigger;	
  	if trigger then
  		rise_time <= (others => '0');
  	else
  		rise_time <= rise_time+1;
  	end if;
  	
  	--  FIXME the path for trigger is going to be a problem
  	case capture_cfd.detection is 
  	when PEAK_DETECTION_D | AREA_DETECTION_D =>
  		if event_start then
        event_time <= (others => '0');
        time_overflow_int <= FALSE;
      else
        if event_time=to_unsigned(2**TIME_BITS-1,TIME_BITS) then
          time_overflow_int <= TRUE;
        else
          event_time <= event_time+1;
        end if;
      end if;

  	when PULSE_DETECTION_D | TRACE_DETECTION_D =>
      if event_start then
        event_time <= (others => '0');
        time_overflow_int <= FALSE;
      else
        if event_time=to_unsigned(2**TIME_BITS-1,TIME_BITS) then
          time_overflow_int <= TRUE;
        else
          event_time <= event_time+1;
        end if;
      end if;
  	end case;
  	
  	--FIXME clean up the registration and delay lines
  	max_at_cfd_reg <= peak_cfd;
  	peak_start_reg <= peak_start;
  	
    case capture_cfd.height is
    when PEAK_HEIGHT_D =>
    	if peak_cfd then
    		m.height_valid <= TRUE; 
        if capture_cfd.height_rel2min then --FIXME not making sense
          m.height <= reshape(filtered_cfd-minima_value_cfd,
            									FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        else
          m.height <= reshape(filtered_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        end if;
      else
    		m.height_valid <= FALSE;
    	end if;

    when CFD_HIGH_D =>
      --height_valid <= cfd_high;
    	if cfd_high then
    		m.height_valid <= TRUE;
        if capture_cfd.height_rel2min then
          m.height 
            <= reshape(filtered_cfd-minima_value_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        else
          m.height <= reshape(filtered_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        end if;
      else
    		m.height_valid <= FALSE;
    	end if;

    when SLOPE_INTEGRAL_D =>
      height_valid <= peak_cfd;
    	if slope_zero_xing and cfd_state=WAIT_PEAK then
    		m.height_valid <= TRUE;
        m.height <= reshape(slope_area,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
      else
    		m.height_valid <= FALSE;
      end if;
    end case;
  	
  	if pulse_start_cfd then
  		pulse_area <= resize(filtered_cfd,AREA_SUM_BITS);
  		pulse_extrema <= filtered_cfd; 
  		peak_count <= (others => '0'); --FIXME move peak_count to own process
  	else
  		if filtered_cfd > pulse_extrema then
  			pulse_extrema <= filtered_cfd;
  		end if;
  		if max_at_cfd_reg then
  			if peaks_full then
  				peak_overflow_int <= TRUE;
  			else
  				peak_overflow_int <= FALSE;
  				peak_count <= peak_count+1;
  			end if;
  		else
 				peak_overflow_int <= FALSE;
  		end if;
  		
  		pulse_area <= pulse_area+filtered_cfd;
  		area_below_threshold 
  			<= to_0ifX(pulse_area) < 
  				 resize(capture_cfd.area_threshold,AREA_SUM_BITS);
  	end if;
  --FIXME these no longer need to registered	
    m.peak_start <= peak_start;
    
    m.cfd_low <= cfd_low;
    m.cfd_high <= cfd_high;
    
    --measurements.event_start <= min_valid and cfd_state=WAIT_MIN;
    
    m.pulse.pos_threshxing <= pulse_start_cfd;
    m.pulse.neg_threshxing <= pulse_stop_cfd;
  	
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

peak_overflow <= peak_overflow_int;
time_overflow <= time_overflow_int;
m.peak <= max_at_cfd_reg;
m.peak_count <= peak_count;
--m.pulse_time <= event_time;
m.pulse.time <= event_time;
m.pulse.area <= reshape(pulse_area,FRAC,AREA_BITS,AREA_FRAC);
m.pulse.extrema <= reshape(pulse_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);

--------------------------------------------------------------------------------
-- Framer stage
--------------------------------------------------------------------------------
-- NOTE if the frame is dumped old values are still in memory but not put in the 
-- stream, so need to make sure that old values don't propagate in next frame
-- by making sure that that each BUS_CHUNK is written to each frame.
-- commit <= commit_int;

dump <= dump_reg;

detection_flags.channel <= to_unsigned(CHANNEL,CHANNEL_WIDTH);
detection_flags.event_type.detection_type <= capture_cfd.detection;
detection_flags.event_type.tick <= FALSE;
detection_flags.peak_count <= m.peak_count;

single_word_event <= capture_cfd.detection=PEAK_DETECTION_D or
										 capture_cfd.detection=AREA_DETECTION_D;

peak_event.height <= m.height; 
peak_chunk_we(3) <= m.height_valid; 
peak_event.minima <= m.filtered.sample;
peak_chunk_we(2) <= m.peak_start;
peak_event.flags <= detection_flags;
peak_chunk_we(1) <= m.peak_start;
peak_event.rel_timestamp <= (others => '0'); -- time-stamp added by MUX
peak_chunk_we(0) <= m.peak_start; -- clear it at start
commit_peak <= m.height_valid;

-- FIXME do the same as peak_event
area_event.area <= m.pulse.area;
area_event.flags <= detection_flags;
area_event.rel_timestamp <= (others => '-'); -- time-stamp added by MUX
area_chunk_we <= (others => m.pulse.neg_threshxing);
commit_area <= m.pulse.neg_threshxing;

-- FIXME re-think remove variable length version
pulse_peak(3) <= to_std_logic(m.filtered.sample);
pulse_peak_we(3) <= m.height_valid;
pulse_peak(2) <= to_std_logic(m.filtered.sample);
pulse_peak_we(2) <= m.peak_start;
pulse_peak(1) <= to_std_logic(rise_time);
pulse_peak_we(1) <= m.height_valid;
pulse_peak(0) <= to_std_logic(m.pulse.time);
pulse_peak_we(0) <= m.trigger;

--TODO go over traces code traces
--------------------------------------------------------------------------------
-- Framer FSMs
--------------------------------------------------------------------------------
FSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			event_state <= IDLE;
			pulse_state <= PEAKS;
		else
			event_state <= event_nextstate;
			pulse_state <= pulse_nextstate;
		end if;
	end if;
end process FSMnextstate;

dual_trace <= capture_cfd.trace0/=NO_TRACE_D and 
							capture_cfd.trace1/=NO_TRACE_D;
single_trace <= not dual_trace and capture_cfd.trace0/=NO_TRACE_D;

traceCapture:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    trace0_count <= (others => '0');
    trace1_count <= to_unsigned(1,ceilLog2(BUS_CHUNKS));
  else
  	if event_start then
      trace0_count <= (others => '0');
      trace1_count <= to_unsigned(1,ceilLog2(BUS_CHUNKS));
      trace_address <= resize(last_peak_count,FRAMER_ADDRESS_BITS);
	  else
	  	--infer adder with carry in
	  	trace0_count <= trace0_count+1+to_unsigned(dual_trace);
	  	trace1_count <= trace1_count+1+to_unsigned(dual_trace);
      if dual_trace then 
        trace_reg(to_integer(trace0_count)) <= trace0;
        trace_reg(to_integer(trace1_count)) <= trace1;
      else
        trace_reg(to_integer(trace0_count)) <= trace0;
      end if;
  	end if;
  end if;
end if;
end process traceCapture;

traceMux:process(capture_cfd.trace0,capture_cfd.trace1,
								 m.filtered.sample,m.raw.sample,m.slope.sample)
begin
	
  case capture_cfd.trace0 is
  when NO_TRACE_D =>
  	trace0 <= (others => '-');
  when FILTERED_TRACE_D =>
    trace0 <= to_std_logic(m.filtered.sample);
  when SLOPE_TRACE_D =>
    trace0 <= to_std_logic(m.slope.sample);
  when RAW_TRACE_D =>
    trace0 <= to_std_logic(m.raw.sample);
  end case;	
  
  case capture_cfd.trace1 is
  when NO_TRACE_D =>
  	trace1 <= (others => '-');
  when FILTERED_TRACE_D =>
    trace1 <= to_std_logic(m.filtered.sample);
  when SLOPE_TRACE_D =>
    trace1 <= to_std_logic(m.slope.sample);
  when RAW_TRACE_D =>
    trace1 <= to_std_logic(m.raw.sample);
  end case;	
end process traceMux;

	
eventFSMtransition:process(event_state,m.peak_start,m.trigger,cfd_error_int,
												   commit_int,dump_int)
begin
event_nextstate <= event_state;
	case event_state is 
	when IDLE =>
		if m.trigger then
			event_nextstate <= QUEUED;
		elsif m.peak_start then -- event_start???
			event_nextstate <= STARTED;
		end if; 
	when STARTED =>
		if cfd_error_int then
			event_nextstate <= IDLE;
		elsif m.trigger then
			event_nextstate <= QUEUED;
		end if; 
	when QUEUED =>
		if commit_int or dump_int then
			event_nextstate <= IDLE;
		end if;
	end case;
end process eventFSMtransition;

pulseEventFSMtransition:process(pulse_state,peaks_done,last_clear_peak,
																header_valid)
begin
	pulse_nextstate <= pulse_state;
	case pulse_state is 
	when HEADER0 =>
		if header_valid then
			pulse_nextstate <= HEADER1;
		end if;
  when HEADER1 =>
    pulse_nextstate <= PEAKS;
  when PEAKS =>
  	if peaks_done then
    	pulse_nextstate <= HEADER0;
    end if;
  when TRACE =>
  	pulse_nextstate <= PEAKS; 
  when CLEAR =>
  	--FIXME this state is not reachable
  	if last_clear_peak then
  		pulse_nextstate <= PEAKS;
  	end if;
	end case;
end process pulseEventFSMtransition;

--------------------------------------------------------------------------------
--FIXME two adders is a poor solution to the problem
pulse_peak_address <= resize(m.peak_count+2,FRAMER_ADDRESS_BITS); 
clear_address <= resize(clear_count+3,FRAMER_ADDRESS_BITS); 

last_peak <= peak_count=last_peak_count;
last_clear <= clear_count=last_peak_count;
peaks_done <= m.pulse.neg_threshxing or (last_peak and m.height_valid);

pulsePeakreg:process (clk) is
begin
if rising_edge(clk) then
  if reset = '1' then
    pulse_peak_we_reg <= (others => FALSE);
  else
  	
  	-- FIXME this may break on event_type change
  	if (capture_cfd.detection=PULSE_DETECTION_D and pulse_state=PEAKS) then 
	    pulse_peak_we_reg <= (others => FALSE);
  	else
  		
      -- NOTE this registration is to handle the case were a new event starts 
      -- just after the end of another, while the first is clearing or writing 
      -- the header or when recording traces.
      -- TODO consider better ways to handle this.
  		
      if m.height_valid then
        if pulse_peak_we_reg(3) or pulse_peak_we_reg(1) then 
          peak_lost <= TRUE;
        else
          pulse_peak_reg(3) <= to_std_logic(m.filtered.sample);
          pulse_peak_we_reg(3) <= TRUE;
          pulse_peak_reg(1) <= to_std_logic(m.pulse.time);
          pulse_peak_we_reg(1) <= TRUE;
        end if;
      end if;
  		
      if m.peak_start then
        if not pulse_peak_we_reg(2) then
          pulse_peak_reg(2) <= to_std_logic(m.filtered.sample);
          pulse_peak_we_reg(2) <= TRUE;
        else 
          peak_lost <= TRUE;
        end if;
      end if;
      
      if m.trigger then
        if not pulse_peak_we_reg(0) then	
          pulse_peak_reg(0) <= to_std_logic(m.pulse.time);
          pulse_peak_we_reg(0) <= TRUE;
        else
          peak_lost <= TRUE;
        end if;
      end if;
      
  	end if;
  	
  end if;
end if;
end process pulsePeakreg;

pulsePeakMux:process(pulse_peak_we_reg,pulse_peak,pulse_peak_reg,pulse_peak_we)
begin
	for c in 0 to BUS_CHUNKS-1 loop
    if pulse_peak_we_reg(c) then
			pulse_peak_mux(c) <= pulse_peak_reg(c);
			pulse_peak_mux_we(c) <= TRUE;
		else
			pulse_peak_mux(c) <= pulse_peak(c);
			pulse_peak_mux_we(c) <= pulse_peak_we(c);
    end if;
	end loop;	
end process pulsePeakMux;

header0_chunk(2) <= (others => '0');
header0_chunk(0) <= (others => '0');
header1_chunk(1) <= (others => '0');

frameControlReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    commit_int <= FALSE;
    dump_reg <= FALSE;
    chunk_we <= (others => FALSE);
    commit_reg <= FALSE;
    event_lost <= FALSE;
    header_valid <= FALSE;
    clear_count <= (others => '0');
  else
    framer_overflow <= frame_overflow_int;
    dump_reg <= dump_int;
    commit <= commit_frame;
    
    -- header registers for PULSE_EVENT_D and TRACE_EVENT_D
    -- NOTE this registration is to handle the case were a new event starts just 
    -- after the end of another, while the first is clearing or writing the
    -- header. TODO think of a better way to handle this case.
    
		if single_word_event then
			event_lost <= FALSE;
      header_valid <= FALSE;
		else
      if m.pulse.neg_threshxing then
        if header_valid then 
          event_lost <= TRUE;
          -- TODO check that this can happen -- handle it how?
          -- TODO dump?
        else
          header0_chunk(1) <= to_std_logic(detection_flags);
          if fixed_length then
            header0_chunk(3) 
              <= to_std_logic(resize(capture_cfd.max_peaks+3,CHUNK_DATABITS));
          else
            header0_chunk(3) 
            	<= to_std_logic(resize(m.peak_count+3,CHUNK_DATABITS));
          end if;
          header1_chunk(0) <= to_std_logic(m.pulse.time);
          header1_chunk(3) <= to_std_logic(m.pulse.area(31 downto 16));
          header1_chunk(2) <= to_std_logic(m.pulse.area(15 downto 0));
          header_valid <= TRUE;
        end if;
      end if;
    end if;
      
    case capture_cfd.detection is
    when PEAK_DETECTION_D =>
      frame_word <= to_streambus(peak_event,ENDIANNESS);
      frame_address <= (others => '0');
      frame_length <= to_unsigned(1,FRAMER_ADDRESS_BITS);
      chunk_we <= peak_chunk_we;
      commit_int <= commit_peak;

    when AREA_DETECTION_D =>
      frame_word <= to_streambus(area_event,ENDIANNESS);
      frame_address <= (others => '0');
      frame_length <= to_unsigned(1,FRAMER_ADDRESS_BITS);
      chunk_we <= area_chunk_we;
      commit_int <= commit_area;
      
    when PULSE_DETECTION_D =>
      case pulse_state is 
      when PEAKS =>
        commit_int <= FALSE;
        frame_word <= to_streambus(pulse_peak_mux,
                                   (others => FALSE),
                                   (0 => peaks_done,others => FALSE)); 
        frame_address <= pulse_peak_address;
        chunk_we <= pulse_peak_mux_we;
        clear_count <= m.peak_count;
      when TRACE =>
      	commit_int <= FALSE;
      	frame_word <= to_streambus(trace_reg,(others => FALSE),
      														 (others => FALSE));
      	chunk_we <= (others => TRUE);
      	frame_address <= trace_address;
      when CLEAR =>
	        commit_int <= FALSE;
          frame_word <= to_streambus(to_std_logic(0,BUS_DATABITS),
                                     (others => FALSE),
                                     (0 => last_clear,others => FALSE)); 
          frame_address <= clear_address;
          chunk_we <= (others => TRUE);
          clear_count <= clear_count+1;
      	
      when HEADER0 =>
        commit_int <= FALSE;
        if header_valid then
          frame_word <= to_streambus(header0_chunk,(others => FALSE),
          													 (others => FALSE));
          frame_address <= (others => '0');
          chunk_we <= (others => TRUE);	
        else
        	chunk_we <= (others => FALSE);
        end if;
        
      when HEADER1 =>
        frame_word <= to_streambus(header1_chunk,
                                   (others => FALSE),
                                   (others => FALSE));
        frame_address <= to_unsigned(1,FRAMER_ADDRESS_BITS);
        chunk_we <= (others => TRUE);	
        frame_length 
          <= unsigned(header0_chunk(3)(FRAMER_ADDRESS_BITS-1 downto 0));
        commit_int <= TRUE;
      end case;
      
    when TRACE_DETECTION_D =>
      null;
    end case;		
    
  end if;
end if;
end process frameControlReg;

frame_full <= frame_address >= frame_free;
writeEnable:process(chunk_we,commit_int,frame_full)
begin
	frame_we <= (others => FALSE);
	dump_int <= FALSE;
	commit_frame <= FALSE;
	frame_overflow_int <= TRUE;
	if unaryOr(chunk_we) then
		if frame_full then
			dump_int <= TRUE;
			frame_overflow_int <= TRUE;
		else
			commit_frame <= commit_int;
			frame_we <= chunk_we;
		end if;
	end if;
end process writeEnable;

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS => BUS_CHUNKS,
  ADDRESS_BITS => FRAMER_ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  data => frame_word,
  address => frame_address,
  chunk_we => frame_we,
  free => frame_free,
  length => frame_length,
  commit => commit_frame,
  stream => eventstream,
  valid => valid,
  ready => ready
);

end architecture RTL;
