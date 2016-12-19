--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:3 Feb 2016
--
-- Design Name: TES_digitiser
-- Module Name: mca_unit_TB
-- Project Name: TES_digitiser 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

library streamlib;
use streamlib.types.all;

--use work.protocol.all;
use work.registers.all;
use work.measurements.all;
use work.types.all;
use work.events.all;

entity mca_unit_TB is
generic(
  CHANNELS:integer:=2;
  ADDRESS_BITS:integer:=4;
  COUNTER_BITS:integer:=32;
  VALUE_BITS:integer:=32;
  TOTAL_BITS:integer:=64;
  TICKCOUNT_BITS:integer:=32;
  TICK_PERIOD_BITS:integer:=32;
  MIN_TICK_PERIOD:integer:=8
);
end entity mca_unit_TB;

architecture testbench of mca_unit_TB is

signal clk:std_logic:='1';	
signal reset:std_logic:='1';	
constant CLK_PERIOD:time:=4 ns;

signal update_asap:boolean;
signal update_on_completion:boolean;
signal updated:boolean;
signal registers:mca_registers_t;
signal channel_select:std_logic_vector(CHANNELS-1 downto 0);
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal qualifier_select:std_logic_vector(NUM_MCA_QUAL_D-1 downto 0);
signal stream:streambus_t;
signal ready:boolean;
signal m,m_reg:measurements_array(CHANNELS-1 downto 0);
signal valid: boolean;
signal initialising:boolean;
signal tick_period:unsigned(TICK_PERIOD_BITS-1 downto 0);
--
signal mca_values:mca_value_array(CHANNELS-1 downto 0);
signal mca_value_valids:boolean_vector(CHANNELS-1 downto 0);
--------------------------------------------------------------------------------
-- Pipelines
--------------------------------------------------------------------------------
constant VALUE_PIPE_DEPTH:integer:=3; --latency to mca_value VALUE_PIPE_DEPTH+2 

type value_pipe_t is array (1 to VALUE_PIPE_DEPTH) of
     mca_value_array(CHANNELS-1 downto 0);
type value_valid_pipe_t is array (1 to VALUE_PIPE_DEPTH) of
     boolean_vector(CHANNELS-1 downto 0);
     
signal value_pipe:value_pipe_t;
signal value_valid_pipe:value_valid_pipe_t;

constant SIM_WIDTH:natural:=ADDRESS_BITS;
signal simcount:unsigned(SIM_WIDTH-1 downto 0);
signal simvalid:boolean;
signal mca_value:signed(VALUE_BITS-1 downto 0);
signal mca_value_valid:boolean;

begin
	
clk <= not clk after CLK_PERIOD/2;

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      simcount <= (others => '0');
    else
      simcount <= simcount+1;
    end if;
  end if;
end process sim;
simvalid <= simcount(0) = '1'; 


-- each channel has a value mux that can be located near measurement
-- then there is a pipeline (DEPTH-2) to the channel mux near the MCA
-- this pipelining is required to meet timing with many channels implemented
-- to operate need a pre tick signal

chanGen:for c in CHANNELS-1 downto 0 generate
  m(c).filtered.sample <= resize(signed(simcount+c),SIGNAL_BITS);
  m(c).filtered.area <= resize(signed(simcount+c),AREA_BITS);
  m(c).filtered.neg_0xing <= simvalid;
  m(c).filtered.pos_0xing <= simvalid;
  m(c).filtered.extrema <= resize(signed(simcount+c+1),SIGNAL_BITS);
  m(c).filtered.zero_xing <= simcount(1 downto 0)="00"; 
  
  -- latency 1
  valueMux:entity work.mca_value_selector3
  generic map(
    VALUE_BITS => MCA_VALUE_BITS,
    NUM_VALUES => NUM_MCA_VALUE_D,
    NUM_VALIDS => NUM_MCA_TRIGGER_D-1,
    NUM_QUALS => NUM_MCA_QUAL_D
  )
  port map(
    clk => clk,
    reset => reset,
    measurements => m(c),
    value_select => value_select,
    trigger_select => trigger_select,
    qualifier_select => qualifier_select,
    value => mca_values(c),
    valid => mca_value_valids(c)
  );
