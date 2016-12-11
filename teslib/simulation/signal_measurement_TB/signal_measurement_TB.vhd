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
  AREA_FRAC:integer:=1
);
end entity signal_measurement_TB;

architecture RTL of signal_measurement_TB is
  
signal clk:std_logic:='1';
signal reset:std_logic:='1';
signal signal_in:signed(WIDTH-1 downto 0);
signal signal_out:signed(WIDTH_OUT-1 downto 0);
signal signal_threshold:signed(WIDTH-1 downto 0);
signal area_threshold:signed(AREA_WIDTH-1 downto 0);

constant CLK_PERIOD:time:=4 ns;
signal area:signed(AREA_WIDTH-1 downto 0);
signal above_area_threshold:boolean;
signal pos_0xing:boolean;
signal neg_0xing:boolean;
signal zero_xing:boolean;
signal extrema:signed(WIDTH_OUT-1 downto 0);

constant SIM_WIDTH:natural:=7;
signal sim_count:unsigned(SIM_WIDTH-1 downto 0);
signal squaresig:signed(WIDTH-1 downto 0);
begin
  
clk <= not clk after CLK_PERIOD/2;

UUT:entity work.signal_measurement3
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT => FRAC_OUT,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  signal_threshold => signal_threshold,
  area_threshold => area_threshold,
  signal_out => signal_out,
  pos_xing => pos_0xing,
  neg_xing => neg_0xing,
  xing => zero_xing,
  area => area,
  above_area_threshold => above_area_threshold,
  extrema => extrema
);

simsquare:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      sim_count <= (others => '0');
    else
      sim_count <= sim_count+1;
    end if;
  end if;
end process simsquare;
squaresig <= to_signed(-800,WIDTH)
             when sim_count(SIM_WIDTH-1)='1' 
             else to_signed(800,WIDTH);
               
signal_in <= squaresig;
             
stimulus:process is
begin
signal_threshold <= to_signed(400,WIDTH);
area_threshold <= to_signed(2000,AREA_WIDTH);
wait for CLK_PERIOD;
reset <= '0';
wait;
end process stimulus;


end architecture RTL;
