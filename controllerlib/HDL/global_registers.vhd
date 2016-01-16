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
library adclib;
use adclib.types.all;

entity global_registers is
generic(
  VERSION:unsigned(31 downto 0):=to_unsigned(42,32);
  TES_CHANNEL_BITS:integer:=3;
  ADC_CHANNELS:integer:=8;
  ------------------------------------------------------------------------------
  -- Register Widths etc
  ------------------------------------------------------------------------------
  MTU_BITS:integer:=13;
  EVENT_THRESHOLD_BITS:integer:=10;
  EVENT_TIMEOUT_BITS:integer:=32;
  TICK_PERIOD_BITS:integer:=32;
  TICK_COUNT_BITS:integer:=32;
  MCA_ADDRESS_BITS:integer:=14;
  MCA_VALUES:integer:=8;
  MCA_VALUE_BITS:integer:=AREA_BITS;
  IODELAY_CONTROL_BITS:integer:=ADC_BITS+3; --bits(ADC_CHANNELS);
  ------------------------------------------------------------------------------
  -- Register Defaults
  ------------------------------------------------------------------------------
  DEFAULT_MTU:integer:=1470;
  DEFAULT_EVENT_THRESHOLD:integer:=1000;
  DEFAULT_EVENT_TIMEOUT:integer:=25000000;
  DEFAULT_TICK_PERIOD:integer:=25000000
);
port (
  clk:in std_logic;
  reset:in std_logic;
  --!* register signals from/to channel CPU
  data:in registerdata;
  address:in registeraddress;
  data_out:out registerdata;
  write:in boolean; --Strobe
  --registers
  FMC_internal_clk_en:out std_logic;
  FMC_VCO_power_en:out std_logic;
  MTU:out unsigned(MTU_BITS-1 downto 0);
  event_threshold:out unsigned(EVENT_THRESHOLD_BITS-1 downto 0);
  event_timeout:out unsigned(EVENT_TIMEOUT_BITS-1 downto 0);
  tick_period:out unsigned(TICK_PERIOD_BITS-1 downto 0);
  adc_enables:out boolean_vector(ADC_CHANNELS-1 downto 0);
  eventstream_enables:out boolean_vector(2**TES_CHANNEL_BITS-1 downto 0);
  -- mca control
  mca_update_asap:out boolean;
  mca_update_on_completion:out boolean;
  mca_bin_n:out unsigned(ceilLog2(MCA_ADDRESS_BITS)-1 downto 0);
  mca_lowest_value:out signed(MCA_VALUE_BITS-1 downto 0);
  mca_last_bin:out unsigned(MCA_ADDRESS_BITS-1 downto 0);
  mca_ticks:out unsigned(TICK_COUNT_BITS-1 downto 0);
  mca_channel_sel:out unsigned(TES_CHANNEL_BITS-1 downto 0);
  mca_value_sels:out boolean_vector(MCA_VALUES-1 downto 0);
  --iodelay comtrol
  iodelay_control:out std_logic_vector(IODELAY_CONTROL_BITS-1 downto 0);
  iodelay_updated:out boolean
);
end entity global_registers;
--------------------------------------------------------------------------------
-- All register addresses are one-hot
-- NOTE relies on CPU to do address validation
--------------------------------------------------------------------------------
architecture if_decode of global_registers is
constant TES_CHANNELS:integer := 2**TES_CHANNEL_BITS;
--------------------------------------------------------------------------------
-- Registers 
--------------------------------------------------------------------------------
signal max_payload_reg:unsigned(MTU_BITS-1 downto 0);
signal event_threshold_reg:unsigned(EVENT_THRESHOLD_BITS-1 downto 0);
signal event_timeout_reg:unsigned(EVENT_TIMEOUT_BITS-1 downto 0);
signal tick_period_reg:unsigned(TICK_PERIOD_BITS-1 downto 0);
signal adc_enables_reg:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal mca_bin_n_reg:unsigned(ceilLog2(MCA_ADDRESS_BITS)-1 downto 0);
signal mca_lowest_value_reg:signed(MCA_VALUE_BITS-1 downto 0);
signal mca_last_bin_reg:unsigned(MCA_ADDRESS_BITS-1 downto 0);
signal mca_ticks_reg:unsigned(TICK_COUNT_BITS-1 downto 0);
signal mca_channel_sel_reg:unsigned(TES_CHANNEL_BITS-1 downto 0);
signal mca_value_sels_reg:boolean_vector(MCA_VALUES-1 downto 0);
signal eventstream_enables_reg:std_logic_vector(TES_CHANNELS-1 downto 0);
signal iodelay_control_reg:std_logic_vector(IODELAY_CONTROL_BITS-1 downto 0);
--
constant NUMBER_OF_FLAGS:integer:=2;
constant INTERNAL_CLK_BIT:integer:=0;
constant VCO_POWER_BIT:integer:=1;
signal flags_reg:std_logic_vector(NUMBER_OF_FLAGS-1 downto 0);
--------------------------------------------------------------------------------
-- Register Addresses 
--------------------------------------------------------------------------------
--NOTE address bit 0 corresponds to the features command
constant HDL_VERSION_ADDR_BIT:integer:=1;  
constant EVENT_THRESHOLD_ADDR_BIT:integer:=2;
constant EVENT_TIMEOUT_ADDR_BIT:integer:=3;
constant TICK_PERIOD_ADDR_BIT:integer:=4;
constant ADC_ENABLE_ADDR_BIT:integer:=5; 
constant MAX_PAYLOAD_ADDR_BIT:integer:=6;
-- bit0 asap bit1 on_completion
constant MCA_UPDATE_ADDR_BIT:integer:=7;
constant MCA_BIN_N_ADDR_BIT:integer:=8;
constant MCA_LOWEST_VALUE_ADDR_BIT:integer:=9;
constant MCA_LAST_BIN_ADDR_BIT:integer:=10;
constant MCA_TICKS_ADDR_BIT:integer:=11;
constant MCA_SELECT_ADDR_BIT:integer:=12;
constant FLAGS_ADDR_BIT:integer:=13;
constant STREAM_ENABLE_ADDR_BIT:integer:=14;
constant IODELAY_CONTROL_ADDR_BIT:integer:=15;
-- 
constant MCA_UPDATE_ASAP_BIT:integer:=0;
constant MCA_UPDATE_ON_COMPLETION_BIT:integer:=1;
--
begin 
--
MTU <= max_payload_reg;
event_threshold <= event_threshold_reg;
event_timeout <= event_timeout_reg;
tick_period <= tick_period_reg;
adc_enables <= to_boolean(adc_enables_reg);
eventstream_enables <= to_boolean(eventstream_enables_reg);
mca_bin_n <= mca_bin_n_reg;
mca_lowest_value <= mca_lowest_value_reg;
mca_last_bin <= mca_last_bin_reg;
mca_ticks <= mca_ticks_reg;
mca_channel_sel <= mca_channel_sel_reg;
mca_value_sels <= mca_value_sels_reg;
FMC_internal_clk_en <= flags_reg(INTERNAL_CLK_BIT);
FMC_VCO_power_en <= flags_reg(VCO_POWER_BIT);
iodelay_control <= iodelay_control_reg;
--------------------------------------------------------------------------------
-- read_data mux
--------------------------------------------------------------------------------
readDataMux:process(address,adc_enables_reg,event_threshold_reg,
                    event_timeout_reg,max_payload_reg,mca_bin_n_reg,
                    mca_channel_sel_reg,mca_last_bin_reg,mca_lowest_value_reg,
                    mca_ticks_reg,mca_value_sels_reg,tick_period_reg,flags_reg,
                    eventstream_enables_reg)
