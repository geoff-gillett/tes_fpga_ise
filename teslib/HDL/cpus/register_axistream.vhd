--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:10 Apr 2016
--
-- Design Name: TES_digitiser
-- Module Name: register_axistream
-- Project Name: teslib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;

library streamlib;

use work.types.all;

-- expects s_clk 2*reg_clk
entity register_axistream is
generic(
	DATA_BITS:integer:=25
);
port (
	-- reg_clk domian
	reg_clk:in std_logic;
  reg_reset:in std_logic;
  data:in std_logic_vector(DATA_BITS-1 downto 0);
  write:in boolean;  -- strobe
  reg_last:in boolean;
  axis_done:out boolean;
  axis_error:out boolean; 
  axis_ready:out boolean;
  
  --stream_clk domain
  stream_clk:std_logic;
  stream_reset:std_logic;
  last_error:in boolean;
  stream:out std_logic_vector(DATA_BITS-1 downto 0);
  valid:out boolean;
  ready:in boolean;
  last:out boolean
);
end entity register_axistream;

architecture RTL of register_axistream is
	
signal stream_int,reg_data:std_logic_vector(DATA_BITS downto 0);
signal reg_valid,stream_valid,axis_ready_int:boolean;

begin
stream <= stream_int(DATA_BITS-1 downto 0);
last <= to_boolean(stream_int(DATA_BITS));
axis_ready <= axis_ready_int;
valid <= stream_valid;

reg:process (reg_clk) is
begin
	if rising_edge(reg_clk) then
		if reg_reset = '1' then
			reg_valid <= FALSE;
		else
			if write then
				reg_valid <= TRUE;
				reg_data <= to_std_logic(reg_last) & data;
			elsif reg_valid and axis_ready_int then
				reg_valid <= FALSE;
				reg_data <= (others => '-');
			end if;
		end if;
	end if;
end process reg;

cdc:entity streamlib.stream_cdc
generic map(
  WIDTH => DATA_BITS+1
)
port map(
  s_clk => reg_clk,
  s_reset => reg_reset,
  s_stream => reg_data,
  s_valid => reg_valid,
  s_ready => axis_ready_int,
  r_clk => stream_clk,
  r_reset => stream_reset,
  r_stream => stream_int,
  r_valid => stream_valid,
  r_ready => ready
);

flags:process(stream_clk)
begin
	if rising_edge(stream_clk) then
		if stream_reset = '1' then
			axis_done <= FALSE;
			axis_error <= FALSE;
		else
			if stream_valid and ready then
        axis_done <= TRUE;
        axis_error <= last_error;
      elsif reg_valid and axis_ready_int then
        axis_done <= FALSE;
        axis_error <= FALSE;
			end if;
		end if;
	end if;
end process flags;

end architecture RTL;
