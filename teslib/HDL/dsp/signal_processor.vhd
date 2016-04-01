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

use work.registers.all;
use work.types.all;
use work.functions.all;
use work.dsptypes.all;
use work.adc.all;
use work.events.all;
use work.measurements.all;

entity signal_processor is
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
  PEAK_COUNT_BITS:integer:=3
);
port(
  clk:in std_logic;
  reset:in std_logic;
  adc_sample:in adc_sample_t;
  -- Control registers
  registers:in measurement_registers_t;
  -- FIR filters
  filter_config_data:in std_logic_vector(7 downto 0);
  filter_config_valid:in boolean;
  filter_config_ready:out boolean;
  filter_reload_data:in std_logic_vector(31 downto 0);
  filter_reload_valid:in boolean;
  filter_reload_ready:out boolean;
  filter_reload_last:in boolean;
  differentiator_config_data:in std_logic_vector(7 downto 0);
  differentiator_config_valid:in boolean;
  differentiator_config_ready:out boolean;
  differentiator_reload_data:in std_logic_vector(31 downto 0);
  differentiator_reload_valid:in boolean;
  differentiator_reload_ready:out boolean;
  differentiator_reload_last:in boolean;

  measurements:out measurement_t;
  
  baseline_range_error:out boolean;
  cfd_error:out boolean;
  time_overflow:out boolean;
  peak_overflow:out boolean
);
end entity signal_processor;

architecture RTL of signal_processor is
	
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
constant NUM_FLAGS:integer:=6;
-- internal area accumulator width
constant AREA_SUM_WIDTH:integer:=TIME_BITS+WIDTH;

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
--
signal pulse_threshold:signed(WIDTH-1 downto 0);
signal slope_pos_0xing_pd,slope_neg_0xing_pd:boolean;
signal slope_zero_xing_pd,arming_pd:boolean;
signal slope_pd,filtered_pd:signed(WIDTH-1 downto 0);
signal maxima_pd,minima_pd:boolean;
signal minima_value_pd,last_minima_value:signed(WIDTH-1 downto 0);
signal filtered_pos_threshxing_pd,filtered_neg_threshxing_pd:boolean;
signal slope_pos_thresh_xing_pd:boolean;
signal pulse_start_pd,pulse_stop_pd:boolean;
--
signal cf_of_peak,cf_of_peak_reg:signed(CFD_BITS+WIDTH-1 downto 0);
signal cf_of_peak_reg2:signed(CFD_BITS+WIDTH-1 downto 0);
signal cfd_low_thresh_pd,cfd_high_thresh_pd:signed(WIDTH-1 downto 0);
signal signal_for_cfd:signed(WIDTH-1 downto 0);
signal peak_pipe,first_rise_pipe:boolean_vector(1 to MULT_PIPE_DEPTH);
signal queue_overflow:boolean;
signal minima_for_cfd,maxima_for_cfd:signed(WIDTH-1 downto 0);

--------------------------------------------------------------------------------
-- Signals for delay and FIFO stage
--------------------------------------------------------------------------------
signal filtered_cfd_delay,slope_cfd_delay:std_logic_vector(WIDTH-1 downto 0);
signal raw_cfd_delay:std_logic_vector(WIDTH-1 downto 0);
signal flags_pd,flags_cfd_delay:std_logic_vector(NUM_FLAGS-1 downto 0);
signal queue_rd_en:std_logic;
signal queue_full,queue_empty:std_logic;
signal queue_wr_en:std_logic;
signal cfd_low_thresh,cfd_high_thresh:std_logic_vector(WIDTH-1 downto 0);
signal minima_value_cfd:std_logic_vector(WIDTH-1 downto 0);

--------------------------------------------------------------------------------
-- Measurement Signals 
--------------------------------------------------------------------------------
signal pulse_area:signed(AREA_SUM_WIDTH-1 downto 0);
signal raw_extrema,filtered_extrema:signed(WIDTH-1 downto 0);
signal slope_extrema,pulse_extrema:signed(WIDTH-1 downto 0);
signal filtered_area,slope_area:signed(AREA_SUM_WIDTH-1 downto 0);
signal filtered_zero_xing,slope_zero_xing:boolean;
signal trigger:boolean;
signal area_below_threshold:boolean;
signal pulse_time:unsigned(TIME_BITS-1 downto 0);
signal peak_count_pd:unsigned(PEAK_COUNT_BITS-1 downto 0);
signal height_valid:boolean;
signal peak_overflow_int:boolean;
signal pulse_length:unsigned(TIME_BITS-TIME_FRAC-1 downto 0);
signal pulse_overflow:boolean;
signal peak_count:unsigned(PEAK_COUNT_WIDTH-1 downto 0);
signal raw_area:signed(AREA_SUM_WIDTH-1 downto 0);
signal raw_zero_xing:boolean;

