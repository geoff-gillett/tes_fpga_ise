--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:10 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: stream_registers
-- Project Name:streamlib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--
-- 	if (not valid_reg) or valid_reg and ready_in
--	  ready_reg <= TRUE
--		if store_valid 	
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library teslib;
use teslib.types.all;

-- used to break long ready signal paths
entity stream_registers is
generic(STREAM_BITS:integer:=8);
port (
  clk:in std_logic;
  reset:in std_logic;
  -- Input interface
  stream_in:in std_logic_vector(STREAM_BITS-1 downto 0);
  ready_out:out boolean;
  valid_in:in boolean;
  last_in:boolean;
  -- Output interface
  stream:out std_logic_vector(STREAM_BITS-1 downto 0);
  ready:in boolean;
  valid:out boolean;
  last:out boolean
);
end entity stream_registers;
--
architecture RTL of stream_registers is
signal store:std_logic_vector(STREAM_BITS-1 downto 0);
signal valid_int,store_valid,last_int,store_last,ready_int:boolean;
signal sel:boolean_vector(3 downto 0);
--
begin
ready_out <= ready_int;
valid <= valid_int; --valid1 when read_sel='0' else valid2;
last <= last_int;
--
sel(0) <= store_valid;
sel(1) <= valid_int;
sel(2) <= ready_int and valid_in; --read in 
sel(3) <= ready and valid_int; -- read out
reg:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    valid_int <= FALSE;
    store_valid <= FALSE;
    ready_int <= TRUE;
    last_int <= FALSE;
    store_last <= FALSE;
    store <= (others => '-');
  else
    case sel is
		--straight through
    when (FALSE,TRUE,FALSE,FALSE) | (TRUE,TRUE,FALSE,FALSE) |
    		 (TRUE,TRUE,TRUE,FALSE) => 
      valid_int <= TRUE;
      ready_int <= TRUE;
      stream <= stream_in;
      last_int <= last_in;
		--read in no read out, stream valid and store empty
    when (FALSE,TRUE,TRUE,FALSE) => 
      valid_int <= TRUE;
      ready_int <= FALSE;
      store <= stream_in;
      store_last <= last_in;
      store_valid <= TRUE;
    -- no read in read out and full;
    when (TRUE,FALSE,TRUE,TRUE) => 
      valid_int <= TRUE;
      ready_int <= TRUE;
      store <= (others => '-');
      stream <= store;
      last_int <= store_last;
      store_last <= FALSE;
      store_valid <= FALSE;
    -- no read in read out and store empty;
    when (TRUE,FALSE,TRUE,FALSE) => 
      valid_int <= FALSE;
      ready_int <= TRUE;
      last_int <= FALSE;
      stream <= (others => '-');
    when others => 
      null;
    end case;
  end if;
end if;
end process reg;
end architecture RTL;
