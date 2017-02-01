library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library dsp;
use dsp.types.all;

library extensions;
use extensions.logic.all;
use extensions.boolean_vector.all;

entity baseline_estimator_TB is
generic(
  BASELINE_BITS:natural:=11;
  --width of counters and stream
  ADC_WIDTH:natural:=14;
  COUNTER_BITS:natural:=18;
  TIMECONSTANT_BITS:natural:=32;
  WIDTH:natural:=18;
  FRAC:natural:=3
);
end entity baseline_estimator_TB;

architecture testbench of baseline_estimator_TB is
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
constant CLK_PERIOD:time:=4 ns;

type int_file is file of integer; 
file trace_file:int_file;
 
signal sample_valid:boolean;
signal av_config:fir_control_in_t;
signal av_events:fir_control_out_t;
signal timeconstant:unsigned(TIMECONSTANT_BITS-1 downto 0);
signal threshold:unsigned(BASELINE_BITS-2 downto 0);
signal count_threshold:unsigned(COUNTER_BITS-1 downto 0);
signal new_only:boolean;
signal baseline_estimate:signed(WIDTH-1 downto 0);
signal range_error:boolean;

--signal simsig:signed(BASELINE_BITS-1 downto 0);
signal sample,sample_inv,sample_in:signed(ADC_WIDTH-1 downto 0);
signal adc_sample:unsigned(13 downto 0);
signal invert,subtraction:boolean;
signal offset:unsigned(WIDTH-2 downto 0);
signal clk_count:integer;

constant SIM_WIDTH:natural:=6;
signal sim_count:signed(SIM_WIDTH-1 downto 0);

begin
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.baseline_estimator2
generic map(
  BASELINE_BITS => BASELINE_BITS,
  ADC_WIDTH => ADC_WIDTH,
  COUNTER_BITS => COUNTER_BITS,
  TIMECONSTANT_BITS => TIMECONSTANT_BITS,
  WIDTH => WIDTH,
  FRAC => FRAC
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
      sim_count<= (others => '0');
    else
      sim_count <= sim_count+1;
    end if;
  end if;
end process sim;
sample <= resize(sim_count,ADC_WIDTH);

--file_open(trace_file, "../traces",WRITE_MODE);
--traceWriter:process
--begin
--	while TRUE loop
--    wait until rising_edge(clk);
--	  write(trace_file, to_integer(sample));
--	  write(trace_file, to_integer(sample_in));
--	  write(trace_file, to_integer(baseline_estimate));
--	end loop;
--end process traceWriter; 
--
--stimulusFile:process
--	file sample_file:int_file is in "../input_signals/test.bin";
--	variable sample:integer;
--begin
--	while not endfile(sample_file) loop
--		read(sample_file, sample);
--		wait until rising_edge(clk);
--		adc_sample <= to_unsigned(sample, 14);
--		if clk_count mod 10000 = 0 then
--			report "sample " & integer'image(clk_count);
--		end if;
--		--assert false report str_sample severity note;
--	end loop;
--	wait;
--end process stimulusFile;

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
threshold <= (BASELINE_BITS-2 => '0', others => '1');
sample_valid <= TRUE;
offset <= to_unsigned(2119,WIDTH-1);
invert <= FALSE;
  
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait;
end process stimulus;


end architecture testbench;