--------------------------------------------------------------------------------
-- Signals for CFD stage
--------------------------------------------------------------------------------
type cfdFSMstate is (IDLE,WAIT_MIN,WAIT_PEAK);
signal cfd_state,cfd_nextstate:cfdFSMstate;
signal filtered_cfd,slope_cfd,raw_cfd:signed(WIDTH-1 downto 0);
signal cfd_low_threshold:signed(WIDTH-1 downto 0);
signal minima_cfd:signed(WIDTH-1 downto 0);
signal slope_pos_thresh_xing_cfd:boolean;

signal cfd_low,cfd_high,min_at_cfd,max_at_cfd,max_at_cfd_reg:boolean;
signal cfd_pulse_state,cfd_pulse_nextstate:pulseFSMstate;
signal pulse_stop_cfd,pulse_start_cfd:boolean;
signal filtered_cfd_reg,filtered_cfd_reg2:signed(WIDTH-1 downto 0);
signal filtered_is_min:boolean;
signal cfd_low_xing,cfd_high_xing:boolean;
signal cfd_error_int:boolean;
signal min_valid:boolean;
signal cfd_high_threshold:signed(WIDTH-1 downto 0);
signal cfd_reset:boolean;
signal cfd_low_crossed,cfd_high_crossed:boolean;
signal cfd_high_done,cfd_low_done:boolean;
signal event_start,save_registers:boolean;
signal peaks_full:boolean;
signal time_overflow_int:boolean;

begin

--------------------------------------------------------------------------------
-- Peak detection stage
--------------------------------------------------------------------------------

--peak_overflow <= peak_overflow_int;

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
  stage2_config_data => differentiator_config_data,
  stage2_config_valid => differentiator_config_valid,
  stage2_config_ready => differentiator_config_ready,
  stage2_reload_data => differentiator_reload_data,
  stage2_reload_valid => differentiator_reload_valid,
  stage2_reload_ready => differentiator_reload_ready,
  stage2_reload_last => differentiator_reload_last,
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
  FRAC  => FRAC
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

pulseThreshold:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			pulse_threshold <= (0 => '0', others=>'1');
		else
			if registers.capture.threshold_rel2min then
				pulse_threshold 
					<= last_minima_value+signed('0' & registers.capture.pulse_threshold);
			else
				pulse_threshold <= signed('0' & registers.capture.pulse_threshold);
			end if;
		end if;
	end if;
end process pulseThreshold;

filteredXing:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
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

minima_pd <= slope_pos_0xing_pd and pd_state=WAITING;

maxima_pd <= pd_state=ARMED and 
						 (pd_pulse_state/=IDLE or filtered_pos_threshxing_pd) and 
						 slope_neg_0xing_pd;
							
arming_pd <= pd_state=WAITING and slope_pos_thresh_xing_pd;

peakDectection:process(clk)
begin
	if rising_edge(clk) then
		if cfd_reset then
			last_minima_value <= (others => '0');
			pulse_length <= to_unsigned(1,TIME_BITS-TIME_FRAC);
			queue_wr_en <= '0';
			peak_count_pd <= (others => '0');
		else
			
			--FIXME this needed here? move to cfd stage
