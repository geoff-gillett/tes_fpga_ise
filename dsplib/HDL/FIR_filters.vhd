--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:8 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: dsp
-- Project Name:dsplib 
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

entity FIR_filters is
generic(
	STAGE1_OUT_WIDTH:integer:=45;
	STAGE2_OUT_WIDTH:integer:=48;
	DELAY_DEPTH:integer:=64
);
port(
  clk:in std_logic;
  sample:in sample_t;
  -- stage1 usually a low pass/bandpass filter
  stage1_shift:in unsigned(bits(STAGE1_OUT_WIDTH-SIGNAL_BITS)-1 downto 0);
  stage1_delay:in unsigned(bits(DELAY_DEPTH)-1 downto 0);
  stage1_config_data:in std_logic_vector(7 downto 0);
  stage1_config_valid:in boolean;
  stage1_config_ready:out boolean;
  stage1_reload_data:in std_logic_vector(31 downto 0);
  stage1_reload_valid:in boolean;
  stage1_reload_ready:out boolean;
  stage1_reload_last:in boolean;
  stage2_shift:in unsigned(bits(STAGE2_OUT_WIDTH-SIGNAL_BITS)-1 downto 0);
  stage2_config_data:in std_logic_vector(7 downto 0);
  stage2_config_valid:in boolean;
  stage2_config_ready:out boolean;
  stage2_reload_data:in std_logic_vector(31 downto 0);
  stage2_reload_valid:in boolean;
  stage2_reload_ready:out boolean;
  stage2_reload_last:in boolean;
  raw_delay:in unsigned(bits(DELAY_DEPTH)-1 downto 0);
  -- output signals
  raw_sample:out signal_t;
  stage1_sample:out signal_t;
  stage2_sample:out signal_t
  
);
end entity FIR_filters;

architecture order_23 of FIR_filters is
--IP cores FIR compiler 6.3
component stage1_fir_23
port (
  aclk:in std_logic;
  s_axis_data_tvalid:in std_logic;
  s_axis_data_tready:out std_logic;
  s_axis_data_tdata:in std_logic_vector(15 downto 0);
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

component stage2_fir_23
port (
  aclk:in std_logic;
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

signal stage1_out:std_logic_vector(47 downto 0);
signal stage1_reload_last_missing:std_logic;
signal stage1_reload_last_unexpected:std_logic;
signal stage2_data:std_logic_vector(23 downto 0);
signal stage2_out:std_logic_vector(47 downto 0);
signal stage2_reload_last_missing:std_logic;
signal stage2_reload_last_unexpected:std_logic;
signal stage1_config_ready_int:std_logic;
signal stage1_reload_ready_int:std_logic;
signal stage2_config_ready_int:std_logic;
signal stage2_reload_ready_int:std_logic;
signal raw_sample_int:std_logic_vector(SAMPLE_BITS-1 downto 0);
signal stage1_sample_int:std_logic_vector(SIGNAL_BITS-1 downto 0);

begin
	
stage1_config_ready <= to_boolean(stage1_config_ready_int);
stage1_reload_ready <= to_boolean(stage1_reload_ready_int);
stage2_config_ready <= to_boolean(stage2_config_ready_int);
stage2_reload_ready <= to_boolean(stage2_reload_ready_int);
raw_sample <= resize(signed(raw_sample_int),SIGNAL_BITS);
stage1_sample <= signed(stage1_sample_int);

--------------------------------------------------------------------------------
-- FIR filter stages with reloadable coefficients (FIR compiler 6.3)
--------------------------------------------------------------------------------

stage1FIRfilter:stage1_FIR_23
port map(
  aclk => clk,
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => to_std_logic(resize(sample,16)),
  s_axis_config_tvalid => to_std_logic(stage1_config_valid),
  s_axis_config_tready => stage1_config_ready_int,
  s_axis_config_tdata => stage1_config_data,
  s_axis_reload_tvalid => to_std_logic(stage1_reload_valid),
  s_axis_reload_tready => stage1_reload_ready_int,
  s_axis_reload_tlast => to_std_logic(stage1_reload_last),
  s_axis_reload_tdata => stage1_reload_data,
  m_axis_data_tvalid => open,
  m_axis_data_tdata => stage1_out,
  event_s_reload_tlast_missing => stage1_reload_last_missing,
  event_s_reload_tlast_unexpected => stage1_reload_last_unexpected
);

stage2FIRfilter:stage2_FIR_23
port map(
  aclk => clk,
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => stage2_data,
  s_axis_config_tvalid => to_std_logic(stage2_config_valid),
  s_axis_config_tready => stage2_config_ready_int,
  s_axis_config_tdata => stage2_config_data,
  s_axis_reload_tvalid => to_std_logic(stage2_reload_valid),
  s_axis_reload_tready => stage2_reload_ready_int,
  s_axis_reload_tlast => to_std_logic(stage2_reload_last),
  s_axis_reload_tdata => stage2_reload_data,
  m_axis_data_tvalid => open,
  m_axis_data_tdata => stage2_out,
  event_s_reload_tlast_missing => stage2_reload_last_missing,
  event_s_reload_tlast_unexpected => stage2_reload_last_unexpected
);

--------------------------------------------------------------------------------
-- shift to correct fixed precision and register the outputs of each FIR stage
--------------------------------------------------------------------------------
firOutputReg:process (clk) is
begin
if rising_edge(clk) then
  stage2_data <= to_std_logic(
    resize(shift_right(signed(stage1_out),to_integer(stage1_shift)),24)
  );
  stage2_sample <= signed(to_std_logic(
    resize(shift_right(signed(stage1_out),to_integer(stage2_shift)),SIGNAL_BITS)
  ));
end if;
end process firOutputReg;

--------------------------------------------------------------------------------
-- delays to align outputs after FIR group delay
--------------------------------------------------------------------------------
rawDelay:entity work.SREG_delay
generic map(
  DEPTH => DELAY_DEPTH,
  DATA_BITS => SAMPLE_BITS
)
port map(
  clk => clk,
  data_in => to_std_logic(sample),
  delay => raw_delay,
  delayed => raw_sample_int
);

stage1Delay:entity work.SREG_delay
generic map(
  DEPTH => DELAY_DEPTH,
  DATA_BITS => SIGNAL_BITS
)
port map(
  clk     => clk,
  data_in => stage2_data(17 downto 18-SIGNAL_BITS),
  delay   => stage1_delay,
  delayed => stage1_sample_int
);

end architecture order_23;
