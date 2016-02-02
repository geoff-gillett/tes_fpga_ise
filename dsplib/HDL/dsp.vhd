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
	TIME_BITS:integer:=16;
	TIME_FRAC:integer:=0;
  BASELINE_BITS:integer:=10;
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
  slope_threshold:unsigned(WIDTH-2 downto 0);
  -- signal area and extrema measurements
  raw:out signal_t;
  raw_area:out area_t;
  raw_extrema:out signal_t;
  raw_valid:out boolean;
  --
  filtered:out signal_t;
  filtered_area:out area_t;
  filtered_extrema:out signal_t;
  filtered_valid:out boolean;
  --
  slope:out signal_t;
  slope_area:out area_t;
  slope_extrema:out signal_t;
  slope_valid:out boolean;
  -- pulse measurements
  --w=16 f=BASELINE_AV_FRAC default is signed 11.5 bits
  --baseline:out signal_t;
  --raw:out signal_t;
  slope_threshold_xing:out boolean; --@ output delay
  -- flags
  peak_start:out boolean; -- minima that starts the peak/pulse;
  peak:out boolean;
  pulse_pos_xing:out boolean; -- 
  pulse_neg_xing:out boolean; -- 
  peak_minima:out signal_t; --value at bottom of peak
  cfd_low:out boolean;
  cfd_high:out boolean;
  pulse_area:out area_t;
  pulse_extrema:out signal_t; --always a maxima
  pulse_valid:out boolean;
  cfd_error:out boolean;
  time_overflow:out boolean
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
	
constant CFD_DELAY_DEPTH:integer:=256;
constant CFD_DELAY:integer:=200;
constant BASELINE_AV_FRAC:integer:=SIGNAL_BITS-BASELINE_BITS;
--
signal signal_FIR:signed(WIDTH-1 downto 0);	
signal slope_FIR:signed(WIDTH-1 downto 0);	
signal sample:sample_t;
signal stage1_input:signed(WIDTH-1 downto 0);
signal baseline_estimate:signal_t;
signal baseline_range_error:boolean;
--signal raw_FIR_delay,raw_CFD_delay:std_logic_vector(SIGNAL_BITS-1 downto 0);
signal signal_CFD_delay:std_logic_vector(WIDTH-1 downto 0);
--signal slope_above:boolean;
signal cf_of_peak,cf_of_peak_reg:signed(CFD_BITS+WIDTH-1 downto 0);
signal cf_of_peak_reg2:signed(CFD_BITS+WIDTH-1 downto 0);
signal cfd_low_in:signed(WIDTH-1 downto 0);
signal slope_CFD_delay:std_logic_vector(WIDTH-1 downto 0);
signal pulse_start:boolean;
signal pulse_area_reg:area_t;
signal pulse_end:boolean;
signal raw_extrema_int,signal_extrema_int:signed(WIDTH-1 downto 0);
signal slope_extrema_int:signed(WIDTH-1 downto 0);
signal pulse_extrema_reg:signed(WIDTH-1 downto 0);
signal signal_for_cfd:signed(WIDTH-1 downto 0);
signal flags,flags_CFD_delay:std_logic_vector(4 downto 0);
signal cfd_low_out:std_logic_vector(WIDTH-1 downto 0);
signal cfd_low_threshold:signed(WIDTH-1 downto 0);
constant MULT_PIPE_DEPTH:integer:=4;
signal peak_pipe:boolean_vector(1 to MULT_PIPE_DEPTH);
signal first_rise_pipe:boolean_vector(1 to MULT_PIPE_DEPTH);
signal minima_int,minima_reg:signed(WIDTH-1 downto 0);
signal queue_rd_en:std_logic;
signal minima_out:std_logic_vector(WIDTH-1 downto 0);
signal queue_full:std_logic;
signal queue_empty:std_logic;
type cfdFSMstate is (IDLE,WAIT_MIN,WAIT_PEAK);
signal cfd_state,cfd_nextstate:cfdFSMstate;
signal minima_cfd:signed(WIDTH-1 downto 0);
signal cfd_low_int:boolean;
signal min,max:boolean;
--signal slope_pos_xing:boolean;
signal slope_out:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH-1 downto 0);
signal signal_at_cfd,slope_at_cfd:signed(WIDTH-1 downto 0);
signal min_at_cfd:boolean;
signal peak_at_cfd:boolean;
type peakFSMstate is (WAITING,ARMED);
signal pd_state,pd_nextstate:peakFSMstate;
type pulseFSMstate is (IDLE,FIRST_RISE,PEAKED);
signal pulse_state,pulse_nextstate:pulseFSMstate;
--
signal peak_int:boolean;
signal queue_overflow:boolean;
signal queue_wr_en:std_logic;
--signal peaked:boolean;
--signal write_queue:boolean;
signal slope_pos_xing:boolean;
signal signal_pos_xing,signal_neg_xing:boolean;
signal filtered_area_int:signed(AREA_BITS-1 downto 0);
signal filtered_valid_int:boolean;
signal slope_area_int:signed(AREA_BITS-1 downto 0);
signal slope_valid_int:boolean;
signal pulse_stop:boolean;
signal pulse_valid_int:boolean;
signal signal_cfd_reg,signal_cfd_reg2:signed(WIDTH-1 downto 0);
signal signal_is_min:boolean;
signal start_int,stop_int:boolean;
signal cfd_low_xing:boolean;
signal pulse_length:unsigned(TIME_BITS-TIME_FRAC-1 downto 0);
signal time_overflow_int:boolean;
signal arming:boolean;
signal cfd_error_int:boolean;
signal min_valid:boolean;
signal slope_xing_at_cfd:boolean;
signal cfd_high_out:std_logic_vector(WIDTH-1 downto 0);
signal cfd_high_in:signed(WIDTH-1 downto 0);
signal peak_for_cfd:signed(WIDTH-1 downto 0);
signal cfd_high_threshold:signed(WIDTH-1 downto 0);
signal cfd_high_xing:boolean;
signal cfd_high_int:boolean;
signal minima_for_cfd:signed(WIDTH-1 downto 0);
signal cfd_reset:boolean;
signal cfd_low_crossed,cfd_high_crossed:boolean;
signal cfd_high_done,cfd_low_done:boolean;
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
				 	shift_right(to_0IfX(baseline_estimate),BASELINE_AV_FRAC-FRAC),
				 	WIDTH
				 );		
	else
		stage1_input <= shift_left(resize(sample,WIDTH),FRAC);
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
  --w=18 f=3
  stage1 => signal_FIR,
  --w=18 f=8
  stage2 => slope_FIR
);

rawMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => stage1_input,
  signal_out => raw,
  threshold => (others => '0'),
  pos_xing => open,
  neg_xing => open,
  pos_0xing => open,
  neg_0xing => open,
  pos_0closest => open,
  neg_0closest => open,
  area => raw_area,
  extrema => raw_extrema_int,
  valid => raw_valid
);
raw_extrema <= resize(
							   shift_right(raw_extrema_int,FRAC-SIGNAL_FRAC),
								   SIGNAL_BITS
								 );
								 
slopeXing:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => slope_FIR,
  signal_out => slope_out,
  threshold => signed('0' & slope_threshold),
  pos_xing => slope_pos_xing,
  neg_xing => open,
  pos_0xing => open,
  neg_0xing => open,
  pos_0closest => min,
  neg_0closest => max,
  area => open,
  extrema => open,
  valid => open
);

signalXing:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_FIR,
  signal_out => signal_out,
  threshold => signed('0' & pulse_threshold),
  pos_xing => signal_pos_xing,
  neg_xing => signal_neg_xing,
  pos_0xing => open,
  neg_0xing => open,
  pos_0closest => open,
  neg_0closest => open,
  area => open,
  extrema => open,
  valid => open
);

pdNextstate:process(clk)
begin
	if rising_edge(clk) then
		if cfd_reset then
			pd_state <= WAITING;
			pulse_state <= IDLE;
		else
			pd_state <= pd_nextstate;
			pulse_state <= pulse_nextstate;
		end if;
	end if;
end process pdNextstate;

pdTransition:process(pd_state,max,slope_pos_xing)
begin
	pd_nextstate <= pd_state;
	case pd_state is 
		when WAITING =>
			if slope_pos_xing then
				pd_nextstate <= ARMED;
			end if;
		when ARMED =>
			if max then
				pd_nextstate <= WAITING;
			end if; 
	end case;
