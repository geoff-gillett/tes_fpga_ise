
--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:21/03/2014 
--
-- Design Name: TES_digitiser
-- Module Name: ram_serialiser
-- Project Name: teslib
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

--! buffer from RAM to stream interface, handling ram read latency
entity first_word_fall_through is
generic(
  LATENCY:integer:=2;
  DATA_BITS:integer:=8
);
port(
  clk:in std_logic;
  -- synchronous reset
  reset:in std_logic;
  --
  read:out boolean;
  read_en:in boolean; 
  last_read:in boolean; --used to generate last signal
  -- ram data
  data:in std_logic_vector(DATA_BITS-1 downto 0);
  --! stream interface
  stream:out std_logic_vector(DATA_BITS-1 downto 0);
  ready:in boolean;
  valid:out boolean;
  last:out boolean
);
end entity first_word_fall_through;
--
architecture FSM of first_word_fall_through is
--
subtype ramword is std_logic_vector(DATA_BITS-1 downto 0);
type pipe is array (natural range <>) of ramword;
signal data_shifter:pipe(1 to LATENCY);
attribute shreg_extract:string;
attribute shreg_extract of data_shifter:signal is "NO";
signal valid_int,valid_read,last_int,read_stream,ready_int,data_valid:boolean;
signal valid_read_pipe,last_read_pipe,last_shifter:boolean_vector(1 to LATENCY);
attribute shreg_extract of valid_read_pipe,last_read_pipe,last_shifter:
					signal is "NO";
signal read_en_pipe:boolean_vector(1 to LATENCY);
signal stream_int:ramword;
signal shift_addr:integer range 0 to LATENCY;
signal read_ram:boolean;
--
begin

read <= read_ram;
stream <= stream_int;
valid <= valid_int;
last <= last_int;
--FIXME why extra signal?
ready_int <= ready;
read_stream <= (valid_int and ready_int) or not valid_int; -- stream read
--

shiftLogic:entity work.serialiser_logic
generic map(LATENCY => LATENCY)
port map(
 clk => clk,
 reset => reset,
 address => shift_addr,
 read_ram => read_ram,
 read_ram_pipe => valid_read_pipe,
 read_stream => read_stream
);
--
valid_read <= read_ram and read_en;
streamRegisters:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    valid_int <= FALSE; 
    stream_int <= (others => '-');
    valid_read_pipe <= (others => FALSE);
    last_read_pipe <= (others => FALSE);
  else
    -- pipelines handling read latency
    read_en_pipe <= read_en & read_en_pipe(1 to LATENCY-1);
    valid_read_pipe <= valid_read & valid_read_pipe(1 to LATENCY-1);
    -- valid_read_pipe <= read_en  & valid_read_pipe(1 to LATENCY-1);
    last_read_pipe <= last_read & last_read_pipe(1 to LATENCY-1);
    if read_stream then
      if shift_addr=0 then
        stream_int <= data;
        valid_int <= valid_read_pipe(LATENCY);
        last_int <= last_read_pipe(LATENCY) and valid_read_pipe(LATENCY);
      else
        stream_int <= data_shifter(shift_addr);
        valid_int <= TRUE;
        last_int <= last_shifter(shift_addr);
      end if;
    end if;
    data_valid <= valid_read_pipe(LATENCY-1);
    if valid_read_pipe(LATENCY) then
      data_shifter <= data & data_shifter(1 to LATENCY-1);
      last_shifter <= last_read_pipe(LATENCY) & last_shifter(1 to LATENCY-1);
    end if;
  end if;
end if;
end process streamRegisters;
end architecture FSM;
