--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: dsp
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library adclib;
use adclib.types.all;
--
entity dsp is
generic(
	THRESHOLD_BITS:integer:=25;
	THRESHOLD_FRAC:integer:=10;
	INTERSTAGE_SHIFT:integer:=24;
	STAGE1_IN_BITS:integer:=18;
	STAGE1_IN_FRAC:integer:=3;
	
	STAGE1_BITS:integer:=48;
	STAGE1_FRAC:integer:=28;
	STAGE2_BITS:integer:=48;
	STAGE2_FRAC:integer:=28;
	--STAGE2_OUT_BITS:integer:=SIGNAL_BITS;
	--STAGE2_OUT_FRAC:integer:=9;
	--
  BASELINE_BITS:integer:=11;
  --BASELINE_AV_FRAC:integer:=5;
  --width of counters and stream
  BASELINE_COUNTER_BITS:integer:=18;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_MAX_AVERAGE_ORDER:integer:=6;
  CFD_BITS:integer:=17;
  CFD_FRAC:integer:=17
);
port(
  clk:in std_logic;
  reset:in std_logic;
  adc_sample:in adc_sample_t;
  -- fixed baseline, subtracted from sample
  adc_baseline:in adc_sample_t;
  -- baseline estimate control values
  baseline_subtraction:boolean;
  baseline_timeconstant:in unsigned(BASELINE_TIMECONSTANT_BITS-1 downto 0);
  -- above this threshold sample does not contribute to estimate
  baseline_threshold:unsigned(BASELINE_BITS-2 downto 0);
  -- count required before adding to average
  baseline_count_threshold:in unsigned(BASELINE_COUNTER_BITS-1 downto 0);
  baseline_average_order:natural range 0 to BASELINE_MAX_AVERAGE_ORDER;
  -- FIR filters
  --interstage_shift:in unsigned(bits(STAGE1_BITS-SIGNAL_BITS)-1 downto 0);
  stage1_config_data:in std_logic_vector(7 downto 0);
  stage1_config_valid:in boolean;
  stage1_config_ready:out boolean;
  stage1_reload_data:in std_logic_vector(31 downto 0);
  stage1_reload_valid:in boolean;
  stage1_reload_ready:out boolean;
  stage1_reload_last:in boolean;
  stage2_config_data:in std_logic_vector(7 downto 0);
  stage2_config_valid:in boolean;
  stage2_config_ready:out boolean;
  stage2_reload_data:in std_logic_vector(31 downto 0);
  stage2_reload_valid:in boolean;
  stage2_reload_ready:out boolean;
  stage2_reload_last:in boolean;
  -- outputs
  constant_fraction:in unsigned(CFD_BITS-2 downto 0);
  pulse_threshold:unsigned(THRESHOLD_BITS-2 downto 0);
  slope_threshold:unsigned(THRESHOLD_BITS-2 downto 0);
  pulse_area_threshold:unsigned(AREA_BITS-2 downto 0);
  -- signal_t default is signed 15.1 bits
  raw:out signal_t;
  raw_area:out area_t;
  raw_extrema:out signal_t;
  new_raw_area:out boolean;
  --w=16 f=BASELINE_AV_FRAC default is signed 11.5 bits
  baseline:out signal_t;
  stage1:out signal_t;
  stage1_area:out area_t;
  stage1_extrema:out signal_t;
  new_stage1_area:out boolean;
  stage2:out signal_t;
  stage2_area:out area_t;
  stage2_extrema:out signal_t;
  new_stage2_area:out boolean;
  pulse_detected:out boolean;
  accept_pulse:out boolean;
  reject_pulse:out boolean; -- pulse_area valid when asserted
  pulse_area:out area_t;
  pulse_length:out time_t;
  peak:out signal_t;
  peak_time:out time_t;
  new_peak:out boolean;
  minima:out signal_t;
  minima_time:out time_t;
  --new_minima:out boolean;
  cfd_value:out signal_t;
  new_cfd_value:out boolean
);
end entity dsp;
--
architecture RTL of dsp is
	
