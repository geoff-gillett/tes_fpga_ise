--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:20/02/2014 
--
-- Design Name: TES_digitiser
-- Module Name: event_mux_TB
-- Project Name: channel
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.ibufds;
use unisim.vcomponents.bufg;
use unisim.vcomponents.bufr;
use unisim.vcomponents.idelayctrl;
use unisim.vcomponents.iodelaye1;
use unisim.vcomponents.iddr;
use unisim.vcomponents.mmcm_adv;
 
library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library mcalib;

library streamlib;
use streamlib.types.all;

library tes;
use tes.types.all;
use tes.functions.all;
use tes.registers.all;
use tes.adc.all;
use tes.measurements.all;

entity ml605_v6_emac is
generic(
  VERSION:std_logic_vector(31 downto 0):=to_std_logic(23,32);
  DEFAULT_IODELAY_VALUE:integer:=12;
  ADC_CHIPS:integer:=4;
  ADC_CHIP_CHANNELS:integer:=2;
  ADC_BITS:integer:=14;
  DSP_CHANNELS:integer:=8;
  EVENT_FRAMER_ADDRESS_BITS:integer:=11;
  MIN_TICKPERIOD:integer:=2**TIME_BITS
);
port(
  ------------------------------------------------------------------------------
  -- System clocks and resets
  ------------------------------------------------------------------------------
  sys_clk_p:in std_logic;
  sys_clk_n:in std_logic;
  global_reset:in std_logic;
  
  LEDs:out std_logic_vector(7 downto 0);
  ------------------------------------------------------------------------------
  -- USB-UART bridge
  ------------------------------------------------------------------------------
  main_Rx:in std_logic;
  main_Tx:out std_logic;
  ------------------------------------------------------------------------------
  -- FMC108 pins - HPC FMC connector on the ML605  
  ------------------------------------------------------------------------------
  FMC_power_good:in std_logic;
  FMC_present_n:in std_logic; --FMC108 present in the HPC FMC connector
  FMC_AD9510_status:in std_logic;
  FMC_reset:out std_logic;
  FMC_internal_clk_en:out std_logic;
  FMC_VCO_power_en:out std_logic;
  FMC_AD9510_function:out std_logic;
  -- Texas instruments ADS62P49 ADC chip SPI communication
  ADC_spi_clk:out std_logic;
  ADC_spi_ce_n:out std_logic_vector(ADC_CHIPS-1 downto 0);
  ADC_spi_miso:in std_logic_vector(ADC_CHIPS-1 downto 0);
  ADC_spi_mosi:out std_logic;
  -- Analog Devices AD9510 PLL/clock distribution SPI communication
  AD9510_spi_clk:out std_logic;
  AD9510_spi_ce_n:out std_logic;
  AD9510_spi_miso:in std_logic;
  AD9510_spi_mosi:out std_logic;
  -- ADS62P49 clocks derived from AD9510
  adc_clk_p:in std_logic_vector(ADC_CHIPS-1 downto 0);
  adc_clk_n:in std_logic_vector(ADC_CHIPS-1 downto 0);
  -- ADS62P49 LVDS samples
  adc_data_p:in ddr_sample_array(ADC_CHIPS*ADC_CHIP_CHANNELS-1 downto 0);
  adc_data_n:in ddr_sample_array(ADC_CHIPS*ADC_CHIP_CHANNELS-1 downto 0);

  phy_resetn:out std_logic;
  gmii_txd:out std_logic_vector(7 downto 0);
  gmii_tx_en:out std_logic;
  gmii_tx_er:out std_logic;
  gmii_tx_clk:out std_logic;
  gmii_rxd:in std_logic_vector(7 downto 0);
  gmii_rx_dv:in std_logic;
  gmii_rx_er:in std_logic;
  gmii_rx_clk:in std_logic;
  gmii_col:in std_logic;
  gmii_crs:in std_logic;
  mii_tx_clk:in std_logic;
  --
  mdio:inout std_logic;
  mdc:out std_logic;
  --
  tx_statistics_s:out std_logic;
  rx_statistics_s:out std_logic;
  --
  pause_req_s:in std_logic;
  --
  mac_speed:in std_logic_vector(1 downto 0);
  update_speed:in std_logic;
  serial_command:in std_logic;
  serial_response:out std_logic;
  --
  reset_error:in std_logic;
  frame_error:out std_logic;
  frame_errorn:out std_logic
);
end entity ml605_v6_emac;

