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

-- stage1 output w=48 f=28
-- stage2 output w=48 f=28
entity two_stage_FIR is
generic(
	STAGE1_IN_BITS:integer:=18;
	INTERSTAGE_SHIFT:integer:=25;
	STAGE1_OUT_WIDTH:integer:=48;
	STAGE2_OUT_WIDTH:integer:=48
);
port(
  clk:in std_logic;
  sample:in signed(STAGE1_IN_BITS-1 downto 0);
  stage1_config_data:in std_logic_vector(7 downto 0);
  stage1_config_valid:in boolean;
  stage1_config_ready:out boolean;
  stage1_reload_data:in std_logic_vector(31 downto 0);
  stage1_reload_valid:in boolean;
  stage1_reload_ready:out boolean;
  stage1_reload_last:in boolean;
  stage2_config_data:in std_logic_vector(7 downto 0);
  stage2_config_valid:in boolean;
  stage2_config_ready:out boolean;
  stage2_reload_data:in std_logic_vector(31 downto 0);
  stage2_reload_valid:in boolean;
  stage2_reload_ready:out boolean;
  stage2_reload_last:in boolean;
  -- output signals
  stage1:out std_logic_vector(STAGE1_OUT_WIDTH-1 downto 0);
  stage2:out std_logic_vector(STAGE2_OUT_WIDTH-1 downto 0)
  
);
end entity two_stage_FIR;

architecture order_23 of two_stage_FIR is
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

begin
	
stage1_config_ready <= to_boolean(stage1_config_ready_int);
stage1_reload_ready <= to_boolean(stage1_reload_ready_int);
stage2_config_ready <= to_boolean(stage2_config_ready_int);
stage2_reload_ready <= to_boolean(stage2_reload_ready_int);

--------------------------------------------------------------------------------
-- FIR filter stages with reloadable coefficients (FIR compiler 6.3)
--------------------------------------------------------------------------------
-- stage1 internal output w=45 f=25
stage1FIRfilter:stage1_FIR_23
port map(
  aclk => clk,
  s_axis_data_tvalid => '1',
  s_axis_data_tready => open,
  s_axis_data_tdata => to_std_logic(resize(sample,24)),
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

--------------------------------------------------------------------------------
-- shift to correct fixed precision and register the outputs of each FIR stage
--------------------------------------------------------------------------------
firOutputReg:process (clk) is
begin
if rising_edge(clk) then
	-- stage2 input is w=18 f=3 but the port is rounded up to nearest byte
  stage2_data <= to_std_logic(
    resize(shift_right(signed(stage1_out),INTERSTAGE_SHIFT),24)
  );
end if;
end process firOutputReg;

-- stage2 internal output w=48 f=28
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
-- delays to align outputs after FIR group delay
--------------------------------------------------------------------------------

stage1Delay:entity work.SREG_delay
generic map(
  DEPTH => 64,
  DATA_BITS => STAGE1_OUT_WIDTH
)
port map(
  clk     => clk,
  data_in => stage1_out(STAGE1_OUT_WIDTH-1 downto 0),
  delay   => 42,
  delayed => stage1
);

stage2Reg:process (clk) is
begin
	if rising_edge(clk) then
		stage2 <=stage2_out;
	end if;
end process stage2Reg;


end architecture order_23;
