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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;
use work.functions.all;
use work.adc.all;
use work.registers.all;

entity global_registers is
generic(
  HDL_VERSION:register_data_t:=to_std_logic(66,REGISTER_DATA_BITS);
  MIN_TICK_PERIOD:integer:=MIN_TICK_PERIOD;
  MIN_MTU:integer:=64
);
port (
  clk:in std_logic;
  reset:in std_logic;
  
  --mmcm_locked:std_logic;
  
  -- register signals from/to channel CPU
  data:in register_data_t;
  address:in register_address_t;
	value:out register_data_t;
  write:in boolean; --Strobe
  --registers
  registers:out global_registers_t
);
end entity global_registers;
--------------------------------------------------------------------------------
-- All register addresses are one-hot
-- NOTE relies on CPU to do address validation
--------------------------------------------------------------------------------
architecture RTL of global_registers is

signal address_reg:register_address_t;
signal data_reg,value_int:register_data_t;
signal reg:global_registers_t;
signal reg_data:AXI_data_array(11 downto 0);
type bit_array is array (natural range <>) of std_logic_vector(11 downto 0);
signal reg_bits:bit_array(AXI_DATA_BITS-1 downto 0);

begin 
registers <= reg;
	
regwrite:process(clk)
begin
	if rising_edge(clk) then
		--FIXME replace reset with init values
		if reset = '1' then
			value <= (others => '-');
			address_reg <= (others => '0');
			data_reg <= (others => '0');
			reg.adc_enable <= (others => '0');
			reg.channel_enable <= (others => '0');
			reg.iodelay_control <= (others => '0');
			reg.mtu <= DEFAULT_MTU;
			reg.tick_period <= DEFAULT_TICK_PERIOD;
			reg.tick_latency <= DEFAULT_TICK_LATENCY;
			reg.mca.bin_n <= DEFAULT_MCA_BIN_N;
			reg.mca.channel <= (others => '0');
			reg.mca.last_bin <= DEFAULT_MCA_LAST_BIN;
			reg.mca.ticks <= DEFAULT_MCA_TICKS;
			reg.mca.trigger <= DEFAULT_MCA_TRIGGER;
			reg.mca.value <= DEFAULT_MCA_VALUE;
			reg.mca.lowest_value <= DEFAULT_MCA_LOWEST_VALUE;
			reg.FMC108_internal_clk <= TRUE;
			reg.VCO_power <= TRUE;
		else
			address_reg <= address;
			data_reg <= data;
			value <= value_int;
			if write then
				if address_reg(MCA_CONTROL_REGISTER_ADDR_BIT)='1' then
					reg.mca.value <= to_mca_value_d(data_reg(3 downto 0));
					reg.mca.trigger <= to_mca_trigger_d(data_reg(7 downto 4));
					reg.mca.channel <= unsigned(data_reg(10 downto 8));
					reg.mca.bin_n <= unsigned(data_reg(15 downto 11));
					reg.mca.last_bin <= unsigned(data_reg(29 downto 16));
				end if;
				if address_reg(MCA_LOWEST_VALUE_ADDR_BIT)='1' then
					reg.mca.lowest_value <= signed(data_reg(MCA_VALUE_BITS-1 downto 0));
				end if;
				if address_reg(MCA_TICKS_ADDR_BIT)='1' then
					reg.mca.ticks <= unsigned(data_reg(MCA_TICKCOUNT_BITS-1 downto 0));
				end if;
				if address_reg(MTU_ADDR_BIT)='1' then
					if unsigned(data_reg(MTU_BITS-1 downto 0)) < MIN_MTU then
						reg.mtu <= to_unsigned(MIN_MTU,MTU_BITS);
					else
						reg.mtu <= unsigned(data_reg(MTU_BITS-1 downto 0));
					end if;
				end if;
				if address_reg(TICK_PERIOD_ADDR_BIT)='1' then
					if unsigned(data_reg(TICK_PERIOD_BITS-1 downto 0)) < MIN_TICK_PERIOD then
						reg.tick_period <= to_unsigned(MIN_TICK_PERIOD, TICK_PERIOD_BITS);
					else
						reg.tick_period <= unsigned(data_reg(TICK_PERIOD_BITS-1 downto 0));
					end if;
				end if;
				if address_reg(TICK_LATENCY_ADDR_BIT)='1' then
					reg.tick_latency <= unsigned(data_reg(TICK_LATENCY_BITS-1 downto 0));
				end if;
				if address_reg(ADC_ENABLE_ADDR_BIT)='1' then
					reg.adc_enable <= data_reg(ADC_CHANNELS-1 downto 0);
				end if;
				if address_reg(CHANNEL_ENABLE_ADDR_BIT)='1' then
					reg.channel_enable <= data_reg(CHANNELS-1 downto 0);
				end if;
				if address_reg(FLAGS_ADDR_BIT)='1' then
					reg.FMC108_internal_clk 
						<= to_boolean(data_reg(CTL_FMC108_INTERNAL_CLK_BIT));
					reg.VCO_power <= to_boolean(data_reg(CTL_VCO_POWER_BIT));
				end if;
				if address_reg(WINDOW_ADDR_BIT)='1' then
					reg.window <= unsigned(data_reg(TIME_BITS-1 downto 0));
				end if;
			end if;	
			
			-- strobing registers
      if write and address_reg(IODELAY_CONTROL_ADDR_BIT)='1' then
        reg.iodelay_control <= data_reg(IODELAY_CONTROL_BITS-1 downto 0);
      else
        reg.iodelay_control <= (others => '0');
      end if;
      if write and address_reg(MCA_UPDATE_ADDR_BIT)='1' then
        reg.mca.update_on_completion 
        	<= to_boolean(data_reg(MCA_UPDATE_ON_COMPLETION_BIT));
        reg.mca.update_asap <= to_boolean(data_reg(MCA_UPDATE_ASAP));
      else
        reg.mca.update_on_completion <= FALSE;
        reg.mca.update_asap <= FALSE;
      end if;
      
		end if;
	end if;