constant CFD_DELAY_DEPTH:integer:=64;
constant CFD_DELAY:integer:=50;
constant BASELINE_AV_FRAC:integer:=SIGNAL_BITS-BASELINE_BITS;
--
signal stage1_out:std_logic_vector(STAGE1_BITS-1 downto 0);
signal stage2_out:std_logic_vector(STAGE2_BITS-1 downto 0);
signal signal_out,signal_reg:signed(THRESHOLD_BITS-1 downto 0);	
signal slope_out:signed(THRESHOLD_BITS-1 downto 0);	
signal sample:sample_t;
signal stage1_input:signed(STAGE1_IN_BITS-1 downto 0);
signal baseline_estimate:signal_t;
signal baseline_range_error:boolean;
--signal raw_FIR_delay
signal raw_FIR_delay,raw_CFD_delay:std_logic_vector(SIGNAL_BITS-1 downto 0);
signal baseline_FIR_delay,baseline_CFD_delay:
			 std_logic_vector(SIGNAL_BITS-1 downto 0);
signal signal_CFD_delay:std_logic_vector(THRESHOLD_BITS-1 downto 0);
signal slope_positive:boolean;
signal slope_below_threshold:boolean;
signal slope_was_positive:boolean;
signal slope_was_below_threshold:boolean;
signal slope_armed:boolean;
signal cfd_threshold_reg,cfd_threshold:
			 signed(CFD_BITS+THRESHOLD_BITS-1 downto 0);
signal above_CFD_threshold : boolean;
signal was_above_CFD_threshold,CFD_valid:boolean;
signal slope_CFD_delay:std_logic_vector(THRESHOLD_BITS-1 downto 0);
signal signal_below_threshold:boolean;
signal signal_above_0,slope_above_0,raw_above_0:boolean;
signal signal_below_0,slope_below_0,raw_below_0:boolean;
signal signal_above_threshold:boolean;
signal signal_was_above_threshold:boolean;
signal pulse_start:boolean;
signal signal_area_int,slope_area_int:
			 signed(THRESHOLD_BITS+TIME_BITS-1 downto 0);
signal raw_area_int:signed(STAGE1_IN_BITS+TIME_BITS-1 downto 0);
signal signal_was_above_0,signal_was_below_0:boolean;
signal slope_was_above_0,slope_was_below_0:boolean;
signal raw_was_above_0,raw_was_below_0:boolean;
signal pulse_area_int:area_t;
signal signal_was_below_threshold,pulse_end:boolean;
signal pulse_length_int:time_t;
signal signal_equal_threshold:boolean;
signal signal_was_equal_threshold:boolean;
signal slope_negative,slope_was_negative:boolean;
signal minima_int:signed(THRESHOLD_BITS-1 downto 0);
signal minima_time_int:time_t;
signal raw_int,signal_int,slope_int:signal_t;
signal raw_extrema_int,signal_extrema_int,slope_extrema_int:signal_t;
--
begin
--	
sampleoffset:process(clk)
begin
if rising_edge(clk) then
	sample <= signed('0' & adc_sample) - signed('0' & adc_baseline);
end if;
end process sampleoffset;
--
baselineEstimator:entity work.baseline_estimator
generic map(
  BASELINE_BITS => BASELINE_BITS,
  COUNTER_BITS => BASELINE_COUNTER_BITS,
  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  MAX_AVERAGE_ORDER => BASELINE_MAX_AVERAGE_ORDER,
  OUT_BITS => BASELINE_BITS+BASELINE_AV_FRAC 
)
port map(
  clk => clk,
  reset => reset,
  sample => sample,
  sample_valid => TRUE,
  timeconstant => baseline_timeconstant,
  threshold => baseline_threshold,
  count_threshold => baseline_count_threshold,
  average_order => baseline_average_order,
  baseline_estimate => baseline_estimate,
  range_error => baseline_range_error
);
--
baselineSubraction:process(clk)
begin
if rising_edge(clk) then
	if baseline_subtraction then
		stage1_input 
			<= shift_left(resize(sample,STAGE1_IN_BITS),STAGE1_IN_FRAC) - 
				 resize(
				 	shift_right(baseline_estimate,BASELINE_AV_FRAC-STAGE1_IN_FRAC),
				 	STAGE1_IN_BITS
				 );		
	else
		stage1_input 
			<= shift_left(resize(sample,STAGE1_IN_BITS),STAGE1_IN_FRAC);
	end if;
