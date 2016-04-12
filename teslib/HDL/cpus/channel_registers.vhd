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
-- reserved										address bit 11
--
-- 2  downto 0  baseline.average_order
-- 4 						baseline.subtraction 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;
use work.functions.all;
use work.adc.all;
use work.dsptypes.all;
use work.registers.all;
use work.events.all;

-- expects s_clk = 2*reg_clk
entity channel_registers is
generic(
	CONFIG_BITS:integer:=8;
	CONFIG_STREAM_WIDTH:integer:=8;
	COEF_BITS:integer:=25;
	COEF_STREAM_WIDTH:integer:=32
);
port (
	-- reg_clk domain
  reg_clk:in std_logic;
  reg_reset:in std_logic;
  --!* register signals from/to channel CPU
  data:in registerdata_t;
  address:in registeraddress_t;
  write:in boolean; --Strobe
  value:out registerdata_t;
  
  axis_ready:out boolean;
  axis_done:out boolean;
  axis_error:out boolean;
  
  --sclk domain
  stream_clk:in std_logic;
  stream_reset:in std_logic;
  
	registers:out channel_registers_t;

  filter_config_data:out std_logic_vector(CONFIG_STREAM_WIDTH-1 downto 0);
  filter_config_valid:out boolean;
  filter_config_ready:in boolean;
  -- coefficients are 25 bits all fractional 
  -- the register uses bit 31 as AXI stream last
  filter_reload_data:out std_logic_vector(COEF_STREAM_WIDTH-1 downto 0); 
  filter_reload_valid:out boolean;
  filter_reload_ready:in boolean;
  filter_reload_last:out boolean;
  filter_reload_last_error:in boolean;
  
  differentiator_config_data:out std_logic_vector(CONFIG_STREAM_WIDTH-1 downto 0);
  differentiator_config_valid:out boolean;
  differentiator_config_ready:in boolean;
  differentiator_reload_data:out std_logic_vector(COEF_STREAM_WIDTH-1 downto 0);
  differentiator_reload_valid:out boolean;
  differentiator_reload_ready:in boolean;
  differentiator_reload_last:out boolean;
  differentiator_reload_last_error:in boolean
);
end entity channel_registers;
--
architecture RTL of channel_registers is

signal reg:channel_registers_t;
signal value_int:std_logic_vector(AXI_DATA_BITS-1 downto 0);

signal reg_data:AXI_data_array(11 downto 0);
type bit_array is array (natural range <>) of std_logic_vector(11 downto 0);
signal reg_bits:bit_array(AXI_DATA_BITS-1 downto 0);
signal filter_reload,differentiator_reload:boolean;
signal filter_config,differentiator_config:boolean;
signal filter_reload_axis_done:boolean;
signal filter_reload_axis_error:boolean;
signal filter_reload_axis_ready:boolean;
signal filter_config_axis_done:boolean;
signal filter_config_axis_ready:boolean;
signal differentiator_reload_axis_done:boolean;
signal differentiator_reload_axis_error:boolean;
signal differentiator_reload_axis_ready:boolean;
signal differentiator_config_axis_done:boolean;
signal differentiator_config_axis_ready:boolean;
signal filter_config_data_int:std_logic_vector(CONFIG_BITS-1 downto 0);
signal filter_reload_data_int:std_logic_vector(COEF_BITS-1 downto 0);
signal differentiator_reload_data_int:std_logic_vector(COEF_BITS-1 downto 0);
signal differentiator_config_data_int:std_logic_vector(CONFIG_BITS-1 downto 0);

--NOTE bits 16 to 19 are used as the bit address when the iodelay is read
--
begin 
value <= value_int;
registers <= reg;
filter_reload_data(COEF_BITS-1 downto 0) <= filter_reload_data_int;
filter_reload_data(COEF_STREAM_WIDTH-1 downto COEF_BITS) <= (others => '0');
filter_config_data(CONFIG_BITS-1 downto 0) <= filter_config_data_int;
filter_config_data(CONFIG_STREAM_WIDTH-1 downto CONFIG_BITS) <= (others => '0');

differentiator_reload_data(COEF_BITS-1 downto 0) 
	<= differentiator_reload_data_int;
differentiator_reload_data(COEF_STREAM_WIDTH-1 downto COEF_BITS) 
	<= (others => '0');
differentiator_config_data(CONFIG_BITS-1 downto 0) 
	<= differentiator_config_data_int;
differentiator_config_data(CONFIG_STREAM_WIDTH-1 downto CONFIG_BITS) 
	<= (others => '0');