end process regwrite;
	
reg_data(HDL_VERSION_ADDR_BIT) <= HDL_VERSION; --FIXME 
reg_data(MCA_CONTROL_REGISTER_ADDR_BIT) <= mca_control_register(reg.mca);
reg_data(MCA_LOWEST_VALUE_ADDR_BIT)
   <= to_std_logic(resize(reg.mca.lowest_value,AXI_DATA_BITS));
reg_data(MCA_TICKS_ADDR_BIT)
   <= to_std_logic(resize(reg.mca.ticks,AXI_DATA_BITS));
reg_data(MTU_ADDR_BIT) <= to_std_logic(resize(reg.mtu,AXI_DATA_BITS));
reg_data(TICK_PERIOD_ADDR_BIT)
   <= to_std_logic(resize(reg.tick_period,AXI_DATA_BITS));
reg_data(TICK_LATENCY_ADDR_BIT)
   <= to_std_logic(resize(reg.tick_latency,AXI_DATA_BITS));
reg_data(ADC_ENABLE_ADDR_BIT) <= resize(reg.adc_enable,AXI_DATA_BITS);
reg_data(CHANNEL_ENABLE_ADDR_BIT) <= resize(reg.channel_enable,AXI_DATA_BITS);
-- FIXME implement
reg_data(FLAGS_ADDR_BIT) <= (
	CTL_FMC108_INTERNAL_CLK_BIT => to_std_logic(reg.FMC108_internal_clk),
	CTL_VCO_POWER_BIT => to_std_logic(reg.VCO_power),
	others => '-'
);
reg_data(WINDOW_ADDR_BIT) <= to_std_logic(resize(reg.window,AXI_DATA_BITS));  
reg_data(11) <= (others => '-');

selectorGen:for b in 0 to AXI_DATA_BITS-1 generate
begin
	
	bitGen:for reg in 0 to 11 generate
	begin
		reg_bits(b)(reg) <= reg_data(reg)(b);
	end generate;
				  
	selector:entity work.select_1of12
  port map(
    input => reg_bits(b),
    sel => address_reg(11 downto 0),
    output => value_int(b)
  );
end generate;

end architecture RTL;
--------------------------------------------------------------------------------