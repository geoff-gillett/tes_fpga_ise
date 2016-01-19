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
--
library main;
--
entity eventstream_mux_TB is
generic(
  CHANNEL_BITS:integer:=3;
  RELTIME_BITS:integer:=16;
  TIMESTAMP_BITS:integer:=64;
  TICK_BITS:integer:=32;
  ENDIANNESS:string:="LITTLE"
);
end entity eventstream_mux_TB;

architecture RTL of eventstream_mux_TB is
constant CLK_PERIOD:time:= 4 ns;
constant CHANNELS:integer:=2**CHANNEL_BITS;

signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal start:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal commit:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal commitdump_toggle:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal dump:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal pulsestreams:eventbus_array(2**CHANNEL_BITS-1 downto 0);
signal pulsestream_lasts:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal pulsestream_valids:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal ready_for_pulsestreams:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal full:boolean;
signal tick_period:unsigned(TICK_BITS-1 downto 0);
signal events_lost:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal dirty:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal eventstream:eventbus_t;
signal valid:boolean;
signal last:boolean;
signal ready:boolean;
--
constant COUNTER_BITS:integer:=16;
type counter_array is array (natural range <>) 
		 of unsigned(COUNTER_BITS-1 downto 0);
signal counter:counter_array(0 to CHANNELS-1);
--minimum 4
constant PULSE_PERIOD:integer:=64;
--
begin
clk <= not clk after CLK_PERIOD/2;
--
--pulsestreams <= (others => (others => '0'));
streamGen:for i in 0 to CHANNELS-1 generate
begin 
	simstream:process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				counter(i) <= to_unsigned(31,COUNTER_BITS);
				pulsestream_lasts(i) <= FALSE;
				pulsestream_valids(i) <= FALSE;
				commitdump_toggle(i) <= TRUE; --i mod 2 = 0;
				pulsestreams(i) <= to_std_logic(i,BUS_CHUNKS*CHUNK_BITS);
			else
				commit(i) <= FALSE;
				dump(i) <= FALSE;
				pulsestream_valids(i) <= TRUE;
				if ready_for_pulsestreams(i) and pulsestream_valids(i) then
					pulsestream_lasts(i) <= not pulsestream_lasts(i);
				end if;
				if counter(i) = to_unsigned(PULSE_PERIOD-2, COUNTER_BITS) then
					start(i) <= TRUE;
				else
					start(i) <= FALSE;
				end if;
				if counter(i) = to_unsigned(PULSE_PERIOD-1, COUNTER_BITS) then
					counter(i) <= (others => '0');
					commitdump_toggle(i) <= not commitdump_toggle(i);
					if commitdump_toggle(i) then
						commit(i) <= TRUE;
					else
						dump(i) <= TRUE;
					end if;
				else
					commit(i) <= FALSE;
					dump(i) <= FALSE;
					counter(i) <= counter(i)+1;
				end if;
			end if;
		end if;
	end process simstream;
end generate;
--
UUT:entity main.eventstream_mux
generic map(
  CHANNEL_BITS   => CHANNEL_BITS,
  RELTIME_BITS   => RELTIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICK_BITS      => TICK_BITS,
  MIN_TICKPERIOD  => 0,
  ENDIANNESS     => ENDIANNESS
)
port map(
  clk                    => clk,
  reset                  => reset,
  start                  => start,
  commit                 => commit,
  dump                   => dump,
  pulsestreams           => pulsestreams,
  pulsestream_lasts      => pulsestream_lasts,
  pulsestream_valids     => pulsestream_valids,
  ready_for_pulsestreams => ready_for_pulsestreams,
  full                   => full,
  tick_period            => tick_period,
  events_lost            => events_lost,
  dirty                  => dirty,
  eventstream            => eventstream,
  valid                  => valid,
  last                   => last,
  ready                  => ready
);
--
stimulus:process is
begin
dirty <= (others => FALSE);
events_lost <= (others => FALSE);
tick_period <= to_unsigned(32, TICK_BITS);
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*10;
ready <= TRUE; 
wait;
end process stimulus;

end architecture RTL;