end process pdTransition;

pulseTransition:process(pulse_state,signal_pos_xing,signal_neg_xing,
												time_overflow_int,max)
begin
	pulse_nextstate <= pulse_state;
	case pulse_state is 
	when IDLE =>
		if signal_pos_xing then
			pulse_nextstate <= FIRST_RISE;
		end if;
	when FIRST_RISE =>
		if signal_neg_xing or time_overflow_int then
			pulse_nextstate <= IDLE;
		elsif max then 
			pulse_nextstate <= PEAKED;
		end if;
	when PEAKED =>
		if signal_neg_xing or time_overflow_int then
			pulse_nextstate <= IDLE;
		end if;
	end case;
end process pulseTransition;

peak_int <= pd_state=ARMED and pulse_state/=IDLE and max;
start_int <= pulse_state=IDLE and signal_pos_xing;
stop_int <= (pulse_state/=IDLE and signal_neg_xing) or time_overflow_int;
--write_queue <= cfd_queue_full='0' and peak_pipe(MULT_PIPE_DEPTH);
arming <= pd_state=WAITING and slope_pos_xing;
time_overflow_int <= pulse_length=0;

pdReg:process(clk)
begin
	if rising_edge(clk) then
		if cfd_reset then
			minima_int <= (others => '0');
			pulse_length <= to_unsigned(1,TIME_BITS-TIME_FRAC);
			queue_wr_en <= '0';
		else
			
			if start_int then
				pulse_length <= to_unsigned(1,TIME_BITS-TIME_FRAC);
			else
				pulse_length <= pulse_length+1;
			end if;
			
      if min and pd_state=WAITING then	
      	minima_int <= signal_out;	
      end if;
      
     	if arming then 
     		minima_reg <= minima_int;
      end if;
      
      if peak_int then
        --minima_reg <= minima_int;
        minima_for_cfd <= minima_reg;
        peak_for_cfd <= signal_out;
        if  pulse_state=FIRST_RISE and not cfd_relative then
          signal_for_cfd <= signal_out;
        else
          signal_for_cfd <= signal_out-minima_int;
        end if;
      end if;
 			
 			time_overflow <= time_overflow_int;
 			
      peak_pipe(1) <= peak_int;
      peak_pipe(2 to MULT_PIPE_DEPTH) <= peak_pipe(1 to MULT_PIPE_DEPTH-1);
      first_rise_pipe(1) <= pulse_state=FIRST_RISE; 
      first_rise_pipe(2 to MULT_PIPE_DEPTH) 
      	<= first_rise_pipe(1 to MULT_PIPE_DEPTH-1);
      --registers to be absorbed into multiplier macro
      cf_of_peak <= signal_for_cfd*signed('0' & constant_fraction);
      cf_of_peak_reg <= cf_of_peak;
      cf_of_peak_reg2 <= cf_of_peak_reg;
     
      if peak_pipe(MULT_PIPE_DEPTH) then
      	if queue_full='0' then
		      queue_overflow <= FALSE;
      		queue_wr_en <= '1';
      		--FIXME this will fail if pulse ends within 4 clocks of peak
          if first_rise_pipe(MULT_PIPE_DEPTH) and not cfd_relative then
            cfd_low_in <= resize(shift_right(cf_of_peak_reg2,CFD_FRAC),WIDTH);
          else
            cfd_low_in 
              <= resize(shift_right(cf_of_peak_reg2,CFD_FRAC),WIDTH)+
                 minima_for_cfd;
          end if;
          cfd_high_in 
            <= peak_for_cfd-resize(shift_right(cf_of_peak_reg2,CFD_FRAC),WIDTH);
        else
		      queue_overflow <= TRUE;
       	end if;
      else
	      queue_overflow <= FALSE;
        queue_wr_en <= '0';
      end if;
    end if;
	end if;
end process pdReg;

cfdLowQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => to_std_logic(cfd_reset),
  din => to_std_logic(cfd_low_in),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => cfd_low_out,
  full => queue_full,
  empty => queue_empty
);

cfdHighQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => to_std_logic(cfd_reset),
  din => to_std_logic(cfd_high_in),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => cfd_high_out,
  full => open,
  empty => open
);

minimaQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => to_std_logic(cfd_reset),
  din => to_std_logic(minima_reg),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => minima_out,
  full => open,
  empty => open
);

flags <= (to_std_logic(start_int),
					to_std_logic(stop_int),
					to_std_logic(peak_int),
					to_std_logic(min),
					to_std_logic(arming)
				 );

-- TODO make this break the delays up into 64 bit lots with a reg at the end 
flagsCFDdelay:entity work.RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => 5
)
port map(
  clk     => clk,
  data_in => flags,
  delay   => CFD_DELAY+3,
  delayed => flags_CFD_delay
);

pulse_start <= to_boolean(flags_cfd_delay(4));
pulse_stop <= to_boolean(flags_cfd_delay(3));
peak_at_cfd <= to_boolean(flags_cfd_delay(2));
min_at_cfd <= to_boolean(flags_cfd_delay(1));
slope_xing_at_cfd <= to_boolean(flags_cfd_delay(0));

signalCFDdelay:entity work.RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => to_std_logic(signal_out),
  delay => CFD_DELAY,
  delayed => signal_CFD_delay
);

slopeCFDdelay:entity work.RAM_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => to_std_logic(slope_out),
  delay => CFD_DELAY,
  delayed => slope_CFD_delay
);

filteredMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(signal_CFD_delay),
  threshold => signed('0' & pulse_threshold),
  signal_out => signal_at_cfd,
  pos_xing => open, --pulse_start,
  neg_xing => open, --pulse_stop,
  pos_0xing => open,
  neg_0xing => open,
  area => filtered_area_int,
  extrema => signal_extrema_int,
  valid => filtered_valid_int
);

slopeMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => SLOPE_FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(slope_CFD_delay),
  threshold => signed('0' & slope_threshold),
  signal_out => slope_at_cfd,
  pos_0xing => open,
  neg_0xing => open,
  pos_xing => open,
  neg_xing => open,
  pos_0closest => open,
  neg_0closest => open,
  area => slope_area_int,
  extrema => slope_extrema_int,
  valid => slope_valid_int
);

pulseMeasurement:process(clk)
begin
if rising_edge(clk) then
	if reset = '1' then
		pulse_extrema_reg <= (others => '0');
		pulse_area_reg <= (others => '0');
	else
  	pulse_valid_int <= pulse_end;
  	--FIXME make this a flag
  	if pulse_start then
  		--pulse_length <= to_unsigned(1,TIME_BITS-TIME_FRAC);
  		pulse_area_reg <= resize(signed(signal_at_cfd),AREA_BITS);
  		pulse_extrema_reg <= signed(signal_at_cfd); 
  	else
  		--pulse_length <= pulse_length+1;
  		if signed(signal_at_cfd) > pulse_extrema_reg then
  			pulse_extrema_reg <= signed(signal_at_cfd);
  		end if;
  		pulse_area_reg <= pulse_area_reg+signed(signal_at_cfd);
  	end if;
  	if pulse_stop then
  		pulse_area <= shift_right(pulse_area_reg,FRAC-AREA_FRAC);
  		pulse_extrema 
  			<= resize(shift_right(pulse_extrema_reg,FRAC-SIGNAL_FRAC),SIGNAL_BITS);
  		pulse_valid <= TRUE;
  	else 
  		pulse_valid <= FALSE;
  	end if;
    filtered_extrema <= resize(
                          shift_right(signal_extrema_int,FRAC-SIGNAL_FRAC),
                          SIGNAL_BITS
                        );
  	filtered_area <= filtered_area_int;
  	filtered_valid <= filtered_valid_int;	
    slope_extrema <= resize(
                       shift_right(slope_extrema_int,FRAC-SIGNAL_FRAC),
                       SIGNAL_BITS
                     );
  	slope_area <= slope_area_int;
  	slope_valid <= slope_valid_int;	
  end if;
end if;
end process pulseMeasurement;

cfdLowXing:entity work.closest_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  signal_in => signed(signal_cfd_delay),
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
  signal_in => signed(signal_cfd_delay),
  threshold => cfd_high_threshold,
  signal_out => open,
  pos => cfd_high_xing,
  neg => open
);

