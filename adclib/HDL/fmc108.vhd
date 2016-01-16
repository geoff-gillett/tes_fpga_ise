--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:31/01/2014 
--
-- Design Name: TES_digitiser
-- Module Name: FMC108
-- Project Name: ADC_hardware
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
use work.types.all;

library unisim;
use unisim.vcomponents.iodelaye1;
use unisim.vcomponents.iddr;
--! The FMC108 has four Ti ADS62P49 each with two 14 bit 250 Mhz ADCs
--! Each chip is in LVDS mode
--! This entity wraps the general LVDS IBUF entity and unfolds the 2D arrays
--! for use in UCF LOCS
entity fmc108 is
generic(
  ADC_CHIPS:integer:=4;
  CHIP_CHANNELS:integer:=2;
  IODELAY_VALUE:integer:=12
);
port (
  pipeline_clk:in std_logic; --common output clock
  reset:in std_logic;
  --!* Individual chip clocks
  chip_clks:in std_logic_vector(ADC_CHIPS-1 downto 0);
  adc_enables:in boolean_vector(ADC_CHIPS*CHIP_CHANNELS-1 downto 0);
  adc_ddr:in ddr_sample_array(ADC_CHIPS*CHIP_CHANNELS-1 downto 0);
  -- iodelay control
  inc:in std_logic_vector(ADC_BITS/2-1 downto 0);
  dec:in std_logic_vector(ADC_BITS/2-1 downto 0);
  channel:in unsigned(ceilLog2(ADC_CHIPS*CHIP_CHANNELS)-1 downto 0);
  update:in boolean;
  --
  samples:out adc_sample_array(ADC_CHIPS*CHIP_CHANNELS-1 downto 0);
  fifo_full:out boolean_vector(ADC_CHIPS*CHIP_CHANNELS-1 downto 0);
  samples_valid:out boolean
);
end entity fmc108;
--
architecture wrapper of fmc108 is
constant ADC_CHANNELS:integer:=ADC_CHIPS*CHIP_CHANNELS;
--assures there are a few samples in the adc fifos before reading starts
constant WR_EN_DELAY:integer:=8;
constant RD_EN_DELAY:integer:=2;
--
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
--
signal adc_ddr_delay:ddr_sample_array(ADC_CHANNELS-1 downto 0);
signal adc_sdr,fifo_dout:adc_sample_array(ADC_CHANNELS-1 downto 0);
signal fifo_reset_chipclk:std_logic_vector(ADC_CHANNELS-1 downto 0)
       :=(others => '1');
signal fifo_valid:boolean_vector(ADC_CHANNELS-1 downto 0);
signal fifo_reset:std_logic_vector(ADC_CHANNELS-1 downto 0):=(others => '1');
signal fifo_wr_en_chipclk,fifo_wr_en:std_logic_vector(ADC_CHANNELS-1 downto 0)
       :=(others => '0');
signal fifo_rd_en:boolean_vector(ADC_CHANNELS-1 downto 0);
signal enables_reg:boolean_vector(ADC_CHANNELS-1 downto 0);

signal samples_int:adc_sample_array(ADC_CHANNElS-1 downto 0);
signal fifo_full_chipclk,fifo_empty:std_logic_vector(ADC_CHANNELS-1 downto 0);
signal fifo_full_int:std_logic_vector(ADC_CHANNELS-1 downto 0);
attribute keep:string;
attribute keep of fifo_full_int:signal is "true";

subtype iodelay_cntrl is std_logic_vector(ADC_BITS/2-1 downto 0);
type iodelay_cntrl_array is array (ADC_CHANNELS-1 downto 0) of iodelay_cntrl;
signal inc_chipclk:iodelay_cntrl_array;
signal ce_chipclk:iodelay_cntrl_array;
signal ce:iodelay_cntrl_array;

