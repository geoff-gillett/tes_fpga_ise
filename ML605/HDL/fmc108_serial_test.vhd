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
 
library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

library mcalib;

library tes;
use tes.types.all;
use tes.functions.all;
use tes.registers.all;
use tes.adc.all;

entity fmc108_serial_test is
generic(
  VERSION:std_logic_vector(31 downto 0):=to_std_logic(23,32);
  DEFAULT_IODELAY_VALUE:integer:=12;
  ADC_CHIPS:integer:=4;
  ADC_CHIP_CHANNELS:integer:=2;
  ADC_BITS:integer:=14
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
  adc_data_n:in ddr_sample_array(ADC_CHIPS*ADC_CHIP_CHANNELS-1 downto 0)
);
end entity fmc108_serial_test;

architecture ML605 of fmc108_serial_test is
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
signal global_reset_IO_clk,IO_clk,signal_clk:std_logic;
signal reset0,reset1,reset2,CPU_reset,fmc108_MMCM_locked:std_logic;

signal refclk : std_logic;
signal onboard_mmcm_locked:std_logic;
signal iodelayctrl_rdy:std_ulogic;
signal reset_enable:std_logic;
signal iodelay_inc:ddr_sample_array(ADC_CHANNELS-1 downto 0);
signal iodelay_ce:ddr_sample_array(ADC_CHANNELS-1 downto 0);
signal iodelay_clk_inc:std_logic_vector(ADC_CHIPS-1 downto 0);
signal iodelay_clk_ce:std_logic_vector(ADC_CHIPS-1 downto 0);

signal adc_chip_clk,adc_clk_bufds:std_logic_vector(ADC_CHIPS-1 downto 0);
signal adc_clk_delayed:std_logic_vector(ADC_CHIPS-1 downto 0);

attribute keep:string;
attribute keep of reset0:signal is "true";
attribute keep of reset1:signal is "true";
attribute keep of reset2:signal is "true";
attribute keep of CPU_reset:signal is "true";

--------------------------------------------------------------------------------
-- FMC108 signals
--------------------------------------------------------------------------------
-- ADC signals
signal adc_ddr,adc_ddr_delay:ddr_sample_array(ADC_CHANNELS-1 downto 0);
signal adc_sdr:adc_sample_array(ADC_CHANNELS-1 downto 0);

signal fifo_reset:std_logic;
signal fifo_reset_chipclk:std_logic_vector(ADC_CHANNELS-1 downto 0);

signal fifo_valid:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal fifo_rd_en:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal enables_reg:std_logic_vector(ADC_CHANNELS-1 downto 0);

signal samples_int,fifo_dout:adc_sample_array(ADC_CHANNElS-1 downto 0);
signal fifo_empty:std_logic_vector(ADC_CHANNELS-1 downto 0);

signal FMC_internal_clk_en_int,FMC_VCO_power_en_int,FMC_present:std_logic;
--------------------------------------------------------------------------------
-- Main CPU signals
--------------------------------------------------------------------------------
signal spi_clk,spi_mosi:std_logic;
signal spi_ce_n,spi_miso:std_logic_vector(SPI_CHANNELS-1 downto 0);
signal write_global_register:boolean;
attribute keep of write_global_register:signal is "true";

signal global:global_registers_t;
signal global_address:register_address_t;
signal global_data : register_data_t;
signal global_value : register_data_t;
signal global_write : boolean;
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
FMC_internal_clk_en <= '1'; --FMC_internal_clk_en_int;
FMC_VCO_power_en <= '1';  --FMC_VCO_power_en_int;
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
fmc108mmcm:fmc108_clk_tree
port map
(
  adc_chip0_clk => adc_chip_clk(0),
  signal_clk => signal_clk,
  io_clk => io_clk,
  locked => fmc108_mmcm_locked
);
    
onboardmmcm:onboard_clk_tree
port map
(
  sys_clk_P => sys_clk_p,
  sys_clk_N => sys_clk_n,
  refclk => refclk,
  locked => onboard_mmcm_locked
);

