--------------------------------------------------------------------------------
-- Project    : Xilinx LogiCORE Virtex-6 Embedded Tri-Mode Ethernet MAC
-- File       : v6_emac_v2_3_0_example_design.vhd
-- Version    : 2.3
-------------------------------------------------------------------------------
--
-- (c) Copyright 2004-2011 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-- Description:  This is the VHDL example design for the Virtex-6
--               Embedded Tri-Mode Ethernet MAC. It is intended that this
--               example design can be quickly adapted and downloaded onto
--               an FPGA to provide a real hardware test environment.
--
--               This level:
--
--               * Instantiates the FIFO Block wrapper, containing the
--                 block level wrapper and an RX and TX FIFO with an
--                 AXI-S interface;
--
--               * Instantiates a simple AXI-S example design,
--                 providing an address swap and a simple
--                 loopback function;
--
--               * Instantiates transmitter clocking circuitry
--                   -the User side of the FIFOs are clocked at gtx_clk
--                    at all times
--
--               * Instantiates a state machine which drives the AXI Lite
--                 interface to bring the TEMAC up in the correct state
--
--               * Serializes the Statistics vectors to prevent logic being
--                 optimized out
--
--               * Ties unused inputs off to reduce the number of IO
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
--               further information.
--
--
--    ---------------------------------------------------------------------
--    | EXAMPLE DESIGN WRAPPER                                            |
--    |           --------------------------------------------------------|
--    |           |FIFO BLOCK WRAPPER                                     |
--    |           |                                                       |
--    |           |                                                       |
--    |           |              -----------------------------------------|
--    |           |              | BLOCK LEVEL WRAPPER                    |
--    | --------  |              |                                        |
--    | |      |  |              |      -------------------               |
--    | | AXI  |--|--------------|----->|                 |               |
--    | | LITE |  |              |      | AXI4-Lite IPIF  |               |
--    | |  SM  |  |              |      |                 |               |
--    | |      |<-|--------------|------|                 |               |
--    | |      |  |              |      -------------------               |
--    | --------  |              |         |    |                         |
--    |           |              |    ---------------------               |
--    |           |              |    |   V6 EMAC CORE    |               |
--    |           |              |    |                   |               |
--    |           |              |    |                   |               |
--    |           |              |    |                   |               |
--    |           |              |    |                   |               |
--    | --------  |  ----------  |    |                   |               |
--    | |      |  |  |        |  |    |                   |  ---------    |
--    | |      |->|->|        |--|--->| Tx            Tx  |--|       |--->|
--    | |      |  |  |        |  |    | AXI-S         PHY |  |       |    |
--    | | ADDR |  |  |        |  |    | I/F           I/F |  |       |    |
--    | | SWAP |  |  |  AXI-S |  |    |                   |  | PHY   |    |
--    | |      |  |  |  FIFO  |  |    |                   |  | I/F   |    |
--    | |      |  |  |        |  |    |                   |  |       |    |
--    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
--    | |      |  |  |        |  |    | AX)-S         PHY |  |       |    |
--    | |      |<-|<-|        |<-|----| I/F           I/F |<-|       |<---|
--    | |      |  |  |        |  |    |                   |  ---------    |
--    | --------  |  ----------  |    ---------------------               |
--    |           |              |           |     |                      |
--    |           |              |        --------------                  |
--    |           |              |        |  STATS     |                  |
--    |           |              |        |    DECODE  |                  |
--    |           |              |        |            |                  |
--    |           |              |        --------------                  |
--    |           |              |                                        |
--    |           |              -----------------------------------------|
--    |           --------------------------------------------------------|
--    ---------------------------------------------------------------------
--
--------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.PULLUP;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
--! Modification of the example design wrapper
--! Rempve the addr swap module and expose the tx fifo interface
--! Move MMCM and reset generators to outside
--! TODO this is a simple hack if time do the following: (in order of priority)
--! deepen the TX side FIFO to enable jumbo frames
--! remove all RX side logic as it is not used
--! replace AXI FSM with the central picoblaze
--------------------------------------------------------------------------------

