--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: histogram_unit
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

library dsp;
use dsp.types.all;

library mcalib;


entity baseline_estimator is
generic(
  BASELINE_BITS:natural:=12;
  --width of counters and stream
  COUNTER_BITS:natural:=18;
  TIMECONSTANT_BITS:natural:=32;
  WIDTH:natural:=18
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  sample:in signed(WIDTH-1 downto 0);
  sample_valid:in boolean;
  --
  av_config:in fir_control_in_t;
  av_events:out fir_control_out_t;
  
  timeconstant:in unsigned(TIMECONSTANT_BITS-1 downto 0);
  -- above this threshold sample does not contribute to estimate
  threshold:in unsigned(BASELINE_BITS-2 downto 0);
  -- count required before adding to average
  count_threshold:in unsigned(COUNTER_BITS-1 downto 0);
  --only include a value in average if it different from the previous value
  new_only:in boolean;
  --
  baseline_estimate:out signed(WIDTH-1 downto 0);
  range_error:out boolean
);
end entity baseline_estimator;

architecture most_frequent of baseline_estimator is
component baseline_av
port (
  aclk:in std_logic;
  aclken:in std_logic;
  s_axis_data_tvalid:in std_logic;
  s_axis_data_tready:out std_logic;
  s_axis_data_tdata:in std_logic_vector(23 downto 0);
  s_axis_config_tvalid:in std_logic;
  s_axis_config_tready:out std_logic;
  s_axis_config_tdata:in std_logic_vector(7 downto 0);
  s_axis_reload_tvalid:in std_logic;
  s_axis_reload_tready:out std_logic;
  s_axis_reload_tlast:in std_logic;
  s_axis_reload_tdata:in std_logic_vector(31 downto 0);
  m_axis_data_tvalid:out std_logic;
  m_axis_data_tdata:out std_logic_vector(47 downto 0);
  event_s_reload_tlast_missing:out std_logic;
  event_s_reload_tlast_unexpected:out std_logic
);
end component;

signal baseline_sample:std_logic_vector(BASELINE_BITS-1 downto 0);
signal baseline_sample_valid:boolean;
signal most_frequent:std_logic_vector(BASELINE_BITS-1 downto 0);
signal previous_mf:std_logic_vector(BASELINE_BITS-1 downto 0);
--signal mf_value:signed(BASELINE_BITS-1 downto 0);
signal av_enable:boolean;
signal most_frequent_av:signed(WIDTH-1 downto 0);
signal new_most_frequent:boolean;
signal new_mf_value:boolean;
signal av_valid:std_logic;
signal av_int:std_logic_vector(47 downto 0);
signal mf_average:std_logic_vector(WIDTH-1 downto 0);
signal mf_value:std_logic_vector(23 downto 0);

begin
--FIXME lower values should saturate
--FIXME make range error more useful so can feed back to offset
baselineControl:process(clk)
variable lowest,highest:signed(WIDTH-1 downto 0);
constant HALF_RANGE:signed(WIDTH-1 downto 0)
         :=to_signed((2**BASELINE_BITS)/2,WIDTH);
begin
if rising_edge(clk) then
  lowest:=-HALF_RANGE;
  highest:=HALF_RANGE-1;
  --FIXME use overflow 
  if sample_valid then 
    baseline_sample <= std_logic_vector(resize(sample,BASELINE_BITS));
    if (sample > resize(signed('0' & threshold), WIDTH)) then 
      baseline_sample_valid <= FALSE;
      range_error <= FALSE;
    elsif sample < lowest then
      baseline_sample_valid <= TRUE;
      baseline_sample <= std_logic_vector(resize(lowest,BASELINE_BITS));
      range_error <= TRUE;
    else
      baseline_sample_valid <= sample_valid;
      range_error <= FALSE;
    end if;
  else
    baseline_sample_valid <= FALSE;
  end if;
    
end if;
end process baselineControl;

mostFrequent:entity mcalib.most_frequent
generic map(
  ADDRESS_BITS => BASELINE_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS
)
port map(
  clk => clk,
  reset => reset,
  timeconstant => timeconstant,
  threshold => count_threshold,
  sample => baseline_sample,
  sample_valid => baseline_sample_valid,
  most_frequent => most_frequent,
  new_value => new_most_frequent
);

new_mf_value <= previous_mf /= most_frequent;
newOnly:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			previous_mf <= (others => '0');
			av_enable <= FALSE;
		else
			if new_most_frequent then
				previous_mf <= most_frequent;
				if new_only then
					if new_mf_value then
						av_enable <= TRUE;
						mf_value <= std_logic_vector(resize(signed(most_frequent),24));
					else
						av_enable <= FALSE;	
					end if;
				else
					mf_value <= std_logic_vector(resize(signed(most_frequent),24));
					av_enable <= TRUE;
				end if;
			else
				av_enable <= FALSE;
			end if;
		end if;
	end if;
end process newOnly;

av:baseline_av
port map (
  aclk => clk,
  aclken => to_std_logic(av_enable),
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => mf_value,
  s_axis_config_tvalid => av_config.config_valid,
  s_axis_config_tready => av_events.config_ready,
  s_axis_config_tdata => av_config.config_data,
  s_axis_reload_tvalid => av_config.reload_valid,
  s_axis_reload_tready => av_events.reload_ready,
  s_axis_reload_tlast => av_config.reload_last,
  s_axis_reload_tdata => av_config.reload_data,
  m_axis_data_tvalid => av_valid,
  m_axis_data_tdata => av_int,
  event_s_reload_tlast_missing => av_events.last_missing,
  event_s_reload_tlast_unexpected => av_events.last_unexpected
);

-- FIXME only need the rounding stage
round:entity dsp.round
generic map(
  WIDTH_IN => 48,
  FRAC_IN => 28,
  WIDTH_OUT => 18,
  FRAC_OUT => 3
)
port map(
  clk => clk,
  reset => reset,
  input => av_int,
  output => mf_average
);
most_frequent_av <= signed(mf_average);

outputReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    baseline_estimate <= to_signed(0,WIDTH);
  else
    if timeconstant=0 then
    	baseline_estimate <= to_signed(0,WIDTH);
    else
      baseline_estimate <=  most_frequent_av;
    end if;
  end if;
end if;
end process outputReg;

end architecture most_frequent;