begin
--
fifo_full <= to_boolean(fifo_full_int);
samples <= samples_int;
--
chipGen:for chip in 0 to ADC_CHIPS-1 generate
  chanGen:for chan in 0 to CHIP_CHANNELS-1 generate
    bitGen:for bit in 0 to ADC_BITS/2-1 generate
      
      incSync:entity teslib.sync_pulse
      generic map(INITIALISE => "0000")
      port map(
        in_clk => pipeline_clk,
        out_clk => chip_clks(chip),
        pulse_in => inc(bit),
        pulse_out => inc_chipclk(chip*CHIP_CHANNELS+chan)(bit)
      );
      
      ce(chip*CHIP_CHANNELS+chan)(bit) <= (inc(bit) or dec(bit)) 
                 and to_std_logic(
                   channel=to_unsigned(chip*CHIP_CHANNELS+chan,ADC_CHANNELS)
                 )
                 and to_std_logic(update);

      ceSync:entity teslib.sync_pulse
      generic map(INITIALISE => "0000")
      port map(
        in_clk => pipeline_clk,
        out_clk => chip_clks(chip),
        pulse_in =>ce(chip*CHIP_CHANNELS+chan)(bit),
        pulse_out => ce_chipclk(chip*CHIP_CHANNELS+chan)(bit)
      );
      
      ioDelay:iodelaye1
        generic map(
          DELAY_SRC => "I",
          IDELAY_TYPE => "VARIABLE",
          IDELAY_VALUE => IODELAY_VALUE
        )
        port map(
          cntvalueout => open,
          dataout => adc_ddr_delay(chip*CHIP_CHANNELS+chan)(bit),
          c => chip_clks(chip),
          ce => ce_chipclk(chip*CHIP_CHANNELS+chan)(bit),
          cinvctrl => '0',
          clkin => '0',
          cntvaluein => to_std_logic(to_unsigned(IODELAY_VALUE,5)),
          datain => '0',
          idatain => adc_ddr(chip*CHIP_CHANNELS+chan)(bit),
          inc => inc_chipclk(chip*CHIP_CHANNELS+chan)(bit),
          odatain => '0',
          rst => reset,
          t => '1'
        );
        
      bitIddr:iddr
        generic map(DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
        port map(
          q1 => adc_sdr(chip*CHIP_CHANNELS+chan)(2*bit),
          q2 => adc_sdr(chip*CHIP_CHANNELS+chan)(2*bit+1),
          c => chip_clks(chip),
          ce => '1',
          d => adc_ddr_delay(chip*CHIP_CHANNELS+chan)(bit),
          r => reset,
          s => '0'
        );
        
    end generate bitGen;
    
    FIFO:component adc_fifo
    port map(
      wr_clk => chip_clks(chip),
      rst => fifo_reset_chipclk(chip*CHIP_CHANNELS+chan),
      rd_clk => pipeline_clk,
      din => adc_sdr(chip*CHIP_CHANNELS+chan),
      wr_en => fifo_wr_en_chipclk(chip*CHIP_CHANNELS+chan),
      rd_en => to_std_logic(fifo_rd_en(chip*CHIP_CHANNELS+chan)),
      dout => fifo_dout(chip*CHIP_CHANNELS+chan),
      full => fifo_full_chipclk(chip*CHIP_CHANNELS+chan),
      empty => fifo_empty(chip*CHIP_CHANNELS+chan)
    );
    
    resetSync:entity teslib.sync_level
    generic map(INITIALISE => "11")
    port map(
      clk => chip_clks(chip),
      data_in => fifo_reset(chip*CHIP_CHANNELS+chan),
      data_out => fifo_reset_chipclk(chip*CHIP_CHANNELS+chan)
    );
    
    fullSync:entity teslib.sync_level
    port map(
      clk => pipeline_clk,
      data_in => fifo_full_chipclk(chip*CHIP_CHANNELS+chan),
      data_out => fifo_full_int(chip*CHIP_CHANNELS+chan)
    );
    
    wrEnSync:entity teslib.sync_level
    port map(
      clk => chip_clks(chip),
      data_in => fifo_wr_en(chip*CHIP_CHANNELS+chan),
      data_out => fifo_wr_en_chipclk(chip*CHIP_CHANNELS+chan)
    );
    
    fifoReg:process(pipeline_clk)
    begin
      if rising_edge(pipeline_clk) then
        samples_int(chip*CHIP_CHANNELS+chan) 
          <= fifo_dout(chip*CHIP_CHANNELS+chan);
        fifo_valid(chip*CHIP_CHANNELS+chan) 
          <= to_boolean(not fifo_empty(chip*CHIP_CHANNELS+chan));
      end if;
    end process fifoReg;
    
  end generate chanGen;
end generate chipGen;
-- 
-- Main control is via adc_enables
-- When enable goes low want to pulse FIFO reset
-- When enable goes high want to wait till all enabled FIFOs are not empty
-- then delay to accumulate a few samples
-- before setting valid and rd_en
--fifo_wr_en_chipclk <= not fifo_reset_chipclk;
enable:process(pipeline_clk)
variable wr_delay:integer range 0 to WR_EN_DELAY;
variable rd_delay:integer range 0 to RD_EN_DELAY;
begin
if rising_edge(pipeline_clk) then
  if reset = '1' then
    wr_delay:=WR_EN_DELAY;
    rd_delay:=RD_EN_DELAY;
    samples_valid <= FALSE;
    enables_reg <= (others => FALSE);
    fifo_reset <= (others => '1');
    fifo_rd_en <= (others => FALSE);
  else
    enables_reg <= adc_enables;
    if (enables_reg /= adc_enables) then
      fifo_reset <= (others => '1');
      fifo_rd_en <= (others => FALSE);
      fifo_wr_en <= (others => '0');
      wr_delay:=WR_EN_DELAY;
      rd_delay:=RD_EN_DELAY;
      samples_valid <= FALSE;
    else
      fifo_reset <= to_std_logic(not enables_reg);
      if wr_delay/=0 then
        wr_delay:=wr_delay-1;
      else
        fifo_wr_en <= to_std_logic(enables_reg);
      end if;
      if fifo_valid=enables_reg then 
        if rd_delay=0 then
          fifo_rd_en <= fifo_valid;
          samples_valid <= TRUE;
        else
          rd_delay:=rd_delay-1;
        end if;
      end if;
    end if;
  end if;
end if;
end process enable;
--
end architecture wrapper;