entity v6_emac_v2_3 is
port(
    -- global reset synced to IO clk
  global_reset_IO_clk:in std_logic; --!

  -- 200MHz clock input from board
  --clk_in_p              : in  std_logic;
  --clk_in_n              : in  std_logic;
  --! clk tree (MMCM moved outside of entity)
  IO_clk:in std_logic; --! 125Mhz 
  s_axi_aclk:in std_logic; --! 100Mhz,
  refclk_bufg:in std_logic; --! 200Mhz
  
  --! tx fifo interface exposed
  tx_axis_fifo_tdata:in std_logic_vector(7 downto 0);
  tx_axis_fifo_tvalid:in std_logic;
  tx_axis_fifo_tready:out std_logic;
  tx_axis_fifo_tlast:in std_logic;
  
  ------------------------------------------------------------------------------
  phy_resetn:out std_logic;
  -- GMII Interface
  -----------------
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

  -- MDIO Interface
  -----------------
  mdio:inout std_logic;
  mdc:out std_logic;

  -- Serialised statistics vectors
  --------------------------------
  tx_statistics_s:out std_logic;
  rx_statistics_s:out std_logic;

  -- Serialised Pause interface controls
  --------------------------------------
  pause_req_s:in std_logic;

  -- Main example design controls
  -------------------------------
  mac_speed:in std_logic_vector(1 downto 0);
  update_speed:in std_logic;
  serial_command:in std_logic;
  serial_response:out std_logic;
 -- gen_tx_data:in std_logic;
 -- chk_tx_data:in std_logic;
 -- swap_address:in std_logic;
  reset_error:in std_logic;
  frame_error:out std_logic;
  frame_errorn:out std_logic
);
end v6_emac_v2_3;

architecture modifed_example_design of v6_emac_v2_3 is

  ------------------------------------------------------------------------------
  -- Component Declaration for the Tri-Mode EMAC core FIFO Block wrapper
  ------------------------------------------------------------------------------

component v6_emac_v2_3_0_fifo_block
generic(
  MAC_BASE_ADDR : std_logic_vector(31 downto 0) := X"00000000"
);
port(
  gtx_clk : in std_logic;
  -- Receiver Statistics Interface
  -----------------------------------------
  rx_mac_aclk:out std_logic;
  rx_reset:out std_logic;
  rx_statistics_vector:out std_logic_vector(27 downto 0);
  rx_statistics_valid:out std_logic;

  -- Receiver (AXI-S) Interface
  ------------------------------------------
  rx_fifo_clock:in std_logic;
  rx_fifo_resetn:in std_logic;
  rx_axis_fifo_tdata:out std_logic_vector(7 downto 0);
  rx_axis_fifo_tvalid:out std_logic;
  rx_axis_fifo_tready:in std_logic;
  rx_axis_fifo_tlast:out std_logic;

  -- Transmitter Statistics Interface
  --------------------------------------------
  tx_mac_aclk:out std_logic;
  tx_reset:out std_logic;
  tx_ifg_delay:in std_logic_vector(7 downto 0);
  tx_statistics_vector:out std_logic_vector(31 downto 0);
  tx_statistics_valid:out std_logic;

  -- Transmitter (AXI-S) Interface
  ---------------------------------------------
  tx_fifo_clock:in std_logic;
  tx_fifo_resetn:in std_logic;
  tx_axis_fifo_tdata:in std_logic_vector(7 downto 0);
  tx_axis_fifo_tvalid:in std_logic;
  tx_axis_fifo_tready:out std_logic;
  tx_axis_fifo_tlast:in std_logic;

  -- MAC Control Interface
  --------------------------
  pause_req:in std_logic;
  pause_val:in std_logic_vector(15 downto 0);

  -- Reference clock for IDELAYCTRL's
  refclk:in std_logic;

  -- GMII Interface
  -------------------
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

  -- MDIO Interface
  -------------------
  mdio_i:in std_logic;
  mdio_o:out std_logic;
  mdio_t:out std_logic;
  mdc:out std_logic;

  -- AXI-Lite Interface
  -----------------
  s_axi_aclk:in std_logic;
  s_axi_resetn:in std_logic;

  s_axi_awaddr:in std_logic_vector(31 downto 0);
  s_axi_awvalid:in std_logic;
  s_axi_awready:out std_logic;

  s_axi_wdata:in std_logic_vector(31 downto 0);
  s_axi_wvalid:in std_logic;
  s_axi_wready:out std_logic;

  s_axi_bresp:out std_logic_vector(1 downto 0);
  s_axi_bvalid:out std_logic;
  s_axi_bready:in std_logic;

  s_axi_araddr:in std_logic_vector(31 downto 0);
  s_axi_arvalid:in std_logic;
  s_axi_arready:out std_logic;

  s_axi_rdata:out std_logic_vector(31 downto 0);
  s_axi_rresp:out std_logic_vector(1 downto 0);
  s_axi_rvalid:out std_logic;
  s_axi_rready:in std_logic;

  -- asynchronous reset
  glbl_rstn:in std_logic;
  rx_axi_rstn:in std_logic;
  tx_axi_rstn:in std_logic
);
end component;

  ------------------------------------------------------------------------------
  -- Component Declaration for the basic pattern generator
  ------------------------------------------------------------------------------

