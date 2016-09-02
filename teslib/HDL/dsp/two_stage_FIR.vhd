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

use work.types.all;
use work.functions.all;

-- stage1 output w=48 f=28
-- stage2 output w=48 f=28
entity two_stage_FIR is
generic(
	WIDTH:integer:=18
);
port(
  clk:in std_logic;
  sample_in:in signed(WIDTH-1 downto 0);
  stage1_config_data:in std_logic_vector(7 downto 0);
  stage1_config_valid:in std_logic;
  stage1_config_ready:out std_logic;
  stage1_reload_data:in std_logic_vector(31 downto 0);
  stage1_reload_valid:in std_logic;
  stage1_reload_ready:out std_logic;
  stage1_reload_last:in std_logic;
	stage1_reload_last_missing:out std_logic;
 	stage1_reload_last_unexpected:out std_logic;
  stage2_config_data:in std_logic_vector(7 downto 0);
  stage2_config_valid:in std_logic;
  stage2_config_ready:out std_logic;
  stage2_reload_data:in std_logic_vector(31 downto 0);
  stage2_reload_valid:in std_logic;
  stage2_reload_ready:out std_logic;
  stage2_reload_last:in std_logic;
	stage2_reload_last_missing:out std_logic;
 	stage2_reload_last_unexpected:out std_logic;
  -- output signals
  sample_out:out signed(WIDTH-1 downto 0);
  stage1:out signed(WIDTH-1 downto 0);
  stage2:out signed(WIDTH-1 downto 0)
  
);
end entity two_stage_FIR;

architecture coregen of two_stage_FIR is
--IP cores FIR compiler 6.3
component stage1_fir_23
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
signal stage1_d,stage1_data,stage2_data:std_logic_vector(WIDTH-1 downto 0);
signal sample_d:std_logic_vector(WIDTH-1 downto 0);

begin
	
--------------------------------------------------------------------------------
-- FIR filter stages with reloadable coefficients (FIR compiler 6.3)
--------------------------------------------------------------------------------
-- stage1 internal output w=45 f=25
stage1_in <= to_std_logic(resize(sample_in,24));
stage1FIRfilter:stage1_FIR_23
port map(
  aclk => clk,
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => stage1_in,
  s_axis_config_tvalid => stage1_config_valid,
  s_axis_config_tready => stage1_config_ready,
  s_axis_config_tdata => stage1_config_data,
  s_axis_reload_tvalid => stage1_reload_valid,
  s_axis_reload_tready => stage1_reload_ready,
  s_axis_reload_tlast => stage1_reload_last,
  s_axis_reload_tdata => stage1_reload_data,
  m_axis_data_tvalid => open,
  m_axis_data_tdata => stage1_out,
  event_s_reload_tlast_missing => stage1_reload_last_missing,
  event_s_reload_tlast_unexpected => stage1_reload_last_unexpected
);

stage1Round:entity work.saturate_round
generic map(
  WIDTH_IN => 48,
  FRAC_IN => 28,
  WIDTH_OUT => 18,
  FRAC_OUT => 3
)
port map(
  clk => clk,
  reset => '0',
  input => stage1_out,
  output => stage1_data
);

stage2_in <= std_logic_vector(resize(signed(stage1_data),24));
stage2FIRfilter:stage2_FIR_23
port map(
  aclk => clk,
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => stage2_in,
  s_axis_config_tvalid => stage2_config_valid,
  s_axis_config_tready => stage2_config_ready,
  s_axis_config_tdata => stage2_config_data,
  s_axis_reload_tvalid => stage2_reload_valid,
  s_axis_reload_tready => stage2_reload_ready,
  s_axis_reload_tlast => stage2_reload_last,
  s_axis_reload_tdata => stage2_reload_data,
  m_axis_data_tvalid => open,
  m_axis_data_tdata => stage2_out,
  event_s_reload_tlast_missing => stage2_reload_last_missing,
  event_s_reload_tlast_unexpected => stage2_reload_last_unexpected
);

stage2Round:entity work.saturate_round
generic map(
  WIDTH_IN => 48,
  FRAC_IN => 28,
  WIDTH_OUT => 18,
  FRAC_OUT => 8
)
port map(
  clk => clk,
  reset => '0',
  input => stage2_out,
  output => stage2_data
);

--------------------------------------------------------------------------------
-- delays to align outputs after FIR group delay
--------------------------------------------------------------------------------

sampleDelay:entity work.sdp_bram_delay
generic map(
  DELAY => 94,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => std_logic_vector(sample_in),
  delayed => sample_d
);

stage1Delay:entity work.sdp_bram_delay
generic map(
  DELAY => 47,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => stage1_data,
  delayed => stage1_d
);

sample_out <= signed(sample_d);
stage1 <= signed(stage1_d);
stage2 <= signed(stage2_data);

end architecture coregen;