--TODO add reset?    
idelayctrl_inst:idelayctrl
port map (
   rdy => iodelayctrl_rdy,  -- 1-bit output indicates validity of the refclk
   refclk => refclk, -- 1-bit reference clock input
   rst => '0'        -- 1-bit reset input
);

reset_enable <= fmc108_mmcm_locked and onboard_mmcm_locked and iodelayctrl_rdy;    
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
FMC_present <= not FMC_present_n;

-- map iodelay control bits ce and inc
iodelayControl:process(signal_clk)
	variable ce:std_logic_vector(ADC_BITS/2-1 downto 0);
	variable inc:std_logic_vector(ADC_BITS/2-1 downto 0);
	variable channel_sel:std_logic_vector(ADC_CHANNELS-1 downto 0);
begin
	if rising_edge(signal_clk) then
		
    ce:=global.iodelay_control(ADC_BITS/2-1 downto 0);
    inc:=global.iodelay_control(ADC_BITS-1 downto ADC_BITS/2);
    channel_sel
    	:=global.iodelay_control(ADC_CHANNELS+ADC_BITS-1 downto ADC_BITS);
    iodelay_clk_ce <= global.iodelay_control(
    		ADC_CHIPS+ADC_CHANNELS+ADC_BITS-1 downto
    		ADC_CHANNELS+ADC_BITS);
    iodelay_clk_inc <= global.iodelay_control(
    		2*ADC_CHIPS+ADC_CHANNELS+ADC_BITS-1 downto
    		ADC_CHIPS+ADC_CHANNELS+ADC_BITS);
    		
		for c in ADC_CHANNELS-1 downto 0 loop
			if channel_sel(c)='1' then
				iodelay_ce(c) <= ce;
				iodelay_inc(c) <= inc;
			else
				iodelay_ce(c) <= (others => '0');
				iodelay_inc(c) <= (others  => '0');
			end if;
		end loop;
		--TODO add pipeline here if needed
	end if;
end process iodelayControl;

-- input buffers and iodelays for the ADC chip clocks
-- TODO should there be an iodelay for adc_chip_clk(0)? it drives the MMCM
-- make sure reset sequence is sane
adcClks:for chip in ADC_CHIPS-1 downto 0 generate
begin
	adcClkBufds:ibufds
  generic map(
    DIFF_TERM => TRUE,
    IOSTANDARD => "LVDS_25"
  )
  port map(
    O => adc_clk_bufds(chip),
    I => adc_clk_p(chip),
    IB => adc_clk_n(chip)
  );
  
  adcClkDelay:iodelaye1
  generic map(
    DELAY_SRC => "I",
    IDELAY_TYPE => "VARIABLE",
    IDELAY_VALUE => DEFAULT_IODELAY_VALUE
  )
  port map(
    cntvalueout => open,
    dataout => adc_clk_delayed(chip),
    c => signal_clk,
    ce => iodelay_clk_ce(chip),
    cinvctrl => '0',
    clkin => '0',
    cntvaluein => to_std_logic(to_unsigned(DEFAULT_IODELAY_VALUE,5)),
    datain => '0',
    idatain => adc_clk_bufds(chip),
    inc => iodelay_clk_inc(chip),
    odatain => '0',
    rst => reset0,
    t => '1'
  );
  
  adcClkBufr:bufr
  generic map (
    BUFR_DIVIDE => "BYPASS"
  )
  port map (
    ce => '1',
    clr => '0',
    i  => adc_clk_delayed(chip),
    o  => adc_chip_clk(chip)
  );
end generate;

