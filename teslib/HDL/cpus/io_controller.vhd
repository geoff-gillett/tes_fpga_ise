--------------------------------------------------------------------------------
-- Company: Quantum Technology Laboratory
-- Engineer: Geoff Gillett
-- Date:Oct 17, 2013 
--
-- Design Name: TES_digitiser
-- Module Name: control_unit
-- Project Name: control_unit
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
use work.functions.all;

use work.KCPSM6_AXI.all;

--! Control unit -- CPU receives and responds to commands over the USB UART
--! interface.
entity control_unit is
generic(
  TES_CHANNEL_BITS:integer:=3;
  ADC_CHIPS:integer:=4
  --SPI_CHANNELS:integer:=4
);
port(
  --!* system signals
  clk:in std_logic;
  LEDs:out std_logic_vector(7 downto 0);
  --!* main UART connected to the host PC
  --reset1:in std_logic;
  global_reset:in std_logic;
  ------------------------------------------------------------------------------
  -- FMC status
  ------------------------------------------------------------------------------
  FMC_power_good:in std_logic;
  FMC_present:in std_logic;
  FMC_AD9510_status:in std_logic;
  pipeline_mmcm_locked:in std_logic;
  ------------------------------------------------------------------------------
  -- resets
  ------------------------------------------------------------------------------
  reset0:out std_logic; --channel cpus ethernet
  reset1:out std_logic; --buses
  reset2:out std_logic; --adc pipline also triggered by changing adc_enables
  ------------------------------------------------------------------------------
  -- Interrupts from MCA
  ------------------------------------------------------------------------------
  interrupt:in boolean; -- interrupt
  interrupt_ack:out boolean;
  ------------------------------------------------------------------------------
  --!* UART communication with HOST and channel CPUs
  ------------------------------------------------------------------------------
  main_rx:in std_logic;
  main_tx:out std_logic;
  channel_rx:in std_logic_vector(2**TES_CHANNEL_BITS-1 downto 0);
  channel_tx:out std_logic_vector(2**TES_CHANNEL_BITS-1 downto 0);
  ------------------------------------------------------------------------------
  --!* SPI communication 
  ------------------------------------------------------------------------------
  spi_clk:out std_logic;
  spi_ce_n:out std_logic_vector(ADC_CHIPS downto 0);
  spi_miso:in std_logic_vector(ADC_CHIPS downto 0);
  spi_mosi:out std_logic;
  ------------------------------------------------------------------------------
  -- Global Register IO
  ------------------------------------------------------------------------------
  address:out registeraddress_t;
  data_out:out registerdata_t;
  data_in:in registerdata_t;
  write:out boolean --flag
  ------------------------------------------------------------------------------
  --!* AXI lite master interface to the system
  --TODO rework the AXI its currently not used
  --But should be used to control the TEMAC to add jumbo frames/statistics
  ------------------------------------------------------------------------------
);
end entity control_unit;
--
architecture picoblaze_AXI of control_unit is
  
