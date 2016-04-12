--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:04/01/2014 
--
-- Design Name: TES_digitiser
-- Module Name: channel
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library extensions;
use extensions.boolean_vector.all;

use work.types.all;
use work.functions.all;

use work.KCPSM6_AXI.all;
--
entity channel_controller is
port(
  clk:in std_logic;
  reset:in std_logic;
  
  --!* UART connection to main CPU
  uart_tx:out std_logic;
  uart_rx:in std_logic;
  ------------------------------------------------------------------------------
  -- Register IO
  -- all signals in the IO_clk domain
  ------------------------------------------------------------------------------
  address:out registeraddress_t;
  data_out:out registerdata_t;
  data_in:in registerdata_t;
  write:out boolean --flag
);
end entity channel_controller;
--
architecture picoblaze of channel_controller is
-- KCPSM6 
signal program_counter:std_logic_vector(11 downto 0);
signal instruction:std_logic_vector(17 downto 0);
signal bram_enable:std_logic;
signal in_port:std_logic_vector(7 downto 0);
signal out_port:std_logic_vector(7 downto 0);
signal port_id:std_logic_vector(7 downto 0);
signal write_strobe:std_logic;
signal k_write_strobe:std_logic;
signal read_strobe:std_logic;
signal interrupt:std_logic;
signal interrupt_ack:std_logic;
signal sleep:std_logic;
-- UART signals
signal baud_count:integer range 0 to 67:= 0;
signal en_16_x_baud:std_logic:='0';
signal uart_rx_byte:std_logic_vector(7 downto 0);
signal uart_rd_en:std_logic;
signal uart_wr_en:std_logic;
signal tx_full:std_logic;
signal rx_not_empty:std_logic;
signal tx_not_empty:std_logic;
-- Mux signals
signal byte_sel:std_logic_vector(3 downto 0);
-- transfer registers
signal serial_in : std_logic;
signal serial_out : std_logic;
signal serial_out_reg : std_logic;
signal uart_din : std_logic_vector(7 downto 0);
signal uart_reset_tx : std_logic;
signal uart_reset_rx : std_logic;
--
signal write_byte_to_address:boolean;
signal IO_sel:std_logic_vector(7 downto 0);
signal byte_from_registers:std_logic_vector(7 downto 0);
signal write_byte_to_data:boolean;
--
begin
uart_tx <= serial_out_reg;
--
CPU:entity work.kcpsm6
generic map(
  hwbuild => X"42",
  interrupt_vector => X"7FF",
  scratch_pad_memory_size => 64)
port map(
  address => program_counter,
  instruction => instruction,
  bram_enable => bram_enable,
  in_port => in_port,
  out_port => out_port,
  port_id => port_id,
  write_strobe => write_strobe,
  k_write_strobe => k_write_strobe,
  read_strobe => read_strobe,
  interrupt => interrupt,
  interrupt_ack => interrupt_ack,
  sleep => sleep,
  reset => reset,
  clk => clk
);
interrupt <= '0';
sleep <= '0';
--
programROM:entity work.channel_program
port map(
	address => program_counter,
  instruction => instruction,
  enable => bram_enable,
  clk => clk
);
--
uartRx:entity work.uart_rx6
port map(
  serial_in => serial_in,
  en_16_x_baud => en_16_x_baud,
  data_out => uart_rx_byte,
  buffer_read => uart_rd_en,
  buffer_data_present => rx_not_empty,
  buffer_half_full => open,
  buffer_full => open,
  buffer_reset => uart_reset_rx,
  clk => clk
);

-- registering the serial signals is necessary to avoid a MAP error
-- FIXME USE ASYNC REG
regUart:process (clk) is
begin
  if rising_edge(clk) then
    serial_out_reg <= serial_out;
    serial_in <= uart_rx;
    uart_din <= out_port;
    uart_wr_en <= write_strobe and port_id(UART_IO_PORTID_BIT);
  end if;
end process regUart;
--
uartTx:entity work.uart_tx6
port map(
  data_in => uart_din,
  en_16_x_baud => en_16_x_baud,
  serial_out => serial_out,
  buffer_write => uart_wr_en,
  buffer_data_present => tx_not_empty,
  buffer_half_full => open,
  buffer_full => tx_full,
  buffer_reset => uart_reset_tx,
  clk => clk
);
--
baudRate:process(clk)
begin
if rising_edge(clk) then
  if baud_count = 67 then                 -- counts 67 states including zero
    baud_count <= 0;
    en_16_x_baud <= '1';                  -- single cycle enable pulse
   else
    baud_count <= baud_count+1;
    en_16_x_baud <= '0';
  end if;
end if;
end process baudRate;
--------------------------------------------------------------------------------
--control strobes 
--------------------------------------------------------------------------------
uart_rd_en <= read_strobe and port_id(UART_IO_PORTID_BIT);
uart_reset_tx <= k_write_strobe and port_id(CONTROL_COO_PORTID_BIT) and 
                 out_port(CONTROL_RESET_UART_TX_BIT);
uart_reset_rx <= k_write_strobe and port_id(CONTROL_COO_PORTID_BIT) and
                 out_port(CONTROL_RESET_UART_RX_BIT);
write <= to_boolean(k_write_strobe) and port_id(CONTROL_COO_PORTID_BIT)='1' and
                                        out_port(CONTROL_REG_WRITE_BIT)='1';
--------------------------------------------------------------------------------
-- CPU IO ports 
--------------------------------------------------------------------------------
IOselect:process(clk)
begin
if rising_edge(clk) then
  if reset='1' then
    IO_sel <= (others => '0');
  else
    if k_write_strobe='1' and port_id(IO_SEL_COO_PORTID_BIT)='1' then
      IO_sel <= out_port;
    end if;
  end if;
end if;
end process IOselect;

-- CPU input port mux
byte_sel <= port_id(BYTE3_IO_PORTID_BIT downto BYTE0_IO_PORTID_BIT);
in_port <= uart_rx_byte when port_id(UART_IO_PORTID_BIT)='1' 
                        else byte_from_registers 
                        when byte_sel /= "0000" 
                        else (STATUS_TX_NOTEMPTY_BIT => tx_not_empty,
                              STATUS_TX_FULL_BIT => tx_full,
                              STATUS_RX_NOTEMPTY_BIT => rx_not_empty,
                              others => '-') 
                        when port_id(STATUS_IN_PORTID_BIT)='1' 
                        else (others => '-');
                        	
byte_sel <= port_id(BYTE3_IO_PORTID_BIT downto BYTE0_IO_PORTID_BIT);
write_byte_to_address <= write_strobe='1' and 
                         byte_sel/="0000" and IO_sel(SEL_ADDRESS_BIT)='1';
write_byte_to_data <= write_strobe='1' and 
                      byte_sel/="0000" and IO_sel(SEL_DATA_BIT)='1';
                      
-- Register IO
regIOblock:entity work.register_IO_block
port map(
  clk => clk,
  byte_in => out_port,
  byte_out => byte_from_registers,
  byte_select => byte_sel,
  address_wr => write_byte_to_address,
  data_wr => write_byte_to_data,
  address => address,
  data => data_out,
  read_data => data_in
);
--
end architecture picoblaze;
