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
  BASELINE_BITS:integer:=10;
  --BASELINE_AV_FRAC:integer:=5;
  --width of counters and stream
  BASELINE_COUNTER_BITS:integer:=18;
  BASELINE_TIMECONSTANT_BITS:integer:=32;
  BASELINE_MAX_AVERAGE_ORDER:integer:=6;
  CFD_BITS:integer:=18;
  CFD_FRAC:integer:=17;
  MAX_PEAKS:integer:=2
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
  -- thresholds
  -- total threshold value at slope crossing
  cfd_relative:in boolean;
  constant_fraction:in unsigned(CFD_BITS-2 downto 0);
  pulse_threshold:unsigned(THRESHOLD_BITS-2 downto 0);
  slope_threshold:unsigned(THRESHOLD_BITS-2 downto 0);
  -- signal area and extrema measurements
  raw_area:out area_t;
  raw_extrema:out signal_t;
  new_raw_measurement:out boolean;
  filtered_area:out area_t;
  filtered_extrema:out signal_t;
  new_filtered_measurement:out boolean;
  slope_area:out area_t;
  slope_extrema:out signal_t;
  new_slope_measurement:out boolean;
  -- pulse measurements
  pulse_area:out area_t;
  pulse_length:out time_t;
  pulse_extrema:out signal_t; --always a maxima
  new_pulse_measurement:out boolean;
  --w=16 f=BASELINE_AV_FRAC default is signed 11.5 bits
  baseline:out signal_t;
  raw:out signal_t;
  filtered:out signal_t;
  slope:out signal_t;
  slope_threshold_xing:out boolean; --@ output delay
  --
  pulse_detected:out boolean; -- @ FIR output delay
  peak:out boolean;
  peak_num:out unsigned(MAX_PEAKS-1 downto 0);
  --new_minima:out boolean;
  cfd:out boolean
);
end entity dsp;
--
architecture RTL of dsp is
component cfd_threshold_queue
port( 
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(24 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(24 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;
	
constant CFD_DELAY_DEPTH:integer:=128;
constant CFD_DELAY:integer:=80;
constant BASELINE_AV_FRAC:integer:=SIGNAL_BITS-BASELINE_BITS;
--
signal stage1_out:std_logic_vector(STAGE1_BITS-1 downto 0);
signal stage2_out:std_logic_vector(STAGE2_BITS-1 downto 0);
signal signal_out:signed(THRESHOLD_BITS-1 downto 0);	
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
signal cfd_threshold_reg,cfd_threshold_reg2:
			 signed(CFD_BITS+THRESHOLD_BITS-1 downto 0);
signal cfd_threshold_in:signed(THRESHOLD_BITS-1 downto 0);
signal above_CFD_threshold:boolean;
signal was_above_CFD_threshold:boolean;
signal slope_CFD_delay:std_logic_vector(SIGNAL_BITS-1 downto 0);
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
signal signal_equal_threshold:boolean;
signal signal_was_equal_threshold:boolean;
signal slope_negative:boolean;
signal raw_int,signal_int,slope_int:signal_t;
signal raw_extrema_int,signal_extrema_int,slope_extrema_int:signal_t;
signal pulse_extrema_int:signed(THRESHOLD_BITS-1 downto 0);
signal signal_xing,slope_xing:boolean;
signal signal_at_slope_xing:signed(THRESHOLD_BITS-1 downto 0);
signal signal_for_cfd:signed(THRESHOLD_BITS-1 downto 0);
signal flags,flags_CFD_delay:std_logic_vector(1 downto 0);
signal signal_out_above_threshold:boolean;
signal pulse_length_int:time_t;
signal cfd_xing:boolean;
signal cfd_queue_wr_en,cfd_queue_rd_en,cfd_queue_full,cfd_queue_empty:std_logic;
signal cfd_threshold_out:std_logic_vector(THRESHOLD_BITS-1 downto 0);
signal cfd_threshold:signed(THRESHOLD_BITS-1 downto 0);
constant CFD_PIPE_DEPTH:integer:=3;
signal peak_pipe:boolean_vector(1 to CFD_PIPE_DEPTH);
signal cfd_overflow:boolean;
signal cfd_pending:boolean;
signal slope_was_negative:boolean;

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
								shift_right(signed(slope_out),THRESHOLD_FRAC-SLOPE_FRAC),
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
--FIXME remove the baseline output
baselineFIRdelay:entity work.SREG_delay
generic map(
  DEPTH => 96,
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk => clk,
  data_in => to_std_logic(
  	resize(
  		shift_right(baseline_estimate,BASELINE_AV_FRAC-SIGNAL_FRAC),
  		SIGNAL_BITS
  	)
  ),
  delay => 87,
  delayed => baseline_FIR_delay
);

-- FIXME metavalue here?
slope_positive <= slope_out > 0;
slope_negative <= slope_out(THRESHOLD_BITS-1)='1';
slope_below_threshold 
	<= signed(slope_out) < signed('0' & slope_threshold);

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
  		filtered_area <= resize(shift_right(
  									 	signal_area_int,THRESHOLD_BITS+TIME_BITS-AREA_BITS
  									 ),AREA_BITS);
  		signal_area_int <= resize(signed(signal_out),THRESHOLD_BITS+TIME_BITS);
  		signal_extrema_int <= signal_int;
  		filtered_extrema <= signal_extrema_int;
  		new_filtered_measurement <= TRUE;
  	else
  		new_filtered_measurement <= FALSE;
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
  		slope_area <= resize(shift_right(
  									 	slope_area_int,THRESHOLD_BITS+TIME_BITS-AREA_BITS
  									 ),AREA_BITS);
  		slope_area_int <= resize(signed(slope_out),THRESHOLD_BITS+TIME_BITS);
  		slope_extrema_int <= slope_int;
  		slope_extrema <= slope_extrema_int;
  		new_slope_measurement <= TRUE;
  	else
  		new_slope_measurement <= FALSE;
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
  		new_raw_measurement <= TRUE;
  		raw_extrema_int <= raw_int;
  		raw_extrema <= raw_extrema_int;
  	else
  		new_raw_measurement <= FALSE;
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

signal_out_above_threshold 
	<= signed(signal_out) > signed('0' & pulse_threshold);
-- Detect peak of filtered_out via negative going zero crossing of slope_out
-- after slope has exceeded threshold.
-- Use the peak value to calculate the constant fraction threshold.
--
cfdThresholdQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => reset,
  din => to_std_logic(cfd_threshold_in),
  wr_en => cfd_queue_wr_en,
  rd_en => cfd_queue_rd_en,
  dout => cfd_threshold_out,
  full => cfd_queue_full,
  empty => cfd_queue_empty
);
peakDetect:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    slope_was_positive <= FALSE;
    slope_was_below_threshold <=FALSE;
    slope_armed <= FALSE;
    signal_for_cfd <= (others => '0');
    peak_pipe <= (others => FALSE);
    cfd_queue_wr_en <= '0';
  else
  	slope_was_positive <= slope_positive;
  	slope_was_negative <= slope_negative;
    slope_was_below_threshold <= slope_below_threshold;
  	 
    if slope_was_below_threshold and not slope_below_threshold then
    	slope_armed <= TRUE;
    	slope_xing <= not slope_armed;
    	signal_at_slope_xing <= signal_out;
    else
    	slope_xing <= FALSE;
    end if;
    
    peak_pipe(2 to CFD_PIPE_DEPTH) <= peak_pipe(1 to CFD_PIPE_DEPTH-1);
    if slope_was_positive and not slope_positive then
			slope_armed <= FALSE;
			if slope_armed and signal_out_above_threshold then 
				if cfd_queue_full = '0' then
					peak_pipe(1) <= TRUE;
					cfd_overflow <= FALSE;
				else
					cfd_overflow <= TRUE;
				end if;
				-- this REG is absorbed into the DSP block multiplier.
				if cfd_relative then
			    signal_for_cfd <= (signal_out - signal_at_slope_xing);
				else
			    signal_for_cfd <= signal_out;
				end if;
			end if;
		else
			peak_pipe(1) <= FALSE;
		end if;
		--
		-- this REG is absorbed into the DSP block multiplier.
		CFD_threshold_reg <= signal_for_cfd*signed('0' & constant_fraction);
		cfd_threshold_reg2 <= CFD_threshold_reg;
		if cfd_queue_full = '0' and peak_pipe(CFD_PIPE_DEPTH) then
			cfd_queue_wr_en <= '1';
      if cfd_relative then
        cfd_threshold_in <= resize(
            shift_right(cfd_threshold_reg2,CFD_FRAC), THRESHOLD_BITS
          ) + signal_at_slope_xing;
      else
        cfd_threshold_in <= resize( 
        		shift_right(cfd_threshold_reg2,CFD_FRAC),
            THRESHOLD_BITS
          );
    	end if;
    else
			cfd_queue_wr_en <= '0';
    end if;
  end if;
end if;
end process peakDetect;
-- delay for constant fraction discrimination and to bring other signals to same 
-- latency, really only necessary align traces when implemented.
--
flags <= (to_std_logic(peak_pipe(1)),to_std_logic(slope_xing));
flagsCFDdelay:entity work.SREG_delay
generic map(
  DEPTH     => CFD_DELAY_DEPTH,
  DATA_BITS => 2
)
port map(
  clk     => clk,
  data_in => flags,
  delay   => CFD_DELAY,
  delayed => flags_CFD_delay
);
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
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk     => clk,
  data_in => to_std_logic(slope_int),
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
signal_above_threshold 
	<= signed(signal_CFD_delay) > signed('0' & pulse_threshold);
signal_below_threshold 
	<= signed(signal_CFD_delay) < signed('0' & pulse_threshold);
signal_equal_threshold 
	<= signed(signal_CFD_delay) = signed('0' & pulse_threshold);

pulse_start <= signal_above_threshold and
							 (signal_was_below_threshold or signal_was_equal_threshold);
							 
pulse_end <= ((signal_below_threshold or signal_equal_threshold) and
						  signal_was_above_threshold) or 
						  pulse_length_int=to_unsigned(2**TIME_BITS-1,TIME_BITS);
						  
pulseMeasurement:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    signal_was_above_threshold <= FALSE;
    signal_was_below_threshold <= FALSE;
    signal_was_equal_threshold <= FALSE;
  else
    signal_was_above_threshold <= signal_above_threshold;
    signal_was_below_threshold <= signal_below_threshold;
    signal_was_equal_threshold <= signal_equal_threshold;
    
    new_pulse_measurement <= FALSE;
  	signal_xing <= pulse_start;
  	
  	if pulse_start then
  		pulse_area_int <= resize(signed(signal_cfd_delay),AREA_BITS);
  		pulse_length_int <= to_unsigned(1,TIME_BITS);
  		pulse_extrema_int <= signed(signal_cfd_delay); 
  	elsif signal_above_threshold then
  		if signed(signal_cfd_delay) > pulse_extrema_int then
  			pulse_extrema_int <= signed(signal_cfd_delay);
  		end if;
  		pulse_length_int <= pulse_length_int+1;
  		pulse_area_int <= pulse_area_int+signed(signal_cfd_delay);
  	end if;
  	
  	if pulse_end then
  		pulse_area <= pulse_area_int;
  		pulse_extrema <= resize(
  			shift_right(pulse_extrema_int,THRESHOLD_FRAC-SIGNAL_FRAC),
  			SIGNAL_BITS
  		);
  		pulse_length <= pulse_length_int;
  		new_pulse_measurement <= TRUE;
  	end if;
  	
  end if;
end if;
end process pulseMeasurement;
--
above_CFD_threshold <= signed(signal_CFD_delay) >= cfd_threshold;
cfd_xing <= not was_above_CFD_threshold and above_CFD_threshold;
--
outputReg:process(clk)
begin
if rising_edge(clk) then
	if reset='1' then
		was_above_CFD_threshold <= FALSE; 
		cfd_pending <= FALSE;
		cfd_threshold <= (others => '0');
	else
		was_above_CFD_threshold <= above_CFD_threshold;
		
		if cfd_queue_empty='0' and not cfd_pending then
			cfd_threshold <= signed(cfd_threshold_out);
			cfd_pending <= TRUE;
			cfd_queue_rd_en <= '1';
		else
			cfd_queue_rd_en <= '0';
		end if;	
		
		if cfd_pending then 
			cfd <= above_cfd_threshold;
			if above_cfd_threshold then
				if cfd_queue_empty = '0' then
					cfd_threshold <= signed(cfd_threshold_out);
					cfd_queue_rd_en <= '1';
				else
					cfd_pending <= FALSE;
					cfd_queue_rd_en <= '0';
				end if;
			end if;
		else
			cfd_queue_rd_en <= '1';
			cfd <= FALSE;
		end if;
	end if;	
  filtered <= resize(
    shift_right(signed(signal_CFD_delay),THRESHOLD_FRAC-SIGNAL_FRAC),
    SIGNAL_BITS);
  slope <= signed(slope_CFD_delay);
  raw <= signed(raw_CFD_delay);
  baseline <= signed(baseline_CFD_delay);
end if;
end process outputReg;
--
pulse_detected <= signal_xing;
peak <= to_boolean(flags_CFD_delay(1));
slope_threshold_xing <= to_boolean(flags_CFD_delay(0));
--filtered_threshold_xing <= to_boolean(flags_CFD_delay(0));
--

end architecture RTL;