constant TES_CHANNELS:integer:=2**TES_CHANNEL_BITS;
constant SPI_CHANNELS:integer:=ADC_CHIPS+1;
--
--------------------------------------------------------------------------------
--Signals used to connect KCPSM6
--------------------------------------------------------------------------------
signal program_address:std_logic_vector(11 downto 0);
signal instruction:std_logic_vector(17 downto 0);
signal bram_enable:std_logic;
signal in_port:std_logic_vector(7 downto 0);
signal out_port:std_logic_vector(7 downto 0);
signal port_id:std_logic_vector(7 downto 0);
signal write_strobe:std_logic;
signal k_write_strobe: std_logic;
signal read_strobe:std_logic;
signal kcpsm6_sleep:std_logic;
--------------------------------------------------------------------------------
--signals used to connect the main uart
--------------------------------------------------------------------------------
signal rx_not_empty:std_logic;
signal tx_full:std_logic;
signal tx_not_empty:std_logic;
signal uart_rx_byte:std_logic_vector(7 downto 0);
signal main_uart_sel:boolean; --true io through main uart otherwise the chan
--------------------------------------------------------------------------------
--Channel UART signals
--------------------------------------------------------------------------------
signal channel_sel:std_logic_vector(TES_CHANNELS-1 downto 0):=(others => '0');
signal channel_tx_int:std_logic_vector(TES_CHANNELS-1 downto 0);
--Signals used to define baud rate
signal baud_count:integer range 0 to 67:=0;
signal en_16_x_baud:std_logic:= '0';
--------------------------------------------------------------------------------
--Signals for register IO
--------------------------------------------------------------------------------
signal IO_sel:std_logic_vector(7 downto 0);
signal byte_sel:std_logic_vector(3 downto 0);
signal cpu_reset,reset0_int,reset1_int,reset2_int:std_logic;
--
signal uart_rd_en:std_logic;
signal uart_wr_en:std_logic;
signal uart_din:std_logic_vector(7 downto 0);
signal serial_out:std_logic;
signal serial_in:std_logic;
signal serial_out_reg:std_logic;
signal serial_in_reg:std_logic;
signal uart_reset_tx:std_logic;
signal uart_reset_rx:std_logic;
--
signal test_regs:std_logic_vector(7 downto 0):=(others => '0');
signal spi_ce_n_int:std_logic_vector(SPI_CHANNELS-1 downto 0):=(others => '1');
signal spi_clk_int:std_logic;
signal uart_reset_tx_int:std_logic;
signal uart_reset_rx_int:std_logic;
signal spi_mosi_int:std_logic;
--- 
signal byte_from_registers:std_logic_vector(7 downto 0);
signal write_byte_to_address:boolean;
signal write_byte_to_data:boolean;
signal interrupt_ack_int:std_logic;
--
begin
interrupt_ack <= to_boolean(interrupt_ack_int);
reset0 <= reset0_int;
reset1 <= reset1_int;
reset2 <= reset2_int;
spi_ce_n <= spi_ce_n_int;
spi_clk <= spi_clk_int;
spi_mosi <= spi_mosi_int;
--
--LEDs(SPI_CHANNELS-1 downto 0) <= not spi_ce_n_int;
LEDs <= (others => '0');
--
debug:process(clk)
begin
if rising_edge(clk) then
  if k_write_strobe='1' and port_id(CONTROL_COO_PORTID_BIT)='1' and 
     out_port(CONTROL_TEST_BIT)='1' 
  then
    test_regs(1) <= not test_regs(1);
  end if;
  if uart_wr_en='1' then
    test_regs(2) <= not test_regs(2);
  end if;
  if serial_out_reg='0' then
    test_regs(7) <=  '1';
  end if;
  if serial_in_reg='0' then
    test_regs(6) <= '1';
  end if;
end if;
end process debug;
--------------------------------------------------------------------------------
-- reset sequencer
--------------------------------------------------------------------------------
resetSequencer:process(clk)
begin
if rising_edge(clk) then
  if global_reset='1' then
    cpu_reset <= '1';
    reset0_int <= '1';
    reset1_int <= '1';
    reset2_int <= '1';
  else
    cpu_reset <= '0';
    if k_write_strobe='1' and port_id(RESET_COO_PORTID_BIT)='1' then
      cpu_reset <= out_port(RESET_SYSTEM_BIT);
      reset0_int <= out_port(RESET_TIER0);
      reset1_int <= out_port(RESET_TIER1);
      reset2_int <= out_port(RESET_TIER2);
    end if;
  end if;
end if;
end process resetSequencer;
--------------------------------------------------------------------------------
--Picoblaze CPU and UARTs
--------------------------------------------------------------------------------
CPU:entity work.kcpsm6
generic map(
  HWBUILD => to_std_logic(to_unsigned(ADC_CHIPS,4) & 
               to_unsigned(TES_CHANNEL_BITS,4)
             ), 
  INTERRUPT_VECTOR => X"7F0",
  SCRATCH_PAD_MEMORY_SIZE => 64
)
port map(
  address => program_address,
  instruction => instruction,
  bram_enable => bram_enable,
  port_id => port_id,
  write_strobe => write_strobe,
  k_write_strobe => k_write_strobe,
  out_port => out_port,
  read_strobe => read_strobe,
  in_port => in_port,
  interrupt => interrupt_ack_int,
  interrupt_ack => interrupt_ack_int,
  sleep => kcpsm6_sleep,
  reset => cpu_reset,
  clk => clk
);
-- Reset connected to JTAG Loader enabled Program Memory 
--kcpsm6_reset <= global_reset or cpu_reset or rdl;
kcpsm6_sleep <= '0';

