library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
--
library main;

entity event_buffers_TB is
generic(
  CHANNEL_BITS:integer:=1;
  RELTIME_BITS:integer:=16;
  TIMESTAMP_BITS:integer:=64
);
end entity event_buffers_TB;

architecture RTL of event_buffers_TB is
--
signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal start:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal commit:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal dump:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal tick:boolean;
signal timestamp:unsigned(TIMESTAMP_BITS-1 downto 0);
signal eventtime:unsigned(TIMESTAMP_BITS-1 downto 0);
signal reltime:unsigned(RELTIME_BITS-1 downto 0);
signal started:std_logic_vector(2**CHANNEL_BITS-1 downto 0);
signal ticked:boolean;
signal commited:std_logic_vector(2**CHANNEL_BITS-1 downto 0);
signal dumped:std_logic_vector(2**CHANNEL_BITS-1 downto 0);
signal valid:boolean;
signal read_next:boolean;
signal full:boolean;
--
constant CLK_PERIOD:time:= 4 ns;	

begin
clk <= not clk after CLK_PERIOD/2;	

eventBuffers:entity main.event_buffers
	generic map(
		CHANNEL_BITS   => CHANNEL_BITS,
		RELTIME_BITS   => RELTIME_BITS,
		TIMESTAMP_BITS => TIMESTAMP_BITS
	)
	port map(
		clk       => clk,
		reset     => reset,
		start     => start,
		commit    => commit,
		dump      => dump,
		tick      => tick,
		timestamp => timestamp,
		eventtime => eventtime,
		reltime   => reltime,
		started   => started,
		ticked    => ticked,
		commited  => commited,
		dumped    => dumped,
		valid     => valid,
		read_next => read_next,
		full      => full
	);

timer:process (clk) is
begin
if rising_edge(clk) then
  if reset = '1' then
    timestamp <= (others => '0');
  else
    timestamp <= timestamp+1;
  end if;
end if;
end process timer;

stimulus:process is
begin
tick <= FALSE;
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*10;
start <= (TRUE, TRUE);
wait for CLK_PERIOD;
start <= (FALSE, FALSE);
wait for CLK_PERIOD*6;
dump <= (TRUE, FALSE);
wait for CLK_PERIOD;
dump <= (FALSE, FALSE);
wait for CLK_PERIOD*2;
commit <= (FALSE,TRUE);
wait for CLK_PERIOD;
commit <= (FALSE, FALSE);
wait for CLK_PERIOD*2;
wait;
end process stimulus;

end architecture RTL;
