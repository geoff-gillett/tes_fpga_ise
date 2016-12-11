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
entity signal_measurement3 is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3;
	WIDTH_OUT:integer:=16;
	FRAC_OUT:integer:=1;
	AREA_WIDTH:integer:=32;
	AREA_FRAC:integer:=1;
	-- pipes are closest to crossing
	STRICT:boolean:=TRUE 
);
port (
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  signal_threshold:in signed(WIDTH-1 downto 0);
  area_threshold:in signed(AREA_WIDTH-1 downto 0);
  
  signal_out:out signed(WIDTH_OUT-1 downto 0);
  pos_xing:out boolean;
  neg_xing:out boolean;
  xing:out boolean;
  -- both area and extrema valid at zero_xing
  area:out signed(AREA_WIDTH-1 downto 0);
  above_area_threshold:out boolean;
  extrema:out signed(WIDTH_OUT-1 downto 0)
);
end entity signal_measurement3;

architecture RTL of signal_measurement3 is
  
signal extreme_int:signed(WIDTH_OUT-1 downto 0);
signal pos_x,neg_x,xing_int:boolean;
signal signal_x:signed(WIDTH-1 downto 0);
signal signal_r:signed(WIDTH_OUT-1 downto 0);

constant DEPTH:integer:=6;
signal pos_p,neg_p,xing_p:boolean_vector(1 to DEPTH):=(others => FALSE);
signal pipe:signal_array(1 to DEPTH):=(others => (others => '0'));
signal gt:boolean;

type extrema_state is (MAX_S,MIN_S);
signal state:extrema_state;

begin
signal_out <= pipe(DEPTH);
pos_xing <= pos_p(DEPTH);
neg_xing <= neg_p(DEPTH);
xing <= xing_p(DEPTH);

xing_int <= pos_x or neg_x;

-- saturation handled in FIR
round:entity dsp.round2
generic map(
  WIDTH_IN  => WIDTH,
  FRAC_IN   => FRAC,
  WIDTH_OUT => WIDTH_OUT,
  FRAC_OUT  => FRAC_OUT
)
port map(
  clk => clk,
  reset => reset,
  input => signal_in,
  output_threshold => (others => '0'),
  output => signal_r,
  above_threshold => open
);

crossing:entity dsp.crossing
generic map(
  WIDTH => WIDTH,
  STRICT => STRICT
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  threshold => signal_threshold,
  signal_out => signal_x,
  pos => pos_x,
  neg => neg_x
);

areaAcc:entity dsp.area_acc3
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
  signal_threshold => signal_threshold,
  area_threshold => area_threshold,
  area => area,
  above_area_threshold => above_area_threshold
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
      pos_p(2 to DEPTH) <= pos_x & pos_p(2 to DEPTH-1);   
      neg_p(2 to DEPTH) <= neg_x & neg_p(2 to DEPTH-1);   
      xing_p(2 to DEPTH) <= xing_int & xing_p(2 to DEPTH-1);
      pipe(3 to DEPTH) <= signal_r & pipe(3 to DEPTH-1);   
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
    extrema <= (others => '0');
    
  else
    extrema <= extreme_int;
    
    if pos_p(DEPTH-1) then
      state <= MAX_S;
    elsif neg_p(DEPTH) then
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
