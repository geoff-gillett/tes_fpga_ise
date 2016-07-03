library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library streamlib;
use streamlib.types.all;

use work.events.all;
use work.registers.all;
use work.ethernet.all;

entity packet_generator is
port (
  clk:in std_logic;
  reset:in std_logic;
  period:in unsigned(31 downto 0);
  stream:out streambus_t;
  ready:in boolean;
  valid:out boolean
);
end entity packet_generator;

architecture RTL of packet_generator is
signal header:ethernet_header_t;
type FSMstate is (IDLE,H0,H1,H2,P1,P2,P3,P4,P5);
signal state,nextstate:FSMstate;
signal seq_count:unsigned(15 downto 0);
signal stream_int:streambus_t;
signal ready_int:boolean;
signal valid_int:boolean;
signal send:boolean;
signal t_counter,period_int:unsigned(31 downto 0);

begin
header.destination_address <= X"da0102030405";
header.source_address <= X"5a0102030405";
header.frame_sequence <= seq_count;
header.protocol_sequence <= seq_count;
header.frame_type.detection <= PEAK_DETECTION_D; 
header.frame_type.tick <= FALSE; 
header.ethernet_type <= X"85BB";
header.length <= X"4000";

seq:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      seq_count <= (others => '0');
    else
      if stream_int.last(0) then
        seq_count <= seq_count+1;
      end if;
    end if;
  end if;
end process seq;

timeCounter:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      t_counter <= (others => '0');
      period_int <= period;
      send <= FALSE;
    else
      if state=IDLE then
        period_int <= period;
      end if;
      if t_counter = period_int then
        t_counter <= (others => '0');
        send <= TRUE;
      else
        send <= FALSE;
        t_counter <= t_counter+1;
      end if;
    end if;
  end if;
end process timeCounter;

fsmNextState:process (clk) is
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= IDLE;
    else
      state <= nextstate;
    end if;
  end if;
end process fsmNextState;

fsmTransition:process(state,ready_int,header,send)
begin
  nextstate <= state;
  stream_int.discard <= (others => FALSE);
  stream_int.last <= (others => FALSE);
  stream_int.data <= (others => '0');
  case state is 
  when IDLE =>
    if send then
      nextstate <= H0;  
    end if;
    valid_int <= FALSE;
  when H0 =>
    if ready_int then
      nextstate <= H1;  
    end if;
    valid_int <= TRUE;
    stream_int.data <= to_std_logic(header,0,"LITTLE");
  when H1 =>
    if ready_int then
      nextstate <= H2;  
    end if;
    valid_int <= TRUE;
    stream_int.data <= to_std_logic(header,1,"LITTLE");
  when H2 =>
    if ready_int then
      nextstate <= P5;  
    end if;
    valid_int <= TRUE;
    stream_int.data <= to_std_logic(header,2,"LITTLE");
  when P1 =>
    if ready_int then
      nextstate <= P2;  
    end if;
    valid_int <= TRUE;
  when P2 =>
    if ready_int then
      nextstate <= P3;  
    end if;
    valid_int <= TRUE;
  when P3 =>
    if ready_int then
      nextstate <= P4;  
    end if;
    valid_int <= TRUE;
  when P4 =>
    if ready_int then
      nextstate <= P5;  
    end if;
    valid_int <= TRUE;
  when P5 =>
    if ready_int then
      nextstate <= IDLE;  
    end if;
    valid_int <= TRUE;
    stream_int.last(0) <= TRUE;
  end case;
end process fsmTransition;

reg:entity streamlib.streambus_register_slice
port map(
  clk => clk,
  reset => reset,
  stream_in => stream_int,
  ready_out => ready_int,
  valid_in => valid_int,
  stream => stream,
  ready => ready,
  valid => valid
);
  
end architecture RTL;
