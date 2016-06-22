--------------------------------------------------------------------------------
-- Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: P.20131013
--  \   \         Application: netgen
--  /   /         Filename: cfd_threshold_queue.vhd
-- /___/   /\     Timestamp: Thu Jun 23 00:12:55 2016
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command	: -w -sim -ofmt vhdl C:/TES_project/fpga_ise/teslib/IP_cores/cfd_threshold_queue/tmp/_cg/cfd_threshold_queue.ngc C:/TES_project/fpga_ise/teslib/IP_cores/cfd_threshold_queue/tmp/_cg/cfd_threshold_queue.vhd 
-- Device	: 6vlx240tff1156-1
-- Input file	: C:/TES_project/fpga_ise/teslib/IP_cores/cfd_threshold_queue/tmp/_cg/cfd_threshold_queue.ngc
-- Output file	: C:/TES_project/fpga_ise/teslib/IP_cores/cfd_threshold_queue/tmp/_cg/cfd_threshold_queue.vhd
-- # of Entities	: 1
-- Design Name	: cfd_threshold_queue
-- Xilinx	: C:\Xilinx\14.7\ISE_DS\ISE\
--             
-- Purpose:    
--     This VHDL netlist is a verification model and uses simulation 
--     primitives which may not represent the true implementation of the 
--     device, however the netlist is functionally correct and should not 
--     be modified. This file cannot be synthesized and should only be used 
--     with supported simulation tools.
--             
-- Reference:  
--     Command Line Tools User Guide, Chapter 23
--     Synthesis and Simulation Design Guide, Chapter 6
--             
--------------------------------------------------------------------------------


-- synthesis translate_off
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use UNISIM.VPKG.ALL;

entity cfd_threshold_queue is
  port (
    clk : in STD_LOGIC := 'X'; 
    srst : in STD_LOGIC := 'X'; 
    wr_en : in STD_LOGIC := 'X'; 
    rd_en : in STD_LOGIC := 'X'; 
    full : out STD_LOGIC; 
    empty : out STD_LOGIC; 
    din : in STD_LOGIC_VECTOR ( 17 downto 0 ); 
    dout : out STD_LOGIC_VECTOR ( 17 downto 0 ) 
  );
end cfd_threshold_queue;

