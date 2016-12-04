library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dsp;
use dsp.types.all;

entity baseline_estimator_TB is
generic(
  BASELINE_BITS:natural:=5;
  --width of counters and stream
  COUNTER_BITS:natural:=18;
  TIMECONSTANT_BITS:natural:=32;
  WIDTH:natural:=18
);
end entity baseline_estimator_TB;

architecture testbench of baseline_estimator_TB is
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;
  
signal sample:signed(WIDTH-1 downto 0);
signal sample_valid:boolean;
signal av_config:fir_control_in_t;
signal av_events:fir_control_out_t;
signal timeconstant:unsigned(TIMECONSTANT_BITS-1 downto 0);
signal threshold:unsigned(BASELINE_BITS-2 downto 0);
signal count_threshold:unsigned(COUNTER_BITS-1 downto 0);
signal new_only:boolean;
signal baseline_estimate:signed(WIDTH-1 downto 0);
signal range_error:boolean;

signal simsig:signed(BASELINE_BITS-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.baseline_estimator
generic map(
  BASELINE_BITS => BASELINE_BITS,
  COUNTER_BITS => COUNTER_BITS,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  sample => sample,
  sample_valid => sample_valid,
  av_config => av_config,
  av_events => av_events,
  timeconstant => timeconstant,
  threshold => threshold,
  count_threshold => count_threshold,
  new_only => new_only,
  baseline_estimate => baseline_estimate,
  range_error => range_error
);

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      simsig <= (others => '0');
    else
      simsig <= simsig+1;
    end if;
  end if;
end process sim;
--sample <= resize(simsig,SAMPLE_BITS);
sample <= to_signed(10,WIDTH) when simsig(0)='1' else (others => '0');

stimulus:process
begin
  
av_config.config_data <= (others => '0');
av_config.config_valid <= '0';
av_config.reload_data <= (others => '0');
av_config.reload_last <= '0';
av_config.reload_valid <= '0';
timeconstant <= (BASELINE_BITS => '1',others => '0');
count_threshold <= (others => '0');
new_only <= TRUE;
threshold <= (others => '1');
sample_valid <= TRUE;
  
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait;
end process stimulus;


end architecture testbench;
