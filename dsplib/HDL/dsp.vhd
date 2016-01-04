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
  raw_area:out area_t;
  raw_extrema:out signal_t;
  raw_valid:out boolean;
  filtered:out signal_t;
  filtered_area:out area_t;
  filtered_extrema:out signal_t;
  filtered_valid:out boolean;
  slope:out signal_t;
  slope_area:out area_t;
  slope_extrema:out signal_t;
  slope_valid:out boolean;
  -- pulse measurements
  pulse_area:out area_t;
  --pulse_length:out time_t;
  pulse_extrema:out signal_t; --always a maxima
  pulse_valid:out boolean;
  --w=16 f=BASELINE_AV_FRAC default is signed 11.5 bits
  --baseline:out signal_t;
  --raw:out signal_t;
  slope_threshold_xing:out boolean; --@ output delay
  --
  pulse_detected:out boolean; -- @ FIR output delay
  peak:out boolean;
  minima:out signal_t;
  cfd:out boolean;
  cfd_error:out boolean
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
	
--component minima_queue
--port( 
--  clk:in std_logic;
--  srst:in std_logic;
--  din:in std_logic_vector(SIGNAL_BITS-1 downto 0);
--  wr_en:in std_logic;
--  rd_en:in std_logic;
--  dout:out std_logic_vector(SIGNAL_BITS-1 downto 0);
--  full:out std_logic;
--  empty:out std_logic
--);
--end component;

--component threshold_divider
--port(
--  aclk:in std_logic;
--  s_axis_divisor_tvalid:in std_logic;
--  s_axis_divisor_tready:out std_logic;
--  s_axis_divisor_tdata:in std_logic_vector(15 downto 0);
--  s_axis_dividend_tvalid:in std_logic;
--  s_axis_dividend_tready:out std_logic;
--  s_axis_dividend_tdata:in std_logic_vector(15 downto 0);
--  m_axis_dout_tvalid:out std_logic;
--  m_axis_dout_tdata:out std_logic_vector(23 downto 0)
--);
--end component;

constant CFD_DELAY_DEPTH:integer:=256;
constant CFD_DELAY:integer:=130;
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
signal cfd_threshold_in:signed(WIDTH-1 downto 0);
signal slope_CFD_delay:std_logic_vector(WIDTH-1 downto 0);
signal pulse_start:boolean;
signal pulse_area_reg:area_t;
signal pulse_end:boolean;
signal raw_extrema_int,signal_extrema_int:signed(WIDTH-1 downto 0);
signal slope_extrema_int:signed(WIDTH-1 downto 0);
signal pulse_extrema_reg:signed(WIDTH-1 downto 0);
signal signal_for_cfd:signed(WIDTH-1 downto 0);
signal flags,flags_CFD_delay:std_logic_vector(3 downto 0);
signal cfd_queue_full:std_logic;
signal cfd_threshold_out:std_logic_vector(WIDTH-1 downto 0);
signal cfd_threshold:signed(WIDTH-1 downto 0);
constant MULT_PIPE_DEPTH:integer:=4;
signal peak_pipe:boolean_vector(1 to MULT_PIPE_DEPTH);
signal cfd_overflow:boolean;
signal minima_int,minima_reg:signed(WIDTH-1 downto 0);
signal signal_above,signal_was_below:boolean;
signal slope_above:boolean;
signal queue_rd_en:std_logic;
signal minima_out:std_logic_vector(WIDTH-1 downto 0);
signal queue_full:std_logic;
signal queue_empty:std_logic;
signal start:boolean;
type cfdFSMstate is (IDLE,WAIT_MIN,WAIT_CFD);
signal cfd_state,cfd_nextstate:cfdFSMstate;
signal minima_cfd:signed(WIDTH-1 downto 0);
signal cfd_int:boolean;
signal min,max:boolean;
--signal slope_pos_xing:boolean;
signal slope_out:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH-1 downto 0);
signal signal_at_cfd,slope_at_cfd:signed(WIDTH-1 downto 0);
signal min_at_cfd:boolean;
signal peak_at_cfd:boolean;
type peakFSMstate is (WAITING,ARMED);
signal pd_state,pd_nextstate:peakFSMstate;
type pulseFSMstate is (IDLE,PULSE);
signal pulse_state,pulse_nextstate:pulseFSMstate;

