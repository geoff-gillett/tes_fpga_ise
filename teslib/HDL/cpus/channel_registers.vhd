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
-- ADDRESS MAP (one hot)
-- capture register 					address bit 0
--
-- 1  downto 0  detection
-- 3  downto 2  timing
-- 7  downto 4  max_peaks
-- 9  downto 8  height
-- 11 downto 10 trace0
-- 13 downto 12 trace1
-- 14           cfd_rel2min
-- 15           height_rel2min
-- 16           threshold_rel2min
--
-- pulse_threshold 						address bit 1
-- slope_threshold 						address bit 2
-- constant_fraction 					address bit 3
-- pulse_area_threshold				address bit 4
-- delay											address bit 5
-- baseline.offset   					address bit 6				
-- baseline.timeconstant  		address bit 7				
-- baseline.threshold		  		address bit 8
-- baseline.count_threshold		address bit 9
-- baseline flags							address bit 10
-- 	2  downto 0  baseline.average_order
-- 	4 						baseline.subtraction 
-- input select								address bit 11
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library dsp;
use dsp.types.all;

use work.types.all;
--use work.functions.all;
use work.registers.all;
--use work.events.all;

-- expects s_clk = 2*reg_clk
entity channel_registers is
generic(
	CHANNEL:integer:=0;
	CONFIG_BITS:integer:=8;
	CONFIG_WIDTH:integer:=8;
	--bits in a filter coefficient
	COEF_BITS:integer:=25; 
	--width in the filter reload axi-stream
	COEF_WIDTH:integer:=32
);
port (
	-- reg_clk domain
  clk:in std_logic;
  reset:in std_logic;
  --!* register signals from/to channel CPU
  data:in register_data_t;
  address:in register_address_t;
  write:in std_logic; --Strobe
  value:out register_data_t;
  
  axis_done:out std_logic;
  axis_error:out std_logic;
  
	registers:out channel_registers_t;

  filter_config:out fir_control_in_t;
  filter_events:in fir_control_out_t;
  slope_config:out fir_control_in_t;
  slope_events:in fir_control_out_t;
  baseline_config:out fir_control_in_t;
  baseline_events:in fir_control_out_t
);
end entity channel_registers;
--
architecture RTL of channel_registers is

signal reg:channel_registers_t;

signal reg_data:AXI_data_array(11 downto 0);
type bit_array is array (natural range <>) of std_logic_vector(11 downto 0);
signal reg_bits:bit_array(AXI_DATA_BITS-1 downto 0);

signal filter_data_int:std_logic_vector(COEF_BITS downto 0);
signal dif_data_int:std_logic_vector(COEF_BITS downto 0);
signal filter_error_reg:std_logic;
signal dif_error_reg:std_logic;
signal filter_go,dif_go:std_logic;
signal filter_config_go,dif_config_go:std_logic;
signal filter_done,dif_done:std_logic;
signal resetn:std_logic;
signal filter_config_done,dif_config_done:std_logic;
signal value_int:register_data_t;

--NOTE bits 16 to 19 are used as the bit address when the iodelay is read
-- FIXME huh???
begin 
-- value is read by the cpu in the io_clk domain
-- TODO implement baseline FIR controls
registers <= reg;
baseline_config.config_data <= (others => '0');
baseline_config.config_valid <= '0';
baseline_config.reload_data <= (others => '0');
baseline_config.reload_last <= '0';
baseline_config.reload_valid <= '0';

