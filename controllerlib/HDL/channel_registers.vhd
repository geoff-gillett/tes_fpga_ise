--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:07/01/2014 
--
-- Design Name: TES_digitiser
-- Module Name: channel_register_block
-- Project Name: channel
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
entity channel_registers is
generic(
  ADC_BITS:integer:=14;
  AREA_BITS:integer:=26;
  ------------------------------------------------------------------------------
  -- Register Widths etc
  ------------------------------------------------------------------------------
  DELAY_BITS:integer:=13;
  SIGNAL_AV_ADDRESS_BITS:integer:=6;
  SLOPE_ADDRESS_BITS:integer:=6;
  SYNC_ADDRESS_BITS:integer:=6;
  TIMECONSTANT_BITS:integer:=32;
  BASELINE_AV_ADDRESS_BITS:integer:=10;
  BASELINE_MCA_COUNTER_BITS:integer:=18;
  ------------------------------------------------------------------------------
  -- Register defaults
  ------------------------------------------------------------------------------
  DEFAULT_DELAY:integer:=0;
  DEFAULT_SIGNAL_AVN:integer:=5;
  DEFAULT_SLOPE_N:integer:=3;
  DEFAULT_SYNC_CLKS:integer:=4;
  DEFAULT_BASELINE_TIMECONSTANT:integer:=0;
  DEFAULT_BASELINE_AVN:integer:=7;
  DEFAULT_START_THRESHOLD:integer:=1000;
  DEFAULT_STOP_THRESHOLD:integer:=1000;
  DEFAULT_SLOPE_THRESHOLD:integer:=15;
  DEFAULT_SLOPE_CROSSING:integer:=0;
  DEFAULT_AREA_THRESHOLD:integer:=1000;
  DEFAULT_BASELINE_THRESHOLD:integer:=100;
  DEFAULT_FIXED_BASELINE:integer:=8192
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --!* register signals from/to channel CPU
  data_in:in registerdata;
  address:in registeraddress;
  data_out:out registerdata;
  write:in boolean; --Strobe
  --registers
  -- all *_updated signals are pulses synced to the register_clk domain 
  delay:out unsigned(DELAY_BITS-1 downto 0);
  signal_avn:out unsigned(bits(SIGNAL_AV_ADDRESS_BITS) downto 0);
  signal_avn_updated:out boolean;
  slope_n:out unsigned(bits(SLOPE_ADDRESS_BITS) downto 0);
  slope_n_updated:out boolean;
  sync_clks:out unsigned(SYNC_ADDRESS_BITS downto 0);
  sync_clks_updated:out boolean;
  baseline_timeconstant:out unsigned(TIMECONSTANT_BITS-1 downto 0);
  fixed_baseline:out unsigned(ADC_BITS-1 downto 0);
  baseline_timeconstant_updated:out boolean;
  baseline_avn:out unsigned(bits(BASELINE_AV_ADDRESS_BITS) downto 0);
  baseline_avn_updated:out boolean;
  start_threshold:out unsigned(ADC_BITS-1 downto 0);
  stop_threshold:out unsigned(ADC_BITS-1 downto 0);
  baseline_relative:out boolean;
  slope_threshold:out unsigned(ADC_BITS-1 downto 0);
  slope_crossing_level:out unsigned(ADC_BITS-1 downto 0);
  area_threshold:out unsigned(AREA_BITS-1 downto 0);
  baseline_threshold:out unsigned(BASELINE_MCA_COUNTER_BITS-1 downto 0)
);
end entity channel_registers;
--
architecture RTL of channel_registers is
--------------------------------------------------------------------------------
-- Registers
--------------------------------------------------------------------------------
signal delay_reg:unsigned(DELAY_BITS-1 downto 0);
signal signal_avn_reg:unsigned(bits(SIGNAL_AV_ADDRESS_BITS) downto 0);
signal slope_n_reg:unsigned(bits(SLOPE_ADDRESS_BITS) downto 0);
signal sync_clks_reg:unsigned(SYNC_ADDRESS_BITS downto 0);
signal baseline_timeconstant_reg:unsigned(TIMECONSTANT_BITS-1 downto 0);
signal baseline_avn_reg:unsigned(bits(BASELINE_AV_ADDRESS_BITS) downto 0);
signal start_threshold_reg:unsigned(ADC_BITS-1 downto 0);
signal stop_threshold_reg:unsigned(ADC_BITS-1 downto 0);
signal baseline_relative_reg:boolean;
signal slope_threshold_reg:unsigned(ADC_BITS-1 downto 0);
signal slope_crossing_reg:unsigned(ADC_BITS-1 downto 0);
signal area_threshold_reg:unsigned(AREA_BITS-1 downto 0);
signal baseline_threshold_reg:unsigned(BASELINE_MCA_COUNTER_BITS-1 downto 0);
signal fixed_baseline_reg:unsigned(ADC_BITS-1 downto 0);
--
signal data_out_int:std_logic_vector(AXI_DATA_BITS-1 downto 0);
--------------------------------------------------------------------------------
-- Register Addresses 
--------------------------------------------------------------------------------
constant DELAY_ADDR_BIT:integer:=0;
constant SIGNAL_AVN_ADDR_BIT:integer:=1;
constant SLOPE_N_ADDR_BIT:integer:=2;
constant SYNC_CLKS_ADDR_BIT:integer:=3;
constant BASELINE_TIMECONSTANT_ADDR_BIT:integer:=4;
constant BASELINE_AVN_ADDR_BIT:integer:=5;
constant START_THRESHOLD_ADDR_BIT:integer:=6;
constant STOP_THRESHOLD_ADDR_BIT:integer:=7;
constant BASELINE_RELATIVE_ADDR_BIT:integer:=8;
constant SLOPE_THRESHOLD_ADDR_BIT:integer:=9;
constant SLOPE_CROSSING_ADDR_BIT:integer:=10;
constant AREA_THRESHOLD_ADDR_BIT:integer:=11;
constant BASELINE_THRESHOLD_ADDR_BIT:integer:=12;
constant FIXED_BASELINE_ADDR_BIT:integer:=13;
--NOTE bits 16 to 19 are used as the bit address when the iodelay is read
--
begin 
delay <= delay_reg; 
signal_avn <= signal_avn_reg;  
slope_n <= slope_n_reg;
sync_clks <= sync_clks_reg;
baseline_timeconstant <= baseline_timeconstant_reg;
baseline_avn <= baseline_avn_reg;
start_threshold <= start_threshold_reg;
stop_threshold <= stop_threshold_reg;
baseline_relative <= baseline_relative_reg;
slope_threshold <= slope_threshold_reg;
slope_crossing_level <= slope_crossing_reg;
area_threshold <= area_threshold_reg;
data_out <= data_out_int;
baseline_threshold <= baseline_threshold_reg;
fixed_baseline <= fixed_baseline_reg;
--
regWrite:process(clk) 
begin
if rising_edge(clk) then
  if reset='1' then
    delay_reg <= to_unsigned(DEFAULT_DELAY,DELAY_BITS); 
    signal_avn_reg 
      <= to_unsigned(DEFAULT_SIGNAL_AVN,bits(SIGNAL_AV_ADDRESS_BITS)+1); 
    slope_n_reg<= to_unsigned(DEFAULT_SLOPE_N,bits(SLOPE_ADDRESS_BITS)+1); 
    sync_clks_reg <= to_unsigned(DEFAULT_SYNC_CLKS,SYNC_ADDRESS_BITS+1); 
    baseline_timeconstant_reg 
      <= to_unsigned(DEFAULT_BASELINE_TIMECONSTANT,TIMECONSTANT_BITS); 
    baseline_avn_reg 
      <= to_unsigned(DEFAULT_BASELINE_AVN,bits(BASELINE_AV_ADDRESS_BITS)+1);
    start_threshold_reg 
      <= to_unsigned(DEFAULT_START_THRESHOLD,ADC_BITS);
    stop_threshold_reg 
      <= to_unsigned(DEFAULT_STOP_THRESHOLD,ADC_BITS);
    baseline_relative_reg <= TRUE;
    slope_threshold_reg 
      <= to_unsigned(DEFAULT_SLOPE_THRESHOLD,ADC_BITS);
    slope_crossing_reg 
      <= to_unsigned(DEFAULT_SLOPE_CROSSING,ADC_BITS);
    area_threshold_reg <= to_unsigned(DEFAULT_AREA_THRESHOLD,AREA_BITS);
    baseline_threshold_reg 
      <= to_unsigned(DEFAULT_BASELINE_THRESHOLD,BASELINE_MCA_COUNTER_BITS);
    fixed_baseline_reg
      <= to_unsigned(DEFAULT_FIXED_BASELINE,ADC_BITS);
  else
    signal_avn_updated <= FALSE;
    slope_n_updated <= FALSE;
    sync_clks_updated <= FALSE;
    baseline_timeconstant_updated <= FALSE;
    baseline_avn_updated <= FALSE;
    if write then
      if address(DELAY_ADDR_BIT)='1' then
        delay_reg <= unsigned(data_in(DELAY_BITS-1 downto 0)); 
      end if;
      if address(SIGNAL_AVN_ADDR_BIT)='1' then
        signal_avn_reg 
          <= unsigned(data_in(bits(SIGNAL_AV_ADDRESS_BITS) downto 0)); 
        signal_avn_updated <= TRUE; 
      end if;
      if address(SLOPE_N_ADDR_BIT)='1' then
        slope_n_reg <= unsigned(data_in(bits(SLOPE_ADDRESS_BITS) downto 0)); 
        slope_n_updated <= TRUE;
      end if;
      if address(SYNC_CLKS_ADDR_BIT)='1' then
        sync_clks_reg <= unsigned(data_in(SYNC_ADDRESS_BITS downto 0)); 
        sync_clks_updated <= TRUE;
      end if;
      if address(BASELINE_TIMECONSTANT_ADDR_BIT)='1' then
        baseline_timeconstant_reg 
          <= unsigned(data_in(TIMECONSTANT_BITS-1 downto 0)); 
        baseline_timeconstant_updated <= TRUE;
      end if;
      if address(BASELINE_AVN_ADDR_BIT)='1' then
        baseline_avn_reg 
          <= unsigned(data_in(bits(BASELINE_AV_ADDRESS_BITS) downto 0)); 
        baseline_avn_updated <= TRUE;
      end if;
      if address(START_THRESHOLD_ADDR_BIT)='1' then
        start_threshold_reg <= unsigned(data_in(ADC_BITS-1 downto 0)); 
      end if;
      if address(STOP_THRESHOLD_ADDR_BIT)='1' then
        stop_threshold_reg <= unsigned(data_in(ADC_BITS-1 downto 0)); 
      end if;
      if address(BASELINE_RELATIVE_ADDR_BIT)='1' then
        baseline_relative_reg <= to_boolean(data_in(0)); 
      end if;
      if address(SLOPE_THRESHOLD_ADDR_BIT)='1' then
        slope_threshold_reg <= unsigned(data_in(ADC_BITS-1 downto 0)); 
      end if;
      if address(SLOPE_CROSSING_ADDR_BIT)='1' then
        slope_crossing_reg <= unsigned(data_in(ADC_BITS-1 downto 0)); 
      end if;
      if address(AREA_THRESHOLD_ADDR_BIT)='1' then
        area_threshold_reg <= unsigned(data_in(AREA_BITS-1 downto 0)); 
      end if;
      if address(BASELINE_THRESHOLD_ADDR_BIT)='1' then
        baseline_threshold_reg 
          <= unsigned(data_in(BASELINE_MCA_COUNTER_BITS-1 downto 0)); 
      end if;
      if address(FIXED_BASELINE_ADDR_BIT)='1' then
        fixed_baseline_reg <= unsigned(data_in(ADC_BITS-1 downto 0)); 
      end if;
    end if;
  end if;