signal peak_int:boolean;
signal queue_overflow:boolean;
signal queue_wr_en:std_logic;
signal peaked:boolean;
signal write_queue:boolean;
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
signal cfd_xing:boolean;
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
  --w=18 f=3
  stage1 => signal_FIR,
  --w=18 f=8
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
  signal_out => open,
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

--thresholds
slope_above <= slope_out > resize(signed('0' & slope_threshold),WIDTH);
signal_above <= signal_out > resize(signed('0' & pulse_threshold),WIDTH);
start <= not signal_above and signal_was_below;
--slope_pos_xing <= not slope_below and slope_was_below;

pdNextstate:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
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

pulseTransition:process(pulse_state,signal_pos_xing,signal_neg_xing)
begin
	pulse_nextstate <= pulse_state;
	case pulse_state is 
	when IDLE =>
		if signal_pos_xing then
			pulse_nextstate <= PULSE;
		end if;
	when PULSE =>
		if signal_neg_xing then
			pulse_nextstate <= IDLE;
		end if;
	end case;
end process pulseTransition;

peak_int <= pd_state=ARMED and pulse_state=PULSE and max;
start_int <= pulse_state=IDLE and signal_pos_xing;
stop_int <= pulse_state=PULSE and signal_neg_xing;
write_queue <= queue_full='0' and peak_pipe(MULT_PIPE_DEPTH);
cfd_overflow <= queue_full='1' and peak_pipe(MULT_PIPE_DEPTH);

pdReg:process(clk)
begin
	if rising_edge(clk) then
		if reset='1' then
			minima_int <= (others => '0');
			queue_wr_en <= '0';
		else
			
      if min then	
        if pulse_state=PULSE then
          if peaked and signal_out < minima_int then
              minima_int <= signal_out;	
          end if;
        else
          minima_int <= signal_out;
        end if;
      end if;
      
      if peak_int then
        peaked <= TRUE;
        minima_reg <= minima_int;
        minima_int <= signal_out;
        if peaked and not cfd_relative then
          signal_for_cfd <= signal_out;
        else
          signal_for_cfd <= signal_out-minima_int;
        end if;
      end if;
      
      if stop_int then
      	peaked <= FALSE;
      end if;

      peak_pipe(1) <= peak_int;
      peak_pipe(2 to MULT_PIPE_DEPTH) <= peak_pipe(1 to MULT_PIPE_DEPTH-1);
      
      --registers to be absorbed into multiplier macro
      cf_of_peak <= signal_for_cfd*signed('0' & constant_fraction);
      cf_of_peak_reg <= cf_of_peak;
      cf_of_peak_reg2 <= cf_of_peak_reg;
      
      queue_overflow <= cfd_queue_full='1' and peak_pipe(MULT_PIPE_DEPTH);
      
      if write_queue then
        queue_wr_en <= '1';
        if not cfd_relative then
          cfd_threshold_in 
          	<= resize(shift_right(cf_of_peak_reg2,CFD_FRAC),WIDTH);
        else
          cfd_threshold_in 
          	<= resize(shift_right(cf_of_peak_reg2,CFD_FRAC),WIDTH)+
               minima_reg;
        end if;
      else
        queue_wr_en <= '0';
      end if;
    end if;
	end if;
end process pdReg;

cfdThresholdQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => reset,
  din => to_std_logic(cfd_threshold_in),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => cfd_threshold_out,
  full => queue_full,
  empty => queue_empty
);

minimaQueue:cfd_threshold_queue
port map (
  clk => clk,
  srst => reset,
  din => to_std_logic(minima_reg),
  wr_en => queue_wr_en,
  rd_en => queue_rd_en,
  dout => minima_out,
  full => open,
  empty => open
);

flags <= (to_std_logic(pulse_state=IDLE and signal_pos_xing),
					to_std_logic(pulse_state=PULSE and signal_neg_xing),
					to_std_logic(peak_int),
					to_std_logic(min)
				 );

-- TODO make this break the delays up into 64 bit lots with a reg at the end 
flagsCFDdelay:entity work.SREG_delay
generic map(
  DEPTH => CFD_DELAY_DEPTH,
  DATA_BITS => 4
)
port map(
  clk     => clk,
  data_in => flags,
  delay   => CFD_DELAY+3,
  delayed => flags_CFD_delay
);

