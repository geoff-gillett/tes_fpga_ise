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

-- address bit 23 filter config
-- 
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
entity channel_registers2 is
generic(
	CHANNEL:integer:=0;
  FILTER_COEF_WIDTH:natural:=23;
  SLOPE_COEF_WIDTH:natural:=25;
  BASELINE_COEF_WIDTH:natural:=25
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
  
	registers:out channel_registers_t;

  filter_config:out fir_control_in_t;
  filter_events:in fir_control_out_t;
  slope_config:out fir_control_in_t;
  slope_events:in fir_control_out_t;
  baseline_config:out fir_control_in_t;
  baseline_events:in fir_control_out_t
);
end entity channel_registers2;
--
architecture RTL of channel_registers2 is

signal reg:channel_registers_t;

signal reg_data:AXI_data_array(11 downto 0);
type bit_array is array (natural range <>) of std_logic_vector(11 downto 0);
signal reg_bits:bit_array(AXI_DATA_BITS-1 downto 0);

--signal resetn:std_logic;
signal value_int:register_data_t;
signal last_mising:std_logic;
signal reload_done:std_logic;
signal coef_data:std_logic_vector(AXI_DATA_BITS-1 downto 0);
signal fir_write:std_logic;
signal last_unexpected:std_logic;

--NOTE bits 16 to 19 are used as the bit address when the iodelay is read
-- FIXME huh???
begin 
registers <= reg;

regWrite:process(clk) 
begin
if rising_edge(clk) then
  --FIXME these resets needed? use assignment at definition
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
--		reg.capture.trace0 <= DEFAULT_TRACE0; --FIXME remove
--		reg.capture.trace1 <= DEFAULT_TRACE1; --FIXME remove
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
--      	reg.capture.trace0 <= to_trace_d(data(11 downto 10)); --FIXME remove
--      	reg.capture.trace1 <= to_trace_d(data(13 downto 12)); --FIXME remove
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
        reg.baseline.offset <= signed(data(DSP_BITS-1 downto 0)); 
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
      if address(FIR_RELOAD_ADDR_BIT)='1' then
        coef_data <= data;
      else 
        coef_data <= (others => '0');
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
reg_data(CONSTANT_FRACTION_ADDR_BIT)(AXI_DATA_BITS-1)
   <= to_std_logic(reg.capture.cfd_rel2min);
reg_data(CONSTANT_FRACTION_ADDR_BIT)(AXI_DATA_BITS-2 downto CFD_BITS-1)
   <= (others => '0');
reg_data(CONSTANT_FRACTION_ADDR_BIT)(CFD_BITS-2 downto 0)      
   <= to_std_logic(reg.capture.constant_fraction);
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

FIRreload:entity work.fir_reload
generic map(
  FILTER_COEF_WIDTH => FILTER_COEF_WIDTH,
  SLOPE_COEF_WIDTH => SLOPE_COEF_WIDTH,
  BASELINE_COEF_WIDTH => BASELINE_COEF_WIDTH
)
port map(
  clk => clk,
  reset => reset,
  write => fir_write,
  data => coef_data,
  last_missing => last_mising,
  last_unexpected => last_unexpected,
  done => reload_done,
  filter_config => filter_config,
  filter_events => filter_events,
  slope_config => slope_config,
  slope_events => slope_events,
  baseline_config => baseline_config,
  baseline_events => baseline_events
);
  
valueReg:process (clk) is
variable val:std_logic_vector(AXI_DATA_BITS-1 downto 0):=(others => '0');
begin
	if rising_edge(clk) then
    val(0):=reload_done;
    val(1):=last_mising;
    val(2):=last_unexpected;
	  if address(FIR_RELOAD_ADDR_BIT)='1' then
	    fir_write <= write;
	    if write='1' or fir_write='1' then
	      value <= (others => '0');
	    else
  	    value <= val;
  	  end if;
	  else
      fir_write <= '0';
		  value <= value_int;
		end if;
	end if;
end process valueReg;

--resetn <= not reset;
end architecture RTL;
