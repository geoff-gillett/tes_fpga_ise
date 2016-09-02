library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signal_measurement_TB is
generic(
  WIDTH:integer:=18;
  FRAC:integer:=3;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1
);
end entity signal_measurement_TB;

architecture RTL of signal_measurement_TB is
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal signal_in:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH-1 downto 0);
signal threshold:signed(WIDTH-1 downto 0);
signal pos:boolean;
signal neg:boolean;

constant CLK_PERIOD:time:=4 ns;
signal xing_time:unsigned(15 downto 0);
signal area:signed(AREA_WIDTH-1 downto 0);
signal extrema:signed(WIDTH-1 downto 0);

begin
  
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  threshold => threshold,
  signal_out => signal_out,
  pos => pos,
  neg => neg,
  xing_time => xing_time,
  area => area,
  extrema => extrema
);

stimulus:process is
begin
threshold <= to_signed(0,WIDTH);
signal_in <= to_signed(100,WIDTH);
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*8;
signal_in <= to_signed(-90,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-90,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(80,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(70,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-60,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(70,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-80,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(90,WIDTH);

wait;
  
end process stimulus;


end architecture RTL;