pulse_start <= to_boolean(flags_cfd_delay(3));
pulse_stop <= to_boolean(flags_cfd_delay(2));
peak_at_cfd <= to_boolean(flags_cfd_delay(1));
min_at_cfd <= to_boolean(flags_cfd_delay(0));

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
--
										
slopeMeasurement:entity work.signal_measurement
generic map(
  WIDTH => WIDTH,
  FRAC  => FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signed(slope_CFD_delay),
  threshold => (others => '0'),
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
--
								 
-- Thresholding and zero crossing
--signal_cfd_below_threshold 
--  <= signed(signal_CFD) > signed('0' & pulse_threshold);
--						  
--pulse_start <= not signal_cfd_below_threshold and signal_cfd_was_below_threshold; 

pulseMeasurement:process(clk)
begin
if rising_edge(clk) then
	if reset = '1' then
		pulse_extrema_reg <= (others => '0');
		pulse_area_reg <= (others => '0');
	else
		--signal_cfd_was_below_threshold <= signal_cfd_below_threshold;
  	pulse_valid_int <= pulse_end;
  	--FIXME make this a flag
  	--signal_xing <= pulse_start;
  	if pulse_start then
  		pulse_area_reg <= resize(signed(signal_at_cfd),AREA_BITS);
  		pulse_extrema_reg <= signed(signal_at_cfd); 
  	else
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

cfdXing:entity work.closest_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  signal_in => signed(signal_cfd_delay),
  threshold => cfd_threshold,
  signal_out => open,
  pos => cfd_xing,
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
		if reset = '1' then
			cfd_state <= IDLE;
		else
			cfd_state <= cfd_nextstate;
		end if;
	end if;
end process cfdFSMnextstate;

--FIXME The CFD process will not work properly on arbitrary signals. With some 
--further thought I think it could. Meanwhile this should be OK for TES signals.
cfdFSMtransition:process(cfd_state,queue_empty,min_at_cfd,signal_is_min,
												 cfd_xing,peak_at_cfd)
begin
	cfd_nextstate <= cfd_state;
	case cfd_state is 
	when IDLE =>
		if queue_empty='0' then
			cfd_nextstate <= WAIT_MIN;
		end if;
	when WAIT_MIN =>
		if min_at_cfd and signal_is_min then
			cfd_nextstate <= WAIT_CFD;
		elsif peak_at_cfd then
			-- there is an error in the cfd process
			cfd_nextstate <= IDLE;
		end if;
	when WAIT_CFD =>
		if cfd_xing or peak_at_cfd then
			-- if max_at_cfd there is an error
			cfd_nextstate <= IDLE;
		end if;
	end case;
end process cfdFSMtransition;
cfd_int <= cfd_xing and cfd_state=WAIT_CFD;
--
constantFraction:process(clk)
begin
	if rising_edge(clk) then
		
		if cfd_state=IDLE and queue_empty='0' then
			queue_rd_en <= '1';
			minima_cfd <= signed(minima_out);
			cfd_threshold <= signed(cfd_threshold_out);
		else
			queue_rd_en <= '0';
		end if;
		
		cfd_error <= (peak_at_cfd and cfd_state/=IDLE) or cfd_overflow;
		--if not signal_below_cfd and signal_was_below_cfd
    filtered <= resize(shift_right(signal_at_cfd,FRAC-SIGNAL_FRAC),SIGNAL_BITS);
    slope <= resize(shift_right(slope_at_cfd,FRAC-SIGNAL_FRAC),SIGNAL_BITS);
    --raw <= signed(raw_CFD_delay);
    --baseline <= signed(baseline_CFD_delay);
    peak <= peak_at_cfd;
    pulse_detected <= pulse_start;
    slope_threshold_xing <= to_boolean(flags_CFD_delay(0));
    cfd <= cfd_int;
	end if;
end process constantFraction;
minima <= resize(shift_right(minima_cfd,FRAC-SIGNAL_FRAC),SIGNAL_BITS);
--
--filtered_threshold_xing <= to_boolean(flags_CFD_delay(0));
--

end architecture RTL;