programROM:entity work.IO_controller_program
port map(
  address => program_address,
  instruction => instruction,
  enable => bram_enable,
  clk => clk
);
--------------------------------------------------------------------------------
--RS232 (UART) baud rate 
--------------------------------------------------------------------------------
-- To set serial communication baud rate to 115,200 then en_16_x_baud must pulse 
-- High at 1,843,200Hz which is every 67.81 cycles at 125MHz. In this 
-- implementation a pulse is generated every 68 cycles.
baudRate:process(clk)
begin
if rising_edge(clk) then
  if baud_count=67 then                 -- counts 68 states including zero
    baud_count <= 0;
    en_16_x_baud <= '1';                -- single cycle enable pulse
   else
    baud_count <= baud_count+1;
    en_16_x_baud <= '0';
  end if;
end if;
end process baudRate;
--------------------------------------------------------------------------------
-- UART Transmitter
--------------------------------------------------------------------------------
uartTx:entity work.uart_tx6
port map(
  data_in => uart_din,
  en_16_x_baud => en_16_x_baud,
  serial_out => serial_out,
  buffer_write => uart_wr_en,
  buffer_data_present => tx_not_empty,
  buffer_half_full => open,
  buffer_full => tx_full,
  buffer_reset => uart_reset_tx_int,
  clk => clk
);
uart_reset_tx_int <= uart_reset_tx or reset2_int;
main_tx <= serial_out_reg when main_uart_sel else '1';
channel_tx_int <= (others => serial_out_reg) when not main_uart_sel 
               else (others => '1');
channel_tx <= (not channel_sel) or channel_tx_int;
-- registering the serial signals is necessary to avoid a MAP error
regUart:process(clk)
begin
if rising_edge(clk) then
  serial_out_reg <= serial_out;
  serial_in_reg <= serial_in;
  uart_din <= out_port;
  uart_wr_en <= write_strobe and port_id(UART_IO_PORTID_BIT);
end if;
end process regUart;
--------------------------------------------------------------------------------
-- UART Receiver
--------------------------------------------------------------------------------
uartRx:entity work.uart_rx6
port map(
  serial_in => serial_in_reg, --main_Rx,
  en_16_x_baud => en_16_x_baud,
  data_out => uart_rx_byte,
  buffer_read => uart_rd_en,
  buffer_data_present => rx_not_empty,
  buffer_half_full => open,
  buffer_full => open,
  buffer_reset => uart_reset_rx_int,
  clk => clk
);
uart_reset_rx_int <= uart_reset_rx or reset2_int;
serial_in <= main_rx when main_uart_sel 
             else to_std_logic(unaryOR(channel_rx and channel_sel));
uart_rd_en <= read_strobe and port_id(UART_IO_PORTID_BIT);
--------------------------------------------------------------------------------
-- CPU IO ports 
--------------------------------------------------------------------------------
IOselect:process(clk)
begin
if rising_edge(clk) then
  if reset0_int='1' then
    IO_sel <= (others => '0');
  else
    if k_write_strobe='1' and port_id(IO_SEL_COO_PORTID_BIT)='1' then
      IO_sel <= out_port;
    end if;
  end if;
