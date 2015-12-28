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
	WIDTH:integer:=18;
	FRAC:integer:=3;
	--THRESHOLD_BITS:integer:=18;
	--THRESHOLD_FRAC:integer:=3;
	
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
  -- CFD value relative to last minima
  cfd_relative:in boolean;
  constant_fraction:in unsigned(CFD_BITS-2 downto 0);
  --unsigned w=THRESHOLD_BITS-1 f=THRESHOLD_FRAC (17,3) 
  pulse_threshold:unsigned(WIDTH-2 downto 0);
  --unsigned w=SIGNAL_BITS f=SLOPE_FRAC (16,8)
  slope_threshold:unsigned(SIGNAL_BITS-1 downto 0);
  -- signal area and extrema measurements
  raw_area:out area_t;
  raw_extrema:out signal_t;
  raw_measurement_valid:out boolean;
  filtered_area:out area_t;
  filtered_extrema:out signal_t;
  filtered_measurement_valid:out boolean;
  slope_area:out area_t;
  slope_extrema:out signal_t;
  slope_measurement_valid:out boolean;
  -- pulse measurements
  pulse_area:out area_t;
  --pulse_length:out time_t;
  pulse_extrema:out signal_t; --always a maxima
  pulse_measurement_valid:out boolean;
  --w=16 f=BASELINE_AV_FRAC default is signed 11.5 bits
  --baseline:out signal_t;
  raw:out signal_t;
  filtered:out signal_t;
  slope:out signal_t;
  slope_threshold_xing:out boolean; --@ output delay
  --
  pulse_detected:out boolean; -- @ FIR output delay
  peak:out boolean;
  minima:out signal_t;
  cfd:out boolean
);
end entity dsp;

architecture RTL of dsp is
	
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
	
