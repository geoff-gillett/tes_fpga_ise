--
-------------------------------------------------------------------------------------------
-- Copyright � 2010-2013, Xilinx, Inc.
-- This file contains confidential and proprietary information of Xilinx, Inc. and is
-- protected under U.S. and international copyright and other intellectual property laws.
-------------------------------------------------------------------------------------------
--
-- Disclaimer:
-- This disclaimer is not a license and does not grant any rights to the materials
-- distributed herewith. Except as otherwise provided in a valid license issued to
-- you by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE
-- MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY
-- DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY,
-- INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT,
-- OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable
-- (whether in contract or tort, including negligence, or under any other theory
-- of liability) for any loss or damage of any kind or nature related to, arising
-- under or in connection with these materials, including for any direct, or any
-- indirect, special, incidental, or consequential loss or damage (including loss
-- of data, profits, goodwill, or any type of loss or damage suffered as a result
-- of any action brought by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-safe, or for use in any
-- application requiring fail-safe performance, such as life-support or safety
-- devices or systems, Class III medical devices, nuclear facilities, applications
-- related to the deployment of airbags, or any other applications that could lead
-- to death, personal injury, or severe property or environmental damage
-- (individually and collectively, "Critical Applications"). Customer assumes the
-- sole risk and liability of any use of Xilinx products in Critical Applications,
-- subject only to applicable laws and regulations governing limitations on product
-- liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------------------
--
--
-- Production definition of a 1K program for KCPSM6 in a Virtex-6 device using a 
-- RAMB18E1 primitive.
--
-- Note: The complete 12-bit address bus is connected to KCPSM6 to facilitate future code 
--       expansion with minimum changes being required to the hardware description. 
--       Only the lower 10-bits of the address are actually used for the 1K address range
--       000 to 3FF hex.  
--
-- Program defined by 'C:\TES_project\fpga_ise\controllerlib\PSM\channel_program.psm'.
--
-- Generated by KCPSM6 Assembler: 19 Oct 2015 - 17:54:54. 
--
-- Assembler used ROM_form template: ROM_form_V6_1K_14March13.vhd
--
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
-- The Unisim Library is used to define Xilinx primitives. It is also used during
-- simulation. The source can be viewed at %XILINX%\vhdl\src\unisims\unisim_VCOMP.vhd
--  
library unisim;
use unisim.vcomponents.all;
--
--
entity channel_program is
    Port (      address : in std_logic_vector(11 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                 enable : in std_logic;
                    clk : in std_logic);
    end channel_program;
--
architecture low_level_definition of channel_program is
--
signal  address_a : std_logic_vector(13 downto 0);
signal  data_in_a : std_logic_vector(17 downto 0);
signal data_out_a : std_logic_vector(17 downto 0);
signal  address_b : std_logic_vector(13 downto 0);
signal  data_in_b : std_logic_vector(17 downto 0);
signal data_out_b : std_logic_vector(17 downto 0);
signal   enable_b : std_logic;
signal      clk_b : std_logic;
signal       we_b : std_logic_vector(3 downto 0);
--
begin
--
  address_a <= address(9 downto 0) & "1111";
  instruction <= data_out_a(17 downto 0);
  data_in_a <= "0000000000000000" & address(11 downto 10);
  --
  address_b <= "11111111111111";
  data_in_b <= data_out_b(17 downto 0);
  enable_b <= '0';
  we_b <= "0000";
  clk_b <= '0';
  --
  --
  -- 
  kcpsm6_rom: RAMB18E1
  generic map ( READ_WIDTH_A => 18,
                WRITE_WIDTH_A => 18,
                DOA_REG => 0,
                INIT_A => "000000000000000000",
                RSTREG_PRIORITY_A => "REGCE",
                SRVAL_A => X"000000000000000000",
                WRITE_MODE_A => "WRITE_FIRST",
                READ_WIDTH_B => 18,
                WRITE_WIDTH_B => 18,
                DOB_REG => 0,
                INIT_B => X"000000000000000000",
                RSTREG_PRIORITY_B => "REGCE",
                SRVAL_B => X"000000000000000000",
                WRITE_MODE_B => "WRITE_FIRST",
                INIT_FILE => "NONE",
                SIM_COLLISION_CHECK => "ALL",
                RAM_MODE => "TDP",
                RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
                SIM_DEVICE => "VIRTEX6",
                INIT_00 => X"209B370F1C361D111E135F0A4F064F064F064F061F0F00B4200100F9001EB032",
                INIT_01 => X"160000AF50009501201610009101601CD004908011FF5000D5016010D0029080",
                INIT_02 => X"4B004A00490048004706100420371401E02A00ED00E72039D50D202100151400",
                INIT_03 => X"17002040D7032040D7012040D702202116014750602B90014F004E004D004C00",
                INIT_04 => X"50003600204DB0F4604ED7036050D7C02050D70F57802046D40057402043D612",
                INIT_05 => X"9D089E109F205000B0820062B0210068B0115000005D0068B0115000460F00AA",
                INIT_06 => X"A072008B00A012005000D804D908DA10DB205000DC04DD08DE10DF2050009C04",
                INIT_07 => X"A082008B0080120802106089D2005000207DA079008B00901210021050002074",
                INIT_08 => X"E08C2093400691011108500032FF6085D2005000418002106089D20050002087",
                INIT_09 => X"047020AAD401340F047020AA5720370F20AA573050004080E090500030FF1100",
                INIT_0A => X"1B0050000010150D00D6047000D604C000D604D000D604E000D604F060AAD4F0",
                INIT_0B => X"1009113D120020D110041100120050001C001D001E001F001700180019001A00",
                INIT_0C => X"10E21104120020D110941135127720D11028116B12EE20D110B411C4120420D1",
                INIT_0D => X"00E2350F0540001000E2450E450E450E450E0540500060D1B200B100900120D1",
                INIT_0E => X"95E9900015B9500035DFD000D57B9000D5615000153A1507A0E5950A50000010",
                INIT_0F => X"2098006C209820FED7012105D7025000150A500095F690001507E0F795119000",
                INIT_10 => X"0000000000000000209B0053E096D20EE0962004006C20AA0057E096D20EE096",
                INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
                INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
               INITP_00 => X"E136F84BE0AAAAA802AAAAA68ADCC34D37764D555549EB7828B702B0800552BA",
               INITP_01 => X"EB766777763765DA82954B5602020202020200002888888C342089E0F52364DB",
               INITP_02 => X"0000000000000000000000000000000000000000000000000000000000ADFAB7",
               INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
               INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
               INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
               INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
               INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
  port map(   ADDRARDADDR => address_a,
                  ENARDEN => enable,
                CLKARDCLK => clk,
                    DOADO => data_out_a(15 downto 0),
                  DOPADOP => data_out_a(17 downto 16), 
                    DIADI => data_in_a(15 downto 0),
                  DIPADIP => data_in_a(17 downto 16), 
                      WEA => "00",
              REGCEAREGCE => '0',
            RSTRAMARSTRAM => '0',
            RSTREGARSTREG => '0',
              ADDRBWRADDR => address_b,
                  ENBWREN => enable_b,
                CLKBWRCLK => clk_b,
                    DOBDO => data_out_b(15 downto 0),
                  DOPBDOP => data_out_b(17 downto 16), 
                    DIBDI => data_in_b(15 downto 0),
                  DIPBDIP => data_in_b(17 downto 16), 
                    WEBWE => we_b,
                   REGCEB => '0',
                  RSTRAMB => '0',
                  RSTREGB => '0');
--
--
end low_level_definition;
--
------------------------------------------------------------------------------------
--
-- END OF FILE channel_program.vhd
--
------------------------------------------------------------------------------------
