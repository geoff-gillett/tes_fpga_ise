library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

library extensions;
use extensions.logic.all;


use work.events.all;
use work.registers.all;

entity event_generator is
  port (
    clk:in std_logic;
    reset:in std_logic;
    
    stream:out streambus_t;
    valid:out boolean;
    ready:in boolean
  );
end entity event_generator;

architecture RTL of event_generator is
signal seq:unsigned(15 downto 0);
signal flags:detection_flags_t;
signal stream_int:streambus_t;
signal valid_int:boolean:=FALSE;
begin

stream <= stream_int;
valid <= valid_int;

flags.event_type.detection <= PEAK_DETECTION_D;
flags.event_type.tick <= FALSE;
flags.peak_number <= (others => '0');
flags.peak_overflow <= FALSE;
flags.height <= CFD_HEIGHT_D;
flags.timing <= CFD_LOW_TIMING_D;
flags.channel <= (others => '0');
flags.new_window <= FALSE;

stream_int.last <= (0 => TRUE, others => FALSE);
stream_int.discard <= (others => FALSE);
stream_int.data <= to_std_logic(seq) &to_std_logic(seq) & to_std_logic(flags) &
                   to_std_logic(seq); 

gen:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      seq <= (others => '0');
      valid_int <= FALSE;
    else
      valid_int <= TRUE;
      if ready then
        seq <= seq + 1;
      end if;
    end if;
  end if;
end process gen;


end architecture RTL;
