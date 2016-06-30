--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:4 Apr 2016
--
-- Design Name: TES_digitiser
-- Module Name: cdc_downsizer
-- Project Name: 
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

entity CDC_bytestream_adapter is
port (
	-- streambus clk domain
  s_clk:in std_logic;  
  s_reset:in std_logic;
  
  streambus:in streambus_t;
  streambus_valid:in boolean;
  streambus_ready:out boolean;
  
	-- bytestream clk domain
  b_clk:in std_logic;  
  b_reset:in std_logic;
  
  bytestream:out std_logic_vector(7 downto 0);
  bytestream_valid:out boolean;
  bytestream_ready:in boolean;
  bytestream_last:out boolean
);
end entity CDC_bytestream_adapter;

-- NOTE expects stream_clk to be twice bytestream_clk ignores keep_n
architecture HALF_RATE of CDC_bytestream_adapter is

attribute clock_signal:string;
attribute clock_signal of s_clk,b_clk:signal is "YES";

type byte_array is array (natural range <>) of std_logic_vector(11 downto 0);
signal bits:byte_array(7 downto 0);
--signal bus_byte:std_logic_vector(7 downto 0);
signal s_ready:boolean;
signal bytestream_int:std_logic_vector(8 downto 0);
signal ready_for_byte:boolean;

signal sel_ring,byte_out:std_logic_vector(7 downto 0);
signal sel_int:std_logic_vector(11 downto 0);
signal last:std_logic;
signal stream_in:std_logic_vector(8 downto 0);

signal stream_reg:streamvector_t;
signal stream_last:boolean_vector(BUS_CHUNKS-1 downto 0);
signal ready_io:boolean;
begin
	
streambus_ready <= s_ready;
bytestream <= bytestream_int(7 downto 0);
bytestream_last <= to_boolean(bytestream_int(8));

inputReg:process(s_clk)
begin
	if rising_edge(s_clk) then
		if s_reset = '1' then
			s_ready <= FALSE;
		else
			if s_ready and streambus_valid then
				stream_reg <= to_std_logic(streambus);
				stream_last <= streambus.last;
				s_ready <= FALSE; 
			end if;
			if ready_io then --io_clk domain
				s_ready <= TRUE;		
			end if;
		end if;
	end if;
end process inputReg;
ready_io <= ready_for_byte and sel_ring(0)='1';

-- break streambus into bytes
--bytes(7) <= streambus.data(63 downto 56);
--bytes(6) <= streambus.data(55 downto 48);
--bytes(5) <= streambus.data(47 downto 40);
--bytes(4) <= streambus.data(39 downto 32);
--bytes(3) <= streambus.data(31 downto 24);
--bytes(2) <= streambus.data(23 downto 16);
--bytes(1) <= streambus.data(15 downto 8);
--bytes(0) <= streambus.data(7 downto 0);

-- byte 0 is the LSB of bus and first transmitted
-- transpose the bus for the selector
--bitmap:process(streambus.data)
--variable bus_byte:std_logic_vector(7 downto 0);
--begin
--	for bit in 7 downto 0 loop
--		for byte in 7 downto 0 loop
--			bus_byte:=streambus.data(8*(byte+1)-1 downto 8*byte);
--			bits(bit)(byte) <= bus_byte(bit);
--		end loop;
--	end loop;
--end process bitmap;


bitGen:for bit in 7 downto 0 generate
begin
	byteGen:for byte in 7 downto 0 generate	
	begin
			--bus_byte <= streambus.data(8*(byte+1)-1 downto 8*byte);
			bits(bit)(byte) <= streambus.data(8*byte+bit);
	end generate;
end generate;

--generate selectors that select each bit from the bytes in the bus
sel_int(11 downto 8) <= (others => '0');
sel_int(7 downto 0) <= sel_ring;
byteSelGen:for bit in 7 downto 0 generate
begin
	selector:entity work.select_1of12
		port map(
			input => bits(bit),
			sel => sel_int,
			output => byte_out(bit)
		);
end generate;
last <= to_std_logic(streambus.last(0)) and sel_ring(0);

-- create one-hot sel value
selRing:process(b_clk)
begin
	if rising_edge(b_clk) then
		if b_reset = '1' then
			sel_ring <= (7 => '1', others => '0');
		else
			if ready_for_byte and streambus_valid then -- this is a problem ready in IO valid in sample
				sel_ring(6 downto 0) <= sel_ring(7 downto 1);
				sel_ring(7) <= sel_ring(0);
			end if;
		end if;
	end if;
end process selRing;

input:process(s_clk)
begin
	if rising_edge(s_clk) then
		if s_reset = '1' then
			s_ready <= FALSE;
		else
			s_ready <= ready_for_byte and sel_ring(0)='1' and not s_ready;	
		end if;
	end if;
end process input;

--streambus_ready_bclk <= byte_count=7 and ready_for_byte;
stream_in <= last & byte_out;
outputReg:entity streamlib.stream_register
generic map(
  WIDTH => 9
)
port map(
  clk => b_clk,
  reset => b_reset,
  stream_in => stream_in,
  ready_out => ready_for_byte,
  valid_in => streambus_valid,
  stream => bytestream_int,
  ready => bytestream_ready,
  valid => bytestream_valid
);

end architecture HALF_RATE;
