library ieee;
use ieee.std_logic_1164.all;

library extensions;
use extensions.boolean_vector.all;

--use work.types.all;
--use work.functions.all;

-- converts leading edge in in_clk domain to pulse in out_clk domain

entity sync_boolean_pulse is
port (
  in_clk:in std_logic;               -- clock to be sync'ed from 
  out_clk:in std_logic;              -- clock to be sync'ed to
  pulse_in:in boolean;               -- pulse to be 'synced'
  pulse_out:out boolean              -- synced pulse
);
end sync_boolean_pulse;

architecture primitive of sync_boolean_pulse is
signal pulse_out_int:std_logic;

begin
pulse_out <= to_boolean(pulse_out_int);

sync:entity work.sync_pulse
port map(
  in_clk => in_clk,
  out_clk => out_clk,
  pulse_in => to_std_logic(pulse_in),
  pulse_out => pulse_out_int
);
end primitive;


