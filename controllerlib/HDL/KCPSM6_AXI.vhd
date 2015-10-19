--------------------------------------------------------------------------------
-- Company: Quantum Technology Laboratory
-- Engineer: Geoff Gillett
-- Date:12/11/2013 
--
-- Design Name: TES_digitiser
-- Module Name: KCPSM
-- Project Name: TES_Library
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package KCPSM6_AXI is
-- constants
constant RESP_BIT0:integer:=4; --LSB of the response in the in_port;

-- IO ports
constant UART_IO_PORTID_BIT:integer:=0; 
constant SPI_IO_PORTID_BIT:integer:=1;
constant BYTE0_IO_PORTID_BIT:integer:=2;
constant BYTE1_IO_PORTID_BIT:integer:=3;
constant BYTE2_IO_PORTID_BIT:integer:=4;
constant BYTE3_IO_PORTID_BIT:integer:=5;

-- General input ports
constant RESP_IN_PORTID_BIT:integer:=6;
constant STATUS_IN_PORTID_BIT:integer:=7;

-- General output ports
-- TES UART channel select 
-- 00000000 output port_id used for control unit local register address
constant CHAN_SEL_O_PORTID_BIT:integer:=6;
constant SPI_SEL_O_PORTID_BIT:integer:=7;

-- ADC SPI chip selects
-- SPI_IO_PORT_BITs
constant SPI_IO_PORT_MOSI_BIT:integer:=7;
constant SPI_IO_PORT_CLK_BIT:integer:=0; 

-- status bits
constant STATUS_TX_NOTEMPTY_BIT:integer:=0;
--constant STATUS_CHAN_TX_NOTEMPTY_BIT:integer:=1;
constant STATUS_TX_FULL_BIT:integer:=1;
--constant STATUS_CHAN_TX_FULL_BIT:integer:=3;
constant STATUS_RX_NOTEMPTY_BIT:integer:=2;
--constant STATUS_CHAN_RX_NOTEMPTY_BIT:integer:=5;
constant STATUS_FMC_PRESENT_BIT:integer:=3;
constant STATUS_FMC_POWER_BIT:integer:=4;
constant STATUS_FMC_AD9510_BIT:integer:=5;
constant STATUS_PIPELINE_LOCK_BIT:integer:=6;
--constant STATUS_AXI_HANDSHAKE_BIT:integer:=7;

-- IO selection
constant IO_SEL_COO_PORTID_BIT:integer:=0;
constant SEL_ADDRESS_BIT:integer:=0;
constant SEL_DATA_BIT:integer:=1;
-- note the UART selects are independent of the others 
constant SEL_MAIN_UART_BIT:integer:=5;
constant SEL_CHAN_UART_BIT:integer:=6;
--constant SEL_REGISTER_READ_BIT:integer:=7; -- keep as MSB

--control strobes
constant CONTROL_COO_PORTID_BIT:integer:=1;
constant CONTROL_RESET_UART_TX_BIT:integer:=0;
constant CONTROL_RESET_UART_RX_BIT:integer:=1;
constant CONTROL_RESET_SYSTEM_BIT:integer:=2;
constant CONTROL_REG_WRITE_BIT:integer:=3;
constant CONTROL_TEST_BIT:integer:=4;
--
constant RESET_COO_PORTID_BIT:integer:=2;
constant RESET_SYSTEM_BIT:integer:=0;
constant RESET_TIER0:integer:=1;
constant RESET_TIER1:integer:=2;
constant RESET_TIER2:integer:=3;
--------------------------------------------------------------------------------
end package;
package body KCPSM6_AXI is  
end;
