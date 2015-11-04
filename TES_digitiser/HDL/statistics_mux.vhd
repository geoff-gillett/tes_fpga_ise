--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20/03/2014 
--
-- Design Name: TES_digitiser
-- Module Name: mca_mux
-- Project Name: tes_digitiser
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library adclib;
use adclib.types.all;
--use TES.events.all;
--select the channel to histogram
entity statistics_mux is
generic(
  CHANNEL_BITS:integer:=3;
  VALUES:integer:=8;
  VALUE_BITS:integer:=AREA_BITS 
);
port(
  clk:std_logic;
  reset:std_logic;
  --
  swap_buffer:in boolean;
  swap_buffer_out:out boolean;
  ------------------------------------------------------------------------------
  --! selectors
  ------------------------------------------------------------------------------
  value_select:in boolean_vector(VALUES-1 downto 0);
  channel_select:in unsigned(CHANNEL_BITS-1 downto 0);
  ------------------------------------------------------------------------------
  --! inputs from channels
  ------------------------------------------------------------------------------
  samples:in sample_array(2**CHANNEL_BITS-1 downto 0);
  baselines:in sample_array(2**CHANNEL_BITS-1 downto 0);
  extremas:in sample_array(2**CHANNEL_BITS-1 downto 0);
  areas:in area_array(2**CHANNEL_BITS-1 downto 0);
  derivative_extremas:in sample_array(2**CHANNEL_BITS-1 downto 0);
  pulse_areas:in area_array(2**CHANNEL_BITS-1 downto 0);
  pulse_lengths:in time_array(2**CHANNEL_BITS-1 downto 0);
  -- valid flags
  max_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  --min_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  sample_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  derivative_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  pulse_valids:in boolean_vector(2**CHANNEL_BITS-1 downto 0);
  ------------------------------------------------------------------------------
  -- outputs
  ------------------------------------------------------------------------------
  --true 1 clk after update if *any* value is selected.
  enabled:out boolean;
  --outputs to MCA
  value:out signed(VALUE_BITS-1 downto 0);
  value_valid:out boolean
);
end entity statistics_mux;

architecture RTL of statistics_mux is
-- select registers
signal sample:sample_t;
signal baseline:sample_t;
signal extrema,derivative_extrema:sample_t;
signal area:area_t;
signal pulse_area:area_t;
signal max_valid,min_valid,sample_valid,derivative_valid,pulse_valid:boolean;
signal pulse_length:time_t;
signal swap_pipe:boolean;
--
begin
swap_buffer_out <= swap_pipe;
--
controlReg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    swap_pipe <= FALSE;
  else
    swap_pipe <= swap_buffer; 
  end if;
end if;
end process controlReg;
--
channelMux:process(channel_select,areas,derivative_extremas,derivative_valids,
                   extremas,max_valids,pulse_areas,pulse_lengths,
                   pulse_valids,sample_valids,samples,baselines)
begin
  sample <= samples(to_integer(to_0IfX(channel_select)));
  baseline <= baselines(to_integer(to_0IfX(channel_select)));
  max_valid <= max_valids(to_integer(to_0IfX(channel_select)));
  --min_valid <= min_valids(to_integer(channel_select));
  extrema <= extremas(to_integer(to_0IfX(channel_select)));
  area <= areas(to_integer(to_0IfX(channel_select)));
  sample_valid <= sample_valids(to_integer(to_0IfX(channel_select)));
  derivative_extrema <= derivative_extremas(to_integer(to_0IfX(channel_select)));
  derivative_valid <= derivative_valids(to_integer(to_0IfX(channel_select)));
  pulse_area <= pulse_areas(to_integer(to_0IfX(channel_select)));
  pulse_length <= pulse_lengths(to_integer(to_0IfX(channel_select)));
  pulse_valid <= pulse_valids(to_integer(to_0IfX(channel_select)));
end process channelMux;
--
valueMux:process (clk) is
begin
if rising_edge(clk) then
  if reset='1' then
    enabled <= FALSE;
  else
    case to_std_logic(value_select) is
    when "00000001" => -- sample
      enabled <= TRUE;
      value <= resize(sample,VALUE_BITS);
      value_valid <= TRUE;
    when "00000010" => -- sample max
      enabled <= TRUE;
      value <= resize(sample,VALUE_BITS);
      value_valid <= max_valid;
    when "00000100" => --baseline -- sample min
      enabled <= TRUE;
      value <= resize(baseline,VALUE_BITS);
      value_valid <= TRUE; --min_valid;
--    when "00000110" => -- sample max or min
--      enabled <= TRUE;
--      value <= resize(sample,VALUE_BITS);
--      value_valid <= min_valid or max_valid;
    when "00001000" => -- sample extrema
      enabled <= TRUE;
      value <= resize(extrema,VALUE_BITS);
      value_valid <= sample_valid;
    when "00010000" => -- sample area
      enabled <= TRUE;
      value <= area;
      value_valid <= sample_valid;
    when "00100000" => -- derivative extrema
      enabled <= TRUE;
      value <= resize(derivative_extrema,VALUE_BITS);
      value_valid <= derivative_valid;
    when "01000000" => -- pulse area
      enabled <= TRUE;
      value <= pulse_area;
      value_valid<= pulse_valid;
    when "10000000" => -- pulse length
      enabled <= TRUE;
      value <= resize(signed('0' & pulse_length),VALUE_BITS);
      value_valid<= pulse_valid;
    when others => 
      enabled <= FALSE;
      value <= (others => '-');
      value_valid <= FALSE;
    end case;
  end if;
end if;
end process valueMux;
--
end architecture RTL;