end if;
end process baselineSubraction;
-- delay baseline and raw to sync with FIR outputs
FIR:entity work.two_stage_FIR
generic map(
	STAGE1_IN_BITS => 18,
	INTERSTAGE_SHIFT => INTERSTAGE_SHIFT,
  STAGE1_OUT_WIDTH => STAGE1_BITS,
  STAGE2_OUT_WIDTH => STAGE2_BITS
)
port map(
  clk => clk,
  sample => stage1_input,
  --interstage_shift => interstage_shift,
  stage1_config_data => stage1_config_data,
  stage1_config_valid => stage1_config_valid,
  stage1_config_ready => stage1_config_ready,
  stage1_reload_data => stage1_reload_data,
  stage1_reload_valid => stage1_reload_valid,
  stage1_reload_ready => stage1_reload_ready,
  stage1_reload_last => stage1_reload_last,
  stage2_config_data => stage2_config_data,
  stage2_config_valid => stage2_config_valid,
  stage2_config_ready => stage2_config_ready,
  stage2_reload_data => stage2_reload_data,
  stage2_reload_valid => stage2_reload_valid,
  stage2_reload_ready => stage2_reload_ready,
  stage2_reload_last => stage2_reload_last,
  stage1 => stage1_out,
  stage2 => stage2_out
);
--shift and resize outputs to match thresholding precision
filteredOut:process(clk)
begin
if rising_edge(clk) then
	signal_out <= resize(
		shift_right(signed(stage1_out),STAGE1_FRAC-THRESHOLD_FRAC),THRESHOLD_BITS);
end if;
end process filteredOut;
slopeOut:process(clk)
begin
if rising_edge(clk) then
	slope_out <= resize(
		shift_right(signed(stage2_out),STAGE2_FRAC-THRESHOLD_FRAC),THRESHOLD_BITS);
end if;
end process slopeOut;
--
raw_int <= resize(shift_right(stage1_input, STAGE1_IN_FRAC-SIGNAL_FRAC),
  						SIGNAL_BITS);
signal_int <= resize(
								shift_right(signed(signal_out),THRESHOLD_FRAC-SIGNAL_FRAC),
							SIGNAL_BITS); 
slope_int <= resize(
								shift_right(signed(slope_out),THRESHOLD_FRAC-SIGNAL_FRAC),
							SIGNAL_BITS); 
-- delay raw and baseline to sync with FIR outputs
rawFIRdelay:entity work.SREG_delay
generic map(
  DEPTH => 96,
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk => clk,
  data_in => to_std_logic(raw_int),
  delay => 86,
  delayed => raw_FIR_delay
);
--
baselineFIRdelay:entity work.SREG_delay
generic map(
  DEPTH => 96,
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk => clk,
  data_in => to_std_logic(resize(baseline_estimate,SIGNAL_BITS)),
  delay => 87,
  delayed => baseline_FIR_delay
);
-- 
slope_positive <= slope_out > 0;
slope_negative <= slope_out(THRESHOLD_BITS-1)='1';
slope_below_threshold 
	<= signed(slope_out) < signed('0' & slope_threshold);

signal_above_threshold <= signed(signal_out) > signed('0' & pulse_threshold);
signal_below_threshold <= signed(signal_out) <= signed('0' & pulse_threshold);
signal_equal_threshold <= signed(signal_out) = signed('0' & pulse_threshold);

signal_above_0 <= signed(signal_out) > 0;
signal_below_0 <= signal_out(THRESHOLD_BITS-1)='1';
slope_above_0 <= signed(slope_out) > 0;
slope_below_0 <= slope_out(THRESHOLD_BITS-1)='1';
raw_above_0 <= signed(stage1_input) > 0;
raw_below_0 <= stage1_input(SAMPLE_BITS-1)='1';

