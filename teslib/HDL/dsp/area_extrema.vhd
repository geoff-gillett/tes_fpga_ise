--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:28 Dec 2015
--
-- Design Name: TES_digitiser
-- Module Name: signal_measurement
-- Project Name: dsplib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library dsp;
use dsp.types.all;

use work.types.all;

-- Assumes FRAC >= AREA_FRAC
entity area_extrema is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3;
	WIDTH_OUT:integer:=16;
	FRAC_OUT:integer:=1;
	AREA_WIDTH:integer:=32;
	AREA_FRAC:integer:=1
);
port (
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  
  signal_out:out signed(WIDTH_OUT-1 downto 0);
  pos_xing:out boolean;
  neg_xing:out boolean;
  xing:out boolean;
  -- both area and extrema valid at zero_xing
  area:out signed(AREA_WIDTH-1 downto 0);
  extrema:out signed(WIDTH_OUT-1 downto 0)
);
end entity area_extrema;

architecture RTL of area_extrema is
  
--FIXME add saturation check on area remove shifts and do them outside
signal extreme_int:signed(WIDTH_OUT-1 downto 0);
signal pos_x,neg_x,xing_int:boolean;
signal signal_x:signed(WIDTH-1 downto 0);
signal signal_r:std_logic_vector(WIDTH_OUT-1 downto 0);

constant DEPTH:integer:=5;
signal pos_p,neg_p,xing_p:boolean_vector(1 to DEPTH):=(others => FALSE);
signal pipe:signal_array(1 to DEPTH):=(others => (others => '0'));
signal gt:boolean;

type extrema_state is (MAX_S,MIN_S);
signal state:extrema_state;

begin
signal_out <= pipe(DEPTH);
extrema <= extreme_int;
pos_xing <= pos_p(DEPTH-1);
neg_xing <= neg_p(DEPTH-1);
xing <= xing_p(DEPTH-1);


xing_int <= pos_x or neg_x;

-- saturation handled in FIR
round:entity dsp.round
generic map(
  WIDTH_IN  => WIDTH,
  FRAC_IN   => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT  => FRAC_OUT
)
port map(
  clk => clk,
  reset => reset,
  input => std_logic_vector(signal_in),
  output => signal_r
);

areaAcc:entity dsp.area_acc
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => xing_int,
  sig => signal_x,
  area => area
);

crossing:entity dsp.crossing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  threshold => threshold,
  signal_out => signal_x,
  pos => pos_x,
  neg => neg_x
);

pipeline:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      pos_p <= (others => FALSE);
      neg_p <= (others => FALSE);
      xing_p <= (others => FALSE);
      pipe <= (others => (others => '0'));
    else
      pos_p <= pos_x & pos_p(1 to DEPTH-1);   
      neg_p <= neg_x & neg_p(1 to DEPTH-1);   
      xing_p <= (pos_x or neg_x) & xing_p(1 to DEPTH-1);
      pipe <= signed(signal_r) & pipe(1 to DEPTH-1);   
    end if;
  end if;
end process pipeline;

--FIXME check extrema
gt <= pipe(DEPTH-1) > extreme_int; 
extremeMeas:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    
    extreme_int <= (others => '0');
    state <= MAX_S; 
    
  else
    if pos_p(DEPTH-1) then
      state <= MAX_S;
    elsif neg_p(DEPTH-1) then
      state <= MIN_S;
    end if;
    if xing_p(DEPTH-1) then
      extreme_int <= pipe(DEPTH-1);
    else
      if state=MAX_S and gt then
        extreme_int <= pipe(DEPTH-1);
      end if;
      
      if (state=MIN_S and not gt) then
        extreme_int <= pipe(DEPTH-1);
      end if;
    end if;
    
  end if;
end if;
end process extremeMeas;

end architecture RTL;
