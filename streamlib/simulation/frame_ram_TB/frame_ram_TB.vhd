library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;

entity frame_ram_TB is
generic(
  CHUNKS:integer:=4;
  CHUNK_BITS:integer:=18; -- 8,9,16 or 18
  ADDRESS_BITS:integer:=6
);
end entity frame_ram_TB;

architecture RTL of frame_ram_TB is
  
constant CLK_PERIOD:time:=4 ns;

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal din:std_logic_vector(CHUNKS*CHUNK_BITS-1 downto 0);
signal address:unsigned(ADDRESS_BITS-1 downto 0);
signal chunk_we:boolean_vector(CHUNKS-1 downto 0);
signal length:unsigned(ADDRESS_BITS downto 0);
signal commit:boolean;
signal free:unsigned(ADDRESS_BITS downto 0);
signal stream:std_logic_vector(CHUNKS*CHUNK_BITS-1 downto 0);
signal valid:boolean;
signal ready:boolean;
signal count1,count2:unsigned(3 downto 0);
signal clk_count:integer;
signal streambus_in,streambus_out:streambus_t;
  
begin
clk <= not clk after CLK_PERIOD/2;

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset  = '1' then
      count1 <= (others => '0');
      count2 <= (others => '0');
--      commit <= FALSE;
      clk_count <= 0;
    else
      clk_count <= clk_count+1;
      if count2=count1 then
        count1 <= count1+1;
        count2 <= (others => '0');
--        commit <= TRUE;
      else
        count2 <= count2+1;
--        commit <= FALSE;
      end if;
    end if;
  end if;
end process sim;
commit <= count1=count2;

streambus_in.data <= resize(count2,64);
streambus_in.discard <= (others => FALSE);
streambus_in.last <= (0 => commit, others => FALSE);

length <= resize(count1+1,ADDRESS_BITS+1);
address <= resize(count2,ADDRESS_BITS);
din <= to_std_logic(streambus_in);
UUT:entity work.frame_ram
generic map(
  CHUNKS => CHUNKS,
  CHUNK_BITS => CHUNK_BITS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  din => din,
  address => address,
  chunk_we => chunk_we,
  length => length,
  commit => commit,
  free => free,
  stream => stream,
  valid => valid,
  ready => ready
);
ready <= clk_count mod 1=0;
streambus_out <= to_streambus(stream);

stimulus:process is
begin
chunk_we <= (others => FALSE);
wait for CLK_PERIOD;
reset <= '0';
chunk_we <= (others => TRUE);
wait;
end process stimulus;


end architecture RTL;
