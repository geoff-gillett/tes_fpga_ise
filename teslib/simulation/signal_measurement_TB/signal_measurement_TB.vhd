library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

entity signal_measurement_TB is
generic(
  WIDTH:integer:=18;
  FRAC:integer:=3;
	WIDTH_OUT:integer:=16;
	FRAC_OUT:integer:=1;
  AREA_WIDTH:integer:=32;
  AREA_FRAC:integer:=1;
  CLOSEST:boolean:=FALSE
);
end entity signal_measurement_TB;

architecture RTL of signal_measurement_TB is
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal signal_in:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH_OUT-1 downto 0);
signal threshold:signed(WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
signal area:signed(AREA_WIDTH-1 downto 0);
signal pos_0xing:boolean;
signal neg_0xing:boolean;
signal zero_xing:boolean;
signal extrema:signed(WIDTH_OUT-1 downto 0);

begin
  
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.signal_measurement2
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC,
  CLOSEST => CLOSEST
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  threshold => threshold,
  signal_out => signal_out,
  pos_xing => pos_0xing,
  neg_xing => neg_0xing,
  xing => zero_xing,
  area => area,
  extrema => extrema
);

stimulus:process is
begin
threshold <= to_signed(0,WIDTH);
signal_in <= (17 downto 17 => '0', others => '1');
wait for CLK_PERIOD;
reset <= '0';
wait for CLK_PERIOD*8;
signal_in <= (17 downto 17 => '1', others => '0');
wait for CLK_PERIOD*8;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(1,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-1,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(8,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-8,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(1,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(8,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(0,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-8,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-16,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(8,WIDTH);
wait for CLK_PERIOD;
signal_in <= to_signed(-9,WIDTH);

wait;
  
end process stimulus;


end architecture RTL;