begin
  if address(HDL_VERSION_ADDR_BIT)='1' then 
    data_out <= to_std_logic(VERSION);
  elsif address(EVENT_THRESHOLD_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(event_threshold_reg,REGISTER_DATA_BITS)); 
  elsif address(EVENT_TIMEOUT_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(event_timeout_reg,REGISTER_DATA_BITS)); 
  elsif address(TICK_PERIOD_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(tick_period_reg,REGISTER_DATA_BITS)); 
  elsif address(MAX_PAYLOAD_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(max_payload_reg,REGISTER_DATA_BITS)); 
  elsif address(ADC_ENABLE_ADDR_BIT)='1' then
    data_out 
      <= to_std_logic(resize(unsigned(adc_enables_reg),REGISTER_DATA_BITS)); 
  elsif address(MCA_BIN_N_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(mca_bin_n_reg,REGISTER_DATA_BITS)); 
  elsif address(MCA_LOWEST_VALUE_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(mca_lowest_value_reg,REGISTER_DATA_BITS)); 
  elsif address(MCA_LAST_BIN_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(mca_last_bin_reg,REGISTER_DATA_BITS)); 
  elsif address(MCA_TICKS_ADDR_BIT)='1' then
    data_out <= to_std_logic(resize(mca_ticks_reg,REGISTER_DATA_BITS)); 
  elsif address(MCA_SELECT_ADDR_BIT)='1' then 
    data_out <= to_std_logic(resize(
                   mca_channel_sel_reg & 
                   unsigned(to_std_logic(mca_value_sels_reg)
                 ),REGISTER_DATA_BITS));
  elsif address(MCA_UPDATE_ADDR_BIT)='1' then
    data_out <= (others => '0');
  elsif address(FLAGS_ADDR_BIT)='1' then
  	data_out(NUMBER_OF_FLAGS-1 downto 0) <= flags_reg;
  	data_out(REGISTER_DATA_BITS-1 downto NUMBER_OF_FLAGS) <= (others => '0');
  elsif address(STREAM_ENABLE_ADDR_BIT)='1' then 
    data_out <= to_std_logic(
                  resize(unsigned(eventstream_enables_reg),REGISTER_DATA_BITS)
                );
  else
    data_out <= (others => '-');
  end if;
