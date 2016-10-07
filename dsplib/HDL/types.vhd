library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is

-- fir configuration
type fir_control_in_t is record
  config_data:std_logic_vector(7 downto 0);
  config_valid:std_logic;
  reload_data:std_logic_vector(31 downto 0);
  reload_valid:std_logic;
  reload_last:std_logic;
end record;

type fir_control_out_t is record
  config_ready:std_logic;
  reload_ready:std_logic;
	last_missing:std_logic;
 	last_unexpected:std_logic;
end record;

type fir_ctl_in_array is array (natural range <>) of fir_control_in_t;
type fir_ctl_out_array is array (natural range <>) of fir_control_out_t;
  
end package types;

package body types is
  
end package body types;