regWrite:process(clk) 
begin
if rising_edge(clk) then
	if reset='1' then
		reg.baseline.offset <= DEFAULT_BL_OFFSET;
		reg.baseline.subtraction <= DEFAULT_BL_SUBTRACTION;
		reg.baseline.timeconstant <= DEFAULT_BL_TIMECONSTANT;
		reg.baseline.threshold <= DEFAULT_BL_THRESHOLD;
		reg.baseline.count_threshold <= DEFAULT_BL_COUNT_THRESHOLD;
		reg.capture.max_peaks <= DEFAULT_MAX_PEAKS;
		reg.capture.constant_fraction <= DEFAULT_CONSTANT_FRACTION;
		reg.capture.pulse_threshold <= DEFAULT_PULSE_THRESHOLD;
		reg.capture.slope_threshold <= DEFAULT_SLOPE_THRESHOLD;
		reg.capture.slope_threshold <= DEFAULT_SLOPE_THRESHOLD;
		reg.capture.area_threshold <= DEFAULT_AREA_THRESHOLD;
		reg.capture.height <= DEFAULT_HEIGHT;
		--reg.capture.threshold_rel2min <= DEFAULT_THRESHOLD_REL2MIN;
		reg.capture.timing <= DEFAULT_TIMING;
		reg.capture.detection <= DEFAULT_DETECTION;
		reg.capture.trace0 <= DEFAULT_TRACE0;
		reg.capture.trace1 <= DEFAULT_TRACE1;
		reg.capture.delay <= DEFAULT_DELAY;
		reg.capture.adc_select <= (CHANNEL => '1',others => '0');
  else
    if write='1' then
      if address(DELAY_ADDR_BIT)='1' then
        reg.capture.delay <= unsigned(data(DELAY_BITS-1 downto 0)); 
      end if;
      if address(CAPTURE_ADDR_BIT)='1' then
      	--FIXME make this a function
      	reg.capture.detection <= to_detection_d(data(1 downto 0));
      	reg.capture.timing <= to_timing_d(data(3 downto 2));
      	reg.capture.max_peaks <= unsigned(data(7 downto 4));
      	reg.capture.height <= to_height_d(data(9 downto 8));
      	reg.capture.trace0 <= to_trace_d(data(11 downto 10));
      	reg.capture.trace1 <= to_trace_d(data(13 downto 12));
      	--reg.capture.threshold_rel2min <= to_boolean(data(16));
      end if;
      if address(PULSE_THRESHOLD_ADDR_BIT)='1' then
        reg.capture.pulse_threshold 
        	<= unsigned(data(DSP_BITS-2 downto 0)); 
      end if;
      if address(SLOPE_THRESHOLD_ADDR_BIT)='1' then
        reg.capture.slope_threshold 
        	<= unsigned(data(DSP_BITS-2 downto 0)); 
      end if;
      if address(CONSTANT_FRACTION_ADDR_BIT)='1' then
      	reg.capture.constant_fraction
          <= unsigned(data(CFD_BITS-2 downto 0));
        reg.capture.cfd_rel2min <= data(AXI_DATA_BITS-1)='1'; 
      end if;
      if address(AREA_THRESHOLD_ADDR_BIT)='1' then
      	reg.capture.area_threshold 
      		<= unsigned(data(AREA_BITS-2 downto 0)); 
      end if;
      if address(DELAY_ADDR_BIT)='1' then
      	reg.capture.delay <= unsigned(data(DELAY_BITS-1 downto 0)); 
      end if;
      if address(BL_OFFSET_ADDR_BIT)='1' then
        reg.baseline.offset <= unsigned(data(DSP_BITS-2 downto 0)); 
      end if;
      if address(BL_TIMECONSTANT_ADDR_BIT)='1' then
        reg.baseline.timeconstant 
        	<= unsigned(data(BASELINE_TIMECONSTANT_BITS-1 downto 0)); 
      end if;
      if address(BL_THRESHOLD_ADDR_BIT)='1' then
        reg.baseline.threshold 
        	<= unsigned(data(BASELINE_BITS-2 downto 0)); 
      end if;
      if address(BL_COUNT_THRESHOLD_ADDR_BIT)='1' then
        reg.baseline.count_threshold 
        	<= unsigned(data(BASELINE_COUNTER_BITS-1 downto 0)); 
      end if;
      if address(BL_FLAGS_ADDR_BIT)='1' then
        reg.baseline.new_only <= to_boolean(data(0));
        reg.baseline.subtraction <= to_boolean(data(1));
      end if;
      if address(INPUT_SEL_ADDR_BIT)='1' then
      	reg.capture.adc_select <= data(ADC_CHIPS*ADC_CHIP_CHANNELS-1 downto 0);
      	reg.capture.invert <= data(ADC_CHIPS*ADC_CHIP_CHANNELS)='1';
      end if;
      if address(FILTER_CONFIG_ADDR_BIT)='1' then
      	--TODO implement
      end if;
    end if;
  end if;
end if;
end process regWrite;

-- register read
-- create register array for selector
reg_data(CAPTURE_ADDR_BIT) <= capture_register(reg.capture);
reg_data(PULSE_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.pulse_threshold,AXI_DATA_BITS));
reg_data(SLOPE_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.slope_threshold,AXI_DATA_BITS));
reg_data(CONSTANT_FRACTION_ADDR_BIT)
   <= to_std_logic(reg.capture.cfd_rel2min) & 
      to_std_logic(resize(reg.capture.constant_fraction,AXI_DATA_BITS-1));
reg_data(AREA_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.area_threshold,AXI_DATA_BITS));
reg_data(DELAY_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.delay,AXI_DATA_BITS));
reg_data(BL_OFFSET_ADDR_BIT)
   <= to_std_logic(resize(unsigned(reg.baseline.offset),AXI_DATA_BITS));
reg_data(BL_TIMECONSTANT_ADDR_BIT)
   <= to_std_logic(resize(reg.baseline.timeconstant,AXI_DATA_BITS));