end generate;

mcaPipe:process(clk)
begin
  if rising_edge(clk) then
    m_reg <= m; -- FIXME is this needed?
    value_pipe <= mca_values & value_pipe(1 to VALUE_PIPE_DEPTH-1);
    value_valid_pipe 
      <= mca_value_valids & value_valid_pipe(1 to VALUE_PIPE_DEPTH-1);
  end if;
end process mcaPipe;

--latency 1
mcaChanSel:entity work.mca_channel_selector
generic map(
  CHANNELS => CHANNELS,
  VALUE_BITS => MCA_VALUE_BITS
)
port map(
  clk => clk,
  reset => reset,
  channel_select => channel_select,
  values => value_pipe(VALUE_PIPE_DEPTH),
  valids => value_valid_pipe(VALUE_PIPE_DEPTH),
  value => mca_value,
  valid => mca_value_valid
);

UUT:entity work.mca_unit3
  generic map(
    CHANNELS => CHANNELS,
    ADDRESS_BITS => ADDRESS_BITS,
    COUNTER_BITS => COUNTER_BITS,
    VALUE_BITS => VALUE_BITS,
    TOTAL_BITS => TOTAL_BITS,
    TICKCOUNT_BITS => TICKCOUNT_BITS,
    TICKPERIOD_BITS => 32,
    MIN_TICK_PERIOD => MIN_TICK_PERIOD,
    DEPTH => VALUE_PIPE_DEPTH+2,
    ENDIANNESS => ENDIANNESS
  )
  port map(
    clk => clk,
    reset => reset,
    initialising => initialising,
    update_asap => update_asap,
    update_on_completion => update_on_completion,
    updated => updated,
    registers => registers,
    tick_period => tick_period,
    channel_select => channel_select,
    value_select => value_select,
    trigger_select => trigger_select,
    qualifier_select => qualifier_select,
    value => mca_value,
    value_valid => mca_value_valid,
    stream => stream,
    valid => valid,
    ready => ready
  );

stimulus:process is
begin
registers.bin_n <= to_unsigned(0,MCA_BIN_N_BITS);
registers.channel <= (0 => '0', others => '0');
registers.value <= MCA_FILTERED_SIGNAL_D;
registers.trigger <= CLOCK_MCA_TRIGGER_D;
registers.last_bin <= to_unsigned(2**ADDRESS_BITS-1,MCA_ADDRESS_BITS);
registers.lowest_value 
  <= (MCA_VALUE_BITS-1 downto SIM_WIDTH-1 => '1', others => '0');
registers.ticks <= to_unsigned(1,MCA_TICKCOUNT_BITS);
tick_period <= to_unsigned(32,TICK_PERIOD_BITS);
update_asap <= FALSE;
update_on_completion <= FALSE;

--value <= (others => '0');
--value_valid <= TRUE;
ready <= TRUE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD;
wait until not initialising;
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait until updated;
registers.trigger <= FILTERED_0XING_MCA_TRIGGER_D;
registers.value <= MCA_FILTERED_EXTREMA_D;
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait until updated;
registers.value <= MCA_FILTERED_AREA_D;
update_asap <= TRUE;
wait for CLK_PERIOD;
wait until updated;
registers.value <= MCA_PULSE_AREA_D;
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
update_asap <= FALSE;
wait until updated;
registers.trigger <= SLOPE_0XING_MCA_TRIGGER_D;
registers.value <= MCA_SLOPE_EXTREMA_D;
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait until updated;
registers.trigger <= SLOPE_0XING_MCA_TRIGGER_D;
registers.value <= MCA_SLOPE_AREA_D;
update_asap <= TRUE;
wait for CLK_PERIOD;
update_asap <= FALSE;
wait;
end process stimulus;

end architecture testbench;