component minima_queue
port( 
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(SIGNAL_BITS-1 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(SIGNAL_BITS-1 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;

component threshold_divider
port(
  aclk:in std_logic;
  s_axis_divisor_tvalid:in std_logic;
  s_axis_divisor_tready:out std_logic;
  s_axis_divisor_tdata:in std_logic_vector(15 downto 0);
  s_axis_dividend_tvalid:in std_logic;
  s_axis_dividend_tready:out std_logic;
  s_axis_dividend_tdata:in std_logic_vector(15 downto 0);
  m_axis_dout_tvalid:out std_logic;
  m_axis_dout_tdata:out std_logic_vector(23 downto 0)
);
end component;

constant CFD_DELAY_DEPTH:integer:=128;
constant CFD_DELAY:integer:=79;
constant BASELINE_AV_FRAC:integer:=SIGNAL_BITS-BASELINE_BITS;
--
signal signal_FIR:signed(WIDTH-1 downto 0);	
signal slope_FIR:signed(WIDTH-1 downto 0);	
signal sample:sample_t;
signal stage1_input:signed(WIDTH-1 downto 0);
signal baseline_estimate:signal_t;
signal baseline_range_error:boolean;
signal raw_FIR_delay,raw_CFD_delay:std_logic_vector(SIGNAL_BITS-1 downto 0);
signal signal_CFD_delay:std_logic_vector(WIDTH-1 downto 0);
signal slope_above:boolean;
signal slope_was_above:boolean;
signal slope_armed:boolean;
signal cfd_threshold_reg,cfd_threshold_reg2,cfd_threshold_int:
			 signed(CFD_BITS+WIDTH-1 downto 0);
signal cfd_threshold_in:signed(WIDTH-1 downto 0);
signal signal_below_CFD:boolean;
signal signal_was_below_CFD:boolean;
signal slope_CFD_delay:std_logic_vector(SIGNAL_BITS-1 downto 0);
signal signal_above_0,slope_above_0,raw_above_0:boolean;
signal signal_below_0,slope_below_0,raw_below_0:boolean;
signal signal_above_threshold:boolean;
signal pulse_start:boolean;
signal signal_area_int,slope_area_int:
			 signed(WIDTH+TIME_BITS-1 downto 0);
signal raw_area_int:signed(WIDTH+TIME_BITS-1 downto 0);
signal signal_was_above_0,signal_was_below_0:boolean;
signal slope_was_above_0,slope_was_below_0:boolean;
signal raw_was_above_0,raw_was_below_0:boolean;
signal pulse_area_int:area_t;
signal pulse_end:boolean;
signal raw_int,signal_int,slope_int:signal_t;
signal raw_extrema_int,signal_extrema_int,slope_extrema_int:signal_t;
signal pulse_extrema_int:signed(WIDTH-1 downto 0);
signal signal_xing,slope_xing:boolean;
signal signal_at_slope_xing:signed(WIDTH-1 downto 0);
signal signal_for_cfd:signed(WIDTH-1 downto 0);
signal flags,flags_CFD_delay:std_logic_vector(2 downto 0);
signal cfd_queue_wr_en,cfd_queue_rd_en,cfd_queue_full,cfd_queue_empty:std_logic;
signal cfd_threshold_out:std_logic_vector(WIDTH-1 downto 0);
signal cfd_threshold:signed(WIDTH-1 downto 0);
constant CFD_PIPE_DEPTH:integer:=4;
signal peak_pipe:boolean_vector(1 to CFD_PIPE_DEPTH);
signal cfd_overflow:boolean;
signal minima_int:signed(WIDTH-1 downto 0);
signal signal_above,signal_below:boolean;
signal signal_was_above,signal_was_below,signal_was_equal:boolean;
signal signal_pos_xing:boolean;
signal slope_below,slope_was_below:boolean;
signal minima_queue_wr_en:std_logic;
signal minima_queue_rd_en:std_logic;
signal minima_out,minima_reg:std_logic_vector(SIGNAL_BITS-1 downto 0);
signal minima_queue_full:std_logic;
signal minima_queue_empty:std_logic;
signal peak_cfd_delay:boolean;
signal start,start_reg:boolean;
signal start_cfd_delay:boolean;
type CFDFsmState is (IDLE,WAIT_MIN,MIN_XING,WAIT_CFD,CFD_XING);
signal state,nextstate:CFDFsmState;
signal minima_cfd_delay:signal_t;
signal signal_below_min,signal_was_below_min:boolean;
signal filtered_int:signal_t;
signal cfd_int:boolean;
signal min,max:boolean;
signal arm_slope:boolean;

begin

sampleoffset:process(clk)
begin
if rising_edge(clk) then
	sample <= signed('0' & adc_sample) - signed('0' & adc_baseline);
end if;
end process sampleoffset;

baselineEstimator:entity work.baseline_estimator
generic map(
  BASELINE_BITS => BASELINE_BITS,
  COUNTER_BITS => BASELINE_COUNTER_BITS,
  TIMECONSTANT_BITS => BASELINE_TIMECONSTANT_BITS,
  MAX_AVERAGE_ORDER => BASELINE_MAX_AVERAGE_ORDER,
  OUT_BITS => BASELINE_BITS+BASELINE_AV_FRAC 
)
port map(
  new_only => TRUE,
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

baselineSubraction:process(clk)
begin
if rising_edge(clk) then
	if baseline_subtraction then
		stage1_input 
			<= shift_left(resize(sample,WIDTH),FRAC) - 
				 resize(
				 	shift_right(baseline_estimate,BASELINE_AV_FRAC-FRAC),
				 	WIDTH
				 );		
	else
		stage1_input <= shift_left(resize(sample,WIDTH),FRAC);
	end if;
end if;
end process baselineSubraction;

-- delay baseline and raw to sync with FIR outputs
FIR:entity work.two_stage_FIR
generic map(
	WIDTH => 18
)
port map(
  clk => clk,
  sample_in => stage1_input,
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
  stage1 => signal_FIR,
  stage2 => slope_FIR
);

-- signal measurements
rawMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => stage1_input,
  area => raw_area,
  extrema => raw_extrema,
  valid => raw_measurement_valid
);

filteredMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_FIR,
  area => filtered_area,
  extrema => filtered_extrema,
  valid => filtered_measurement_valid
);

slopeMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_FIR,
  signal_out => open,
  pos_xing => open,
  neg_xing => open,
  area => slope_area,
  extrema => slope_extrema,
  valid => slope_measurement_valid
);

--thresholds

slope0xing:entity work.threshold_xing
generic map(
  THRESHOLD_BITS => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  threshold => signed('0' & slope_threshold),
  signal_in => slope_FIR,
  pos_xing => arm_slope,
  closest_pos_xing => open,
  neg_xing => open,
  closest_neg_xing => open,
  signal_out => slope_at_xing
);


peakDetection:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    slope_armed <= FALSE;
    signal_for_cfd <= (others => '0');
    peak_pipe <= (others => FALSE);
    cfd_queue_wr_en <= '0';
		minima_queue_wr_en <= '0';
		minima_int <= (others => '0');
	else
		start_reg <= start;
		if start then
  		minima_int <= (others => '0');
    elsif slope_was_below_0 and not slope_below_0 then
    	if signal_FIR < minima_int then
    		minima_int <= signal_FIR;
    	end if;
    end if;

    if slope_was_below and not slope_below then
    	slope_armed <= TRUE;
    	slope_xing <= not slope_armed;
    	signal_at_slope_xing <= signal_FIR;
    else
    	slope_xing <= FALSE;
    end if;
    --
    peak_pipe(2 to CFD_PIPE_DEPTH) <= peak_pipe(1 to CFD_PIPE_DEPTH-1);
    --FIXME this should fire when zero
    if slope_was_above_0 and not slope_above_0 then
			slope_armed <= FALSE;
			if slope_armed and signal_above then 
				if minima_queue_full = '0' then
					peak_pipe(1) <= TRUE;
					cfd_overflow <= FALSE;
					minima_int <= signal_FIR;
					--minima_int_reg <= minima_int;
          if cfd_relative then
            signal_for_cfd <= signal_FIR - minima_int;
            minima_reg <= to_std_logic(
              resize(
                shift_right(minima_int,WIDTH-SIGNAL_BITS),
                SIGNAL_BITS
              )
            );
          else
            signal_for_cfd <= signal_FIR;
            minima_reg <= (others => '0');
          end if;
					minima_queue_wr_en <= '1';
				else
					cfd_overflow <= TRUE;
					minima_queue_wr_en <= '0';
				end if;
				--
			end if;
		else
			minima_queue_wr_en <= '0';
			peak_pipe(1) <= FALSE;
		end if;
		-- this REG is absorbed into the DSP block multiplier.
		cfd_threshold_reg <= signal_for_cfd*signed('0' & constant_fraction);
		cfd_threshold_reg2 <= cfd_threshold_reg;
		cfd_threshold_int <= shift_right(cfd_threshold_reg2,CFD_FRAC);
		if cfd_queue_full = '0' and peak_pipe(CFD_PIPE_DEPTH) then
			cfd_queue_wr_en <= '1';
      if cfd_relative then
        cfd_threshold_in <= resize(cfd_threshold_int,WIDTH) + 
        										signed(minima_reg);
      else
        cfd_threshold_in <= resize(cfd_threshold_int,WIDTH);
    	end if;
    else
			cfd_queue_wr_en <= '0';
    end if;
  end if;
end if;
end process peakDetection;


slope_below 
	<= signed(slope_FIR) < resize(signed('0' & slope_threshold),WIDTH);
slope_above 
	<= signed(slope_FIR) > resize(signed('0' & slope_threshold),WIDTH);

--shift and resize outputs to match thresholding precision

raw_int <= resize(shift_right(stage1_input, FRAC-SIGNAL_FRAC),SIGNAL_BITS);
signal_int <= resize(shift_right(signal_FIR,FRAC-SIGNAL_FRAC),SIGNAL_BITS); 
slope_int <= resize(shift_right(slope_FIR,FRAC-SIGNAL_FRAC),SIGNAL_BITS); 
							
-- delay raw and baseline to sync with FIR outputs
rawFIRdelay:entity work.SREG_delay
generic map(
  DEPTH => 96,
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk => clk,
  data_in => to_std_logic(raw_int),
  delay => 90,
  delayed => raw_FIR_delay
);

-- FIXME metavalue here?
--signal_above_0 <= signed(signal_FIR) > 0;
--signal_below_0 <= signal_FIR(WIDTH-1)='1';
--slope_above_0 <= signed(slope_FIR) > 0;
--slope_below_0 <= slope_FIR(WIDTH-1)='1';
--raw_above_0 <= signed(stage1_input) > 0;
--raw_below_0 <= stage1_input(SAMPLE_BITS-1)='1';

--slope_is_0 <= slope_out = 0;
--FIXME this should use generics
signal_above 
	<= signed(signal_FIR) > resize(signed('0' & pulse_threshold),WIDTH);
signal_below 
	<= signed(signal_FIR) < resize(signed('0' & pulse_threshold),WIDTH);
--signal_equal <= signed(signal_out) = signed('0' & pulse_threshold);

signal_pos_xing <= signal_above and (signal_was_below or signal_was_equal);

xingReg:process (clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    signal_was_above_0 <= FALSE;	
    signal_was_below_0 <= FALSE;
    slope_was_above_0 <= FALSE;	
    slope_was_below_0 <= FALSE;
    raw_was_above_0 <= FALSE;	
    raw_was_below_0 <= FALSE;
    signal_was_below <= FALSE;
    signal_was_above <= FALSE;
    slope_was_above <= FALSE;
    slope_was_below <= FALSE;
  else
    signal_was_above_0 <= signal_above_0;	
    signal_was_below_0 <= signal_below_0;
    slope_was_above_0 <= slope_above_0;	
    slope_was_below_0 <= slope_below_0;
    raw_was_above_0 <= raw_above_0;	
    raw_was_below_0 <= raw_below_0;
    signal_was_below <= signal_below;
    signal_was_above <= signal_above;
    slope_was_above <= slope_above;
    slope_was_below <= slope_below;
  end if;
end if;
end process xingReg;

-- area accumulators w=THRESHOLD_BITS+TIME_BITS (default 41) f=THRESHOLD_FRAC
signalMeasurements:process(clk)
begin
if rising_edge(clk) then
	if reset = '1' then
  	signal_area_int <= (others => '0');
  	slope_area_int <= (others => '0');
  	raw_area_int <= (others => '0');
  	signal_extrema_int <= (others => '0');
  	slope_extrema_int <= (others => '0');
  	raw_extrema_int <= (others => '0');
  else
  	--
  	raw_area_int <= raw_area_int + signed(stage1_input);
  	signal_area_int <= signal_area_int + signed(signal_FIR);
  	slope_area_int <= slope_area_int + signed(slope_FIR);
    --	
  	if (signal_was_above_0 and not signal_above_0) or
  		 (signal_was_below_0 and not signal_below_0) then
  		filtered_area <= resize(
                         shift_right(
                           signal_area_int,WIDTH+TIME_BITS-AREA_BITS
                         ),
                         AREA_BITS
                       );
  		signal_area_int <= resize(signed(signal_FIR),WIDTH+TIME_BITS);
  		signal_extrema_int <= signal_int;
  		filtered_extrema <= signal_extrema_int;
  		filtered_measurement_valid <= TRUE;
  	else
  		filtered_measurement_valid <= FALSE;
  		if signal_above_0 and signal_int > signal_extrema_int then
  				signal_extrema_int <= signal_int;
  		end if;
  		if signal_below_0 and signal_int < signal_extrema_int then
  				signal_extrema_int <= signal_int;
  		end if;
  	end if;
    	 
  	
  	if (slope_was_above_0 and not slope_above_0) or
  		 (slope_was_below_0 and not slope_below_0) then
  		slope_area <= resize(shift_right(
  									 	slope_area_int,WIDTH+TIME_BITS-AREA_BITS
  									 ),AREA_BITS);
  		slope_area_int <= resize(signed(slope_FIR),WIDTH+TIME_BITS);
  		slope_extrema_int <= slope_int;
  		slope_extrema <= slope_extrema_int;
  		slope_measurement_valid <= TRUE;
  	else
  		slope_measurement_valid <= FALSE;
  		if slope_above_0 and slope_int > slope_extrema_int then
  				slope_extrema_int <= slope_int;
  		end if;
  		if slope_below_0 and slope_int < slope_extrema_int then
  				slope_extrema_int <= slope_int;
  		end if;
  	end if;

  	if (raw_was_above_0 and not raw_above_0) or
  		 (raw_was_below_0 and not raw_below_0) then
  		raw_area <= resize(
  									shift_right(raw_area_int,WIDTH-AREA_FRAC),
  								AREA_BITS);
  		raw_area_int <= resize(signed(stage1_input),WIDTH+TIME_BITS);
  		raw_measurement_valid <= TRUE;
  		raw_extrema_int <= raw_int;
  		raw_extrema <= raw_extrema_int;
  	else
  		raw_measurement_valid <= FALSE;
  		if raw_above_0 and raw_int > raw_extrema_int then
  				raw_extrema_int <= raw_int;
  		end if;
  		if raw_below_0 and raw_int < raw_extrema_int then
  				raw_extrema_int <= raw_int;
  		end if;
  	end if;
  end if;
end if;
end process signalMeasurements;

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

minimaQueue:minima_queue
port map (
  clk => clk,
  srst => reset,
  din => minima_reg,
  wr_en => minima_queue_wr_en,
  rd_en => minima_queue_rd_en,
  dout => minima_out,
  full => minima_queue_full,
  empty => minima_queue_empty
);

--signal_neg_xing <= (signal_out_below or signal_out_equal) and signal_was_above; 


--FIXME move start to this process
start <= signal_was_below and not signal_below;
peakDetection:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    slope_armed <= FALSE;
    signal_for_cfd <= (others => '0');
    peak_pipe <= (others => FALSE);
    cfd_queue_wr_en <= '0';
		minima_queue_wr_en <= '0';
		minima_int <= (others => '0');
	else
		start_reg <= start;
		if start then
  		minima_int <= (others => '0');
    elsif slope_was_below_0 and not slope_below_0 then
    	if signal_FIR < minima_int then
    		minima_int <= signal_FIR;
    	end if;
    end if;

    if slope_was_below and not slope_below then
    	slope_armed <= TRUE;
    	slope_xing <= not slope_armed;
    	signal_at_slope_xing <= signal_FIR;
    else
    	slope_xing <= FALSE;
    end if;
    --
    peak_pipe(2 to CFD_PIPE_DEPTH) <= peak_pipe(1 to CFD_PIPE_DEPTH-1);
    --FIXME this should fire when zero
    if slope_was_above_0 and not slope_above_0 then
			slope_armed <= FALSE;
			if slope_armed and signal_above then 
				if minima_queue_full = '0' then
					peak_pipe(1) <= TRUE;
					cfd_overflow <= FALSE;
					minima_int <= signal_FIR;
					--minima_int_reg <= minima_int;
          if cfd_relative then
            signal_for_cfd <= signal_FIR - minima_int;
            minima_reg <= to_std_logic(
              resize(
                shift_right(minima_int,WIDTH-SIGNAL_BITS),
                SIGNAL_BITS
              )
            );
          else
            signal_for_cfd <= signal_FIR;
            minima_reg <= (others => '0');
          end if;
					minima_queue_wr_en <= '1';
				else
					cfd_overflow <= TRUE;
					minima_queue_wr_en <= '0';
				end if;
				--
			end if;
		else
			minima_queue_wr_en <= '0';
			peak_pipe(1) <= FALSE;
		end if;
		-- this REG is absorbed into the DSP block multiplier.
		cfd_threshold_reg <= signal_for_cfd*signed('0' & constant_fraction);
		cfd_threshold_reg2 <= cfd_threshold_reg;
		cfd_threshold_int <= shift_right(cfd_threshold_reg2,CFD_FRAC);
		if cfd_queue_full = '0' and peak_pipe(CFD_PIPE_DEPTH) then
			cfd_queue_wr_en <= '1';
      if cfd_relative then
        cfd_threshold_in <= resize(cfd_threshold_int,WIDTH) + 
        										signed(minima_reg);
      else
        cfd_threshold_in <= resize(cfd_threshold_int,WIDTH);
    	end if;
    else
			cfd_queue_wr_en <= '0';
    end if;
  end if;
end if;
end process peakDetection;

-- delay for constant fraction discrimination and to bring other signals to same 
-- latency, really only necessary align traces when implemented.
flags <= (to_std_logic(start_reg),to_std_logic(peak_pipe(1)),
					to_std_logic(slope_xing)
				 );

flagsCFDdelay:entity work.SREG_delay
generic map(
  DEPTH     => CFD_DELAY_DEPTH,
  DATA_BITS => 3
)
port map(
  clk     => clk,
  data_in => flags,
  delay   => CFD_DELAY-1,
  delayed => flags_CFD_delay
);

filteredCFDdelay:entity work.SREG_delay
generic map(
  DEPTH     => CFD_DELAY_DEPTH,
  DATA_BITS => WIDTH
)
port map(
  clk     => clk,
  data_in => to_std_logic(signal_FIR),
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

-- Thresholding and zero crossing
signal_above_threshold 
  <= signed(signal_CFD_delay) > signed('0' & pulse_threshold);
						  
pulseMeasurement:process(clk)
begin
if rising_edge(clk) then
	if reset = '1' then
		pulse_extrema_int <= (others => '0');
		pulse_area_int <= (others => '0');
  else
  	pulse_measurement_valid <= FALSE;
  	--FIXME make this a flag
  	signal_xing <= pulse_start;
  	if pulse_start then
  		pulse_area_int <= resize(signed(signal_cfd_delay),AREA_BITS);
  		--pulse_length_int <= to_unsigned(1,TIME_BITS);
  		pulse_extrema_int <= signed(signal_cfd_delay); 
  	elsif signal_above_threshold then
  		if signed(signal_cfd_delay) > pulse_extrema_int then
  			pulse_extrema_int <= signed(signal_cfd_delay);
  		end if;
  		--pulse_length_int <= pulse_length_int+1;
  		pulse_area_int <= pulse_area_int+signed(signal_cfd_delay);
  	end if;
  	
  	if pulse_end then
  		pulse_area <= pulse_area_int;
  		pulse_extrema <= resize(
  			shift_right(pulse_extrema_int,FRAC-SIGNAL_FRAC),
  			SIGNAL_BITS
  		);
  		--pulse_length <= pulse_length_int;
  		pulse_measurement_valid <= TRUE;
  	end if;
  	
  end if;
end if;
end process pulseMeasurement;

--cfd_xing <= not signal_was_above_CFD and signal_above_CFD;

FSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			state <= IDLE;
		else
			state <= nextstate;
		end if;
	end if;
end process FSMnextstate;

peak_cfd_delay <= to_boolean(flags_cfd_delay(1));
start_cfd_delay <= to_boolean(flags_cfd_delay(2));
signal_below_min <= signed(filtered_int) < minima_cfd_delay;
signal_below_CFD <= signed(signal_CFD_delay) < cfd_threshold;

filtered_int 
	<= resize(
  	   shift_right(signed(signal_CFD_delay),FRAC-SIGNAL_FRAC),
  	   SIGNAL_BITS
  	 );
  	
FSMtransition:process(state,minima_queue_empty,signal_below_CFD,
											signal_below_min,signal_was_below_CFD,
											signal_was_below_min,slope_CFD_delay, cfd_queue_empty)
begin
	nextstate <= state;
	minima_queue_rd_en <= '0';
	cfd_queue_rd_en <= '0';
	cfd_int <= FALSE;
	case state is 
	when IDLE =>
		if minima_queue_empty = '0' then
			minima_queue_rd_en <= '1';
			nextstate <= WAIT_MIN;
		end if;
	when WAIT_MIN =>
		if signal_below_min or slope_CFD_delay(SIGNAL_BITS-1)='1' then
			nextstate <= MIN_XING;
		else
			nextstate <= WAIT_CFD;
		end if;
	when MIN_XING =>
		if not signal_below_min and signal_was_below_min then
			nextstate <= WAIT_CFD;
		end if;
	when WAIT_CFD =>
		if cfd_queue_empty='0' then
			nextstate <= CFD_XING;
			cfd_queue_rd_en <= '1';
		end if;
	when CFD_XING =>
		if not signal_below_cfd and signal_was_below_cfd then
			nextstate <= IDLE;
			cfd_int <= TRUE;
		end if;
	end case;
end process FSMtransition;

--slopeXing:threshold_divider
--port map (
--  aclk => clk,
--  s_axis_divisor_tvalid => s_axis_divisor_tvalid,
--  s_axis_divisor_tready => s_axis_divisor_tready,
--  s_axis_divisor_tdata => s_axis_divisor_tdata,
--  s_axis_dividend_tvalid => s_axis_dividend_tvalid,
--  s_axis_dividend_tready => s_axis_dividend_tready,
--  s_axis_dividend_tdata => s_axis_dividend_tdata,
--  m_axis_dout_tvalid => m_axis_dout_tvalid,
--  m_axis_dout_tdata => m_axis_dout_tdata
--);

constantFraction:process(clk)
begin
	if rising_edge(clk) then
		signal_was_below_min <= signal_below_min;
		signal_was_below_cfd <= signal_below_cfd;
		if minima_queue_rd_en='1' then
			minima_cfd_delay <= signed(minima_out);
		end if;
		if cfd_queue_rd_en='1' then
			cfd_threshold <= signed(cfd_threshold_out);
		end if;
		--if not signal_below_cfd and signal_was_below_cfd
    filtered <= filtered_int;
    slope <= signed(slope_CFD_delay);
    raw <= signed(raw_CFD_delay);
    --baseline <= signed(baseline_CFD_delay);
    peak <= peak_cfd_delay;
    pulse_detected <= start_cfd_delay;
    slope_threshold_xing <= to_boolean(flags_CFD_delay(0));
    cfd <= cfd_int;
	end if;
end process constantFraction;
minima <= minima_cfd_delay;
--
--filtered_threshold_xing <= to_boolean(flags_CFD_delay(0));
--

end architecture RTL;
