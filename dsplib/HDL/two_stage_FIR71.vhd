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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

--use work.types.all;
--use work.functions.all;
use work.types.all;

-- stage1 output w=48 f=28
-- stage2 output w=48 f=28
entity two_stage_FIR71 is
generic(
	WIDTH:integer:=18;
	FRAC:natural:=3;
	SLOPE_FRAC:natural:=8
);
port(
  clk:in std_logic;
  sample_in:in signed(WIDTH-1 downto 0);
  stage1_config:in fir_control_in_t;
  stage1_events:out fir_control_out_t;
  stage2_config:in fir_control_in_t;
  stage2_events:out fir_control_out_t;

  stage1:out signed(WIDTH-1 downto 0);
  stage2:out signed(WIDTH-1 downto 0)
);
end entity two_stage_FIR71;

architecture coregen of two_stage_FIR71 is
--IP cores FIR compiler 6.3

component stage1_fir_71
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
  s_axis_reload_tdata:in std_logic_vector(23 downto 0);
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

signal stage1_in,stage2_in:std_logic_vector(23 downto 0);
signal stage1_out,stage2_out:std_logic_vector(47 downto 0);
signal stage1_d:std_logic_vector(WIDTH-1 downto 0);
signal stage1_data,stage2_data:signed(WIDTH-1 downto 0);
signal stage1_valid:std_logic;

begin
	
--------------------------------------------------------------------------------
-- FIR filter stages with reloadable coefficients (FIR compiler 6.3)
--------------------------------------------------------------------------------
-- stage1 internal output 48 bits frac=26
stage1_in <= to_std_logic(resize(sample_in,24));
stage1FIRfilter:stage1_FIR_71
port map (
  aclk => clk,
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => stage1_in,
  s_axis_config_tvalid => stage1_config.config_valid,
  s_axis_config_tready => stage1_events.config_ready,
  s_axis_config_tdata => stage1_config.config_data,
  s_axis_reload_tvalid => stage1_config.reload_valid,
  s_axis_reload_tready => stage1_events.reload_ready,
  s_axis_reload_tlast => stage1_config.reload_last,
  s_axis_reload_tdata => stage1_config.reload_data(23 downto 0),
  m_axis_data_tvalid => stage1_valid,
  m_axis_data_tdata => stage1_out,
  event_s_reload_tlast_missing => stage1_events.last_missing,
  event_s_reload_tlast_unexpected => stage1_events.last_unexpected
);

--TODO check out using rounding in the macro
--would still need to handle saturation
stage1Round:entity work.round2
generic map(
  WIDTH_IN => 48,
  FRAC_IN => 26,
  WIDTH_OUT => WIDTH,
  FRAC_OUT => FRAC
)
port map(
  clk => clk,
  reset => '0',
  input => signed(stage1_out),
  output_threshold => (others => '0'),
  output => stage1_data
);

stage2_in <= resize(stage1_data,24);
stage2FIRfilter:stage2_FIR_23
port map(
  aclk => clk,
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => stage2_in,
  s_axis_config_tvalid => stage2_config.config_valid,
  s_axis_config_tready => stage2_events.config_ready,
  s_axis_config_tdata => stage2_config.config_data,
  s_axis_reload_tvalid => stage2_config.reload_valid,
  s_axis_reload_tready => stage2_events.reload_ready,
  s_axis_reload_tlast => stage2_config.reload_last,
  s_axis_reload_tdata => stage2_config.reload_data,
  m_axis_data_tvalid => open,
  m_axis_data_tdata => stage2_out,
  event_s_reload_tlast_missing => stage2_events.last_missing,
  event_s_reload_tlast_unexpected => stage2_events.last_unexpected
);

stage2Round:entity work.round2
generic map(
  WIDTH_IN => 48,
  FRAC_IN => 28,
  WIDTH_OUT => WIDTH,
  FRAC_OUT => SLOPE_FRAC
)
port map(
  clk => clk,
  reset => '0',
  input => signed(stage2_out),
  output_threshold => (others => '0'),
  output => stage2_data
);

--------------------------------------------------------------------------------
-- delays to align outputs after FIR group delay
--------------------------------------------------------------------------------
stage1Delay:entity work.sdp_bram_delay
generic map(
  DELAY => 46,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(stage1_data),
  delayed => stage1_d
);

--sample_out <= signed(sample_d);
stage1 <= signed(stage1_d);
stage2 <= signed(stage2_data);

end architecture coregen;