end if;
end process IOselect;
-- CPU input port mux
inportMux:process(clk)
begin
if rising_edge(clk) then
  if cpu_reset = '1' then
    in_port <= (others => '0');
  else
    if  port_id(UART_IO_PORTID_BIT)='1' then
      in_port <= uart_rx_byte;
    elsif port_id(SPI_IO_PORTID_BIT)='1' then
      in_port <= std_logic_vector(to_unsigned(0,8-SPI_CHANNELS)) & spi_miso;
    elsif byte_sel /= "0000" then
      in_port <= byte_from_registers;
    elsif port_id(STATUS_IN_PORTID_BIT)='1' then
      in_port <= (STATUS_TX_NOTEMPTY_BIT => tx_not_empty,
                  STATUS_TX_FULL_BIT => tx_full,
                  STATUS_RX_NOTEMPTY_BIT => rx_not_empty,
                  STATUS_FMC_PRESENT_BIT => FMC_present,
                  STATUS_FMC_POWER_BIT => FMC_power_good,
                  STATUS_FMC_AD9510_BIT => FMC_AD9510_status,
                  STATUS_PIPELINE_LOCK_BIT => pipeline_mmcm_locked,
                  others => '-');
    else
     in_port <= (others => '-');
    end if;
  end if;
end if;
end process inportMux;
--
byte_sel <= port_id(BYTE3_IO_PORTID_BIT downto BYTE0_IO_PORTID_BIT);
write_byte_to_address <= write_strobe='1' and 
                         byte_sel/="0000" and IO_sel(SEL_ADDRESS_BIT)='1';
write_byte_to_data <= write_strobe='1' and 
                      byte_sel/="0000" and IO_sel(SEL_DATA_BIT)='1';
--
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
--------------------------------------------------------------------------------
-- SPI communication
--------------------------------------------------------------------------------
SPIselect:process(clk)
begin
if rising_edge(clk) then
  if reset0_int='1' then
    spi_ce_n_int <= (others => '1');
  else
    if write_strobe='1' and port_id(SPI_SEL_O_PORTID_BIT)='1' then
      spi_ce_n_int <= not out_port(SPI_CHANNELS-1 downto 0);
    end if;
  end if;
end if;
end process SPIselect;
--
SPIoutput:process(clk)
begin
if rising_edge(clk) then
  if reset0_int='1' then
    spi_mosi_int <= '0';
    spi_clk_int <= '0';
  else
    if write_strobe='1' and port_id(SPI_IO_PORTID_BIT)='1' then
      spi_mosi_int <= out_port(SPI_IO_PORT_MOSI_BIT);
      spi_clk_int <= out_port(SPI_IO_PORT_CLK_BIT);
    end if;
  end if;
end if;
end process SPIoutput;
--------------------------------------------------------------------------------
-- UART IO: main_uart_sel=TRUE IO between PC and control_unit
-- else between control_unit and active channel (channel_sel)
--------------------------------------------------------------------------------
UARTselect:process(clk)
begin
if rising_edge(clk) then
  if reset0_int= '1' then
    main_uart_sel <= TRUE;
  else
    if k_write_strobe='1' and port_id(IO_SEL_COO_PORTID_BIT)='1' then
      if out_port(SEL_MAIN_UART_BIT)='1' then
        main_uart_sel <= TRUE;   
      elsif out_port(SEL_CHAN_UART_BIT)='1' then
        main_uart_sel <= FALSE; 
      end if;
    end if;
  end if;
end if;
end process UARTselect;
-- when main_uart_sel=FALSE selects which channel the UART communicates with 
channelSelect:process(clk)
begin
if rising_edge(clk) then
  if write_strobe='1' and port_id(CHAN_SEL_O_PORTID_BIT)='1' then
    channel_sel <= out_port(TES_CHANNELS-1 downto 0);
  end if;
end if;
end process channelSelect;
--------------------------------------------------------------------------------
--control strobes 
--------------------------------------------------------------------------------
uart_reset_tx <= k_write_strobe and port_id(CONTROL_COO_PORTID_BIT) and 
                 out_port(CONTROL_RESET_UART_TX_BIT);
uart_reset_rx <= k_write_strobe and port_id(CONTROL_COO_PORTID_BIT) and
                 out_port(CONTROL_RESET_UART_RX_BIT);
write <= to_boolean(
           k_write_strobe and port_id(CONTROL_COO_PORTID_BIT) and
           out_port(CONTROL_REG_WRITE_BIT)
         );
--
end architecture picoblaze_AXI;