end if;
end process regWrite;
--
regRead:process(address,area_threshold_reg,baseline_avn_reg,
                baseline_relative_reg,baseline_timeconstant_reg,delay_reg,
                signal_avn_reg,slope_crossing_reg,slope_n_reg,
                slope_threshold_reg,start_threshold_reg,stop_threshold_reg,
                sync_clks_reg, baseline_threshold_reg,fixed_baseline_reg) 
begin
  if address(DELAY_ADDR_BIT)='1' then
    data_out_int <= std_logic_vector(resize(delay_reg,AXI_DATA_BITS)); 
  elsif address(SIGNAL_AVN_ADDR_BIT)='1' then
    data_out_int <= std_logic_vector(resize(signal_avn_reg,AXI_DATA_BITS)); 
  elsif address(SLOPE_N_ADDR_BIT)='1' then
    data_out_int <= std_logic_vector(resize(slope_n_reg,AXI_DATA_BITS)); 
  elsif address(SYNC_CLKS_ADDR_BIT)='1' then
    data_out_int <= std_logic_vector(resize(sync_clks_reg,AXI_DATA_BITS)); 
  elsif address(BASELINE_TIMECONSTANT_ADDR_BIT)='1' then
    data_out_int 
      <= std_logic_vector(resize(baseline_timeconstant_reg,AXI_DATA_BITS)); 
  elsif address(BASELINE_AVN_ADDR_BIT)='1' then
    data_out_int <= std_logic_vector(resize(baseline_avn_reg,AXI_DATA_BITS)); 
  elsif address(START_THRESHOLD_ADDR_BIT)='1' then
    data_out_int 
      <= std_logic_vector(resize(unsigned(start_threshold_reg),AXI_DATA_BITS)); 
  elsif address(STOP_THRESHOLD_ADDR_BIT)='1' then
    data_out_int 
      <= std_logic_vector(resize(unsigned(stop_threshold_reg),AXI_DATA_BITS)); 
  elsif address(BASELINE_RELATIVE_ADDR_BIT)='1' then
    data_out_int <= (0 => to_std_logic(baseline_relative_reg), others => '0');
  elsif address(SLOPE_THRESHOLD_ADDR_BIT)='1' then
    data_out_int 
      <= std_logic_vector(resize(unsigned(slope_threshold_reg),AXI_DATA_BITS)); 
  elsif address(SLOPE_CROSSING_ADDR_BIT)='1' then
    data_out_int 
      <= std_logic_vector(resize(unsigned(slope_crossing_reg),AXI_DATA_BITS)); 
  elsif address(AREA_THRESHOLD_ADDR_BIT)='1' then
    data_out_int <= std_logic_vector(resize(area_threshold_reg,AXI_DATA_BITS)); 
  elsif address(BASELINE_THRESHOLD_ADDR_BIT)='1' then
    data_out_int <= std_logic_vector(
      resize(baseline_threshold_reg,AXI_DATA_BITS)
    ); 
  elsif address(FIXED_BASELINE_ADDR_BIT)='1' then
    data_out_int <= to_std_logic(resize(fixed_baseline_reg,AXI_DATA_BITS));
  else
    data_out_int <= (others => '-');
  end if;
end process regRead;
--
end architecture RTL;