--   component basic_pat_gen
--   port (
--    axi_tclk                    : in  std_logic;
--    axi_tresetn                 : in  std_logic;
--    check_resetn                : in  std_logic;
--
--    enable_pat_gen              : in  std_logic;
--    enable_pat_chk              : in  std_logic;
--    enable_address_swap         : in  std_logic;
--
--    -- data from the RX FIFO
--    rx_axis_fifo_tdata          : in  std_logic_vector(7 downto 0);
--    rx_axis_fifo_tvalid         : in  std_logic;
--    rx_axis_fifo_tlast          : in  std_logic;
--    rx_axis_fifo_tready         : out std_logic;
--
--    -- data TO the tx fifo
--    tx_axis_fifo_tdata          : out std_logic_vector(7 downto 0);
--    tx_axis_fifo_tvalid         : out std_logic;
--    tx_axis_fifo_tlast          : out std_logic;
--    tx_axis_fifo_tready         : in  std_logic;
--
--    frame_error                 : out std_logic
--   );
--   end component;

  ------------------------------------------------------------------------------
  -- Component Declaration for the AXI-Lite State machine
  ------------------------------------------------------------------------------

component axi_lite_sm
generic (
  BOARD_PHY_ADDR            : std_logic_vector(7 downto 0) := "00000111";
  MAC_BASE_ADDR             : std_logic_vector(31 downto 0) := X"00000000"
);
port(
  s_axi_aclk : in std_logic;
  s_axi_resetn : in std_logic;

  mac_speed : in std_logic_vector(1 downto 0);
  update_speed : in std_logic;
  serial_command : in std_logic;
  serial_response : out std_logic;

  s_axi_awaddr : out std_logic_vector(31 downto 0);
  s_axi_awvalid : out std_logic;
  s_axi_awready : in std_logic;

  s_axi_wdata : out std_logic_vector(31 downto 0);
  s_axi_wvalid : out std_logic;
  s_axi_wready : in std_logic;

  s_axi_bresp : in std_logic_vector(1 downto 0);
  s_axi_bvalid : in std_logic;
  s_axi_bready : out std_logic;

  s_axi_araddr : out std_logic_vector(31 downto 0);
  s_axi_arvalid : out std_logic;
  s_axi_arready : in std_logic;

  s_axi_rdata : in std_logic_vector(31 downto 0);
  s_axi_rresp : in std_logic_vector(1 downto 0);
  s_axi_rvalid : in std_logic;
  s_axi_rready : out std_logic
);
end component;

  ------------------------------------------------------------------------------
  -- Component Declaration for the Clock generator
  ------------------------------------------------------------------------------

--   component clk_wiz_v2_1
--   port (
--      -- Clock in ports
--      CLK_IN1_P                 : in  std_logic;
--      CLK_IN1_N                 : in  std_logic;
--      -- Clock out ports
--      CLK_OUT1                  : out std_logic;
--      CLK_OUT2                  : out std_logic;
--      CLK_OUT3                  : out std_logic;
--      -- Status and control signals
--      RESET                     : in  std_logic;
--      LOCKED                    : out std_logic
--   );
--   end component;


  ------------------------------------------------------------------------------
  -- Component declaration for the reset synchroniser
  ------------------------------------------------------------------------------
  component reset_sync
  port (
     reset_in                   : in  std_logic;    -- Active high asynchronous reset
     enable                     : in  std_logic;
     clk                        : in  std_logic;    -- clock to be sync'ed to
     reset_out                  : out std_logic     -- "Synchronised" reset signal
  );
  end component;

  ------------------------------------------------------------------------------
  -- Component declaration for the synchroniser
  ------------------------------------------------------------------------------
  component sync_block
  port (
     clk                        : in  std_logic;
     data_in                    : in  std_logic;
     data_out                   : out std_logic
  );
  end component;

   ------------------------------------------------------------------------------
   -- Constants used in this top level wrapper.
   ------------------------------------------------------------------------------
   constant MAC_BASE_ADDR                   : std_logic_vector(31 downto 0) := X"00000000";
   constant BOARD_PHY_ADDR                  : std_logic_vector(7 downto 0)  := "00000111";


   ------------------------------------------------------------------------------
   -- internal signals used in this top level wrapper.
   ------------------------------------------------------------------------------

   -- example design clocks
   signal gtx_clk_bufg                      : std_logic;
   --signal refclk_bufg                       : std_logic;
   --signal s_axi_aclk                        : std_logic;
   signal rx_mac_aclk                       : std_logic;
   signal tx_mac_aclk                       : std_logic;


   signal phy_resetn_int                    : std_logic;

   -- resets (and reset generation)
   signal s_axi_reset_int                   : std_logic;
   signal s_axi_pre_resetn                  : std_logic := '0';
   signal s_axi_resetn                      : std_logic := '0';
   signal local_chk_reset                   : std_logic;
   signal chk_reset_int                     : std_logic;
   signal chk_pre_resetn                    : std_logic := '0';
   signal chk_resetn                        : std_logic := '0';
   signal local_gtx_reset                   : std_logic;
   signal gtx_clk_reset_int                 : std_logic;
   signal gtx_pre_resetn                    : std_logic := '0';
   signal gtx_resetn                        : std_logic := '0';
   signal rx_reset                          : std_logic;
   signal tx_reset                          : std_logic;

  -- signal dcm_locked                        : std_logic;
