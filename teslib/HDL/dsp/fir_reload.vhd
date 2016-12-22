--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:21Dec.,2016
--
-- Design Name: TES_digitiser
-- Module Name: dsp_coefficient_reload
-- Project Name: 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dsp;
use dsp.types.all;

library extensions;
use extensions.logic.all;

use work.types.all;

-- 
-- data
-- 31 = last
-- 30 filter
-- 29 slope
-- 28 baseline
-- COEFF_WIDTH-1 downto 0 coefficient 
-- output errors done

entity fir_reload is
generic(
  FILTER_COEF_WIDTH:natural:=23;
  SLOPE_COEF_WIDTH:natural:=25;
  BASELINE_COEF_WIDTH:natural:=25
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  write:in std_logic;
  data:in std_logic_vector(AXI_DATA_BITS-1 downto 0);
  
  last_missing:out std_logic;
  last_unexpected:out std_logic;
  done:out std_logic;

  filter_config:out fir_control_in_t;
  filter_events:in fir_control_out_t;
  slope_config:out fir_control_in_t;
  slope_events:in fir_control_out_t;
  baseline_config:out fir_control_in_t;
  baseline_events:in fir_control_out_t
);
end entity fir_reload;

architecture RTL of fir_reload is
  
type FSMstate is (
  IDLE,FILTER,SLOPE,BASELINE,F_COMMIT,S_COMMIT,B_COMMIT,CHECK_ERROR,
  MISSING,UNEXPECTED
);
constant LAST_BIT:natural:=31;
constant RESET_BIT:natural:=30;
constant FILTER_BIT:natural:=29;
constant SLOPE_BIT:natural:=28;
constant BASELINE_BIT:natural:=27;

signal state,nextstate:FSMstate;
signal error_int:std_logic;

begin

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

done <= '1' when state=IDLE else '0';
error_int <= filter_events.last_missing or filter_events.last_unexpected or
             slope_events.last_missing or slope_events.last_unexpected or
             baseline_events.last_missing or baseline_events.last_unexpected;
  
FSMtransition:process(
  state,write,data,baseline_events.reload_ready,filter_events.reload_ready, 
  slope_events.reload_ready,filter_events.config_ready, 
  baseline_events.config_ready, slope_events.config_ready, 
  baseline_events.last_missing, baseline_events.last_unexpected, 
  filter_events.last_missing, filter_events.last_unexpected, 
  slope_events.last_missing, slope_events.last_unexpected
)

begin
nextstate <= state;
case state is 
when IDLE =>
	if write='1' then
	  if data(FILTER_BIT)='1' then
	    nextstate <= FILTER;
	  end if;
	  if data(SLOPE_BIT)='1' then
	    nextstate <= SLOPE;
	  end if;
	  if data(BASELINE_BIT)='1' then
	    nextstate <= BASELINE;
	  end if;
  end if;
when FILTER =>
  if filter_events.reload_ready='1' then
    nextstate <= CHECK_ERROR;
  end if;
when SLOPE =>
  if slope_events.reload_ready='1' then
    nextstate <= CHECK_ERROR;
  end if;
when BASELINE =>
  if baseline_events.reload_ready='1' then
    nextstate <= CHECK_ERROR;
  end if;
when F_COMMIT =>
  if filter_events.config_ready='1' then
    nextstate <= IDLE;
  end if;
when S_COMMIT =>
  if slope_events.config_ready='1' then
    nextstate <= IDLE;
  end if;
when B_COMMIT =>
  if baseline_events.config_ready='1' then
    nextstate <= IDLE;
  end if;
when CHECK_ERROR =>
      nextstate <= IDLE;
      if data(FILTER_BIT)='1' then
        if data(LAST_BIT)='1' then
          nextstate <= F_COMMIT;
        end if;
        if filter_events.last_missing='1' then
          nextstate <= MISSING;
        end if;
        if filter_events.last_unexpected='1' then
          nextstate <= UNEXPECTED;
        end if;
      end if;
      if data(SLOPE_BIT)='1' then
        if data(LAST_BIT)='1' then
          nextstate <= S_COMMIT;
        end if;
        if slope_events.last_missing='1' then
          nextstate <= MISSING;
        end if;
        if slope_events.last_unexpected='1' then
          nextstate <= UNEXPECTED;
        end if;
      end if;
      if data(BASELINE_BIT)='1' then
        if data(LAST_BIT)='1' then
          nextstate <= B_COMMIT;
        end if;
        if baseline_events.last_missing='1' then
          nextstate <= MISSING;
        end if;
        if baseline_events.last_unexpected='1' then
          nextstate <= UNEXPECTED;
        end if;
      end if;
when MISSING =>
  if write='1' and data(RESET_BIT)='1' then
    nextstate <= IDLE; 
  end if;
when UNEXPECTED =>
  if write='1' and data(RESET_BIT)='1' then
    nextstate <= IDLE; 
  end if;
end case;
end process FSMtransition;

last_missing <= '1' when state=MISSING else '0';
last_unexpected <= '1' when state=UNEXPECTED else '0';

filter_config.reload_valid <= '1' when state=FILTER else '0';
filter_config.reload_last <= data(LAST_BIT);
filter_config.reload_data 
  <= resize(data(FILTER_COEF_WIDTH-1 downto 0), AXI_DATA_BITS);
filter_config.config_data <= (others => '0');
filter_config.config_valid <= '1' when state=F_COMMIT else '0';

slope_config.reload_valid <= '1' when state=SLOPE else '0';
slope_config.reload_last <= data(LAST_BIT);
slope_config.reload_data 
  <= resize(data(SLOPE_COEF_WIDTH-1 downto 0), AXI_DATA_BITS);
slope_config.config_data <= (others => '0');
slope_config.config_valid <= '1' when state=S_COMMIT else '0';

baseline_config.reload_valid <= '1' when state=BASELINE else '0';
baseline_config.reload_last <= data(LAST_BIT);
baseline_config.reload_data 
  <= resize(data(BASELINE_COEF_WIDTH-1 downto 0), AXI_DATA_BITS);
baseline_config.config_data <= (others => '0');
baseline_config.config_valid <= '1' when state=B_COMMIT else '0';
end architecture RTL;