-- signal_cfd_reg2 is 1 clock before signal_cfd
-- equivalent register removal should optimise this and equate with the 
-- registers inside fiteredMeasurement and cfdXing.
signalCFDreg:process(clk)
begin
	if rising_edge(clk) then
		signal_cfd_reg <= signed(signal_cfd_delay);
		signal_cfd_reg2 <= signal_cfd_reg;
		signal_is_min <= to_0ifX(signal_cfd_reg2)=to_0IfX(minima_cfd);
	end if;
end process signalCFDreg;

cfdFSMnextstate:process(clk)
begin
	if rising_edge(clk) then
		if cfd_reset then
			cfd_state <= IDLE;
		else
			cfd_state <= cfd_nextstate;
		end if;
	end if;
end process cfdFSMnextstate;

--FIXME The CFD process will not work properly on arbitrary signals. With some 
--further thought I think it could. Meanwhile this should be OK for TES signals.
min_valid <= min_at_cfd and signal_is_min;

cfdFSMtransition:process(peak_at_cfd,queue_empty,cfd_state,min_valid, 
												 cfd_high_xing,cfd_low_xing)
begin
	cfd_nextstate <= cfd_state;
	cfd_low_int <= FALSE;
	cfd_high_int <= FALSE;
	case cfd_state is 
	when IDLE =>
		if queue_empty='0' then
			cfd_nextstate <= WAIT_MIN;
		end if;
	when WAIT_MIN =>
		if min_valid then
			cfd_nextstate <= WAIT_PEAK;
      cfd_low_int <= cfd_low_xing;
      cfd_high_int <= cfd_high_xing;
		end if;
	when WAIT_PEAK =>
		if peak_at_cfd then
			cfd_nextstate <= IDLE;
		end if;
    cfd_low_int <= cfd_low_xing;
    cfd_high_int <= cfd_high_xing;
	end case;
end process cfdFSMtransition;
--
cfd_high_done <= cfd_high_crossed or (peak_at_cfd and cfd_high_xing);
cfd_low_done <= cfd_high_crossed or (peak_at_cfd and cfd_high_xing);
cfd_error_int <= (peak_at_cfd and not (cfd_low_done and cfd_high_done)) 
									or queue_overflow;
                 
constantFraction:process(clk)
begin
	if rising_edge(clk) then
		
    if cfd_state=IDLE and queue_empty='0' then
      queue_rd_en <= '1';
      cfd_low_threshold <= signed(cfd_low_out);
      cfd_high_threshold <= signed(cfd_high_out);
      minima_cfd <= signed(minima_out);
    else
      queue_rd_en <= '0';
    end if;
   
    if cfd_state=IDLE then
    	cfd_low_crossed <= FALSE;
    	cfd_high_crossed <= FALSE;
    end if;

    if cfd_low_int then
    	cfd_low_crossed <= TRUE;
    end if;

    if cfd_high_int then
    	cfd_high_crossed <= TRUE;
    end if; 

    if peak_at_cfd then
      peak_minima 
        <= resize(shift_right(minima_cfd,FRAC-SIGNAL_FRAC),SIGNAL_BITS);
    end if;
    
    --
    --cfd_error <= cfd_error_int;
    --if not signal_below_cfd and signal_was_below_cfd
    cfd_error <= cfd_error_int;
		cfd_reset <= cfd_error_int or reset='1';
    filtered 
      <= resize(shift_right(signal_at_cfd,FRAC-SIGNAL_FRAC),SIGNAL_BITS);
    slope <= resize(slope_at_cfd,SIGNAL_BITS);
    --raw <= signed(raw_CFD_delay);
    --baseline <= signed(baseline_CFD_delay);
    peak <= peak_at_cfd;
    pulse_pos_xing <= pulse_start;
    pulse_neg_xing <= pulse_stop;
    slope_threshold_xing <= slope_xing_at_cfd;
    cfd_low <= cfd_low_int;
    cfd_high <= cfd_high_int;
    peak_start <= min_valid and cfd_state=WAIT_MIN;
  end if;
end process constantFraction;
--
end architecture RTL;