regWrite:process(reg_clk) 
begin
if rising_edge(reg_clk) then
	if reg_reset='1' then
		reg.baseline.offset <= DEFAULT_BL_OFFSET;
		reg.baseline.subtraction <= DEFAULT_BL_SUBTRACTION;
		reg.baseline.timeconstant <= DEFAULT_BL_TIMECONSTANT;
		reg.baseline.threshold <= DEFAULT_BL_THRESHOLD;
		reg.baseline.count_threshold <= DEFAULT_BL_COUNT_THRESHOLD;
		reg.baseline.average_order <= DEFAULT_BL_AVERAGE_ORDER;
		reg.capture.max_peaks <= DEFAULT_MAX_PEAKS;
		reg.capture.constant_fraction <= DEFAULT_CONSTANT_FRACTION;
		reg.capture.pulse_threshold <= DEFAULT_PULSE_THRESHOLD;
		reg.capture.slope_threshold <= DEFAULT_SLOPE_THRESHOLD;
		reg.capture.slope_threshold <= DEFAULT_SLOPE_THRESHOLD;
		reg.capture.area_threshold <= DEFAULT_AREA_THRESHOLD;
		reg.capture.height <= DEFAULT_HEIGHT;
		reg.capture.threshold_rel2min <= DEFAULT_THRESHOLD_REL2MIN;
		reg.capture.height_rel2min <= DEFAULT_HEIGHT_REL2MIN;
		reg.capture.cfd_rel2min <= DEFAULT_CFD_REL2MIN;
		reg.capture.timing <= DEFAULT_TIMING;
		reg.capture.detection <= DEFAULT_DETECTION;
		reg.capture.trace0 <= DEFAULT_TRACE0;
		reg.capture.trace1 <= DEFAULT_TRACE1;
		reg.capture.delay <= DEFAULT_DELAY;
  else
    if write then
      if address(DELAY_ADDR_BIT)='1' then
        reg.capture.delay <= unsigned(data(DELAY_BITS-1 downto 0)); 
      end if;
      if address(CAPTURE_ADDR_BIT)='1' then
      	reg.capture.detection <= to_detection_d(data(1 downto 0));
      	reg.capture.timing <= to_timing_d(data(3 downto 2));
      	reg.capture.max_peaks <= unsigned(data(7 downto 4));
      	reg.capture.height <= to_height_d(data(9 downto 8));
      	reg.capture.trace0 <= to_trace_d(data(11 downto 10));
      	reg.capture.trace1 <= to_trace_d(data(13 downto 12));
      	reg.capture.cfd_rel2min <= to_boolean(data(14));
      	reg.capture.height_rel2min <= to_boolean(data(15));
      	reg.capture.threshold_rel2min <= to_boolean(data(16));
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
      end if;
      if address(AREA_THRESHOLD_ADDR_BIT)='1' then
      	reg.capture.area_threshold 
      		<= signed(data(AREA_BITS-1 downto 0)); 
      end if;
      if address(DELAY_ADDR_BIT)='1' then
      	reg.capture.delay <= unsigned(data(DELAY_BITS-1 downto 0)); 
      end if;
      if address(BL_OFFSET_ADDR_BIT)='1' then
        reg.baseline.offset <= data(ADC_BITS-1 downto 0); 
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
        reg.baseline.average_order 
        	<= to_integer(unsigned(data(2 downto 0))); 
        reg.baseline.subtraction <= to_boolean(data(4));
      end if;
      if address(FILTER_CONFIG_ADDR_BIT)='1' then
      	
      end if;
    end if;
  end if;
end if;
end process regWrite;

outputmux:process(address,filter_reload_axis_done,filter_reload_axis_error,
									filter_reload_axis_ready,differentiator_config_axis_done, 
									differentiator_config_axis_ready,
									differentiator_reload_axis_done, 
									differentiator_reload_axis_error, 
									differentiator_reload_axis_ready,filter_config_axis_done,
									filter_config_axis_ready)
begin
	if address(FILTER_RELOAD_ADDR_BIT)='1' then
		axis_done <= filter_reload_axis_done;
		axis_error <= filter_reload_axis_error;
		axis_ready <= filter_reload_axis_ready;
	elsif address(FILTER_CONFIG_ADDR_BIT)='1' then
		axis_done <= filter_config_axis_done;
		axis_error <= FALSE;
		axis_ready <= filter_config_axis_ready;
	elsif address(DIFFERENTIATOR_RELOAD_ADDR_BIT)='1' then
		axis_done <= differentiator_reload_axis_done;
		axis_error <= differentiator_reload_axis_error;
		axis_ready <= differentiator_reload_axis_ready;
	elsif address(DIFFERENTIATOR_CONFIG_ADDR_BIT)='1' then
		axis_done <= differentiator_config_axis_done;
		axis_error <= FALSE;
		axis_ready <= differentiator_config_axis_ready;
	else
		axis_done <= FALSE;
		axis_error <= FALSE;
		axis_ready <= FALSE;
	end if;	
