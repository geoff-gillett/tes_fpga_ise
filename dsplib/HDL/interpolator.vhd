--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:29 Dec 2015
--
-- Design Name: TES_digitiser
-- Module Name: interpolator
-- Project Name: dsplib
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
--latency 3?
entity interpolator is
generic(
	WIDTH:integer:=18;
	TIME_FRAC:integer:=6
);
port (
  clk:in std_logic;
  --
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  frac_delay:in signed(TIME_FRAC-1 downto 0);
  
  clk_frac:out unsigned(TIME_FRAC-1 downto 0);
  valid:out boolean
);
end entity interpolator;

architecture core_gen of interpolator is
component divider
port (
  aclk:in std_logic;
  s_axis_divisor_tvalid:in std_logic;
  s_axis_divisor_tdata:in std_logic_vector(15 downto 0);
  s_axis_dividend_tvalid:in std_logic;
  s_axis_dividend_tdata:in std_logic_vector(15 downto 0);
  m_axis_dout_tvalid:out std_logic;
  m_axis_dout_tdata:out std_logic_vector(23 downto 0)
);
end component;

signal signal_reg,signal_reg2,dividend,divisor:signed(WIDTH-1 downto 0);
signal below,was_below,xing:boolean;
signal valid_int:std_logic;
signal data:std_logic_vector(23 downto 0);
begin
	
below <= signal_in < threshold;
--todo handle 0
thresholdDivider:divider
port map (
  aclk => clk,
  s_axis_divisor_tvalid => to_std_logic(xing),
  s_axis_divisor_tdata => to_std_logic(resize(divisor, 16)),
  s_axis_dividend_tvalid => to_std_logic(xing),
  s_axis_dividend_tdata => to_std_logic(resize(dividend,16)),
  m_axis_dout_tvalid => valid_int,
  m_axis_dout_tdata => data
);

delay:entity work.SREG_delay
generic map(
  DEPTH => 32,
  DATA_BITS => WIDTH
)
port map(
  clk => clk,
  data_in => to_std_logic(signal_in),
  delay => 27,
  delayed => delayed
);
	
name:process (clk) is
begin
	if rising_edge(clk) then
		was_below <= below;
		signal_reg <= signal_in;
		signal_reg2 <= signal_reg;
		divisor <= signal_in-signal_reg;
		dividend <= threshold-signal_reg;
		xing <= not below and was_below;
	end if;
end process name;

clk_frac <= unsigned(data(TIME_FRAC-1 downto 0));
valid <= to_boolean(valid_int);

end architecture core_gen;