reg_data(BL_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.baseline.threshold,AXI_DATA_BITS));
reg_data(BL_COUNT_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.baseline.count_threshold,AXI_DATA_BITS));
reg_data(BL_FLAGS_ADDR_BIT) <= baseline_flags(reg.baseline);
reg_data(INPUT_SEL_ADDR_BIT) <= resize(to_std_logic(reg.capture.invert) & 
			 														reg.capture.adc_select,AXI_DATA_BITS
		 														);

selGen:for b in AXI_DATA_BITS-1 downto 0 generate
begin
	bitGen:for reg in 11 downto 0 generate
	begin
		reg_bits(b)(reg) <= reg_data(reg)(b);
	end generate;
	selector:entity work.select_1of12
  port map(
    input => reg_bits(b),
    sel => address(11 downto 0),
    output => value_int(b)
  );
end generate;

valueReg:process (clk) is
begin
	if rising_edge(clk) then
		value <= value_int;
	end if;
end process valueReg;

resetn <= not reset;
erroReg:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			filter_error_reg <= '0';
			dif_error_reg <= '0';
		else
			if filter_go='1' then
				filter_error_reg <= '0';
			elsif filter_events.last_missing='1' or 
			      filter_events.last_unexpected='1' then
				filter_error_reg <= '1';
			end if; 
			if dif_go='1' then
				dif_error_reg <= '0';
			elsif slope_events.last_missing='1' or 
			      slope_events.last_unexpected='1' then
				dif_error_reg <= '1';
			end if;
		end if;
	end if;
end process erroReg;

outputMux:process(clk)
begin
	if rising_edge(clk) then
    if address(FILTER_RELOAD_ADDR_BIT)='1' then
      axis_error <= filter_error_reg;
      axis_done <= filter_done;
    elsif address(DIFFERENTIATOR_RELOAD_ADDR_BIT)='1' then
      axis_error <= dif_error_reg;
      axis_done <= dif_done;
    elsif address(FILTER_CONFIG_ADDR_BIT)='1' then
      axis_error <= '0';
      axis_done <= filter_config_done;
    elsif address(DIFFERENTIATOR_CONFIG_ADDR_BIT)='1' then
      axis_error <= '0';
      axis_done <= dif_config_done;
    else
      axis_error <= '0';
      axis_done <= '0';
    end if;
	end if;
end process outputMux;

filter_go <= write and address(FILTER_RELOAD_ADDR_BIT);
filterReload:entity work.axi_wr_chan
generic map(WIDTH => COEF_BITS+1)
port map(
  clk => clk,
  resetn => resetn,
  reg_value => data(COEF_BITS downto 0),
  go => filter_go,
  done => filter_done,
  axi_data => filter_data_int,
  axi_valid => filter_config.reload_valid,
  axi_ready => filter_events.reload_ready
);
filter_config.reload_data 
  <= resize(filter_data_int(COEF_BITS-1 downto 0), COEF_WIDTH);
filter_config.reload_last <= filter_data_int(COEF_BITS);

filter_config_go <= write and address(FILTER_CONFIG_ADDR_BIT);
filterConfig:entity work.axi_wr_chan
generic map(WIDTH => CONFIG_BITS)
port map(
  clk => clk,
  resetn => resetn,
  reg_value => data(CONFIG_BITS-1 downto 0),
  go => filter_config_go,
  done => filter_config_done,
  axi_data => filter_config.config_data,
  axi_valid => filter_config.config_valid,
  axi_ready => filter_events.config_ready
);

dif_go <= write and address(DIFFERENTIATOR_RELOAD_ADDR_BIT);
difReload:entity work.axi_wr_chan
generic map(WIDTH => COEF_BITS+1)
port map(
  clk => clk,
  resetn => resetn,
  reg_value => data(COEF_BITS downto 0),
  go => dif_go,
  done => dif_done,
  axi_data => dif_data_int,
  axi_valid => slope_config.reload_valid,
  axi_ready => slope_events.reload_ready
);
slope_config.reload_data 
	<= resize(dif_data_int(COEF_BITS-1 downto 0), COEF_WIDTH);
slope_config.reload_last <= dif_data_int(COEF_BITS);

dif_config_go <= write and address(DIFFERENTIATOR_CONFIG_ADDR_BIT);
difConfig:entity work.axi_wr_chan
generic map(WIDTH => CONFIG_BITS)
port map(
  clk => clk,
  resetn => resetn,
  reg_value => data(CONFIG_BITS-1 downto 0),
  go => dif_config_go,
  done => dif_config_done,
  axi_data => slope_config.config_data,
  axi_valid => slope_config.config_valid,
  axi_ready => slope_events.config_ready
);
end architecture RTL;
