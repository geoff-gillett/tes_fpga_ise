--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:6Feb.,2017
--
-- Design Name: TES_digitiser
-- Module Name: serialiser_TB
-- Project Name:  streamlib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serialiser_TB is
generic(
  WIDTH:natural:=4
);
end entity serialiser_TB;

architecture testbench of serialiser_TB is

signal clk:std_logic:='1';  
signal reset:std_logic:='1';  
constant CLK_PERIOD:time:=4 ns;
signal empty:boolean;
signal write:boolean;
signal last_address:boolean;
signal read:boolean;
signal ram_data:std_logic_vector(WIDTH-1 downto 0);
signal stream:std_logic_vector(WIDTH-1 downto 0);
signal valid:boolean;
signal ready:boolean;
signal last:boolean;

constant DEPTH:natural:=4;
type pipe is array (1 to DEPTH) of std_logic_vector(WIDTH-1 downto 0);
signal sim_pipe:pipe;
signal sim_data:unsigned(WIDTH-1 downto 0);
signal clk_count:integer:=0;
signal sim_ready,sim_enable:boolean;
begin

clk <= not clk after CLK_PERIOD/2;

UUT:entity work.serialiser
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  empty => empty,
  write => write,
  last_address => last_address,
  read => read,
  ram_data => ram_data,
  stream => stream,
  valid => valid,
  ready => ready,
  last => last
);

sim:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_pipe <= (others => (others => '0'));
      sim_data <= (others => '0');
      clk_count <= 0;
    else
      clk_count <= clk_count+1;
      if sim_enable then
        sim_ready <= clk_count mod 2 = 0;
      else
        sim_ready <= FALSE;
      end if;
      if read then
        sim_data <= sim_data+1;
      end if;
      if write then
        sim_pipe <= std_logic_vector(sim_data) & sim_pipe(1 to DEPTH-1);
      elsif empty then
        sim_pipe(1) <= (others => '-');
        sim_pipe(2 to DEPTH) <= sim_pipe(1 to DEPTH-1);
      else
        if read then
          sim_pipe <= std_logic_vector(sim_data+1) & sim_pipe(1 to DEPTH-1);
          sim_data <= sim_data+1;
          last_address <= sim_data+1 = to_unsigned(2**WIDTH-2,WIDTH);
        else
          sim_pipe <= std_logic_vector(sim_data) & sim_pipe(1 to DEPTH-1);
        end if;
      end if; 
    end if;
  end if;
end process sim;

ram_data <= sim_pipe(DEPTH);
ready <= sim_ready;

stimulus:process is
begin
sim_enable <= TRUE;
empty <= TRUE;
write <= FALSE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*10;
write <= TRUE;
wait for CLK_PERIOD;
write <= FALSE;
wait for CLK_PERIOD*3;
empty <= FALSE;
wait for CLK_PERIOD*10;
sim_enable <= TRUE;
wait;
end process stimulus;

end architecture testbench;