architecture RTL of ml605_v6_emac is
	
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
constant ADC_CHANNELS:integer:=ADC_CHIPS*ADC_CHIP_CHANNELS;
constant SPI_CHANNELS:integer:=ADC_CHIPS+1; -- +1 for AD9510

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
component fmc_mmcm
port
 (-- clock in ports
  clk_in1:in std_logic;
  -- clock out ports
  clk_out1:out std_logic;
  clk_out2:out std_logic;
  -- status and control signals
  locked:out std_logic
 );
end component;

--component fmc108_clk_tree
--port
--(
--  adc_chip0_clk:in std_logic;
--  signal_clk:out std_logic;
--  io_clk:out std_logic;
--  locked:out std_logic
--);
--end component;

component onboard_clk_tree
port
(
  sys_clk_P:in std_logic;
  sys_clk_N:in std_logic;
  refclk:out std_logic;
  io_clk:out std_logic;
  axi_clk:out std_logic;
  locked:out std_logic
);
end component;

component adc_fifo
port (
  wr_clk:in std_logic;
  rst:in std_logic;
  rd_clk:in std_logic;
  din:in std_logic_vector(13 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(13 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component adc_fifo;

--------------------------------------------------------------------------------
-- Clock and reset signals
--------------------------------------------------------------------------------
signal global_reset_IO_clk,IO_clk,signal_clk,axi_clk:std_logic;
signal reset0,reset1,reset2,fmc108_MMCM_locked:std_logic;

signal refclk:std_logic;
signal onboard_mmcm_locked:std_logic;
signal idelayctrl_rdy:std_ulogic;
signal reset_enable:std_logic;
--signal iodelay_inc:ddr_sample_array(ADC_CHANNELS-1 downto 0);
--signal iodelay_ce:ddr_sample_array(ADC_CHANNELS-1 downto 0);
--signal iodelay_clk_inc:std_logic_vector(ADC_CHIPS-1 downto 0);
--signal iodelay_clk_ce:std_logic_vector(ADC_CHIPS-1 downto 0);

signal adc_clk,adc_clk_bufds:std_logic_vector(ADC_CHIPS-1 downto 0);
signal adc_clk_delayed:std_logic_vector(ADC_CHIPS-1 downto 0);

--------------------------------------------------------------------------------
-- FMC108 signals
--------------------------------------------------------------------------------
-- ADC signals
signal adc_ddr,adc_ddr_delay:ddr_sample_array(ADC_CHANNELS-1 downto 0);
signal adc_sdr,adc_reg:adc_sample_array(ADC_CHANNELS-1 downto 0);

signal fifo_reset:std_logic;
signal fifo_reset_chipclk:std_logic_vector(ADC_CHANNELS-1 downto 0);

signal fifo_valid:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal fifo_rd_en:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal enables_reg:std_logic_vector(ADC_CHANNELS-1 downto 0);

constant ADC_PIPE_DEPTH:integer:=3; 
type adc_pipeline is array (ADC_PIPE_DEPTH-1 downto 0) 
	of adc_sample_array(ADC_CHANNELS-1 downto 0);
signal adc_dout_pipe,adc_pipe:adc_pipeline;

signal adc_samples,fifo_dout:adc_sample_array(ADC_CHANNElS-1 downto 0);

type input_sel_array is array (DSP_CHANNELS-1 downto 0) of
	boolean_vector(ADC_CHANNELS-1 downto 0);
signal input_selects:input_sel_array;
	
signal fifo_empty:std_logic_vector(ADC_CHANNELS-1 downto 0);

signal FMC_present:std_logic;

--------------------------------------------------------------------------------
-- Main CPU signals
--------------------------------------------------------------------------------
signal spi_clk,spi_mosi:std_logic;
signal spi_ce_n,spi_miso:std_logic_vector(SPI_CHANNELS-1 downto 0);

signal global:global_registers_t;
signal reg_address:register_address_t;
signal reg_data:register_data_t;
signal global_value:register_data_t;
signal global_write:boolean;
signal reg_write:boolean;

--------------------------------------------------------------------------------
-- Channel CPU signals
--------------------------------------------------------------------------------
signal channel_rx:std_logic_vector(2**CHANNEL_BITS-1 downto 0);
signal channel_tx:std_logic_vector(2**CHANNEL_BITS-1 downto 0);

signal channel_address:registeraddress_array(DSP_CHANNELS-1 downto 0);
signal channel_data,channel_value:registerdata_array(DSP_CHANNELS-1 downto 0);
signal channel_reg_write:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal channel_reg_write_io_clk:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal axis_done:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal axis_error:std_logic_vector(DSP_CHANNELS-1 downto 0);

signal channel_registers:channel_register_array(DSP_CHANNELS-1 downto 0);

--------------------------------------------------------------------------------
-- processing channel signals
--------------------------------------------------------------------------------
signal adc_delayed:adc_sample_array(DSP_CHANNELS-1 downto 0);

-- DSP coefficient reload
constant COEF_BITS:integer:=25;
constant COEF_WIDTH:integer:=32;
constant CONFIG_BITS:integer:=8;

type config_array is array (natural range <>) of 
	std_logic_vector(CONFIG_BITS-1 downto 0);
type coef_array is array (natural range <>) of 
	std_logic_vector(COEF_WIDTH-1 downto 0);
signal filter_config_data:config_array(DSP_CHANNELS-1 downto 0);
signal filter_config_valid:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal filter_config_ready:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal filter_data:coef_array(DSP_CHANNELS-1 downto 0);
signal filter_valid:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal filter_ready:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal filter_last:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal filter_last_missing:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal filter_last_unexpected:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal dif_config_data:config_array(DSP_CHANNELS-1 downto 0);
signal dif_config_valid:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal dif_config_ready:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal dif_data:coef_array(DSP_CHANNELS-1 downto 0);
signal dif_valid:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal dif_ready:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal dif_last:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal dif_last_missing:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal dif_last_unexpected:std_logic_vector(DSP_CHANNELS-1 downto 0);
										 
signal measurements:measurement_array(DSP_CHANNELS-1 downto 0);

-- MCA
signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
signal trigger_select:std_logic_vector(NUM_MCA_TRIGGER_D-2 downto 0);
signal mca_values:mca_value_array(DSP_CHANNELS-1 downto 0);
signal mca_value_valids:boolean_vector(DSP_CHANNELS-1 downto 0);
signal dumps:boolean_vector(DSP_CHANNELS-1 downto 0);
signal commits:boolean_vector(DSP_CHANNELS-1 downto 0);
signal baseline_errors:boolean_vector(DSP_CHANNELS-1 downto 0);
signal cfd_errors:boolean_vector(DSP_CHANNELS-1 downto 0);
signal time_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal peak_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal framer_overflows:boolean_vector(DSP_CHANNELS-1 downto 0);
signal channel_select:std_logic_vector(2**CHANNEL_BITS-1 downto 0);
signal mca_value:signed(MCA_VALUE_BITS-1 downto 0);
signal mca_value_valid:boolean;

signal updated:boolean;
signal mcastream:streambus_t;
signal mcastream_valid:boolean;
signal mcastream_ready:boolean;
--attribute S:string;
--attribute S of mcastream:signal is "TRUE";
--attribute S of mcastream_valid:signal is "TRUE";
--attribute S of mcastream_ready:signal is "TRUE";

signal eventstreams:streambus_array(DSP_CHANNELS-1 downto 0);
signal eventstreams_valid:boolean_vector(DSP_CHANNELS-1 downto 0);
signal eventstreams_ready:boolean_vector(DSP_CHANNELS-1 downto 0);

signal starts:boolean_vector(DSP_CHANNELS-1 downto 0);
signal muxstream:streambus_t;
signal muxstream_valid:boolean;
signal muxstream_ready:boolean;

signal mux_full:boolean;
signal mux_overflows:boolean_vector(2**CHANNEL_BITS-1 downto 0);
signal measurement_overflows:boolean_vector(2**CHANNEL_BITS-1 downto 0);
-- stop the eventstreams being optimised out
--attribute S:string;
--attribute S of muxstream:signal is "TRUE";
--attribute S of muxstream_valid:signal is "TRUE";
--attribute S of muxstream_ready:signal is "TRUE";

-- ethernet
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:std_logic;
signal bytestream_last:boolean;

attribute S:string;
attribute S of bytestream:signal is "TRUE";
attribute S of bytestream_valid:signal is "TRUE";
attribute S of bytestream_ready:signal is "TRUE";
--------------------------------------------------------------------------------
signal overflow_LEDs:std_logic_vector(7 downto 0):=(others => '0');

begin
LEDs <= overflow_LEDs;

ADC_spi_ce_n <= spi_ce_n(ADC_CHIPS-1 downto 0); 
AD9510_spi_ce_n  <= spi_ce_n(ADC_CHIPS); 
spi_miso(ADC_CHIPS-1 downto 0) <= ADC_spi_miso; 
spi_miso(ADC_CHIPS) <= AD9510_spi_miso; 
ADC_spi_clk <= spi_clk;
AD9510_spi_clk <= spi_clk;
ADC_spi_mosi <= spi_mosi;
AD9510_spi_mosi <= spi_mosi;
FMC_reset <= reset0;
FMC_internal_clk_en <= to_std_logic(global.FMC108_internal_clk);
FMC_VCO_power_en <= to_std_logic(global.VCO_power);
--

-- FIXME what does this do?
FMCfunction:process(IO_clk) is
begin
if rising_edge(IO_clk) then
  if reset0 = '1' then
    FMC_AD9510_function <= '0';
  else
    FMC_AD9510_function <= '1';
  end if;
end if;
end process FMCfunction;

--------------------------------------------------------------------------------
-- Clock and resets 
--------------------------------------------------------------------------------
-- FIXME there could be an issue here whit the FMC not coming up and having no 
-- IO_clk, io_clk could be derived by the onboard clock but this would have
-- undefined phase relative to sample_clk, does this break the ethernet cdc?
fmc108mmcm:fmc_mmcm
port map
 (-- Clock in ports
  clk_in1 => adc_clk(0),
  -- clock out ports
  clk_out1 => signal_clk,
  clk_out2 => io_clk,
  -- status and control signals
  locked => fmc108_mmcm_locked
);

--fmc108mmcm:fmc108_clk_tree
--port map
--(
--  adc_chip0_clk => adc_clk(0),
--  signal_clk => signal_clk,
--  io_clk => io_clk, --open,
--  locked => fmc108_mmcm_locked
--);
    
onboardmmcm:onboard_clk_tree
port map
(
  sys_clk_P => sys_clk_p,
  sys_clk_N => sys_clk_n,
  refclk => refclk,
  io_clk => open, --io_clk,
  axi_clk => axi_clk,
  locked => onboard_mmcm_locked
);

--TODO make this a RO flag
idelayctrl_inst:idelayctrl
port map (
   rdy => idelayctrl_rdy,  
   refclk => refclk, 				
   rst => reset0        				
);

reset_enable <= onboard_mmcm_locked;    
glbl_reset_gen:entity tes.reset_sync
port map(
  clk => io_clk,
  enable => reset_enable,
  reset_in => global_reset,
  reset_out => global_reset_IO_clk
);

--------------------------------------------------------------------------------
-- FMC108 ADC input
--------------------------------------------------------------------------------
fmcPres:process(signal_clk)
begin
	if rising_edge(signal_clk) then
		FMC_present <= not FMC_present_n;
	end if;
end process fmcPres;

-- map iodelay control bits ce and inc
-- 
--iodelayControl:process(signal_clk)
--	variable ce:std_logic_vector(ADC_BITS/2-1 downto 0);
--	variable inc:std_logic_vector(ADC_BITS/2-1 downto 0);
--	variable channel_sel:std_logic_vector(ADC_CHANNELS-1 downto 0);
--begin
--	if rising_edge(signal_clk) then
--    ce:=global.iodelay_control(ADC_BITS/2-1 downto 0);
--    inc:=global.iodelay_control(ADC_BITS-1 downto ADC_BITS/2);
--    channel_sel
--    	:=global.iodelay_control(ADC_CHANNELS+ADC_BITS-1 downto ADC_BITS);
--    iodelay_clk_ce <= global.iodelay_control(
--    		ADC_CHIPS+ADC_CHANNELS+ADC_BITS-1 downto
--    		ADC_CHANNELS+ADC_BITS);
--    iodelay_clk_inc <= global.iodelay_control(
--    		2*ADC_CHIPS+ADC_CHANNELS+ADC_BITS-1 downto
--    		ADC_CHIPS+ADC_CHANNELS+ADC_BITS);
--    		
--		for c in ADC_CHANNELS-1 downto 0 loop
--			if channel_sel(c)='1' then
--				iodelay_ce(c) <= ce;
--				iodelay_inc(c) <= inc;
--			else
--				iodelay_ce(c) <= (others => '0');
--				iodelay_inc(c) <= (others  => '0');
--			end if;
--		end loop;
--		--TODO add pipeline here if needed
--	end if;
--end process iodelayControl;

-- input buffers and iodelays for the ADC chip clocks
-- TODO should there be an iodelay for adc_chip_clk(0)? it drives the MMCM
-- make sure reset sequence is sane
adcClk:for chip in ADC_CHIPS-1 downto 0 generate
begin
	clkIbufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_clk_bufds(chip),
    I => adc_clk_p(chip),
    IB => adc_clk_n(chip)
  );
  
  clkIodelay:iodelaye1
  generic map(
    DELAY_SRC => "I",
    IDELAY_TYPE => "VARIABLE",
    IDELAY_VALUE => DEFAULT_IODELAY_VALUE
  )
  port map(
    cntvalueout => open,
    dataout => adc_clk_delayed(chip),
    c => signal_clk,
    ce => '0',--iodelay_clk_ce(chip),
    cinvctrl => '0',
    clkin => '0',
    cntvaluein => to_std_logic(to_unsigned(DEFAULT_IODELAY_VALUE,5)),
    datain => '0',
    idatain => adc_clk_bufds(chip),
    inc => '0',--iodelay_clk_inc(chip),
    odatain => '0',
    rst => '0',
    t => '1'
  );
end generate;  

adcClkBufgInst:bufg
port map(
   O => adc_clk(0), 
   I => adc_clk_delayed(0)  
);

adcBufr:for chip in ADC_CHIPS-1 downto 1 generate
  bufrInst:bufr
  generic map (
  	SIM_DEVICE => "VIRTEX6",
    BUFR_DIVIDE => "BYPASS"
  )
  port map (
    ce => '1',
    clr => '0',
    i  => adc_clk_delayed(chip),
    o  => adc_clk(chip)
  );
end generate;

-- instantiate input buffers, iodelays, DDR to SDR components and CDC FIFOs
-- for each ADC DDR data line.
adcChip:for chip in 0 to ADC_CHIPS-1 generate
	begin
  chan:for chan in 0 to ADC_CHIP_CHANNELS-1 generate
  begin
    ddrBit:for bit in 0 to ADC_BITS/2-1 generate
  	begin
  	
      bufdsInst:ibufds
      generic map(
        DIFF_TERM => TRUE,
        IOSTANDARD => "LVDS_25"
      )
      port map(
        O => adc_ddr(chip*ADC_CHIP_CHANNELS+chan)(bit),
        I => adc_data_p(chip*ADC_CHIP_CHANNELS+chan)(bit),
        IB => adc_data_n(chip*ADC_CHIP_CHANNELS+chan)(bit)
      );
      
      -- adjustable delay for each data channel
      iodelayInst:iodelaye1
      generic map(
        DELAY_SRC => "I",
        IDELAY_TYPE => "VARIABLE",
        IDELAY_VALUE => DEFAULT_IODELAY_VALUE
      )
      port map(
        cntvalueout => open,
        dataout => adc_ddr_delay(chip*ADC_CHIP_CHANNELS+chan)(bit),
        c => signal_clk,
        ce => '0', --iodelay_ce(chip*ADC_CHIP_CHANNELS+chan)(bit),
        cinvctrl => '0',
        clkin => '0',
        cntvaluein => to_std_logic(to_unsigned(DEFAULT_IODELAY_VALUE,5)),
        datain => '0',
        idatain => adc_ddr(chip*ADC_CHIP_CHANNELS+chan)(bit),
        inc => '0',--iodelay_inc(chip*ADC_CHIP_CHANNELS+chan)(bit),
        odatain => '0',
        rst => '0',
        t => '1'
      );
      
      -- DDR to SDR conversion  
     	iddrInst:iddr
        generic map(DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
        port map(
          q1 => adc_sdr(chip*ADC_CHIP_CHANNELS+chan)(2*bit),
          q2 => adc_sdr(chip*ADC_CHIP_CHANNELS+chan)(2*bit+1),
          c => adc_clk(chip),
          ce => '1',
          d => adc_ddr_delay(chip*ADC_CHIP_CHANNELS+chan)(bit),
          r => '0',
          s => '0'
        );
    end generate ddrBit;
    
    -- this fifo crosses from the individual chip clk domains the the common 
    -- signal_clk domain.
    cdcFifo:component adc_fifo
    port map(
      wr_clk => adc_clk(chip),
      rst => fifo_reset_chipclk(chip),
      rd_clk => signal_clk,
      din => adc_pipe(ADC_PIPE_DEPTH-1)(chip*ADC_CHIP_CHANNELS+chan),
      wr_en => '1',
      rd_en => fifo_rd_en(chip*ADC_CHIP_CHANNELS+chan),
      dout => fifo_dout(chip*ADC_CHIP_CHANNELS+chan),
      full => open,
      empty => fifo_empty(chip*ADC_CHIP_CHANNELS+chan)
    );
    
  end generate chan;
  
  adcPipelining:process(signal_clk)
  begin
  	if rising_edge(signal_clk) then
  		if reset0 = '1' then
  			-- pipe on output side of FIFO
  			adc_dout_pipe <= (others => (others => (others => '0')));
  			-- pipe on input side of FIFO
  			adc_pipe <= (others => (others => (others => '0')));
  		else
        fifo_valid <= not fifo_empty;
  			adc_dout_pipe(0) <= fifo_dout;
  			adc_dout_pipe(ADC_PIPE_DEPTH-1 downto 1) 
  				<= adc_dout_pipe(ADC_PIPE_DEPTH-2 downto 0);
  			adc_pipe(0) <= adc_sdr;
  			adc_pipe(ADC_PIPE_DEPTH-1 downto 1) 
  				<= adc_pipe(ADC_PIPE_DEPTH-2 downto 0);
  		end if;
  	end if;
  end process adcPipelining;
  adc_samples <= adc_dout_pipe(ADC_PIPE_DEPTH-1);
  
 	resetSync:entity tes.sync_2FF
  generic map(
   	INIT => "11"
  )
  port map(
    out_clk => adc_clk(chip),
    input   => fifo_reset,
    output  => fifo_reset_chipclk(chip)
  );
end generate adcChip;

-- control is via adc_enables
-- When enable changes pulse FIFO reset and wait till all enabled FIFOs are 
-- not empty before asserting setting rd_en
adcEnable:process(signal_clk)
begin
  if rising_edge(signal_clk) then
    if reset0 = '1' then
      enables_reg <= (others => '0');
      fifo_reset <= '1';
      fifo_rd_en <= (others => '0');
    else
      enables_reg <= global.adc_enable;
      if (enables_reg /= global.adc_enable) then
        fifo_reset <= '1';
        fifo_rd_en <= (others => '0');
      else
        fifo_reset <= '0';
        if fifo_valid=enables_reg then 
        	fifo_rd_en <= enables_reg;
        else
        	fifo_rd_en <= (others  => '0'); 
        end if;
      end if;
    end if;
  end if;
end process adcEnable;

--------------------------------------------------------------------------------
-- processing channels
--------------------------------------------------------------------------------
tesChannel:for c in DSP_CHANNELS-1 downto 0 generate


	registers:entity tes.channel_registers
  generic map(
    CHANNEL => c,
    CONFIG_BITS => CONFIG_BITS,
    CONFIG_WIDTH => CONFIG_BITS,
    COEF_BITS => COEF_BITS,
    COEF_WIDTH => COEF_WIDTH
  )
  port map(
    clk => signal_clk,
    reset => reset0,
    data => channel_data(c),
    address => channel_address(c),
    write => channel_reg_write(c),
    value => channel_value(c),
    axis_done => axis_done(c),
    axis_error => axis_error(c),
    registers => channel_registers(c),
    filter_config_data => filter_config_data(c),
    filter_config_valid => filter_config_valid(c),
    filter_config_ready => filter_config_ready(c),
    filter_data => filter_data(c),
    filter_valid => filter_valid(c),
    filter_ready => filter_ready(c),
    filter_last => filter_last(c),
    filter_last_missing => filter_last_missing(c),
    filter_last_unexpected => filter_last_unexpected(c),
    dif_config_data => dif_config_data(c),
    dif_config_valid => dif_config_valid(c),
    dif_config_ready => dif_config_ready(c), --differentiator_config_ready,
    dif_data => dif_data(c),
    dif_valid => dif_valid(c),
    dif_ready => dif_ready(c),
    dif_last => dif_last(c),
    dif_last_missing => dif_last_missing(c),
    dif_last_unexpected => dif_last_missing(c)
  );
  
  regWriteSync:entity tes.sync_2FF
  port map(
    out_clk => signal_clk,
    input => channel_reg_write_io_clk(c),
    output => channel_reg_write(c)
  );

	cpu:entity tes.channel_controller
		port map(
			clk => io_clk,
			reset => reset0,
			uart_tx => channel_rx(c),
			uart_rx => channel_tx(c),
			reg_address => channel_address(c),
			reg_data => channel_data(c),
			reg_value => channel_value(c),
			reg_write => channel_reg_write_io_clk(c),
			axis_done => axis_done(c),
			axis_error => axis_error(c)
		);

	--TODO add reset??
  delay:entity tes.RAM_delay
  generic map(
    DEPTH => 2**DELAY_BITS,
    DATA_BITS => ADC_BITS
  )
  port map(
    clk => signal_clk,
    data_in => adc_samples(c),
    delay => to_integer(channel_registers(c).capture.delay),
    delayed => adc_delayed(c)
  );

--  inputSel:entity tes.input_sel
--  generic map(
--    CHANNELS => CHANNELS,
--    PIPE_DEPTH => 2
--  )
--  port map(
--    clk => signal_clk,
--    reset => reset0,
--    inputs => fifo_dout,
--    sel => channel_registers(c).capture.adc_select,
--    output => adc_samples(c)
--  );

	measurement:entity tes.measurement_unit
  generic map(
    FRAMER_ADDRESS_BITS => EVENT_FRAMER_ADDRESS_BITS,
    CHANNEL => c,
    ENDIANNESS => ENDIANNESS
  )
  port map(
    clk => signal_clk,
    reset => reset2,
    adc_sample => adc_delayed(c),
    registers => channel_registers(c),
    filter_config_data => filter_config_data(c),
    filter_config_valid => filter_config_valid(c),
    filter_config_ready => filter_config_ready(c),
    filter_reload_data => filter_data(c),
    filter_reload_valid => filter_valid(c),
    filter_reload_ready => filter_ready(c),
    filter_reload_last => filter_last(c),
    filter_reload_last_missing => filter_last_missing(c),
    filter_reload_last_unexpected => filter_last_unexpected(c),
    differentiator_config_data => dif_config_data(c),
    differentiator_config_valid => dif_config_valid(c),
    differentiator_config_ready => dif_config_ready(c),
    differentiator_reload_data => dif_data(c),
    differentiator_reload_valid => dif_valid(c),
    differentiator_reload_ready => dif_ready(c),
    differentiator_reload_last => dif_last(c),
    differentiator_reload_last_missing => dif_last_missing(c),
    differentiator_reload_last_unexpected => dif_last_unexpected(c),
    measurements => measurements(c),
    mca_value_select => value_select,
    mca_trigger_select => trigger_select,
    mca_value => mca_values(c),
    mca_value_valid => mca_value_valids(c),
    mux_full => mux_full,
    start => starts(c),
    dump => dumps(c),
    commit => commits(c),
    cfd_error => cfd_errors(c),
    time_overflow => time_overflows(c),
    peak_overflow => peak_overflows(c),
    framer_overflow => framer_overflows(c),
    mux_overflow => mux_overflows(c),
    measurement_overflow => measurement_overflows(c),
    baseline_underflow => baseline_errors(c),
    eventstream => eventstreams(c),
    valid => eventstreams_valid(c),
    ready => eventstreams_ready(c)
  );
end generate tesChannel;
--------------------------------------------------------------------------------

mux:entity tes.eventstream_mux
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  RELTIME_BITS => TIME_BITS,
  TIMESTAMP_BITS => TIMESTAMP_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICKPERIOD => MIN_TICKPERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => signal_clk,
  reset => reset1,
  start => starts,
  commit => commits,
  dump => dumps,
  instreams => eventstreams,
  instream_valids => eventstreams_valid,
  instream_readys => eventstreams_ready,
  full => mux_full,
  tick_period => global.tick_period,
  window => global.window,
  cfd_errors => cfd_errors,
  framer_overflows => framer_overflows,
  mux_overflows => mux_overflows,
  measurement_overflows => measurement_overflows,
  peak_overflows => peak_overflows,
  time_overflows => time_overflows,
  baseline_underflows => baseline_errors,
  muxstream => muxstream,
  valid => muxstream_valid,
  ready => muxstream_ready
);

mcaChanSel:entity tes.mca_channel_selector
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  VALUE_BITS   => MCA_VALUE_BITS
)
port map(
  clk => signal_clk,
  reset => reset1,
  channel_select => channel_select,
  values => mca_values,
  valids => mca_value_valids,
  value => mca_value,
  valid => mca_value_valid
);

mca:entity tes.mca_unit
generic map(
  CHANNEL_BITS => CHANNEL_BITS,
  ADDRESS_BITS => MCA_ADDRESS_BITS,
  COUNTER_BITS => MCA_COUNTER_BITS,
  VALUE_BITS => MCA_VALUE_BITS,
  TOTAL_BITS => MCA_TOTAL_BITS,
  TICKCOUNT_BITS => MCA_TICKCOUNT_BITS,
  TICKPERIOD_BITS => TICK_PERIOD_BITS,
  MIN_TICK_PERIOD => MIN_TICK_PERIOD,
  TICKPIPE_DEPTH => TICKPIPE_DEPTH,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => signal_clk,
  reset => reset1,
  initialising => open,
  --TODO remove redundant register port
  update_asap => global.mca.update_asap,
  --TODO remove redundant register port
  update_on_completion => global.mca.update_on_completion,
  updated => updated, --TODO implement CPU interupt
  registers => global.mca,
  --TODO remove redundant register port
  tick_period => global.tick_period,
  channel_select => channel_select,
  value_select => value_select,
  trigger_select => trigger_select,
  value => mca_value,
  value_valid => mca_value_valid,
  stream => mcastream,
  valid => mcastream_valid,
  ready => mcastream_ready
);

enet:entity tes.ethernet_framer
generic map(
  MTU_BITS => MTU_BITS,
  FRAMER_ADDRESS_BITS => ETHERNET_FRAMER_ADDRESS_BITS,
  DEFAULT_MTU => DEFAULT_MTU,
  DEFAULT_TICK_LATENCY => DEFAULT_TICK_LATENCY,
  ENDIANNESS => ENDIANNESS
)
port map(
  clk => signal_clk,
  reset => reset0,
  mtu => global.mtu,
  tick_latency => global.tick_latency,
  eventstream => muxstream,
  eventstream_valid => muxstream_valid,
  eventstream_ready => muxstream_ready,
  mcastream => mcastream,
  mcastream_valid => mcastream_valid,
  mcastream_ready => mcastream_ready,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

enetCdc:entity tes.CDC_bytestream_adapter
port map(
  s_clk => signal_clk,
  s_reset => reset0,
  streambus => ethernetstream,
  streambus_valid => ethernetstream_valid,
  streambus_ready => ethernetstream_ready,
  b_clk => io_clk,
  b_reset => reset0,
  bytestream => bytestream,
  bytestream_valid => bytestream_valid,
  bytestream_ready => to_boolean(bytestream_ready),
  bytestream_last => bytestream_last
);

emac:entity work.v6_emac_v2_3
port map(
  global_reset_IO_clk => global_reset_IO_clk,
  IO_clk => io_clk,
  s_axi_aclk => axi_clk,
  refclk_bufg => refclk,
  tx_axis_fifo_tdata => bytestream,
  tx_axis_fifo_tvalid => to_std_logic(bytestream_valid),
  tx_axis_fifo_tready => bytestream_ready,
  tx_axis_fifo_tlast => to_std_logic(bytestream_last),
  phy_resetn => phy_resetn,
  gmii_txd => gmii_txd,
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

registers:entity tes.global_registers
generic map(
  HDL_VERSION => VERSION
)
port map(
  reg_clk => signal_clk,
  reg_reset => reset0,
  data => reg_data,
  address => reg_address,
  value => global_value,
  write => global_write,
  registers => global
);

regWriteSync:entity tes.boolean_sync_2FF
port map(
  out_clk => signal_clk,
  input => reg_write,
  output => global_write
);

cpu:entity tes.main_controller
generic map(
  TES_CHANNEL_BITS => CHANNEL_BITS,
  ADC_CHIPS => ADC_CHIPS
)
port map(
  clk => io_clk,
  LEDs => LEDs,
  global_reset => global_reset,
  FMC_power_good => FMC_power_good,
  FMC_present => FMC_present,
  FMC_AD9510_status => FMC_AD9510_status,
  fmc_mmcm_locked => fmc108_mmcm_locked,
  iodelay_ready => idelayctrl_rdy,
  reset0 => reset0,
  reset1 => reset1,
  reset2 => reset2,
  interrupt => FALSE,
  interrupt_ack => open,
  main_rx => main_Rx,
  main_tx => main_Tx,
  channel_rx => channel_rx,
  channel_tx => channel_tx,
  spi_clk => spi_clk,
  spi_ce_n => spi_ce_n,
  spi_miso => spi_miso,
  spi_mosi => spi_mosi,
  address => reg_address,
  data => reg_data,
  select_axi => open,
  value => global_value,
  axi_resp => "00",
  axi_resp_valid => FALSE,
  reg_write => reg_write,
  axi_read => open,
  axi_write => open
);

end architecture RTL;