--   signal glbl_rst_int                      : std_logic;
   signal phy_reset_count                   : unsigned(5 downto 0);
   signal glbl_rst_intn                     : std_logic;

   -- USER side RX AXI-S interface
   signal rx_fifo_clock                     : std_logic;
   signal rx_fifo_resetn                    : std_logic;
   signal rx_axis_fifo_tdata                : std_logic_vector(7 downto 0);
   signal rx_axis_fifo_tvalid               : std_logic;
   signal rx_axis_fifo_tlast                : std_logic;
   signal rx_axis_fifo_tready               : std_logic;

   -- USER side TX AXI-S interface
   signal tx_fifo_clock                     : std_logic;
   signal tx_fifo_resetn                    : std_logic;
   --signal tx_axis_fifo_tdata                : std_logic_vector(7 downto 0);
   --signal tx_axis_fifo_tvalid               : std_logic;
   --signal tx_axis_fifo_tlast                : std_logic;
   --signal tx_axis_fifo_tready               : std_logic;

   -- RX Statistics serialisation signals
   signal rx_statistics_valid               : std_logic;
   signal rx_statistics_valid_reg           : std_logic;
   signal rx_statistics_vector              : std_logic_vector(27 downto 0);
   signal rx_stats                          : std_logic_vector(27 downto 0);
   signal rx_stats_toggle                   : std_logic := '0';
   signal rx_stats_toggle_sync              : std_logic;
   signal rx_stats_toggle_sync_reg          : std_logic := '0';
   signal rx_stats_shift                    : std_logic_vector(29 downto 0);

   -- TX Statistics serialisation signals
   signal tx_statistics_valid               : std_logic;
   signal tx_statistics_valid_reg           : std_logic;
   signal tx_statistics_vector              : std_logic_vector(31 downto 0);
   signal tx_stats                          : std_logic_vector(31 downto 0);
   signal tx_stats_toggle                   : std_logic := '0';
   signal tx_stats_toggle_sync              : std_logic;
   signal tx_stats_toggle_sync_reg          : std_logic := '0';
   signal tx_stats_shift                    : std_logic_vector(33 downto 0);

   -- Pause interface DESerialisation
   signal pause_shift                       : std_logic_vector(17 downto 0);
   signal pause_req                         : std_logic;
   signal pause_val                         : std_logic_vector(15 downto 0);


   -- AXI-Lite interface
   signal s_axi_awaddr                      : std_logic_vector(31 downto 0);
   signal s_axi_awvalid                     : std_logic;
   signal s_axi_awready                     : std_logic;
   signal s_axi_wdata                       : std_logic_vector(31 downto 0);
   signal s_axi_wvalid                      : std_logic;
   signal s_axi_wready                      : std_logic;
   signal s_axi_bresp                       : std_logic_vector(1 downto 0);
   signal s_axi_bvalid                      : std_logic;
   signal s_axi_bready                      : std_logic;
   signal s_axi_araddr                      : std_logic_vector(31 downto 0);
   signal s_axi_arvalid                     : std_logic;
   signal s_axi_arready                     : std_logic;
   signal s_axi_rdata                       : std_logic_vector(31 downto 0);
   signal s_axi_rresp                       : std_logic_vector(1 downto 0);
   signal s_axi_rvalid                      : std_logic;
   signal s_axi_rready                      : std_logic;

   -- signal tie offs
   signal tx_ifg_delay                      : std_logic_vector(7 downto 0) := (others => '0');    -- not used in this example
  signal mdio_i                             : std_logic;
  signal mdio_o                             : std_logic;
  signal mdio_t                             : std_logic;

  signal int_frame_error                    : std_logic;

  attribute keep : string;
  attribute keep of gtx_clk_bufg             : signal is "true";
  attribute keep of refclk_bufg              : signal is "true";
  attribute keep of rx_statistics_valid      : signal is "true";
  attribute keep of rx_statistics_vector     : signal is "true";
  attribute keep of tx_statistics_valid      : signal is "true";
  attribute keep of tx_statistics_vector     : signal is "true";
  attribute keep of s_axi_aclk               : signal is "true";
  attribute keep of s_axi_awaddr             : signal is "true";
  attribute keep of s_axi_awvalid            : signal is "true";
  attribute keep of s_axi_awready            : signal is "true";
  attribute keep of s_axi_wdata              : signal is "true";
  attribute keep of s_axi_wvalid             : signal is "true";
  attribute keep of s_axi_wready             : signal is "true";
  attribute keep of s_axi_bresp              : signal is "true";
  attribute keep of s_axi_bvalid             : signal is "true";
  attribute keep of s_axi_bready             : signal is "true";
  attribute keep of s_axi_araddr             : signal is "true";
  attribute keep of s_axi_arvalid            : signal is "true";
  attribute keep of s_axi_arready            : signal is "true";
  attribute keep of s_axi_rdata              : signal is "true";
  attribute keep of s_axi_rresp              : signal is "true";
  attribute keep of s_axi_rvalid             : signal is "true";
  attribute keep of s_axi_rready             : signal is "true";

  ------------------------------------------------------------------------------
  -- Begin architecture
  ------------------------------------------------------------------------------

