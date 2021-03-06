--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Apr 2016
--
-- Design Name: TES_digitiser
-- Module Name: stream_cdc
-- Project Name: streamlib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.FDRE;

library extensions;
use extensions.boolean_vector.all;

-- lots of wait states but OK for the register IO to the FIRs
entity stream_cdc is
generic(
  WIDTH:integer:=72
);
port (
	-- sending clock domain
  s_clk:in std_logic;
  s_reset:in std_logic;
  s_stream:in std_logic_vector(WIDTH-1 downto 0);
  s_valid:in boolean;
  s_ready:out boolean;
	-- receiving clock domain
  r_clk:in std_logic;
  r_reset:in std_logic;
  r_stream:out std_logic_vector(WIDTH-1 downto 0);
  r_valid:out boolean;
  r_ready:in boolean
);
end entity stream_cdc;

architecture xilinx_unisim of stream_cdc is
-- TODO and attribute to not infer ram	
type twodeep is array (0 to 1) of std_logic_vector(WIDTH-1 downto 0);
signal store:twodeep;
signal r_ptr_rclk,r_ptr_sclk,w_ptr_sclk,w_ptr_rclk,w_sync,r_sync:std_logic;
signal s_valid_int,s_ready_int,r_valid_int,r_ready_int:std_logic;

attribute ASYNC_REG:string;
attribute ASYNC_REG of w_ptr_sclk:signal is "TRUE";
attribute ASYNC_REG of r_ptr_rclk:signal is "TRUE";

--FIXME need two RLOC sets? wsyncs need to be in the same slice and rsyncs need 
-- to be in the same slice but the relative placement of the two slices need not
-- be constrained.
attribute RLOC:string;
attribute RLOC of wsync1:label is "X0Y0";
attribute RLOC of wsync2:label is "X0Y0";
attribute RLOC of rsync1:label is "X0Y1";
attribute RLOC of rsync2:label is "X0Y1";

begin
s_ready <= to_boolean(s_ready_int);
s_valid_int <= to_std_logic(s_valid);
r_valid <= to_boolean(r_valid_int);
r_ready_int <= to_std_logic(r_ready);

writeport:process(s_clk) 
begin
	if rising_edge(s_clk) then
		if s_reset = '1' then
			w_ptr_sclk <= '0';
		else
			w_ptr_sclk <= w_ptr_sclk xor (s_valid_int and s_ready_int);
			if (s_ready_int and s_valid_int) = '1' then
				if w_ptr_sclk = '0' then
					store(0) <= s_stream;
				else
					store(1) <= s_stream;
				end if;
--        if (r_ready_int and r_valid_int) = '1' then
--          if r_ptr_rclk = '0' then
--            r_stream <= store(0);
--          else
--            r_stream <= store(1);
--          end if;
--        end if; 
			end if; 
		end if;
	end if;
end process writeport;
s_ready_int <= not (w_ptr_sclk xor r_ptr_sclk);

readport:process(r_clk) 
begin
	if rising_edge(r_clk) then
		if r_reset = '1' then
			r_ptr_rclk <= '0';
--			r_stream <= (others => '-');
		else
			r_ptr_rclk <= r_ptr_rclk xor (r_valid_int and r_ready_int);
--			if (r_ready_int and r_valid_int) = '1' then
--				if r_ptr_rclk = '0' then
--					r_stream <= store(0);
--				else
--					r_stream <= store(1);
--				end if;
--			end if; 
		end if;
	end if;
end process readport;
r_valid_int <=  (w_ptr_rclk xor r_ptr_rclk);

output:process(r_ptr_rclk,store(0),store(1))
begin
--  if (r_ready_int and r_valid_int) = '1' then
    if r_ptr_rclk = '0' then
      r_stream <= store(0);
    else
      r_stream <= store(1);
    end if;
--  end if; 
end process output;

wsync1:FDRE
generic map(
	INIT => '0'
)
port map(
  ce => '1',
  r => r_reset,
  C => r_clk,
  D => w_ptr_sclk,
  Q => w_sync
);

wsync2:FDRE
generic map(
	INIT => '0'
)
port map(
  ce => '1',
  r => r_reset,
  C => r_clk,
  D => w_sync,
  Q => w_ptr_rclk
);

rsync1:FDRE
generic map(
	INIT => '0'
)
port map(
  ce => '1',
  r => s_reset,
  C => s_clk,
  D => r_ptr_rclk,
  Q => r_sync
);

rsync2:FDRE
generic map(
	INIT => '0'
)
port map(
  ce => '1',
  r => s_reset,
  C => s_clk,
  D => r_sync,
  Q => r_ptr_sclk
);

end architecture xilinx_unisim;