--			if pulse_start_pd then
--				pulse_length <= to_unsigned(1,TIME_BITS-TIME_FRAC);
--			else
--				pulse_length <= pulse_length+1;
--			end if;
			
      if minima_pd then	
      	last_minima_value <= filtered_pd;	
      end if;
      
     	if arming_pd then 
     		minima_value_pd <= last_minima_value;
      end if;
      
      if maxima_pd then
        minima_for_cfd <= minima_value_pd;
        maxima_for_cfd <= filtered_pd;
        if pd_pulse_state=FIRST_RISE and not registers.capture.cfd_rel2min then
          signal_for_cfd <= filtered_pd;
        else
          signal_for_cfd <= filtered_pd-minima_value_pd;
        end if;
      end if;
 			
 			--FIXME move this to CFD stage
 			--time_overflow <= FALSE;--pulse_overflow;
 			
 			-- multiplier pipeline
 			peak_pipe <= shift(maxima_pd,peak_pipe);
      first_rise_pipe <= shift(pd_pulse_state=FIRST_RISE,first_rise_pipe);
 			-- absorbed into multiplier macro
      cf_of_peak_reg 
      	<= signal_for_cfd*signed('0' & registers.capture.pulse_threshold);
      cf_of_peak_reg2 <= cf_of_peak_reg;
      cf_of_peak <= cf_of_peak_reg2;
     
      if peak_pipe(MULT_PIPE_DEPTH) then
      	if queue_full='0' then
		      queue_overflow <= FALSE;
      		queue_wr_en <= '1';
      		--FIXME this will fail if pulse ends within 4 clocks of peak
          if first_rise_pipe(MULT_PIPE_DEPTH) and 
          	 not registers.capture.cfd_rel2min then
            cfd_low_thresh_pd 
            	<= resize(shift_right(cf_of_peak,CFD_FRAC),WIDTH);
          else
            cfd_low_thresh_pd 
              <= resize(shift_right(cf_of_peak,CFD_FRAC),WIDTH)+
                 minima_for_cfd;
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
  dout => cfd_low_thresh,
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
  dout => cfd_high_thresh,
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
  dout => minima_value_cfd,
  full => open,
  empty => open
);

flags_pd <= (to_std_logic(pd_pulse_state=FIRST_RISE),
						 to_std_logic(pulse_start_pd),
						 to_std_logic(pulse_stop_pd),
						 to_std_logic(maxima_pd),
						 to_std_logic(slope_pos_0xing_pd),
						 to_std_logic(slope_pos_thresh_xing_pd) --arming_pd)--FIXME this right?
				    );

-- TODO make this break the delays up into 64 bit lots with a reg at the end 
flagsCFDdelay:entity work.RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => NUM_FLAGS
)
port map(
  clk     => clk,
  data_in => flags_pd,
  delay   => CFD_DELAY+3,
  delayed => flags_cfd_delay
);

--first_rise_cfd <= to_boolean(flags_cfd_delay(5));
pulse_start_cfd <= to_boolean(flags_cfd_delay(4));
pulse_stop_cfd <= to_boolean(flags_cfd_delay(3));
max_at_cfd <= to_boolean(flags_cfd_delay(2));
min_at_cfd <= to_boolean(flags_cfd_delay(1));
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
  FRAC  => FRAC
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
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(filtered_cfd_delay),
  threshold => signed('0' & registers.capture.pulse_threshold),
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
  FRAC  => SLOPE_FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(slope_cfd_delay),
  threshold => signed('0' & registers.capture.slope_threshold),
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

triggerMux:process(registers.capture.trigger_type,cfd_low,pulse_start_cfd,
									 slope_pos_thresh_xing_cfd,cfd_pulse_state) 
begin
	case registers.capture.trigger_type is
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
	end case;
end process triggerMux;

-- FIXME are these goint to have the correct latency?
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
		filtered_is_min <= to_0ifX(filtered_cfd_reg2)=to_0IfX(minima_cfd);
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

--FIXME The CFD process will not work properly on arbitrary signals. With some 
--further thought I think it could. Meanwhile this should be OK for TES signals.
min_valid <= min_at_cfd and filtered_is_min;
event_start <= min_valid and cfd_state=WAIT_MIN;

--FIXME this is no good need to save at pd stage 
save_registers <= event_start and cfd_pulse_state/=IDLE;

cfdFSMtransition:process(max_at_cfd,queue_empty,cfd_state,min_valid)
begin
	cfd_nextstate <= cfd_state;
	case cfd_state is 
	when IDLE =>
		if queue_empty='0' then
			cfd_nextstate <= WAIT_MIN;
		end if;
	when WAIT_MIN =>
		if min_valid then
			cfd_nextstate <= WAIT_PEAK;
		end if;
	when WAIT_PEAK =>
		if max_at_cfd then
			cfd_nextstate <= IDLE;
		end if;
	end case;
end process cfdFSMtransition;

cfdPulseFSMtransition:process(cfd_pulse_state,cfd_state,min_valid,max_at_cfd,
															pulse_stop_cfd)
begin
	case cfd_pulse_state is 
	when IDLE =>
		if min_valid and cfd_state=WAIT_MIN then
			cfd_pulse_nextstate <= FIRST_RISE;
		end if;
	when FIRST_RISE =>
		if max_at_cfd then
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
cfd_high_done <= cfd_high_crossed or (max_at_cfd and cfd_high_xing);
cfd_low_done <= cfd_high_crossed or (max_at_cfd and cfd_high_xing);
cfd_error_int <= (max_at_cfd and not (cfd_low_done and cfd_high_done)) 
									or queue_overflow;
