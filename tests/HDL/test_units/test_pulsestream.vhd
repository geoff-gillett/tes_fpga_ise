--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Creation Date:20/10/2015 
--
-- Repository Name: tes_fpga_ise
-- Module Name: test_pulsestream
-- Project Name: tests
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--
-- For testing the frame generation on the FPGA side and capture speed on the 
-- PC side.
-- keeps a framer full of pulses.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.types.all;
use streamlib.functions.all;

entity test_pulsestream is
generic(
  BUS_CHUNKS:integer:=4
);
port (
  clk:in std_logic;
  reset:in std_logic;
	pulsestream:out std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
  pulsestream_valid:out boolean;
	pulsestream_ready:in boolean
);
end entity test_pulsestream;

architecture RTL of test_pulsestream is
constant ADDRESS_BITS:integer:=9;
constant ENDIANNESS:string:="LITTLE";
	
signal event1:std_logic_vector(BUS_CHUNKS*CHUNK_DATABITS-1 downto 0);
signal event2:std_logic_vector(BUS_CHUNKS*CHUNK_DATABITS-1 downto 0);
signal lower5bytes:std_logic_vector(5*8-1 downto 0);
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal framer_free:unsigned(ADDRESS_BITS downto 0);
signal framer_full:boolean;
signal chunk_we:boolean_vector(BUS_CHUNKS-1 downto 0);
signal keeps:std_logic_vector(BUS_CHUNKS-1 downto 0);
signal lasts:std_logic_vector(BUS_CHUNKS-1 downto 0);
signal commit:boolean;
signal data:std_logic_vector(BUS_CHUNKS*CHUNK_DATABITS-1 downto 0);
--signal pulsestream:std_logic_vector(BUS_CHUNKS*CHUNK_BITS-1 downto 0);
--signal pulsestream_valid:boolean;
--signal pulsestream_ready:boolean;
--
signal event_counter:unsigned(25 downto 0);
signal frame_addr:std_logic;
begin

framer:entity streamlib.framer
generic map(
  BUS_CHUNKS   => BUS_CHUNKS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk      => clk,
  reset    => reset,
  data     => data,
  address  => address,
  lasts    => lasts,
  keeps    => keeps,
  chunk_we => chunk_we,
  wr_valid => open,
  length   => to_unsigned(2,ADDRESS_BITS),
  commit   => commit,
  free     => framer_free,
  stream   => pulsestream,
  valid    => pulsestream_valid,
  ready    => pulsestream_ready
);

lower5bytes <= to_std_logic(event_counter(13 downto 0)) & 
							 to_std_logic(event_counter(25 downto 0));
event1 <= "0011000010" & to_std_logic(event_counter(13 downto 0)) &
					SetEndianness(lower5bytes, ENDIANNESS);
						 							 
event2 <= SetEndianness(event_counter(15 downto 0), ENDIANNESS) & 
					SetEndianness(event_counter(15 downto 0), ENDIANNESS) &
					"00000000000000000000000000000000";

address <= unsigned(to_std_logic(0, 8) & frame_addr);
eventCount:process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			event_counter <= (others => '0');
			frame_addr <= '0';
		else
			if not framer_full then
				frame_addr <= not frame_addr;
				if frame_addr = '1' then
					event_counter <= event_counter + 1;
				end if;
			end if;
		end if;
	end if;
end process eventCount;

eventGen:process(framer_full,event1,event2,frame_addr)
begin
	keeps <= (others => '1');
	lasts <= (others => '0');
	chunk_we <= (FALSE, FALSE, FALSE, FALSE);
	commit <= FALSE;
  if not framer_full then
    chunk_we <= (TRUE, TRUE, TRUE, TRUE);
  end if;
  if frame_addr = '0' then
    data <= event1;
  else
    data <= event2;
    lasts <= "0100";
    keeps <= "1100";
    commit <= TRUE;
	end if;
end process eventGen;
end architecture RTL;