end process outputmux;

filter_reload <= write and address(FILTER_RELOAD_ADDR_BIT)='1';
filterReload:entity work.register_axistream
generic map(
  DATA_BITS => COEF_BITS
)
port map(
  reg_clk => reg_clk,
  reg_reset => reg_reset,
  data => data(COEF_BITS-1 downto 0),
  write => filter_reload,
  reg_last => to_boolean(data(AXI_DATA_BITS-1)),
  axis_done => filter_reload_axis_done,
  axis_error => filter_reload_axis_error,
  axis_ready => filter_reload_axis_ready,
  stream_clk => stream_clk,
  stream_reset => stream_reset,
  last_error => filter_reload_last_error,
  stream => filter_reload_data_int,
  valid => filter_reload_valid,
  ready => filter_reload_ready,
  last => filter_reload_last
);

filter_config <= write and address(FILTER_CONFIG_ADDR_BIT)='1';
filterConfig:entity work.register_axistream
generic map(
  DATA_BITS => CONFIG_BITS
)
port map(
  reg_clk => reg_clk,
  reg_reset => reg_reset,
  data => data(CONFIG_BITS-1 downto 0),
  write => filter_config,
  reg_last => to_boolean(data(AXI_DATA_BITS-1)),
  axis_done => filter_config_axis_done,
  axis_error => open,
  axis_ready => filter_config_axis_ready,
  stream_clk => stream_clk,
  stream_reset => stream_reset,
  last_error => FALSE,
  stream => filter_config_data_int,
  valid => filter_config_valid,
  ready => filter_config_ready,
  last => open
);

differentiator_reload <= write and address(DIFFERENTIATOR_RELOAD_ADDR_BIT)='1';
differetiatorReload:entity work.register_axistream
generic map(
  DATA_BITS => COEF_BITS
)
port map(
  reg_clk => reg_clk,
  reg_reset => reg_reset,
  data => data(COEF_BITS-1 downto 0),
  write => differentiator_reload,
  reg_last => to_boolean(data(AXI_DATA_BITS-1)),
  axis_done => differentiator_reload_axis_done,
  axis_error => differentiator_reload_axis_error,
  axis_ready => differentiator_reload_axis_ready,
  stream_clk => stream_clk,
  stream_reset => stream_reset,
  last_error => differentiator_reload_last_error,
  stream => differentiator_reload_data_int,
  valid => differentiator_reload_valid,
  ready => differentiator_reload_ready,
  last => differentiator_reload_last
);

differentiator_config <= write and address(DIFFERENTIATOR_CONFIG_ADDR_BIT)='1';
differntiatorConfig:entity work.register_axistream
generic map(
  DATA_BITS => CONFIG_BITS
)
port map(
  reg_clk => reg_clk,
  reg_reset => reg_reset,
  data => data(CONFIG_BITS-1 downto 0),
  write => differentiator_config,
  reg_last => FALSE,
  axis_done => differentiator_config_axis_done,
  axis_error => open,
  axis_ready => differentiator_config_axis_ready,
  stream_clk => stream_clk,
  stream_reset => stream_reset,
  last_error => FALSE,
  stream => differentiator_config_data_int,
  valid => differentiator_config_valid,
  ready => differentiator_config_ready,
  last => open
);

-- create register array for selector
reg_data(CAPTURE_ADDR_BIT) <= capture_register(reg);
reg_data(PULSE_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.pulse_threshold,AXI_DATA_BITS));
reg_data(SLOPE_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.slope_threshold,AXI_DATA_BITS));
reg_data(CONSTANT_FRACTION_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.constant_fraction,AXI_DATA_BITS));
reg_data(AREA_THRESHOLD_ADDR_BIT)
   <= to_std_logic(resize(reg.capture.area_threshold,AXI_DATA_BITS));
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
reg_data(BL_FLAGS_ADDR_BIT) <= baseline_flags(reg);
reg_data(RESERVED_ADDR_BIT) <= (others => '0');

selectorGen:for b in 0 to AXI_DATA_BITS-1 generate
	--variable reg_bits:std_logic_vector(11 downto 0);
begin
	
	bitGen:for reg in 0 to 11 generate
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

end architecture RTL;
