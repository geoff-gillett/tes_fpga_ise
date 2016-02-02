--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Nov 2015
--
-- Design Name: TES_digitiser
-- Module Name: eventstream_select
-- Project Name: TES_digitiser 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;
use teslib.functions.all;
--
library streamlib;
use streamlib.stream.all;

--reads the selected stream into registers until a last is set
-- changes to sel are ignored until the last is read into registers 
entity eventstream_selector is
generic(
	-- number of input streams (MAX 12)
  CHANNELS:integer:=9
);
port(
	clk:in std_logic;
	reset:in std_logic;
  --
  sel:in boolean_vector(CHANNELS-1 downto 0);
  --mux sel stream until last read
  go:in boolean;
 	-- last read into register slice (combinatorial)
  done:out boolean;
  instreams:in streambus_array(CHANNELS-1 downto 0);
  valids:in boolean_vector(CHANNELS-1 downto 0);
  readys:out boolean_vector(CHANNELS-1 downto 0);
  --
  mux_stream:out streambus_t;
	mux_valid:out boolean;
	mux_ready:in boolean
);
end entity eventstream_selector;

architecture frame_wise of eventstream_selector is
	
type input_array is array(0 to BUS_BITS-1) of 
										std_logic_vector(CHANNELS-1 downto 0);
signal mux_inputs:input_array;
signal unused:std_logic_vector(12-CHANNELS-1 downto 0):=(others => '0');
signal muxstream_valid:std_logic;
signal valid:boolean;
signal input_streamvectors:streamvector_array(CHANNELS-1 downto 0);
signal muxstream_vector:streamvector_t;

type inputFSMstate is (IDLE,WAIT_LAST);
signal state,nextstate:inputFSMstate;

signal sel_int:boolean_vector(CHANNELS-1 downto 0);
--signal selected:boolean;
signal input_lasts:boolean_vector(CHANNELS-1 downto 0);
signal ready:boolean;
signal muxstream_last:std_logic;
signal last:boolean;

begin

--mux_valid <= to_boolean(mux_valid_int);
--mux_stream <= to_streambus(muxstream_vector);

FSMnextstate:process(clk)
begin
if rising_edge(clk) then
  if reset = '1' then
    state <= IDLE;
  else
    state <= nextstate;
  end if;
end if;
end process FSMnextstate;

--selected <= unaryOR(sel);
FSMtransition:process(state,last,ready,go,sel_int,muxstream_valid)
begin
	nextstate <= state;	
	readys <= (others => FALSE);
	valid <= FALSE;
	case state is 
	when IDLE =>
		if go then
			nextstate <= WAIT_LAST;	
		end if;
	when WAIT_LAST =>
		valid <= to_boolean(muxstream_valid);
		if ready then
			readys <= sel_int; -- FIXME this goes in then out
		end if;
		if last then
			nextstate <= IDLE;
		end if;
	end case;
end process FSMtransition;

selReg:process(clk)
begin
	if rising_edge(clk) then
		if reset = '1' then
			sel_int <= (others => FALSE);
		else
			if go and state=IDLE then
				sel_int <= sel;
			elsif last then
				sel_int <= (others => FALSE);
			end if;
		end if;
	end if;
end process selReg;

done <= last;
input_streamvectors <= to_std_logic(instreams);	

muxGen:for bit in 0 to BUS_BITS-1 generate
begin
	-- transpose streamvector_array 
	chanGen:for chan in 0 to CHANNELS-1 generate
	begin
		mux_inputs(bit)(chan) <= input_streamvectors(chan)(bit);
	end generate;
	
	selector:entity teslib.select_1of12
  port map(
    input=> (unused & mux_inputs(bit)),
    sel => (unused & to_std_logic(sel)),
    output => muxstream_vector(bit)
  );
end generate;

lastGen:for chan in 0 to CHANNELS-1 generate
begin
	input_lasts(chan) <= instreams(chan).last(0);
end generate;

lastMux:entity teslib.select_1of12
port map(
  input => (unused & to_std_logic(input_lasts)),
  sel => (unused & to_std_logic(sel)),
  output => muxstream_last
);

validMux:entity teslib.select_1of12
port map(
  input => (unused & to_std_logic(valids)),
  sel => (unused & to_std_logic(sel)),
  output => muxstream_valid
);

last <= muxstream_last='1' and muxstream_valid='1' and ready;



streamRegisters:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => to_streambus(muxstream_vector),
  ready_out => ready,
  valid_in => valid,
  stream => mux_stream,
  ready => mux_ready,
  valid => mux_valid
);

end architecture frame_wise;
