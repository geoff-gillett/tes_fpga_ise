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

--NOTE to change precision need to reconfigure cores
entity FIR_SYM141_ASYM23_OUT16_3 is
generic(
	WIDTH:integer:=16;
	FRAC:natural:=3;
	SLOPE_FRAC:natural:=8
);
port(
  clk:in std_logic;
  resetn:in std_logic;
  sample_in:in signed(WIDTH-1 downto 0);
  stage1_config:in fir_control_in_t;
  stage1_events:out fir_control_out_t;
  stage2_config:in fir_control_in_t;
  stage2_events:out fir_control_out_t;

  stage1:out signed(WIDTH-1 downto 0);
  stage2:out signed(WIDTH-1 downto 0)
);
end entity FIR_SYM141_ASYM23_OUT16_3;

architecture coregen of FIR_SYM141_ASYM23_OUT16_3 is
  
--IP cores FIR compiler 6.3

component FIR_SYM141_C24_23_O25_3_RCE
port (
  aclk:in std_logic;
  aresetn:in std_logic;
  s_axis_data_tvalid:in std_logic;
  s_axis_data_tready:out std_logic;
  s_axis_data_tdata:in std_logic_vector(15 downto 0);
  s_axis_config_tvalid:in std_logic;
  s_axis_config_tready:out std_logic;
  s_axis_config_tdata:in std_logic_vector(7 downto 0);
  s_axis_reload_tvalid:in std_logic;
  s_axis_reload_tready:out std_logic;
  s_axis_reload_tlast:in std_logic;
  s_axis_reload_tdata:in std_logic_vector(23 downto 0);
  m_axis_data_tvalid:out std_logic;
  m_axis_data_tdata:out std_logic_vector(31 downto 0);
  event_s_reload_tlast_missing:out std_logic;
  event_s_reload_tlast_unexpected:out std_logic
);
end component;

component FIR_ASYM23_C25_28_O23_8_RCE
  port (
    aresetn:in std_logic;
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
    m_axis_data_tdata:out std_logic_vector(23 downto 0);
    event_s_reload_tlast_missing:out std_logic;
    event_s_reload_tlast_unexpected:out std_logic
  );
end component;

constant GUARD_BITS:natural:=5; --guard bits for saturation check
signal stage1_in:std_logic_vector(15 downto 0);
signal stage2_in:std_logic_vector(15 downto 0);
signal stage1_out:std_logic_vector(31 downto 0);
signal stage2_out:std_logic_vector(23 downto 0);
signal stage1_d:std_logic_vector(WIDTH-1 downto 0);
signal stage2_data:std_logic_vector(WIDTH-1 downto 0);
signal stage1_valid:std_logic;
signal guard1,guard2:std_logic_vector(GUARD_BITS-1 downto 0);
signal sat1,sat2:boolean;

begin
	
--------------------------------------------------------------------------------
-- FIR filter stages with reloadable coefficients (FIR compiler 6.3)
--------------------------------------------------------------------------------
stage1_in <= to_std_logic(sample_in);

--24.23 bit coefficients
stage1FIRfilter:FIR_SYM141_C24_23_O25_3_RCE
port map (
  aclk => clk,
  aresetn => resetn,
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
  m_axis_data_tdata => stage1_out,
  m_axis_data_tvalid => stage1_valid,
  event_s_reload_tlast_missing => stage1_events.last_missing,
  event_s_reload_tlast_unexpected => stage1_events.last_unexpected
);

guard1 <= stage1_out(WIDTH+GUARD_BITS-2 downto WIDTH-1);
sat1 <= unaryAnd(guard1) xnor unaryAnd(not guard1);
stage1sat:process (clk) is
begin
  if rising_edge(clk) then
    if resetn = '0' then
      stage2_in <= (others => '0');
    else
      if sat1 then
        stage2_in <= (
          WIDTH-1 => stage1_out(24), others => (not stage1_out(24))
        );
      else
        stage2_in <= resize(signed(stage1_out),WIDTH);
      end if;
    end if;
  end if;
end process stage1sat;


--stage2_in <= to_std_logic(stage1_data);
--25.28 bit coefficients
stage2FIRfilter:FIR_ASYM23_C25_28_O23_8_RCE
port map(
  aclk => clk,
  aresetn => resetn,
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

guard2 <= stage2_out(WIDTH+GUARD_BITS-2 downto WIDTH-1);
sat2 <= unaryAnd(guard2) xnor unaryAnd(not guard2);
stage2sat:process (clk) is
begin
  if rising_edge(clk) then
    if resetn = '0' then
      stage2_data <= (others => '0');
    else
      if sat2 then
        stage2_data <= (
          WIDTH-1 => stage2_out(22), others => (not stage2_out(22))
        );
      else
        stage2_data <= resize(signed(stage2_out),WIDTH);
      end if;
    end if;
  end if;
end process stage2sat;

--------------------------------------------------------------------------------
-- delays to align outputs after FIR group delay
--------------------------------------------------------------------------------
stage1Delay:entity work.sdp_bram_delay
generic map(
  DELAY => 37,
  WIDTH => WIDTH
)
port map(
  clk => clk,
  input => stage2_in,
  delayed => stage1_d
);

--sample_out <= signed(sample_d);
stage1 <= signed(stage1_d);
stage2 <= signed(stage2_data);

end architecture coregen;