begin

frame_error  <= int_frame_error;
frame_errorn <= not int_frame_error;

------------------------------------------------------------------------------
-- Infer the IOBUF for MDIO
------------------------------------------------------------------------------
mdio <= 'Z' when mdio_t = '1' else mdio_o;

mdio_i <= mdio;

mdio_pu : PULLUP
port map(
  O => mdio_i
);



   ------------------------------------------------------------------------------
   -- Clock logic to generate required clocks from the 200MHz on board
   -- if 125MHz is available directly this can be removed
   ------------------------------------------------------------------------------
--   clock_generator : clk_wiz_v2_1
--   port map (
--      -- Clock in ports
--      CLK_IN1_P         => clk_in_p,
--      CLK_IN1_N         => clk_in_n,
--      -- Clock out ports
--      CLK_OUT1          => gtx_clk_bufg, --this is 125 Mhz
--      CLK_OUT2          => s_axi_aclk,  -- axi lite  100Mhz?
--      CLK_OUT3          => refclk_bufg, -- IO delay controls 200Mhz?
--      -- Status and control signals
--      RESET             => glbl_rst,
--      LOCKED            => dcm_locked
--   );
gtx_clk_bufg <= IO_clk;
--s_axi_aclk <= IO_clk;

   ----------------- Move this out side
   -- global reset
--glbl_reset_gen : reset_sync
--port map(
--  clk => gtx_clk_bufg,
--  enable => dcm_locked,
--  reset_in => glbl_rst,
--  reset_out => glbl_rst_int
--);

glbl_rst_intn <= not global_reset_IO_clk;