peaks_full <= unaryAnd(peak_count);

constantFraction:process(clk)
begin
	if rising_edge(clk) then
    if cfd_state=IDLE and queue_empty='0' then
      queue_rd_en <= '1';
      cfd_low_threshold <= signed(cfd_low_thresh);
      cfd_high_threshold <= signed(cfd_high_thresh);
      minima_cfd <= signed(minima_value_cfd);
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
 		pulse_time <= (others => '0');
	else
  
		--FIXME add overflow
  	measurements.trigger <= trigger;	
  	if trigger then
  		pulse_time <= (others => '0');
  	else
  		if pulse_time=to_unsigned(2**PEAK_COUNT_BITS-1,PEAK_COUNT_BITS) then
  			time_overflow_int <= TRUE;
  		else
  			pulse_time <= pulse_time+1;
  		end if;
  	end if;
  	
  	max_at_cfd_reg <= max_at_cfd;
  	
    case registers.capture.height_type is
    when PEAK_HEIGHT_D =>
    	if max_at_cfd then
    		measurements.height_valid <= TRUE;
        if registers.capture.threshold_rel2min then
          measurements.height 
            <= reshape(filtered_cfd-minima_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        else
          measurements.height 
            <= reshape(filtered_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        end if;
      else
    		measurements.height_valid <= FALSE;
      end if;
    when CFD_HIGH_D =>
      --height_valid <= cfd_high;
    	if cfd_high then
    		measurements.height_valid <= TRUE;
        if registers.capture.threshold_rel2min then
          measurements.height 
            <= reshape(filtered_cfd-minima_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        else
          measurements.height 
            <= reshape(filtered_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
        end if;
      else
    		measurements.height_valid <= FALSE;
      end if;
    when SLOPE_INTEGRAL_D =>
      height_valid <= max_at_cfd;
    	if slope_zero_xing and cfd_state=WAIT_PEAK then
    		measurements.height_valid <= TRUE;
        measurements.height <= reshape(slope_area,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
      else
    		measurements.height_valid <= FALSE;
      end if;
    end case;
  	
  	if pulse_start_cfd then
  		pulse_area <= resize(filtered_cfd,AREA_SUM_WIDTH);
  		pulse_extrema <= filtered_cfd; 
  		peak_count <= (others => '0');
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
  				resize(registers.capture.pulse_area_threshold,AREA_SUM_WIDTH);
  	end if;
  	
    measurements.peak_start <= min_valid and cfd_state=WAIT_MIN;
    
    measurements.cfd_low <= cfd_low;
    measurements.cfd_high <= cfd_high;
    
    --measurements.event_start <= min_valid and cfd_state=WAIT_MIN;
    
    measurements.pulse.pos_threshxing <= pulse_start_cfd;
    measurements.pulse.neg_threshxing <= pulse_stop_cfd;
    measurements.slope.pos_threshxing <= slope_pos_thresh_xing_cfd;
  	
    measurements.raw.zero_xing <= raw_zero_xing;
    measurements.raw.area <= reshape(raw_area,FRAC,AREA_BITS,AREA_FRAC);
    measurements.raw.extrema 
    	<= reshape(raw_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    measurements.raw.sample <= reshape(raw_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    
    measurements.filtered.sample 
    	<= reshape(filtered_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    measurements.filtered.extrema 
    	<= reshape(filtered_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
  	measurements.filtered.area 
  		<= reshape(filtered_area,FRAC,AREA_BITS,AREA_FRAC);
  	measurements.filtered.zero_xing <= filtered_zero_xing;
  	
    measurements.slope.sample 
    	<= reshape(slope_cfd,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
    measurements.slope.extrema 
    	<= reshape(slope_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);
  	measurements.slope.area <= reshape(slope_area,AREA_FRAC,AREA_BITS,FRAC);
  	measurements.slope.zero_xing <= slope_zero_xing;	
    measurements.slope.neg_0xing <= max_at_cfd; --FIXME
  end if;
end if;
end process pulseMeasurement;
peak_overflow <= peak_overflow_int;
time_overflow <= time_overflow_int;
measurements.peak <= max_at_cfd_reg;
measurements.peak_count <= peak_count;
measurements.pulse_time <= pulse_time;
measurements.pulse.area <= reshape(pulse_area,FRAC,AREA_BITS,AREA_FRAC);
measurements.pulse.extrema 
  <= reshape(pulse_extrema,FRAC,SIGNAL_BITS,SIGNAL_FRAC);

end architecture RTL;
