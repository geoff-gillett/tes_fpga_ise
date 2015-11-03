library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library teslib;
use teslib.functions.all;

entity pulse_measurement is
generic(
  ADC_BITS:integer:=14;
  TIME_BITS:integer:=14;
  AREA_BITS:integer:=26
);
port (
  clk:in std_logic;
  reset:in std_logic;

  threshold:in unsigned(ADC_BITS-1 downto 0);
  sample:in signed(ADC_BITS downto 0);
  
  area:out unsigned(AREA_BITS-1 downto 0);
  length:out unsigned;
  start:out boolean;
  stop:out boolean --pulse variables valid
);
end entity pulse_measurement;

architecture RTL of pulse_measurement is

signal sample_rel:signed(ADC_BITS downto 0);
signal rolling_over,start_reg,stop_reg:boolean;
signal start_timer:std_logic;
signal sample_rel_thresh_reg:signed(ADC_BITS downto 0);
signal pulse_area_int:unsigned(31 downto 0);
signal relative_time:unsigned(TIME_BITS-1 downto 0);
signal above,below,was_above,was_below,start_int,stop_int,started:boolean;

begin
--FIXME is area relative to threshold the best way?
--------------------------------------------------------------------------------
-- pipeline
-- 1 sample relative to threshold
-- 2 start/stop
-- 3 saturation
--------------------------------------------------------------------------------
above <= sample_rel > 0;
below <= sample_rel <= 0;
start_int <= above and was_below;
stop_int <= below and was_above;
--
pulseMeasurement:process(clk)
variable rolled_over:boolean;
begin
if rising_edge(clk) then
  if reset='1' then
    sample_rel <= (others => '0');
    rolled_over:=FALSE;
    pulse_area_int <= (others => '0');
    started <= FALSE;
  else
    start <= start_reg;
    stop <= stop_reg;
    
    start_reg <= start_int;
    stop_reg <= (stop_int or rolling_over) and started;
    
    was_below <= below;
    was_above <= above;
    
    sample_rel <= sample-signed(threshold);
    sample_rel_thresh_reg <= sample_rel;

    if start_int then
      pulse_area_int <= resize(unsigned(sample_rel),32);
      started <= TRUE;
    elsif not stop_int then
      pulse_area_int <= pulse_area_int+unsigned(sample_rel);
    end if;
    
    if stop_int or rolling_over then
      started <= FALSE;
    end if;
    
    if unaryOR(pulse_area_int(31 downto AREA_BITS)) then
      area <= (others => '1');
    else
      area <= pulse_area_int(AREA_BITS-1 downto 0);
    end if;
    
    if not (rolled_over or stop_reg) then
      length <= relative_time;
    end if;
    
    if start_int then
      rolled_over:=FALSE;
    elsif rolling_over then
      rolled_over:=TRUE;
    end if;
    
  end if;
end if;
end process;

start_timer <= to_std_logic(start_int) or reset;
relativeTime:entity teslib.clock
generic map(TIME_BITS => TIME_BITS)
port map(
  clk => clk,
  reset => start_timer,
  te => TRUE,
  initialise_to_1 => TRUE,
  rolling_over => rolling_over,
  time_stamp => relative_time
);
end architecture RTL;
