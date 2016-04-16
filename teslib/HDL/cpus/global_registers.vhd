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
  HDL_VERSION:register_data_t:=to_std_logic(42,REGISTER_DATA_BITS)
);
port (
  reg_clk:in std_logic;
  reg_reset:in std_logic;
  --!* register signals from/to channel CPU
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

signal reg:global_registers_t;
signal reg_data:AXI_data_array(11 downto 0);
type bit_array is array (natural range <>) of std_logic_vector(11 downto 0);
signal reg_bits:bit_array(AXI_DATA_BITS-1 downto 0);

begin 
registers <= reg;
	
regwrite:process(reg_clk)
begin
	if rising_edge(reg_clk) then
		if reg_reset = '1' then
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
		else
			if write then
				if address(MCA_CONTROL_REGISTER_ADDR_BIT)='1' then
					reg.mca.value <= to_mca_value_d(data(3 downto 0));
					reg.mca.trigger <= to_mca_trigger_d(data(7 downto 4));
					reg.mca.channel <= unsigned(data(10 downto 8));
					reg.mca.bin_n <= unsigned(data(15 downto 11));
					reg.mca.last_bin <= unsigned(data(29 downto 16));
				end if;
				if address(MCA_LOWEST_VALUE_ADDR_BIT)='1' then
					reg.mca.lowest_value <= signed(data(MCA_VALUE_BITS-1 downto 0));
				end if;
				if address(MCA_TICKS_ADDR_BIT)='1' then
					reg.mca.ticks <= unsigned(data(MCA_TICKCOUNT_BITS-1 downto 0));
				end if;
				if address(MTU_ADDR_BIT)='1' then
					reg.mtu <= unsigned(data(MTU_BITS-1 downto 0));
				end if;
				if address(TICK_PERIOD_ADDR_BIT)='1' then
					reg.tick_period <= unsigned(data(TICK_PERIOD_BITS-1 downto 0));
				end if;
				if address(TICK_LATENCY_ADDR_BIT)='1' then
					reg.tick_latency <= unsigned(data(TICK_LATENCY_BITS-1 downto 0));
				end if;
				if address(ADC_ENABLE_ADDR_BIT)='1' then
					reg.adc_enable <= data(ADC_CHANNELS-1 downto 0);
				end if;
				if address(CHANNEL_ENABLE_ADDR_BIT)='1' then
					reg.channel_enable <= data(CHANNELS-1 downto 0);
				end if;
				if address(STATUS_ADDR_BIT)='1' then
					-- FIXME implement
					null;
				end if;
				if address(STATUS_ADDR_BIT)='1' then
					-- FIXME implement
					null;
				end if;
				if address(IODELAY_CONTROL_ADDR_BIT)='1' then
					reg.iodelay_control <= data(IODELAY_CONTROL_BITS-1 downto 0);
				else
					reg.iodelay_control <= (others => '0');
				end if;
			end if;	
			-- strobing registers
      if write and address(IODELAY_CONTROL_ADDR_BIT)='1' then
        reg.iodelay_control <= data(IODELAY_CONTROL_BITS-1 downto 0);
      else
        reg.iodelay_control <= (others => '0');
      end if;
      if write and address(MCA_UPDATE_ADDR_BIT)='1' then
        reg.mca.update_on_completion 
        	<= to_boolean(data(MCA_UPDATE_ON_COMPLETION_BIT));
        reg.mca.update_asap <= to_boolean(data(MCA_UPDATE_ASAP));
      else
        reg.mca.update_on_completion <= FALSE;
        reg.mca.update_asap <= FALSE;
      end if;
      
		end if;
	end if;
end process regwrite;
	
reg_data(HDL_VERSION_ADDR_BIT) <= HDL_VERSION;
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
reg_data(ADC_ENABLE_ADDR_BIT)
   <= to_std_logic(resize(unsigned(reg.adc_enable),AXI_DATA_BITS));
reg_data(CHANNEL_ENABLE_ADDR_BIT)
   <= to_std_logic(resize(unsigned(reg.channel_enable),AXI_DATA_BITS));
-- FIXME implement
reg_data(STATUS_ADDR_BIT) <= (others => '0');
reg_data(10) <= (others => '0');  -- reserved
reg_data(11) <= (others => '0');

selectorGen:for b in 0 to AXI_DATA_BITS-1 generate
begin
	
	bitGen:for reg in 0 to 11 generate
	begin
		reg_bits(b)(reg) <= reg_data(reg)(b);
	end generate;
				  
	selector:entity work.select_1of12
  port map(
    input => reg_bits(b),
    sel => address(11 downto 0),
    output => value(b)
  );
end generate;

end architecture RTL;
--------------------------------------------------------------------------------