-- area accumulators w=THRESHOLD_BITS+TIME_BITS (default 41) f=THRESHOLD_FRAC
signalAreas:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
  	signal_area_int <= (others => '0');
  	slope_area_int <= (others => '0');
  	raw_area_int <= (others => '0');
  else
  	
  	raw_area_int <= raw_area_int + signed(stage1_input);
  	signal_area_int <= signal_area_int + signed(signal_out);
  	slope_area_int <= slope_area_int + signed(slope_out);

  	signal_was_above_0 <= signal_above_0;	
  	signal_was_below_0 <= signal_below_0;
  	if (signal_was_above_0 and not signal_above_0) or
  		 (signal_was_below_0 and not signal_below_0) then
  		stage1_area <= resize(shift_right(
  									 	signal_area_int,THRESHOLD_BITS+TIME_BITS-AREA_BITS
  									 ),AREA_BITS);
  		signal_area_int <= resize(signed(signal_out),THRESHOLD_BITS+TIME_BITS);
  		signal_extrema_int <= signal_int;
  		stage1_extrema <= signal_extrema_int;
  		new_stage1_area <= TRUE;
  	else
  		new_stage1_area <= FALSE;
  		if signal_above_0 and signal_int > signal_extrema_int then
  				signal_extrema_int <= signal_int;
  		end if;
  		if signal_below_0 and signal_int < signal_extrema_int then
  				signal_extrema_int <= signal_int;
  		end if;
  	end if;
    	 
  	slope_was_above_0 <= slope_above_0;	
  	slope_was_below_0 <= slope_below_0;
  	if (slope_was_above_0 and not slope_above_0) or
  		 (slope_was_below_0 and not slope_below_0) then
  		stage2_area <= resize(shift_right(
  									 	slope_area_int,THRESHOLD_BITS+TIME_BITS-AREA_BITS
  									 ),AREA_BITS);
  		slope_area_int <= resize(signed(slope_out),THRESHOLD_BITS+TIME_BITS);
  		slope_extrema_int <= slope_int;
  		stage2_extrema <= slope_extrema_int;
  		new_stage2_area <= TRUE;
  	else
  		new_stage2_area <= FALSE;
  		if slope_above_0 and slope_int > slope_extrema_int then
  				slope_extrema_int <= slope_int;
  		end if;
  		if slope_below_0 and slope_int < slope_extrema_int then
  				slope_extrema_int <= slope_int;
  		end if;
  	end if;

  	raw_was_above_0 <= raw_above_0;	
  	raw_was_below_0 <= raw_below_0;
  	if (raw_was_above_0 and not raw_above_0) or
  		 (raw_was_below_0 and not raw_below_0) then
  		raw_area <= resize(
  									shift_right(raw_area_int,STAGE1_IN_FRAC-AREA_FRAC),
  								AREA_BITS);
  		raw_area_int <= resize(signed(stage1_input),STAGE1_IN_BITS+TIME_BITS);
  		new_raw_area <= TRUE;
  		raw_extrema_int <= raw_int;
  		raw_extrema <= raw_extrema_int;
  	else
  		new_raw_area <= FALSE;
  		if raw_above_0 and raw_int > raw_extrema_int then
  				raw_extrema_int <= raw_int;
  		end if;
  		if raw_below_0 and raw_int < raw_extrema_int then
  				raw_extrema_int <= raw_int;
  		end if;
  	end if;
  end if;
end if;
end process signalAreas;

-- Detect peak of filtered_out via negative going zero crossing of slope_out
-- after slope has exceeded threshold.
-- Use the peak value to calculate the constant fraction threshold.
pulse_start <= signal_above_threshold and
							 (signal_was_below_threshold or signal_was_equal_threshold);
pulse_end <= ((signal_below_threshold or signal_equal_threshold) and
						  signal_was_above_threshold) or 
						  pulse_length_int=to_unsigned(2**TIME_BITS-1,TIME_BITS);
