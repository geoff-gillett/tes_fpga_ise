library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

entity frame_ram_TB is
generic(
  CHUNKS:integer:=2;
  CHUNK_BITS:integer:=8; -- 8,9,16 or 18
  ADDRESS_BITS:integer:=4
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
signal sim_count:unsigned(15 downto 0);
  
begin
clk <= not clk after CLK_PERIOD/2;

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= (others => '0');
    else
      if commit then
        sim_count <= sim_count+1;
      end if;
    end if;
  end if;
end process sim;

UUT:entity work.frame_ram
generic map(
  CHUNKS => CHUNKS,
  CHUNK_BITS => CHUNK_BITS,
  ADDRESS_BITS => ADDRESS_BITS
)
port map(
  clk => clk,
  reset => reset,
  din => std_logic_vector(sim_count),
  address => address,
  chunk_we => chunk_we,
  length => length,
  commit => commit,
  free => free,
  stream => stream,
  valid => valid,
  ready => ready
);

stimulus:process is
begin
address <= (others => '0');
commit <= FALSE;
din <= (others => '1');
length <= (0 => '1', others => '0');
wait for CLK_PERIOD;
reset <= '0';
wait for 2*CLK_PERIOD;
commit <= TRUE;
chunk_we <= (others => TRUE);
wait for 16*CLK_PERIOD;
chunk_we <= (others => FALSE);
commit <= FALSE;
wait for 32*CLK_PERIOD;
ready <= TRUE;
wait for CLK_PERIOD;
--ready <= FALSE;
--wait for CLK_PERIOD;
--ready <= TRUE;
--wait for CLK_PERIOD;
--ready <= FALSE;
--wait for CLK_PERIOD;
--ready <= TRUE;
--wait for CLK_PERIOD;
--ready <= FALSE;
--wait for CLK_PERIOD;
--ready <= TRUE;
--wait for CLK_PERIOD;
--ready <= FALSE;
--wait for CLK_PERIOD;
--ready <= TRUE;
wait for CLK_PERIOD*20;
commit <= TRUE;
chunk_we <= (others => TRUE);
wait;
end process stimulus;


end architecture RTL;