architecture STRUCTURE of cfd_threshold_queue is
  signal N1 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_i_2 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_ram_empty_fb_i_8 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_i_9 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_fb_i_58 : STD_LOGIC; 
  signal Result_1_1 : STD_LOGIC; 
  signal Result_2_1 : STD_LOGIC; 
  signal Result_3_1 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_going_empty_PWR_20_o_MUX_24_o : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_In : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_going_empty_fwft_PWR_23_o_MUX_31_o : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_fb_112 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_comb_GND_27_o_MUX_36_o : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o1 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o11_115 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o12_116 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o13_117 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o14_118 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o12 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o13_120 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o14_121 : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_Mmux_RAM_RD_EN_FWFT11_122 : STD_LOGIC; 
  signal NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM2_DOD_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM2_DOD_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM1_DOD_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM1_DOD_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM3_DOD_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM3_DOD_0_UNCONNECTED : STD_LOGIC; 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1 : STD_LOGIC_VECTOR ( 3 downto 0 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1 : STD_LOGIC_VECTOR ( 3 downto 0 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i : STD_LOGIC_VECTOR ( 17 downto 0 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rd_pntr_plus1 : STD_LOGIC_VECTOR ( 0 downto 0 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count : STD_LOGIC_VECTOR ( 3 downto 1 ); 
  signal Result : STD_LOGIC_VECTOR ( 3 downto 1 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_Mcount_gcc0_gc0_count_cy : STD_LOGIC_VECTOR ( 0 downto 0 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count : STD_LOGIC_VECTOR ( 3 downto 1 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i : STD_LOGIC_VECTOR ( 17 downto 0 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015 : STD_LOGIC_VECTOR ( 17 downto 0 ); 
  signal U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_next_fwft_state : STD_LOGIC_VECTOR ( 0 downto 0 ); 
begin
  dout(17) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(17);
  dout(16) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(16);
  dout(15) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(15);
  dout(14) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(14);
  dout(13) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(13);
  dout(12) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(12);
  dout(11) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(11);
  dout(10) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(10);
  dout(9) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(9);
  dout(8) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(8);
  dout(7) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(7);
  dout(6) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(6);
  dout(5) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(5);
  dout(4) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(4);
  dout(3) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(3);
  dout(2) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(2);
  dout(1) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(1);
  dout(0) <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(0);
  full <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_i_2;
  empty <= U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_i_9;
  XST_GND : GND
    port map (
      G => N1
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1_3 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(3),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1_2 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(2),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1_1 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(1),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1_0 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rd_pntr_plus1(0),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1_3 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(3),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(3)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1_2 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(2),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(2)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1_1 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(1),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1_0 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_Mcount_gcc0_gc0_count_cy(0),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_1 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      D => Result(1),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(1)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_2 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      D => Result(2),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(2)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_1 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => Result_1_1,
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(1)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_2 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => Result_2_1,
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(2)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_3 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      D => Result(3),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(3)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_3 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => Result_3_1,
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(3)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_17 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(17),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(17)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_16 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(16),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(16)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_15 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(15),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(15)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_14 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(14),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(14)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_13 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(13),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(13)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_12 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(12),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(12)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_11 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(11),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(11)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_10 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(10),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(10)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_9 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(9),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(9)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_8 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(8),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(8)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_7 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(7),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(7)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_6 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(6),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(6)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_5 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(5),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(5)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_4 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(4),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(4)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_3 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(3),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(3)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_2 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(2),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(2)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_1 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(1),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(1)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i_0 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(0),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_dout_i(0)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM2 : RAM32M
    generic map(
      INIT_A => X"0000000000000000",
      INIT_B => X"0000000000000000",
      INIT_C => X"0000000000000000",
      INIT_D => X"0000000000000000"
    )
    port map (
      WCLK => clk,
      WE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      DIA(1) => din(7),
      DIA(0) => din(6),
      DIB(1) => din(9),
      DIB(0) => din(8),
      DIC(1) => din(11),
      DIC(0) => din(10),
      DID(1) => N1,
      DID(0) => N1,
      ADDRA(4) => N1,
      ADDRA(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRA(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRA(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRA(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRB(4) => N1,
      ADDRB(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRB(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRB(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRB(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRC(4) => N1,
      ADDRC(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRC(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRC(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRC(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRD(4) => N1,
      ADDRD(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(3),
      ADDRD(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(2),
      ADDRD(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1),
      ADDRD(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      DOA(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(7),
      DOA(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(6),
      DOB(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(9),
      DOB(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(8),
      DOC(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(11),
      DOC(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(10),
      DOD(1) => NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM2_DOD_1_UNCONNECTED,
      DOD(0) => NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM2_DOD_0_UNCONNECTED
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM1 : RAM32M
    generic map(
      INIT_A => X"0000000000000000",
      INIT_B => X"0000000000000000",
      INIT_C => X"0000000000000000",
      INIT_D => X"0000000000000000"
    )
    port map (
      WCLK => clk,
      WE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      DIA(1) => din(1),
      DIA(0) => din(0),
      DIB(1) => din(3),
      DIB(0) => din(2),
      DIC(1) => din(5),
      DIC(0) => din(4),
      DID(1) => N1,
      DID(0) => N1,
      ADDRA(4) => N1,
      ADDRA(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRA(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRA(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRA(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRB(4) => N1,
      ADDRB(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRB(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRB(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRB(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRC(4) => N1,
      ADDRC(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRC(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRC(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRC(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRD(4) => N1,
      ADDRD(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(3),
      ADDRD(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(2),
      ADDRD(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1),
      ADDRD(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      DOA(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(1),
      DOA(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(0),
      DOB(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(3),
      DOB(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(2),
      DOC(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(5),
      DOC(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(4),
      DOD(1) => NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM1_DOD_1_UNCONNECTED,
      DOD(0) => NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM1_DOD_0_UNCONNECTED
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM3 : RAM32M
    generic map(
      INIT_A => X"0000000000000000",
      INIT_B => X"0000000000000000",
      INIT_C => X"0000000000000000",
      INIT_D => X"0000000000000000"
    )
    port map (
      WCLK => clk,
      WE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      DIA(1) => din(13),
      DIA(0) => din(12),
      DIB(1) => din(15),
      DIB(0) => din(14),
      DIC(1) => din(17),
      DIC(0) => din(16),
      DID(1) => N1,
      DID(0) => N1,
      ADDRA(4) => N1,
      ADDRA(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRA(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRA(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRA(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRB(4) => N1,
      ADDRB(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRB(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRB(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRB(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRC(4) => N1,
      ADDRC(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      ADDRC(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      ADDRC(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      ADDRC(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      ADDRD(4) => N1,
      ADDRD(3) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(3),
      ADDRD(2) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(2),
      ADDRD(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1),
      ADDRD(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      DOA(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(13),
      DOA(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(12),
      DOB(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(15),
      DOB(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(14),
      DOC(1) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(17),
      DOC(0) => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(16),
      DOD(1) => NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM3_DOD_1_UNCONNECTED,
      DOD(0) => NLW_U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_Mram_RAM3_DOD_0_UNCONNECTED
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_17 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(17),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(17)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_16 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(16),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(16)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_15 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(15),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(15)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_14 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(14),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(14)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_13 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(13),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(13)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_12 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(12),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(12)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_11 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(11),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(11)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_10 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(10),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(10)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_9 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(9),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(9)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_8 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(8),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(8)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_7 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(7),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(7)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_6 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(6),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(6)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_5 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(5),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(5)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_4 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(4),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(4)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_3 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(3),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(3)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_2 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(2),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(2)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_1 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(1),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(1)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i_0 : FDRE
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      CE => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_n0015(0),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_gdm_dm_dout_i(0)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_ram_empty_fb_i : FD
    generic map(
      INIT => '1'
    )
    port map (
      C => clk,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_going_empty_PWR_20_o_MUX_24_o,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_ram_empty_fb_i_8
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1 : FDR
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_In,
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2 : FDR
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_next_fwft_state(0),
      R => srst,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_fb : FD
    generic map(
      INIT => '1'
    )
    port map (
      C => clk,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_going_empty_fwft_PWR_23_o_MUX_31_o,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_fb_112
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_i : FD
    generic map(
      INIT => '1'
    )
    port map (
      C => clk,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_going_empty_fwft_PWR_23_o_MUX_31_o,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_i_9
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_i : FD
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_comb_GND_27_o_MUX_36_o,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_i_2
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_fb_i : FD
    generic map(
      INIT => '0'
    )
    port map (
      C => clk,
      D => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_comb_GND_27_o_MUX_36_o,
      Q => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_fb_i_58
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_ram_wr_en_i1 : LUT2
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => wr_en,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_fb_i_58,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_RAM_REGOUT_EN1 : LUT3
    generic map(
      INIT => X"A2"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110,
      I2 => rd_en,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_regout_en
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_Mmux_going_empty_fwft_PWR_23_o_MUX_31_o11 : LUT5
    generic map(
      INIT => X"FFFFB2A2"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_empty_fwft_fb_112,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111,
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110,
      I3 => rd_en,
      I4 => srst,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_going_empty_fwft_PWR_23_o_MUX_31_o
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_Mmux_RAM_RD_EN_FWFT11 : LUT4
    generic map(
      INIT => X"2333"
    )
    port map (
      I0 => rd_en,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_ram_empty_fb_i_8,
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111,
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_In1 : LUT4
    generic map(
      INIT => X"55D5"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_ram_empty_fb_i_8,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111,
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110,
      I3 => rd_en,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_In
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_In1 : LUT3
    generic map(
      INIT => X"AE"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110,
      I2 => rd_en,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_next_fwft_state(0)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o11 : LUT6
    generic map(
      INIT => X"73735050FF73FF50"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(2),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(3),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      I5 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o1
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o12 : LUT6
    generic map(
      INIT => X"FFFFFFFF7350FFFF"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      I5 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o1,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o11_115
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o13 : LUT6
    generic map(
      INIT => X"00AACCEEF0FAFCFE"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(3),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(2),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      I5 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o12_116
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o14 : LUT5
    generic map(
      INIT => X"82410000"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(3),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(2),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(2),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(3),
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_Mmux_RAM_RD_EN_FWFT11_122,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o13_117
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o16 : LUT6
    generic map(
      INIT => X"FFEEEEEEFFEAEAEA"
    )
    port map (
      I0 => srst,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_ram_empty_fb_i_8,
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o12_116,
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o14_118,
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o13_117,
      I5 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o11_115,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_going_empty_PWR_20_o_MUX_24_o
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o13 : LUT6
    generic map(
      INIT => X"FFFFFFFFFFFF7350"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o12_116,
      I5 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o1,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o12
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o14 : LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(3),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(1),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(3),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(1),
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o13_120
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o16 : LUT5
    generic map(
      INIT => X"45440504"
    )
    port map (
      I0 => srst,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_fb_i_58,
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_mem_ram_rd_en_i,
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o14_121,
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o12,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_comb_GND_27_o_MUX_36_o
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o15 : LUT6
    generic map(
      INIT => X"0000D00DD00D0000"
    )
    port map (
      I0 => wr_en,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_ram_full_fb_i_58,
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(1),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(1),
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      I5 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_Mmux_going_empty_PWR_20_o_MUX_24_o14_118
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o15 : LUT6
    generic map(
      INIT => X"0990000000000000"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(2),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(2),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      I4 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_ram_wr_en,
      I5 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o13_120,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_gwss_wsts_Mmux_ram_full_comb_GND_27_o_MUX_36_o14_121
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_Mcount_gc0_count_xor_1_11 : LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(1),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      O => Result_1_1
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_Mcount_gcc0_gc0_count_xor_1_11 : LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(1),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      O => Result(1)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_Mcount_gc0_count_xor_3_11 : LUT4
    generic map(
      INIT => X"AA6A"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(3),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(2),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(1),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      O => Result_3_1
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_Mcount_gcc0_gc0_count_xor_3_11 : LUT4
    generic map(
      INIT => X"AA6A"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(3),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(2),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(1),
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      O => Result(3)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_Mcount_gc0_count_xor_2_11 : LUT3
    generic map(
      INIT => X"A6"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(2),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count(1),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      O => Result_2_1
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_Mcount_gcc0_gc0_count_xor_2_11 : LUT3
    generic map(
      INIT => X"A6"
    )
    port map (
      I0 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(2),
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count(1),
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      O => Result(2)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_Mmux_RAM_RD_EN_FWFT11_1 : LUT4
    generic map(
      INIT => X"2333"
    )
    port map (
      I0 => rd_en,
      I1 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_grss_rsts_ram_empty_fb_i_8,
      I2 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd1_111,
      I3 => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_curr_fwft_state_FSM_FFd2_110,
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_gr1_rfwft_Mmux_RAM_RD_EN_FWFT11_122
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_wr_pntr_0_inv1_INV_0 : INV
    port map (
      I => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_gcc0_gc0_count_d1(0),
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_wr_wpntr_Mcount_gcc0_gc0_count_cy(0)
    );
  U0_xst_fifo_generator_gconvfifo_rf_grf_rf_rd_pntr_0_inv1_INV_0 : INV
    port map (
      I => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rpntr_gc0_count_d1(0),
      O => U0_xst_fifo_generator_gconvfifo_rf_grf_rf_gntv_or_sync_fifo_gl0_rd_rd_pntr_plus1(0)
    );

end STRUCTURE;

-- synthesis translate_on