--
--minima <= resize(shift_right(minima_int,THRESHOLD_FRAC-SIGNAL_FRAC),SIGNAL_BITS);
--minima_time <= minima_time_int;						  
pulseMeasurement:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    slope_was_positive <= FALSE;
    slope_was_below_threshold <=FALSE;
    slope_armed <= FALSE;
    new_peak <= FALSE;
    --new_minima <= FALSE;
  else
  	signal_reg <= signal_out;
    slope_was_positive <= slope_positive;
    slope_was_negative <= slope_negative;
    slope_was_below_threshold <= slope_below_threshold;
    signal_was_above_threshold <= signal_above_threshold;
    signal_was_below_threshold <= signal_below_threshold;
    signal_was_equal_threshold <= signal_equal_threshold;
    reject_pulse <= FALSE;
    accept_pulse <= FALSE;
    pulse_detected <= pulse_start;
  	
  	if pulse_start then
  		pulse_area_int <= resize(signal_out,AREA_BITS);
  		pulse_length_int <= to_unsigned(1,TIME_BITS);
  	elsif signal_above_threshold then
  		pulse_area_int <= pulse_area_int+signal_out;
  		pulse_length_int <= pulse_length_int+1;
  	end if;
  	
  	if pulse_end then
  		pulse_area <= pulse_area_int;
  		pulse_length <= pulse_length_int;
  		if pulse_area_int >= signed( '0' & pulse_area_threshold) then
  			reject_pulse <= FALSE;
  			accept_pulse <= TRUE;
  		else
  			reject_pulse <= TRUE;
  			accept_pulse <= FALSE;
  		end if;
  	end if;
  	 
    if slope_was_below_threshold and not slope_below_threshold then
    	slope_armed <= TRUE;
    end if;
    
    if slope_was_positive and not slope_positive then
			slope_armed <= FALSE;
			if slope_armed and signal_above_threshold then 
				new_peak <= TRUE;
				peak <= resize(shift_right(
											 signal_reg,THRESHOLD_FRAC-SIGNAL_FRAC
								),SIGNAL_BITS);
				minima_int <= signal_reg;	
				minima <= resize(
										shift_right(minima_int,THRESHOLD_FRAC-SIGNAL_FRAC),
									SIGNAL_BITS);
				minima_time <= minima_time_int;
				peak_time <= pulse_length_int;
				-- this REG is absorbed into the DSP block multiplier.
				CFD_threshold_reg <= signal_reg*signed('0' & constant_fraction);
			end if;
		else
			if signal_out < minima_int then
				minima_int <= signal_reg;
				minima_time_int <= pulse_length_int;
			end if;
			new_peak <= FALSE;
		end if;
		
--		if slope_was_negative and not slope_negative then
--			minima <= resize(shift_right(
--											 signal_reg,THRESHOLD_FRAC-SIGNAL_FRAC
--								),SIGNAL_BITS);
--			new_minima <= TRUE;
--			minima_time <= pulse_length_int;
--		else
--			new_minima <= FALSE;
--		end if;
		-- this REG is absorbed into the DSP block multiplier.
		cfd_threshold <= CFD_threshold_reg;
  end if;
end if;
end process pulseMeasurement;
-- delay for constant fraction discrimination and to bring other signals to same 
-- latency, really only necessary align traces when implemented.
--
filteredCFDdelay:entity work.SREG_delay
generic map(
  DEPTH     => CFD_DELAY_DEPTH,
  DATA_BITS => THRESHOLD_BITS
)
port map(
  clk     => clk,
  data_in => to_std_logic(signal_out),
  delay   => CFD_DELAY,
  delayed => signal_CFD_delay
);
slopeCFDdelay:entity work.SREG_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => THRESHOLD_BITS
)
port map(
  clk     => clk,
  data_in => to_std_logic(slope_out),
  delay   => CFD_DELAY,
  delayed => slope_CFD_delay
);
rawCFDdelay:entity work.SREG_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk     => clk,
  data_in => raw_FIR_delay,
  delay   => CFD_DELAY,
  delayed => raw_CFD_delay
);
baselineCFDdelay:entity work.SREG_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk     => clk,
  data_in => baseline_FIR_delay,
  delay   => CFD_DELAY,
  delayed => baseline_CFD_delay
);
--
-- Thresholding and zero crossing
--
above_CFD_threshold <= signed(signal_CFD_delay) > 
			resize(shift_right(cfd_threshold,CFD_FRAC),THRESHOLD_BITS);
--
cfdValue:process(clk)
begin
if rising_edge(clk) then
	if reset='1' then
		was_above_CFD_threshold <= FALSE;
		CFD_valid <= FALSE;
	else
		was_above_CFD_threshold <= above_CFD_threshold;
		if not was_above_CFD_threshold and above_CFD_threshold then
			new_CFD_value <= TRUE;
			CFD_value <= resize(shift_right(
				signed(signal_CFD_delay),THRESHOLD_FRAC-SIGNAL_FRAC
			),SIGNAL_BITS);
		else
			new_CFD_value <= FALSE;
		end if;
			
    stage1 <= resize(
      shift_right(signed(signal_CFD_delay),THRESHOLD_FRAC-SIGNAL_FRAC),
      SIGNAL_BITS);
    stage2 <= resize(
      shift_right(signed(slope_CFD_delay),THRESHOLD_FRAC-SLOPE_FRAC),
      SIGNAL_BITS);
    raw <= signed(raw_CFD_delay);
    baseline <= signed(baseline_CFD_delay);
	end if;	
end if;
end process cfdValue;
--

end architecture RTL;
