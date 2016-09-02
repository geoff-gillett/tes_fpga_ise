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

use work.types.all;

-- Assumes FRAC >= AREA_FRAC

entity signal_measurement2 is
generic(
	WIDTH:integer:=18;
	FRAC:integer:=3;
	AREA_WIDTH:integer:=32;
	AREA_FRAC:integer:=1
);
port (
  clk:in std_logic;
  reset:in std_logic;
  signal_in:in signed(WIDTH-1 downto 0);
  threshold:in signed(WIDTH-1 downto 0);
  signal_out:out signed(WIDTH-1 downto 0);
  --TODO add closest for these
  pos:out boolean;
  neg:out boolean; 
  xing_time:out unsigned(15 downto 0); 
  area:out signed(AREA_WIDTH-1 downto 0);
  extrema:out signed(WIDTH-1 downto 0)
);
end entity signal_measurement2;

architecture RTL of signal_measurement2 is
--FIXME add saturation check on area remove shifts and do them outside
signal extrema_int:signed(WIDTH-1 downto 0);
signal pos_xing,neg_xing,xing:boolean;
signal signal_xing:signed(WIDTH-1 downto 0);
signal time_int:unsigned(xing_time'left+1 downto 0);

constant DEPTH:integer:=3;
signal pos_pipe,neg_pipe:boolean_vector(1 to DEPTH):=(others => FALSE);
type pipe_t is array (1 to DEPTH) of signed(signal_in'range);
signal pipe:pipe_t:=(others => (others => '0'));
signal gt:boolean;
signal extrema_0 :boolean;
--type pipeline is array (natural range <>) of signed(WIDTH-1 downto 0);
--signal pipe:pipeline(1 to PIPELINE_DEPTH);

begin
extrema <= extrema_int;
signal_out <= pipe(DEPTH);
pos <= pos_pipe(DEPTH);
neg <= neg_pipe(DEPTH);
xing_time <= time_int(15 downto 0);

crossing:entity work.threshold_xing
generic map(
  WIDTH => WIDTH
)
port map(
  clk => clk,
  reset => reset,
  signal_in => signal_in,
  threshold => threshold,
  signal_out => signal_xing,
  pos => pos_xing,
  neg => neg_xing
);
  
pipeline:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      pos_pipe <= (others => FALSE);
      neg_pipe <= (others => FALSE);
      pipe <= (others => (others => '0'));
    else
      pos_pipe(1) <= pos_xing;
      pos_pipe(2 to DEPTH) <= pos_pipe(1 to DEPTH-1);   
      neg_pipe(1) <= neg_xing;
      neg_pipe(2 to DEPTH) <= neg_pipe(1 to DEPTH-1);   
      pipe(1) <= signal_xing;
      pipe(2 to DEPTH) <= pipe(1 to DEPTH-1);   
    end if;
  end if;
end process pipeline;

xing <= pos_xing or neg_xing;
areaAcc:entity work.area_acc(dspx2)
generic map(
  WIDTH => WIDTH,
  FRAC => FRAC,
  AREA_WIDTH => AREA_WIDTH,
  AREA_FRAC => AREA_FRAC
)
port map(
  clk => clk,
  reset => reset,
  xing => xing,
  sig => signal_xing,
  area => area
);

gt <= pipe(DEPTH) > extrema_int; 
extrema_0 <= extrema_int=0;
measurement:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    extrema_int <= (others => '0');
    time_int <= (0 => '1', others => '0');
  else
    
    if pos_pipe(DEPTH) or neg_pipe(DEPTH) then
      time_int <= (0 => '1', others => '0'); 
      extrema_int <= pipe(DEPTH);
    else
      if time_int(16)='1' then
        time_int <= (16 => '0', others => '1');
      else
        time_int <= time_int + 1;
      end if;
      if (extrema_int(WIDTH-1)='0' and gt) or 
        (extrema_int(WIDTH-1)='1' and not gt) or extrema_0 then 
        extrema_int <= pipe(DEPTH);
      end if;
      
    end if;
  	
  end if;
end if;
end process measurement;

end architecture RTL;
