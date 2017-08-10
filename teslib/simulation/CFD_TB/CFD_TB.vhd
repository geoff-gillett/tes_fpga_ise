--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:22Nov.,2016
--
-- Design Name: TES_digitiser
-- Module Name: CFD_input_TB
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.debug.all;
use extensions.boolean_vector.all;
use extensions.logic.all;

library dsp;
use dsp.types.all;
use dsp.FIR_142SYM_23NSYM_16bit;

use std.textio.all;
use work.types.all;
use work.registers.all;

entity CFD_TB is
generic(
  WIDTH:integer:=16;
  CF_WIDTH:integer:=18;
  CF_FRAC:integer:=17;
--  DELAY:integer:=112+4;
  DELAY:integer:=1026;
  SIM_WIDTH:integer:=9
);
end entity CFD_TB;

architecture testbench of CFD_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  

constant CLK_PERIOD:time:=4 ns;

signal sim_count:signed(SIM_WIDTH-1 downto 0);
signal stage1_config:fir_control_in_t;
signal stage1_events:fir_control_out_t;
signal stage2_config:fir_control_in_t;
signal stage2_events:fir_control_out_t;
signal simenable:boolean:=FALSE;
signal filtered:signed(WIDTH-1 downto 0);
signal slope:signed(WIDTH-1 downto 0);
signal squaresig,doublesig:signed(WIDTH-1 downto 0);

constant CF:integer:=2**17/5;
signal cfd_low_threshold:signed(WIDTH-1 downto 0);
signal cfd_high_threshold:signed(WIDTH-1 downto 0);
signal max_slope:signed(WIDTH-1 downto 0);
signal max:boolean;
signal min:boolean;
signal p_t_p:boolean;
signal p_t_n:boolean;
signal s_t_p:boolean;
signal s_out:signed(WIDTH-1 downto 0);
signal f_out:signed(WIDTH-1 downto 0);
signal will_cross:boolean;
signal will_arm:boolean;
signal armed:boolean;
signal cfd_error:boolean;
signal sample_in:signed(WIDTH-1 downto 0);
signal rise_start,pulse_start:boolean;
signal cfd_low_p:boolean;
signal cfd_high_p:boolean;
signal max_slope_p:boolean;
signal reg:capture_registers_t;
signal above:boolean;
signal clk_i:integer:=-1; -- to align with python indices

file trace_file,min_file,max_file:extensions.debug.integer_file;
file low_file,high_file,maxslope_file:extensions.debug.integer_file;
signal cfd_overrun,cfd_valid:boolean;
signal flags:boolean_vector(8 downto 0);
signal first_rise:boolean;
signal valid_rise:boolean;

begin
clk <= not clk after CLK_PERIOD/2;
clk_i <= clk_i+1 after CLK_PERIOD;

fir:entity FIR_142SYM_23NSYM_16bit
generic map(
  WIDTH => WIDTH,
  FRAC => 3,
  SLOPE_FRAC => 8
)
port map(
  clk => clk,
  sample_in => sample_in,
  stage1_config => stage1_config,
  stage1_events => stage1_events,
  stage2_config => stage2_config,
  stage2_events => stage2_events,
  stage1 => filtered,
  stage2 => slope
);

UUT:entity work.CFD
generic map(
  WIDTH => WIDTH,
  CF_WIDTH => CF_WIDTH,
  CF_FRAC => CF_FRAC,
  DELAY => DELAY
)
port map(
  clk => clk,
  reset => reset,
  s => slope,
  f => filtered,
  registers => reg,
  cfd_low_threshold => cfd_low_threshold,
  cfd_high_threshold => cfd_high_threshold,
  first_rise => first_rise,
  valid_rise => valid_rise,
  max => max,
  min => min,
  max_slope_threshold => max_slope,
  will_cross => will_cross,
  will_arm => will_arm,
  s_out => s_out,
  s_t_p => s_t_p,
  armed => armed,
  above => above,
  f_out => f_out,
  cfd_low_p => cfd_low_p,
  cfd_high_p => cfd_high_p,
  max_slope_p => max_slope_p,
  p_t_p => p_t_p,
  p_t_n => p_t_n,
  rise_start => rise_start,
  pulse_start => pulse_start,
  cfd_error => cfd_error,
  cfd_overrun => cfd_overrun,
  cfd_valid => cfd_valid
);


file_open(trace_file, "../traces",WRITE_MODE);
traceWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    write(trace_file, to_integer(f_out));
    write(trace_file, to_integer(s_out));
  end loop;