-- instantiate input buffers, iodelays, DDR to SDR components and CDC FIFOs
-- for each ADC DDR data line.
adcChipGen:for chip in 0 to ADC_CHIPS-1 generate
	begin
  adcChanGen:for chan in 0 to ADC_CHIP_CHANNELS-1 generate
  begin
    adcDdrBitGen:for bit in 0 to ADC_BITS/2-1 generate
  	begin
  	
      dataIbufds:ibufds
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
      dataIoDelay:iodelaye1
      generic map(
        DELAY_SRC => "I",
        IDELAY_TYPE => "VARIABLE",
        IDELAY_VALUE => DEFAULT_IODELAY_VALUE
      )
      port map(
        cntvalueout => open,
        dataout => adc_ddr_delay(chip*ADC_CHIP_CHANNELS+chan)(bit),
        c => signal_clk,
        ce => iodelay_ce(chip*ADC_CHIP_CHANNELS+chan)(bit),
        cinvctrl => '0',
        clkin => '0',
        cntvaluein => to_std_logic(to_unsigned(DEFAULT_IODELAY_VALUE,5)),
        datain => '0',
        idatain => adc_ddr(chip*ADC_CHIP_CHANNELS+chan)(bit),
        inc => iodelay_inc(chip*ADC_CHIP_CHANNELS+chan)(bit),
        odatain => '0',
        rst => reset0,
        t => '1'
      );
      
      -- DDR to SDR conversion  
      dataIddr:iddr
        generic map(DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
        port map(
          q1 => adc_sdr(chip*ADC_CHIP_CHANNELS+chan)(2*bit),
          q2 => adc_sdr(chip*ADC_CHIP_CHANNELS+chan)(2*bit+1),
          c => adc_chip_clk(chip),
          ce => '1',
          d => adc_ddr_delay(chip*ADC_CHIP_CHANNELS+chan)(bit),
          r => reset0,
          s => '0'
        );
        
    end generate adcDdrBitGen;
    
    -- this fifo crosses from the individual chip clk domains the the common 
    -- signal_clk domain.
    FIFO:component adc_fifo
    port map(
      wr_clk => adc_chip_clk(chip),
      rst => fifo_reset_chipclk(chip),
      rd_clk => signal_clk,
      din => adc_sdr(chip*ADC_CHIP_CHANNELS+chan),
      wr_en => '1',
      rd_en => fifo_rd_en(chip*ADC_CHIP_CHANNELS+chan),
      dout => fifo_dout(chip*ADC_CHIP_CHANNELS+chan),
      full => open,
      empty => fifo_empty(chip*ADC_CHIP_CHANNELS+chan)
    );
    
    -- register the fifo douts and fifo_valid (not empty)
    fifoReg:process(signal_clk)
    begin
      if rising_edge(signal_clk) then
        samples_int(chip*ADC_CHIP_CHANNELS+chan) 
        	<= fifo_dout(chip*ADC_CHIP_CHANNELS+chan);
        fifo_valid <= not fifo_empty;
      end if;
    end process fifoReg;
    
  end generate adcChanGen;
 
 	-- sync fifo reset to the individual chip_clks 
  resetSync:entity tes.sync_level
  generic map(INITIALISE => "11")
  port map(
    clk => adc_chip_clk(chip),
    data_in => fifo_reset,
    data_out => fifo_reset_chipclk(chip)
  );
  
end generate adcChipGen;

-- control is via adc_enables
-- When enable changes pulse FIFO reset and wait till all enabled FIFOs are 
-- not empty before asserting setting rd_en
enable:process(signal_clk)
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
            fifo_rd_en <= fifo_valid;
        end if;
      end if;
    end if;
  end if;
end process enable;

--------------------------------------------------------------------------------

globalReg:entity tes.global_registers
generic map(
  HDL_VERSION => VERSION
)
port map(
  reg_clk => io_clk,
  reg_reset => reset0,
  data => global_data,
  address => global_address,
  value => global_value,
  write => global_write,
  registers => global
);

mainCpu:entity tes.io_controller
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
  pipeline_mmcm_locked => fmc108_mmcm_locked,
  reset0 => reset0,
  reset1 => reset1,
  reset2 => reset2,
  interrupt => FALSE,
  interrupt_ack => open,
  main_rx => main_Rx,
  main_tx => main_Tx,
  channel_rx => (others => '0'),
  channel_tx => open,
  spi_clk => spi_clk,
  spi_ce_n => spi_ce_n,
  spi_miso => spi_miso,
  spi_mosi => spi_mosi,
  address => global_address,
  data_out => global_data,
  data_in => global_value,
  write => global_write
);

end architecture ML605;
