--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:4 Apr 2016
--
-- Design Name: TES_digitiser
-- Module Name: CDC_bytestream_adapter_TB
-- Project Name: teslib			
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library streamlib;
use streamlib.types.all;

entity CDC_bytestream_adapter_TB is
end entity CDC_bytestream_adapter_TB;

architecture testbench of CDC_bytestream_adapter_TB is

signal s_clk:std_logic:='1';	
signal s_reset:std_logic:='1';	
constant S_CLK_PERIOD:time:=4 ns;
signal b_clk:std_logic:='1';	
signal b_reset:std_logic:='1';	
constant B_CLK_PERIOD:time:=8 ns;

signal streambus:streambus_t;
signal streambus_valid:boolean;
signal streambus_ready:boolean;
signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:boolean;
signal bytestream_last:boolean;

signal sim_count:unsigned(7 downto 0);


begin
	
s_clk <= not s_clk after S_CLK_PERIOD/2;
b_clk <= not b_clk after B_CLK_PERIOD/2;

sim:process(s_clk)
begin
	if rising_edge(s_clk) then
		if s_reset = '1' then
			sim_count <= (others => '0');
		else
			if streambus_valid and streambus_ready then
				sim_count <= sim_count+1;
			end if;
		end if;
	end if;
end process sim;

-- generate individual byte values
simMap:process(sim_count)
begin
	for b in 0 to 7 loop
		streambus.data(8*(b+1)-1 downto 8*b) 
			<= to_std_logic(sim_count + to_unsigned(b, 8));
	end loop;
end process simMap;

streambus.last <= (0 => sim_count=to_unsigned(8,8), others => FALSE);

UUT:entity work.CDC_bytestream_adapter
port map(
  s_clk => s_clk,
  s_reset => s_reset,
  streambus => streambus,
  streambus_valid => streambus_valid,
  streambus_ready => streambus_ready,
  b_clk => b_clk,
  b_reset => b_reset,
  bytestream => bytestream,
  bytestream_valid => bytestream_valid,
  bytestream_ready => bytestream_ready,
  bytestream_last  => bytestream_last
);

stimulus:process is
begin
streambus_valid <= TRUE;
bytestream_ready <= TRUE;
wait for B_CLK_PERIOD;
s_reset <= '0';
b_reset <= '0';
wait until bytestream_last and bytestream_ready and bytestream_valid;
wait for B_CLK_PERIOD;
bytestream_ready <= FALSE;
wait for B_CLK_PERIOD*20;
bytestream_ready <= TRUE;
wait until bytestream_last and bytestream_ready and bytestream_valid;
wait for B_CLK_PERIOD;
bytestream_ready <= FALSE;
streambus_valid <= FALSE;
wait for B_CLK_PERIOD*20;
bytestream_ready <= TRUE;
wait for B_CLK_PERIOD*20;
streambus_valid <= TRUE;
wait;
end process stimulus;

end architecture testbench;