end process traceWriter; 

flags <= valid_rise & first_rise & rise_start & pulse_start & will_cross & 
         will_arm & cfd_error & cfd_overrun & cfd_valid;
file_open(min_file, "../min_data",WRITE_MODE);
minWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if min then
      write(min_file, clk_i);
      write(min_file, to_integer(f_out));
      write(min_file, to_integer(s_out));
      write(min_file, to_integer(cfd_low_threshold));
      write(min_file, to_integer(cfd_high_threshold));
      write(min_file, to_integer(to_unsigned(flags)));
      write(min_file, to_integer(max_slope));
    end if;
  end loop;
end process minWriter; 

file_open(max_file, "../max_data",WRITE_MODE);
maxWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if max then
      write(max_file, clk_i);
      write(max_file, to_integer(f_out));
      write(max_file, to_integer(s_out));
      write(max_file, to_integer(to_unsigned(flags)));
    end if;
  end loop;
end process maxWriter; 

file_open(low_file, "../low_xings",WRITE_MODE);
lowWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if cfd_low_p then
      write(low_file, clk_i);
    end if;
  end loop;
end process lowWriter; 

file_open(high_file, "../high_xings",WRITE_MODE);
highWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if cfd_high_p then
      write(high_file, clk_i);
    end if;
  end loop;
end process highWriter; 

file_open(maxslope_file, "../maxslope_xings",WRITE_MODE);
maxslopeWriter:process
begin
  while TRUE loop
    wait until rising_edge(clk);
    if max_slope_p then
      write(maxslope_file, clk_i);
    end if;
  end loop;
end process maxslopeWriter; 

simsquare:process (clk) is
begin
  if rising_edge(clk) then
    if not simenable then
      sim_count <= (others => '0');
    else
      sim_count <= sim_count+1;
    end if;
  end if;
end process simsquare;

stimulusFile:process
	file sample_file:integer_file is in 
--	     "../input_signals/tes2_250_old.bin";
--	     "../bin_traces/july 10/gt1_100khz.bin";
--	     "../bin_traces/july 10/randn2.bin";
	     "../bin_traces/july 10/randn.bin";
--	     "../bin_traces/double_peak_signal.bin";
	variable sample:integer;
	--variable sample_in:std_logic_vector(13 downto 0);
begin
	while not endfile(sample_file) loop
		read(sample_file, sample);
		wait until rising_edge(clk);
		sample_in <= to_signed(sample, WIDTH);
	end loop;
	wait;
end process stimulusFile;

doublesig <= to_signed(-200,WIDTH)
             when sim_count < 10
             else to_signed(500,WIDTH)
             when sim_count < 40
             else to_signed(0,WIDTH)
             when sim_count < 120
             else to_signed(1000,WIDTH)
             when sim_count < 300
             else to_signed(-200,WIDTH);
--sample_in <= doublesig;

stage1_config.config_data <= (others => '0');
stage1_config.config_valid <= '0';
stage1_config.reload_data <= (others => '0');
stage1_config.reload_last <= '0';
stage1_config.reload_valid <= '0';
stage2_config.config_data <= (others => '0');
stage2_config.config_valid <= '0';
stage2_config.reload_data <= (others => '0');
stage2_config.reload_last <= '0';
stage2_config.reload_valid <= '0';

stimulus:process is
begin

reg.timing <= CFD_LOW_TIMING_D;
reg.constant_fraction <= to_unsigned(CF,CF_WIDTH-1);
reg.cfd_rel2min <= FALSE;
--constant_fraction <= (others => '0');
--slope_threshold <= to_signed(250,WIDTH);
--pulse_threshold <= to_signed(62,WIDTH);
reg.slope_threshold <= to_unsigned(0,WIDTH);
reg.pulse_threshold <= to_unsigned(0,WIDTH);
wait for CLK_PERIOD;
reset <= '0';
--sample_in <= to_signed(0,WIDTH);
--wait for CLK_PERIOD*256;
--simenable <= TRUE;
--sample_in <= (WIDTH-1 => '0', others => '1');
--wait for CLK_PERIOD;
--sample_in <= (others => '0');
--wait for CLK_PERIOD*256;
--sample_in <= (WIDTH-1 => '0', others => '1');
--wait for CLK_PERIOD;
--sample_in <= (others => '0');
wait;
end process stimulus;

end architecture testbench;
