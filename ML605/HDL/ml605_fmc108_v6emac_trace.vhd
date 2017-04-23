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

library dsp;
use dsp.types.all;

library tes;
use tes.types.all;
use tes.functions.all;
use tes.registers.all;
use tes.measurements.all;

entity ml605_fmc108_v6emac_trace is
generic(
  VERSION:std_logic_vector(31 downto 0):=to_std_logic(23,32);
  DEFAULT_IODELAY_VALUE:integer:=24;
  DEFAULT_CLK_IODELAY_VALUE:integer:=0;
  DSP_CHANNELS:integer:=2;
  ENDIAN:string:="LITTLE";
  PACKET_GEN:boolean:=FALSE
);
port(
  ------------------------------------------------------------------------------
  -- System clocks and resets
  ------------------------------------------------------------------------------
  sys_clk_p:in std_logic;
  sys_clk_n:in std_logic;
  global_reset:in std_logic;
  
  --LEDs:out std_logic_vector(7 downto 0);
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
end entity ml605_fmc108_v6emac_trace;

architecture RTL of ml605_fmc108_v6emac_trace is
	
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
constant ADC_CHANNELS:integer:=ADC_CHIPS*ADC_CHIP_CHANNELS;
constant SPI_CHANNELS:integer:=ADC_CHIPS+1; -- +1 for AD9510

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

component fmc108_clk_tree
port
(
  adc_chip0_clk:in std_logic;
  signal_clk:out std_logic;
  io_clk:out std_logic;
  locked:out std_logic
);
end component;

component onboard_clk_tree
port
(
  sys_clk_P:in std_logic;
  sys_clk_N:in std_logic;
  refclk:out std_logic;
  io_clk:out std_logic;
  axi_clk:out std_logic;
  signal_clk:out std_logic;
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

component enet_cdc_fifo
port (
  wr_clk:in std_logic;
  wr_rst:in std_logic;
  rd_clk:in std_logic;
  rd_rst:in std_logic;
  din:in std_logic_vector(71 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(8 downto 0);
  full:out std_logic;
  empty:out std_logic
);
end component;


--attribute S:string;
--------------------------------------------------------------------------------
-- Clock and reset signals
--------------------------------------------------------------------------------
signal global_reset_boot_clk,IO_clk,signal_clk,axi_clk,boot_clk:std_logic;
signal reset0,reset1,reset2:std_logic;
signal reset1_sclk,reset2_sclk:std_logic;
--signal reset0_refclk:std_logic;
signal reset1_ioclk:std_logic;

signal ref_clk:std_logic;
signal onboard_mmcm_locked,fmc108_mmcm_locked:std_logic;
signal idelayctrl_rdy:std_ulogic;
--signal reset_enable:std_logic;
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
signal adc_sdr,adc_sdr_reg:adc_sample_array(ADC_CHANNELS-1 downto 0);

signal fifo_reset:std_logic;
signal fifo_reset_chipclk:std_logic_vector(ADC_CHANNELS-1 downto 0);

signal fifo_valid,enables_valid:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal fifo_rd_en:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal enables_reg,enables_reg2:std_logic_vector(ADC_CHANNELS-1 downto 0);


--constant ADCPIPE_DEPTH:integer:=2; 
--type adcpipe is array(1 to ADCPIPE_DEPTH) of adc_sample_t;
--type adcpipe_array is array(natural range <>) of adcpipe;
--signal adc_pipes:adcpipe_array(ADC_CHANNELS-1 downto 0);
--
--type adc_pipeline is array (ADCPIPE_DEPTH-1 downto 0) 
--	of adc_sample_array(ADC_CHANNELS-1 downto 0);
--signal adc_dout_pipe:adc_pipeline;

--attribute equivalent_register_removal:string;
--attribute shreg_extract:string;
--attribute shreg_extract of adc_pipes:signal is "no";
--attribute shreg_extract of adc_dout_pipe:signal is "no";
--attribute equivalent_register_removal of adc_pipes:signal is "FALSE";
--attribute equivalent_register_removal of adc_dout_pipe:signal is "FALSE";

signal adc_samples:adc_sample_array(ADC_CHANNELS-1 downto 0);
signal fifo_dout:adc_sample_array(ADC_CHANNELS-1 downto 0);
--attribute S of adc_samples:signal is "TRUE";

--type input_sel_array is array (DSP_CHANNELS-1 downto 0) of
--	boolean_vector(ADC_CHANNELS-1 downto 0);
--signal input_selects:input_sel_array;
	
signal fifo_empty:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal FMC_present:std_logic;

--------------------------------------------------------------------------------
-- Main CPU signals
--------------------------------------------------------------------------------
signal spi_clk,spi_mosi:std_logic;
signal spi_ce_n,spi_miso:std_logic_vector(SPI_CHANNELS-1 downto 0);

signal global:global_registers_t;
--attribute S of global:signal is "TRUE"; -- KEEP the register outputs

signal reg_address:register_address_t;
signal reg_data:register_data_t;
signal global_value:register_data_t;
signal global_write:boolean;
signal reg_write:boolean;

--------------------------------------------------------------------------------
-- Channel CPU signals
--------------------------------------------------------------------------------
signal channel_rx:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal channel_tx:std_logic_vector(DSP_CHANNELS-1 downto 0);

signal channel_address:registeraddress_array(DSP_CHANNELS-1 downto 0);
signal channel_data,channel_value:registerdata_array(DSP_CHANNELS-1 downto 0);
signal channel_reg_write:std_logic_vector(DSP_CHANNELS-1 downto 0);
signal channel_reg_write_io_clk:std_logic_vector(DSP_CHANNELS-1 downto 0);
--signal axis_done:std_logic_vector(DSP_CHANNELS-1 downto 0);
--signal axis_error:std_logic_vector(DSP_CHANNELS-1 downto 0);

signal channel_registers:channel_register_array(DSP_CHANNELS-1 downto 0);
--attribute S of channel_registers:signal is "TRUE";
--------------------------------------------------------------------------------
-- processing channel signals
--------------------------------------------------------------------------------
--signal adc_delayed:adc_sample_array(DSP_CHANNELS-1 downto 0);

-- DSP coefficient reload
										 
signal measurements:measurements_array(DSP_CHANNELS-1 downto 0);

-- MCA
--type value_sel_array is array (natural range <>) of 
--  std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
  
--signal value_select:std_logic_vector(NUM_MCA_VALUE_D-1 downto 0);
--signal value_sel_reg:value_sel_array(CHANNELS-1 downto 0);

--signal mca_values,mca_values_reg:mca_value_array(DSP_CHANNELS-1 downto 0);

-- ethernet
signal ethernetstream:streambus_t;
signal ethernetstream_valid:boolean;
signal ethernetstream_ready:boolean;
--signal bytestream:std_logic_vector(7 downto 0);
signal bytestream_valid:boolean;
signal bytestream_ready:std_logic;
--signal bytestream_last:boolean;
signal cdc_din:std_logic_vector(71 downto 0);
signal cdc_wr_en:std_logic;
signal cdc_rd_en:std_logic;
signal cdc_dout:std_logic_vector(8 downto 0);
signal cdc_full:std_logic;
signal cdc_empty:std_logic;
signal cdc_ready:boolean;
signal cdc_valid:boolean;
signal bytestream_int:std_logic_vector(8 downto 0);
signal bytestream:std_logic_vector(7 downto 0);
--signal bytestream_last:boolean;

--attribute S:string;
--attribute S of bytestream:signal is "TRUE";
--attribute S of bytestream_valid:signal is "TRUE";
--attribute S of bytestream_ready:signal is "TRUE";

--attribute KEEP:string;
--attribute KEEP of reset0,reset1,reset2:signal is "TRUE";
--attribute KEEP of reset0_sclk,reset1_sclk,reset2_sclk:signal is "TRUE";
--attribute KEEP of reset0_ioclk,reset1_ioclk,reset2_ioclk:signal is "TRUE";
--attribute KEEP of fmc108_mmcm_locked:signal is "TRUE";


--------------------------------------------------------------------------------
attribute iob:string;
attribute iob of ADC_spi_ce_n:signal is "TRUE";
attribute iob of AD9510_spi_ce_n:signal is "TRUE";
attribute iob of ADC_spi_clk:signal is "TRUE";
attribute iob of AD9510_spi_clk:signal is "TRUE";
attribute iob of ADC_spi_mosi:signal is "TRUE";
attribute iob of AD9510_spi_mosi:signal is "TRUE";
--attribute iob of ADC_spi_miso:signal is "TRUE";
--attribute iob of AD9510_spi_miso:signal is "TRUE";
attribute iob of spi_miso:signal is "TRUE";

signal filter_config,slope_config,baseline_config:
       fir_ctl_in_array(DSP_CHANNELS-1 downto 0);
signal filter_events,slope_events,baseline_events:
       fir_ctl_out_array(DSP_CHANNELS-1 downto 0);
--------------------------------------------------------------------------------
--debug
--signal adc_sample0:adc_sample_t;
--signal adc_enable:boolean_vector(ADC_CHANNELS-1 downto 0);
--signal raw0_debug:signal_t;
--signal adc0_debug:std_logic_vector(ADC_BITS-1 downto 0);

constant DEBUG:string:="FALSE";
attribute MARK_DEBUG:string;
--attribute MARK_DEBUG of raw0_debug:signal is DEBUG;
--attribute MARK_DEBUG of adc0_debug:signal is DEBUG;
--attribute MARK_DEBUG of enables_reg:signal is DEBUG;
--attribute MARK_DEBUG of bytestream:signal is DEBUG;
--attribute MARK_DEBUG of bytestream_ready:signal is DEBUG;
--attribute MARK_DEBUG of bytestream_valid:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_ready:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_valid:signal is DEBUG;
--attribute MARK_DEBUG of cdc_ready:signal is DEBUG;
--attribute MARK_DEBUG of cdc_valid:signal is DEBUG;
attribute MARK_DEBUG of cdc_full:signal is DEBUG;

--attribute MARK_DEBUG of enables_reg2:signal is DEBUG;
--attribute MARK_DEBUG of adc_sample0:signal is DEBUG;
--attribute MARK_DEBUG of fifo_valid:signal is DEBUG;
--attribute MARK_DEBUG of adc_enable:signal is DEBUG;

--signal test_counter:unsigned(15 downto 0):=(others => '0');
--attribute MARK_DEBUG of test_counter:signal is DEBUG;
--attribute MARK_DEBUG of reset0,reset1,reset2:signal is DEBUG;
--attribute MARK_DEBUG of reset0_ioclk,reset1_ioclk,reset2_ioclk:signal is DEBUG;
--attribute MARK_DEBUG of reset2_sclk:signal is DEBUG;
--attribute MARK_DEBUG of onboard_mmcm_locked:signal is DEBUG;
--attribute MARK_DEBUG of fmc108_mmcm_locked:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_valid:signal is DEBUG;
--attribute MARK_DEBUG of ethernetstream_ready:signal is DEBUG;
--attribute MARK_DEBUG of bytestream:signal is DEBUG;
--attribute MARK_DEBUG of bytestream_valid:signal is DEBUG;
--attribute MARK_DEBUG of bytestream_ready:signal is DEBUG;
--attribute MARK_DEBUG of bytestream_last:signal is DEBUG;
--attribute MARK_DEBUG of onboard_mmcm_locked:signal is DEBUG;

--------------------------------------------------------------------------------

--signal overflow_LEDs:std_logic_vector(7 downto 0):=(others => '0');

begin
--raw0_debug <= measurements(0).raw.sample;
--adc0_debug <= adc_samples(0);
--adc_sample0 <= adc_samples(0);
--adc_enable <= to_boolean(global.adc_enable);

--test:process(signal_clk)
--begin
--  if rising_edge(signal_clk) then
--    test_counter <= test_counter + 1;
--  end if;
--end process test;

spiReg:process(boot_clk)
begin
	if rising_edge(boot_clk) then
    ADC_spi_ce_n <= spi_ce_n(ADC_CHIPS-1 downto 0); 
    AD9510_spi_ce_n  <= spi_ce_n(ADC_CHIPS); 
    spi_miso(ADC_CHIPS-1 downto 0) <= ADC_spi_miso; 
    spi_miso(ADC_CHIPS) <= AD9510_spi_miso; 
    ADC_spi_clk <= spi_clk;
    AD9510_spi_clk <= spi_clk;
    ADC_spi_mosi <= spi_mosi;
    AD9510_spi_mosi <= spi_mosi;
	end if;
end process spiReg;

FMC_reset <= reset0;
FMC_internal_clk_en <= '1'; --to_std_logic(global.FMC108_internal_clk);
FMC_VCO_power_en <= '1'; --to_std_logic(global.VCO_power);
FMC_AD9510_function <= '1';
--

-- FIXME what does this do?
--FMC_AD9510_function <= '1';
--FMCfunction:process(boot_clk) is
--begin
--if rising_edge(boot_clk) then
--  if reset0 = '1' then
--    FMC_AD9510_function <= '0';
--  else
--    FMC_AD9510_function <= '1';
--  end if;
--end if;
--end process FMCfunction;

--------------------------------------------------------------------------------
-- Clock and resets 
--------------------------------------------------------------------------------
fmc108mmcm:fmc108_clk_tree
port map
(
  adc_chip0_clk => adc_clk(0),
  signal_clk => signal_clk,
  io_clk => io_clk,
  locked => fmc108_mmcm_locked
);

--FIXME should axi_clk come from FMC MMCM?
onboardmmcm:onboard_clk_tree
port map
(
  sys_clk_P => sys_clk_p,
  sys_clk_N => sys_clk_n,
  refclk => ref_clk,
  io_clk => boot_clk, --io_clk, --open,--io_clk,
  axi_clk => axi_clk,
  signal_clk => open, --signal_clk,
  locked => onboard_mmcm_locked
);

--TODO make this a RO flag
idelayctrl_inst:idelayctrl
port map (
   rdy => idelayctrl_rdy,  
   refclk => ref_clk, 				
   rst => reset0       				
);

--reset_enable <= onboard_mmcm_locked;    
glbl_reset_gen:entity tes.reset_sync
port map(
  clk => boot_clk,
  enable => onboard_mmcm_locked,
  reset_in => global_reset, -- or sys_reset,
  reset_out => global_reset_boot_clk
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
end generate;  

adcClk0Bufg:bufg
port map(
   O => adc_clk(0), 
   I => adc_clk_bufds(0) --adc_clk_delayed(0)  
);

adcClkBufr:for chip in ADC_CHIPS-1 downto 1 generate

  clkIodelay:iodelaye1
  generic map(
    DELAY_SRC => "I",
    IDELAY_TYPE => "VARIABLE",
    IDELAY_VALUE => DEFAULT_CLK_IODELAY_VALUE
  )
  port map(
    cntvalueout => open,
    dataout => adc_clk_delayed(chip),
    c => signal_clk,
    ce => '0',--iodelay_clk_ce(chip),
    cinvctrl => '0',
    clkin => '0',
    cntvaluein => to_std_logic(to_unsigned(DEFAULT_CLK_IODELAY_VALUE,5)),
    datain => '0',
    idatain => adc_clk_bufds(chip),
    inc => '0',--iodelay_clk_inc(chip),
    odatain => '0',
    rst => '0',
    t => '1'
  );
  
  adcBufr:bufr
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
    
    inPipe:process(adc_clk(chip))
    begin
    	if rising_edge(adc_clk(chip)) then
  			adc_sdr_reg(chip*ADC_CHIP_CHANNELS+chan)
  			  <= adc_sdr(chip*ADC_CHIP_CHANNELS+chan);
    	end if;
    end process inPipe;
    
    -- this fifo crosses from the individual chip clk domains the the common 
    -- signal_clk domain.
    adcCdcFIFO:component adc_fifo
    port map(
      wr_clk => adc_clk(chip),
      rst => fifo_reset_chipclk(chip),
      rd_clk => signal_clk,
      din => adc_sdr_reg(chip*ADC_CHIP_CHANNELS+chan),
--      din => adc_pipes(chip*ADC_CHIP_CHANNELS+chan)(ADCPIPE_DEPTH),--adc_sdr(chip*ADC_CHIP_CHANNELS+chan),
      wr_en => '1',
      rd_en => fifo_rd_en(chip*ADC_CHIP_CHANNELS+chan),
      dout => fifo_dout(chip*ADC_CHIP_CHANNELS+chan),
      full => open,
      empty => fifo_empty(chip*ADC_CHIP_CHANNELS+chan)
    );
   
  end generate chan;
  
--  adc_samples <= adc_dout_pipe(ADCPIPE_DEPTH-1)(ADC_CHANNELS-1 downto 0);
  
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
adcEnable:process(signal_clk) --FIXME move this into generate?
begin
  if rising_edge(signal_clk) then
    if reset2_sclk = '1' then
      enables_reg <= (others => '0');
      fifo_reset <= '1';
      fifo_rd_en <= (others => '0');
    else
      fifo_valid <= not fifo_empty;
      enables_reg <= global.adc_enable;
      enables_reg2 <= enables_reg;
      if unaryOr(enables_reg) then
        enables_valid <= (fifo_valid and enables_reg);
      else
        enables_valid <= (others => '0');
      end if;
      adc_samples <= fifo_dout;
      if (enables_reg2 /= enables_reg) then
        fifo_reset <= '1';
        fifo_rd_en <= (others => '0');
      else
        fifo_reset <= '0';
        if enables_valid = enables_reg2 then 
        	fifo_rd_en <= enables_reg2;
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

	registers:entity tes.channel_registers2
  generic map(
    CHANNEL => c
  )
  port map(
    clk => signal_clk,
    reset => reset1_sclk,
    data => channel_data(c),
    address => channel_address(c),
    write => channel_reg_write(c),
    value => channel_value(c),
    
    registers => channel_registers(c),
    filter_config => filter_config(c),
    filter_events => filter_events(c),
    slope_config => slope_config(c),
    slope_events => slope_events(c),
    baseline_config => baseline_config(c),
    baseline_events => baseline_events(c)
  ); 
  
  regWriteSync:entity tes.sync_2FF
  port map(
    out_clk => signal_clk,
    input => channel_reg_write_io_clk(c),
    output => channel_reg_write(c)
  );

	controller:entity tes.channel_controller
  port map(
    clk => io_clk,
    reset => reset1_ioclk,
    uart_tx => channel_rx(c),
    uart_rx => channel_tx(c),
    reg_address => channel_address(c),
    reg_data => channel_data(c),
    reg_value => channel_value(c),
    reg_write => channel_reg_write_io_clk(c)
  );
  
--  valueReg:process(signal_clk)
--  begin
--    if rising_edge(signal_clk) then
--      value_sel_reg(c) <= value_select; 
--      mca_values_reg(c) <= mca_values(c); --can meet timing without this
--    end if;
--  end process valueReg;
  
end generate tesChannel;
--------------------------------------------------------------------------------

measurementSubsystem:entity tes.measurement_subsystem4
generic map(
  DSP_CHANNELS => DSP_CHANNELS,
  ADC_CHANNELS => ADC_CHANNELS,
  ENDIAN => ENDIAN,
  PACKET_GEN => PACKET_GEN
)
port map(
  clk => signal_clk,
  reset1 => reset1_sclk,
  reset2 => reset2_sclk,
  samples => adc_samples,
  channel_reg => channel_registers,
  global_reg => global,
  filter_config => filter_config,
  filter_events => filter_events,
  slope_config => slope_config,
  slope_events => slope_events,
  baseline_config => baseline_config,
  baseline_events => baseline_events,
  measurements => measurements,
  ethernetstream => ethernetstream,
  ethernetstream_valid => ethernetstream_valid,
  ethernetstream_ready => ethernetstream_ready
);

cdc_din <= '0' & ethernetstream.data(63 downto 56) &
           '0' & ethernetstream.data(55 downto 48) &
           '0' & ethernetstream.data(47 downto 40) &
           '0' & ethernetstream.data(39 downto 32) &
           '0' & ethernetstream.data(31 downto 24) &
           '0' & ethernetstream.data(23 downto 16) &
           '0' & ethernetstream.data(15 downto 8) &
           to_std_logic(ethernetstream.last(0)) & 
           ethernetstream.data(7 downto 0);
           
ethernetstream_ready <= cdc_full='0';
cdc_wr_en <= to_std_logic(ethernetstream_valid); 

cdcFIFO:enet_cdc_fifo
port map (
  wr_clk => signal_clk,
  wr_rst =>	reset1_sclk,
  rd_clk => io_clk,
  rd_rst => reset1_ioclk,
  din => cdc_din,
  wr_en => cdc_wr_en,
  rd_en => cdc_rd_en,
  dout => cdc_dout,
  full => cdc_full,
  empty => cdc_empty
);
cdc_valid <= cdc_empty='0';
cdc_rd_en <= to_std_logic(cdc_ready);

bytestreamReg:entity streamlib.stream_register
generic map(
  WIDTH => 9
)
port map(
  clk => io_clk,
  reset => reset1_ioclk,
  stream_in => cdc_dout,
  ready_out => cdc_ready,
  valid_in => cdc_valid,
  stream => bytestream_int,
  ready => to_boolean(bytestream_ready),
  valid => bytestream_valid
);

bytestream <= bytestream_int(7 downto 0);
--bytestream_last <= bytestream_int(8)='1';

emac:entity work.v6_emac_v2_3
port map(
  global_reset_IO_clk => reset1_ioclk,
  IO_clk => io_clk,
  s_axi_aclk => axi_clk,
  refclk_bufg => ref_clk,
  tx_axis_fifo_tdata => bytestream,
  tx_axis_fifo_tvalid => to_std_logic(bytestream_valid),
  tx_axis_fifo_tready => bytestream_ready,
  tx_axis_fifo_tlast => bytestream_int(8),
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
  clk => signal_clk,
  reset => reset1_sclk,
  --mmcm_locked => fmc108_MMCM_locked,
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

--reset0SignalSync:entity tes.sync_2FF
--port map(
--  out_clk => signal_clk,
--  input => reset0,
--  output => reset0_sclk
--);

reset1SignalSync:entity tes.sync_2FF
port map(
  out_clk => signal_clk,
  input => reset1,
  output => reset1_sclk
);

reset2SignalSync:entity tes.sync_2FF
port map(
  out_clk => signal_clk,
  input => reset2,
--  output => reset2_sclk_sync
  output => reset2_sclk
);

--reset0RefSync:entity tes.sync_2FF
--port map(
--  out_clk => ref_clk,
--  input => reset0,
--  output => reset0_refclk
--);

reset1IOSync:entity tes.sync_2FF
port map(
  out_clk => io_clk,
  input => reset1,
  output => reset1_ioclk
);

--reset2IOSync:entity tes.sync_2FF
--port map(
--  out_clk => io_clk,
--  input => reset2,
--  output => reset2_ioclk
--);

--reset0 <= '0';
ioController:entity tes.main_controller
generic map(
  CHANNELS => DSP_CHANNELS,
  ADC_CHIPS => ADC_CHIPS
)
port map(
  clk => boot_clk,
  reset => global_reset_boot_clk,
  FMC_power_good => FMC_power_good,
  FMC_present => FMC_present,
  FMC_AD9510_status => FMC_AD9510_status,
  fmc_mmcm_locked => fmc108_mmcm_locked, --std_logic(test_counter(30)),
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
