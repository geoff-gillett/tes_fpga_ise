library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ML605_TB is
end entity ML605_TB;

architecture RTL of ML605_TB is
  
begin

UUT:entity work.ml605_enet_test
generic map(
  VERSION => VERSION,
  DEFAULT_IODELAY_VALUE => DEFAULT_IODELAY_VALUE,
  ADC_CHIPS => ADC_CHIPS,
  CHIP_CHANNELS => CHIP_CHANNELS,
  ADC_BITS => ADC_BITS,
  DSP_CHANNELS => DSP_CHANNELS,
  EVENT_FRAMER_ADDRESS_BITS => EVENT_FRAMER_ADDRESS_BITS,
  ENET_FRAMER_ADDRESS_BITS => ENET_FRAMER_ADDRESS_BITS,
  MIN_TICKPERIOD => MIN_TICKPERIOD,
  PACKET_GEN => PACKET_GEN
)
port map(
  sys_clk_p => sys_clk_p,
  sys_clk_n => sys_clk_n,
  global_reset => global_reset,
  main_Rx => main_Rx,
  main_Tx => main_Tx,
  FMC_power_good => FMC_power_good,
  FMC_present_n => FMC_present_n,
  FMC_AD9510_status => FMC_AD9510_status,
  FMC_reset => FMC_reset,
  FMC_internal_clk_en => FMC_internal_clk_en,
  FMC_VCO_power_en => FMC_VCO_power_en,
  FMC_AD9510_function => FMC_AD9510_function,
  ADC_spi_clk => ADC_spi_clk,
  ADC_spi_ce_n => ADC_spi_ce_n,
  ADC_spi_miso => ADC_spi_miso,
  ADC_spi_mosi => ADC_spi_mosi,
  AD9510_spi_clk => AD9510_spi_clk,
  AD9510_spi_ce_n => AD9510_spi_ce_n,
  AD9510_spi_miso => AD9510_spi_miso,
  AD9510_spi_mosi => AD9510_spi_mosi,
  adc_clk_p => adc_clk_p,
  adc_clk_n => adc_clk_n,
  adc_data_p => adc_data_p,
  adc_data_n => adc_data_n,
  phy_resetn => phy_resetn,
  gmii_txd  => gmii_txd,
  gmii_tx_en => gmii_tx_en,
  gmii_tx_er => gmii_tx_er,
  gmii_tx_clk => gmii_tx_clk,
  gmii_rxd => gmii_rxd,
  gmii_rx_dv => gmii_rx_dv,
  gmii_rx_er => gmii_rx_er,
  gmii_rx_clk => gmii_rx_clk,
  gmii_col => gmii_col,
  gmii_crs => gmii_crs,
  mii_tx_clk => mii_tx_clk,
  mdio => mdio,
  mdc => mdc,
  tx_statistics_s => tx_statistics_s,
  rx_statistics_s => rx_statistics_s,
  pause_req_s => pause_req_s,
  mac_speed => mac_speed,
  update_speed => update_speed,
  serial_command => serial_command,
  serial_response => serial_response,
  reset_error => reset_error,
  frame_error => frame_error,
  frame_errorn => frame_errorn
);

end architecture RTL;