end process readDataMux;  
--------------------------------------------------------------------------------
-- write_data MUX
--------------------------------------------------------------------------------
writeDataMux:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    max_payload_reg <= to_unsigned(DEFAULT_MTU,MTU_BITS);
    event_threshold_reg 
    		<= to_unsigned(DEFAULT_EVENT_THRESHOLD,EVENT_THRESHOLD_BITS);
    event_timeout_reg <= to_unsigned(DEFAULT_EVENT_TIMEOUT,EVENT_TIMEOUT_BITS);
    tick_period_reg <= to_unsigned(DEFAULT_TICK_PERIOD,TICK_PERIOD_BITS);
    adc_enables_reg <= (others => '0');
    mca_bin_n_reg <= (others => '0');
    mca_lowest_value_reg <= (others => '0');
    mca_last_bin_reg <= (others => '1');
    mca_ticks_reg <= to_unsigned(1,TICK_COUNT_BITS);
    mca_channel_sel_reg <= (others => '0');
    mca_value_sels_reg <= (others => FALSE);
    flags_reg(INTERNAL_CLK_BIT) <= '1';
    flags_reg(VCO_POWER_BIT) <= '1';
    eventstream_enables_reg <= (others => '0');
  else
    mca_update_asap <= FALSE;
    mca_update_on_completion <= FALSE;
    iodelay_updated <= FALSE;
    if write then
      if address(MAX_PAYLOAD_ADDR_BIT)='1' then
        max_payload_reg <= unsigned(data(MTU_BITS-1 downto 0));
      end if;
      if address(EVENT_THRESHOLD_ADDR_BIT)='1' then
        event_threshold_reg 
          <= unsigned(data(EVENT_THRESHOLD_BITS-1 downto 0));
      end if;
      if address(EVENT_TIMEOUT_ADDR_BIT)='1' then
        event_timeout_reg 
          <= unsigned(data(EVENT_TIMEOUT_BITS-1 downto 0));
      end if;
      if address(TICK_PERIOD_ADDR_BIT)='1' then
        tick_period_reg <= unsigned(data(TICK_PERIOD_BITS-1 downto 0));
      end if;
      if address(ADC_ENABLE_ADDR_BIT)='1' then
        adc_enables_reg <= data(ADC_CHANNELS-1 downto 0);
      end if;
      if address(MCA_BIN_N_ADDR_BIT)='1' then
        mca_bin_n_reg 
          <= unsigned(data(ceilLog2(MCA_ADDRESS_BITS)-1 downto 0));
      end if;
      if address(MCA_LOWEST_VALUE_ADDR_BIT)='1' then
        mca_lowest_value_reg <= signed(data(MCA_VALUE_BITS-1 downto 0));
      end if;
      if address(MCA_LAST_BIN_ADDR_BIT)='1' then
        mca_last_bin_reg <= unsigned(data(MCA_ADDRESS_BITS-1 downto 0));
      end if;
      if address(MCA_TICKS_ADDR_BIT)='1' then
        mca_ticks_reg <= unsigned(data(TICK_COUNT_BITS-1 downto 0));
      end if;
      if address(MCA_SELECT_ADDR_BIT)='1' then
        mca_channel_sel_reg <= unsigned(
          data(TES_CHANNEL_BITS+MCA_VALUES-1 downto MCA_VALUES)
        );
        mca_value_sels_reg <= to_boolean(data(MCA_VALUES-1 downto 0));
      end if;
      if address(FLAGS_ADDR_BIT)='1' then
      	flags_reg(INTERNAL_CLK_BIT) <= data(INTERNAL_CLK_BIT);
      	flags_reg(VCO_POWER_BIT) <= data(VCO_POWER_BIT);
      end if;
      if address(MCA_UPDATE_ADDR_BIT)='1' then
      	if data(MCA_UPDATE_ASAP_BIT)='1' then
          mca_update_asap <= TRUE; 
        elsif data(MCA_UPDATE_ON_COMPLETION_BIT)='1' then
          mca_update_on_completion <= TRUE;
        end if;
      end if;
      if address(STREAM_ENABLE_ADDR_BIT)='1' then
        eventstream_enables_reg <= data(TES_CHANNELS-1 downto 0);
      end if;
      if address(IODELAY_CONTROL_ADDR_BIT)='1' then
        iodelay_control_reg <= data(IODELAY_CONTROL_BITS-1 downto 0);
        iodelay_updated <= TRUE;
      end if;
    end if;
  end if;
end if;
end process writeDataMux;
--
end architecture if_decode;
--------------------------------------------------------------------------------