-- generate the user side clocks for the axi fifos
tx_fifo_clock <= gtx_clk_bufg;
rx_fifo_clock <= gtx_clk_bufg;

   ------------------------------------------------------------------------------
   -- Generate resets required for the fifo side signals plus axi_lite logic
   ------------------------------------------------------------------------------
   -- in each case the async reset is first captured and then synchronised

   -----------------
   -- AXI-Lite reset
   axi_lite_reset_gen:reset_sync
   port map (
       clk              => s_axi_aclk,
       --enable           => dcm_locked,
       enable           => '1',
       reset_in         => global_reset_IO_clk,
       reset_out        => s_axi_reset_int
   );

   -- Create fully synchronous reset in the s_axi clock domain.
   gen_axi_reset : process (s_axi_aclk)
   begin
     if s_axi_aclk'event and s_axi_aclk = '1' then
     --if IO_clk'event and IO_clk = '1' then
       if s_axi_reset_int = '1' then
         s_axi_pre_resetn  <= '0';
         s_axi_resetn      <= '0';
       else
         s_axi_pre_resetn  <= '1';
         s_axi_resetn      <= s_axi_pre_resetn;
       end if;
     end if;
   end process gen_axi_reset;


  local_chk_reset <= global_reset_IO_clk or reset_error;

  -----------------
  -- data check reset
   chk_reset_gen : reset_sync
   port map (
       clk              => gtx_clk_bufg,
       --enable           => dcm_locked,
       enable           => '1',
       reset_in         => local_chk_reset,
       reset_out        => chk_reset_int
   );

   -- Create fully synchronous reset in the gtx clock domain.
   gen_chk_reset : process (gtx_clk_bufg)
   begin
     if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
       if chk_reset_int = '1' then
         chk_pre_resetn   <= '0';
         chk_resetn       <= '0';
       else
         chk_pre_resetn   <= '1';
         chk_resetn       <= chk_pre_resetn;
       end if;
     end if;
   end process gen_chk_reset;

  local_gtx_reset <= global_reset_IO_clk or rx_reset or tx_reset;

  -----------------
  -- gtx_clk reset
   gtx_reset_gen : reset_sync
   port map (
       clk              => gtx_clk_bufg,
       --enable           => dcm_locked,
       enable           => '1',
       reset_in         => local_gtx_reset,
       reset_out        => gtx_clk_reset_int
   );

   -- Create fully synchronous reset in the s_axi clock domain.
   gen_gtx_reset : process (gtx_clk_bufg)
   begin
     if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
       if gtx_clk_reset_int = '1' then
         gtx_pre_resetn   <= '0';
         gtx_resetn       <= '0';
       else
         gtx_pre_resetn   <= '1';
         gtx_resetn       <= gtx_pre_resetn;
       end if;
     end if;
   end process gen_gtx_reset;


   -----------------
   -- PHY reset
   -- the phy reset output (active low) needs to be held for at least 10x25MHZ cycles
   -- this is derived using the 125MHz available and a 6 bit counter
   gen_phy_reset : process (gtx_clk_bufg)
   begin
     if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
       if glbl_rst_intn = '0' then
         phy_resetn_int       <= '0';
         phy_reset_count      <= (others => '0');
       else
          if phy_reset_count /= "111111" then
             phy_reset_count <= phy_reset_count + "000001";
          else
             phy_resetn_int   <= '1';
          end if;
       end if;
     end if;
   end process gen_phy_reset;

   phy_resetn <= phy_resetn_int;

   -- generate the user side resets for the axi fifos
   tx_fifo_resetn <= gtx_resetn;
   rx_fifo_resetn <= gtx_resetn;

  ------------------------------------------------------------------------------
  -- Serialize the stats vectors
  -- This is a single bit approach, retimed onto gtx_clk
  -- this code is only present to prevent code being stripped..
  ------------------------------------------------------------------------------

  -- RX STATS

  -- first capture the stats on the appropriate clock
   capture_rx_stats : process (rx_mac_aclk)
   begin
      if rx_mac_aclk'event and rx_mac_aclk = '1' then
         rx_statistics_valid_reg <= rx_statistics_valid;
         if rx_statistics_valid_reg = '0' and rx_statistics_valid = '1' then
            rx_stats        <= rx_statistics_vector;
            rx_stats_toggle <= not rx_stats_toggle;
         end if;
      end if;
   end process capture_rx_stats;

   rx_stats_sync : sync_block
   port map (
      clk              => gtx_clk_bufg,
      data_in          => rx_stats_toggle,
      data_out         => rx_stats_toggle_sync
   );

   reg_rx_toggle : process (gtx_clk_bufg)
   begin
      if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
         rx_stats_toggle_sync_reg <= rx_stats_toggle_sync;
      end if;
   end process reg_rx_toggle;

   -- when an update is rxd load shifter (plus start/stop bit)
   -- shifter always runs (no power concerns as this is an example design)
   gen_shift_rx : process (gtx_clk_bufg)
   begin
      if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
         if (rx_stats_toggle_sync_reg xor rx_stats_toggle_sync) = '1' then
            rx_stats_shift <= '1' & rx_stats &  '1';
         else
            rx_stats_shift <= rx_stats_shift(28 downto 0) & '0';
         end if;
      end if;
   end process gen_shift_rx;

   rx_statistics_s <= rx_stats_shift(29);

  -- TX STATS

  -- first capture the stats on the appropriate clock
   capture_tx_stats : process (tx_mac_aclk)
   begin
      if tx_mac_aclk'event and tx_mac_aclk = '1' then
         tx_statistics_valid_reg <= tx_statistics_valid;
         if tx_statistics_valid_reg = '0' and tx_statistics_valid = '1' then
            tx_stats        <= tx_statistics_vector;
            tx_stats_toggle <= not tx_stats_toggle;
         end if;
      end if;
   end process capture_tx_stats;

   tx_stats_sync : sync_block
   port map (
      clk              => gtx_clk_bufg,
      data_in          => tx_stats_toggle,
      data_out         => tx_stats_toggle_sync
   );

   reg_tx_toggle : process (gtx_clk_bufg)
   begin
      if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
         tx_stats_toggle_sync_reg <= tx_stats_toggle_sync;
      end if;
   end process reg_tx_toggle;

   -- when an update is txd load shifter (plus start bit)
   -- shifter always runs (no power concerns as this is an example design)
   gen_shift_tx : process (gtx_clk_bufg)
   begin
      if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
         if (tx_stats_toggle_sync_reg xor tx_stats_toggle_sync) = '1' then
            tx_stats_shift <= '1' & tx_stats & '1';
         else
            tx_stats_shift <= tx_stats_shift(32 downto 0) & '0';
         end if;
      end if;
   end process gen_shift_tx;

   tx_statistics_s <= tx_stats_shift(33);

  ------------------------------------------------------------------------------
  -- DESerialize the Pause interface
  -- This is a single bit approach timed on gtx_clk
  -- this code is only present to prevent code being stripped..
  ------------------------------------------------------------------------------
  -- the serialized pause info has a start bit followed by the quanta and a stop bit
  -- capture the quanta when the start bit hits the msb and the stop bit is in the lsb
   gen_shift_pause : process (gtx_clk_bufg)
   begin
      if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
         pause_shift <= pause_shift(16 downto 0) & pause_req_s;
      end if;
   end process gen_shift_pause;

   grab_pause : process (gtx_clk_bufg)
   begin
      if gtx_clk_bufg'event and gtx_clk_bufg = '1' then
         if (pause_shift(17) = '1' and pause_shift(0) = '1') then
            pause_req <= '1';
            pause_val <= pause_shift(16 downto 1);
         else
            pause_req <= '0';
            pause_val <= (others => '0');
         end if;
      end if;
   end process grab_pause;

   ------------------------------------------------------------------------------
   -- Instantiate the AXI-LITE Controller

    axi_lite_controller : axi_lite_sm
    generic map (
      BOARD_PHY_ADDR               => BOARD_PHY_ADDR,
      MAC_BASE_ADDR                => MAC_BASE_ADDR

    )
    port map (
      s_axi_aclk                   => s_axi_aclk,
      s_axi_resetn                 => s_axi_resetn,

      mac_speed                    => mac_speed,
      update_speed                 => update_speed,
      serial_command               => serial_command,
      serial_response              => serial_response,

      s_axi_awaddr                 => s_axi_awaddr,
      s_axi_awvalid                => s_axi_awvalid,
      s_axi_awready                => s_axi_awready,

      s_axi_wdata                  => s_axi_wdata,
      s_axi_wvalid                 => s_axi_wvalid,
      s_axi_wready                 => s_axi_wready,

      s_axi_bresp                  => s_axi_bresp,
      s_axi_bvalid                 => s_axi_bvalid,
      s_axi_bready                 => s_axi_bready,

      s_axi_araddr                 => s_axi_araddr,
      s_axi_arvalid                => s_axi_arvalid,
      s_axi_arready                => s_axi_arready,

      s_axi_rdata                  => s_axi_rdata,
      s_axi_rresp                  => s_axi_rresp,
      s_axi_rvalid                 => s_axi_rvalid,
      s_axi_rready                 => s_axi_rready
    );

   ------------------------------------------------------------------------------
   -- Instantiate the V6 Hard MAC core FIFO Block wrapper
   ------------------------------------------------------------------------------
   v6emac_fifo_block : v6_emac_v2_3_0_fifo_block
    generic map (
      MAC_BASE_ADDR                => MAC_BASE_ADDR
    )
    port map (
      gtx_clk                       => gtx_clk_bufg,
      -- Reference clock for IDELAYCTRL's
      refclk                        => refclk_bufg,

      -- Receiver Statistics Interface
      -----------------------------------------
      rx_mac_aclk                   => rx_mac_aclk,
      rx_reset                      => rx_reset,
      rx_statistics_vector          => rx_statistics_vector,
      rx_statistics_valid           => rx_statistics_valid,

      -- Receiver => AXI-S Interface
      ------------------------------------------
      rx_fifo_clock                 => rx_fifo_clock,
      rx_fifo_resetn                => rx_fifo_resetn,
      rx_axis_fifo_tdata            => rx_axis_fifo_tdata,
      rx_axis_fifo_tvalid           => rx_axis_fifo_tvalid,
      rx_axis_fifo_tready           => rx_axis_fifo_tready,
      --rx_axis_fifo_tready           => '0',
      rx_axis_fifo_tlast            => rx_axis_fifo_tlast,

      -- Transmitter Statistics Interface
      --------------------------------------------
      tx_mac_aclk                   => tx_mac_aclk,
      tx_reset                      => tx_reset,
      tx_ifg_delay                  => tx_ifg_delay,
      tx_statistics_vector          => tx_statistics_vector,
      tx_statistics_valid           => tx_statistics_valid,

      -- Transmitter => AXI-S Interface
      ---------------------------------------------
      tx_fifo_clock                 => tx_fifo_clock,
      tx_fifo_resetn                => tx_fifo_resetn,
      tx_axis_fifo_tdata            => tx_axis_fifo_tdata,
      tx_axis_fifo_tvalid           => tx_axis_fifo_tvalid,
      tx_axis_fifo_tready           => tx_axis_fifo_tready,
      tx_axis_fifo_tlast            => tx_axis_fifo_tlast,

      -- MAC Control Interface
      --------------------------
      pause_req                     => pause_req,
      pause_val                     => pause_val,

      -- GMII Interface
      -------------------
      gmii_txd                      => gmii_txd,
      gmii_tx_en                    => gmii_tx_en,
      gmii_tx_er                    => gmii_tx_er,
      gmii_tx_clk                   => gmii_tx_clk,
      gmii_rxd                      => gmii_rxd,
      gmii_rx_dv                    => gmii_rx_dv,
      gmii_rx_er                    => gmii_rx_er,
      gmii_rx_clk                   => gmii_rx_clk,
      gmii_col                      => gmii_col,
      gmii_crs                      => gmii_crs,
      mii_tx_clk                    => mii_tx_clk,

      -- MDIO Interface
      -------------------
      mdio_i                        => mdio_i,
      mdio_o                        => mdio_o,
      mdio_t                        => mdio_t,
      mdc                           => mdc,

      -- AXI-Lite Interface
      -----------------
      s_axi_aclk                    => s_axi_aclk,
      s_axi_resetn                  => s_axi_resetn,

      s_axi_awaddr                  => s_axi_awaddr,
      s_axi_awvalid                 => s_axi_awvalid,
      s_axi_awready                 => s_axi_awready,

      s_axi_wdata                   => s_axi_wdata,
      s_axi_wvalid                  => s_axi_wvalid,
      s_axi_wready                  => s_axi_wready,

      s_axi_bresp                   => s_axi_bresp,
      s_axi_bvalid                  => s_axi_bvalid,
      s_axi_bready                  => s_axi_bready,

      s_axi_araddr                  => s_axi_araddr,
      s_axi_arvalid                 => s_axi_arvalid,
      s_axi_arready                 => s_axi_arready,

      s_axi_rdata                   => s_axi_rdata,
      s_axi_rresp                   => s_axi_rresp,
      s_axi_rvalid                  => s_axi_rvalid,
      s_axi_rready                  => s_axi_rready,

      -- asynchronous reset
      glbl_rstn                     => glbl_rst_intn,
      rx_axi_rstn                   => '1',
      tx_axi_rstn                   => '1'

   );


  ------------------------------------------------------------------------------
  --  Instantiate the address swapping module and simple pattern generator
  ------------------------------------------------------------------------------
--   basic_pat_gen_inst : basic_pat_gen
--   port map (
--       axi_tclk                     => tx_fifo_clock,
--       axi_tresetn                  => tx_fifo_resetn,
--       check_resetn                 => chk_resetn,
--
--       enable_pat_gen               => gen_tx_data,
--       enable_pat_chk               => chk_tx_data,
--       enable_address_swap          => swap_address,
--
--       rx_axis_fifo_tdata           => rx_axis_fifo_tdata,
--       rx_axis_fifo_tvalid          => rx_axis_fifo_tvalid,
--       rx_axis_fifo_tlast           => rx_axis_fifo_tlast,
--       rx_axis_fifo_tready          => rx_axis_fifo_tready,
--
--       tx_axis_fifo_tdata           => tx_axis_fifo_tdata,
--       tx_axis_fifo_tvalid          => tx_axis_fifo_tvalid,
--       tx_axis_fifo_tlast           => tx_axis_fifo_tlast,
--       tx_axis_fifo_tready          => tx_axis_fifo_tready,
--
--       frame_error                  => int_frame_error
--   );

end modifed_example_design;
