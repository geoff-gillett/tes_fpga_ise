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
-- Program defined by 'C:\TES_project\fpga_ise\teslib\PSM\channel_program.psm'.
--
-- Generated by KCPSM6 Assembler: 09 Jun 2016 - 11:09:19. 
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
                INIT_00 => X"200A100091016010D004908011FF5000D5016004D0029080200100F60012B032",
                INIT_01 => X"47061004202B1401E01E00EA00E4202DD50A201500091400160000A050009501",
                INIT_02 => X"D7012034D702201516014750601F90014F004E004D004C004B004A0049004800",
                INIT_03 => X"6042D7036044D7C02044D70F5780203AD40057402037D61217002034D7032034",
                INIT_04 => X"B0820057B021005DB01150000052005DB0115000460F009B500036002041B0F4",
                INIT_05 => X"D804D908DA10DB205000DC04DD08DE10DF2050009C049D089E109F2050000052",
                INIT_06 => X"607ED20050002072A06E008000901210021050002069A067008000A012005000",
                INIT_07 => X"500032FF607AD200500041800210607ED2005000207CA0770080008012080210",
                INIT_08 => X"209B5720370F209B573050004080E085500030FF1100E0812088400691011108",
                INIT_09 => X"50000004150A00D3047000D304C000D304D000D304E000D304F0609BD4F00470",
                INIT_0A => X"4F064F064F064F061F1000A550001C001D001E001F001700180019001A001B00",
                INIT_0B => X"11C4120420CE1009113D120020CE1001110012002090370F1C091D0B1E095F06",
                INIT_0C => X"B100900120CE10E21104120020CE10941135127720CE1028116B12EE20CE10B4",
                INIT_0D => X"950A5000000400DF350F0540000400DF450E450E450E450E0540500060CEB200",
                INIT_0E => X"E0F49511900095E9900015B9500035DFD000D57B9000D5615000153A1507A0E2",
                INIT_0F => X"208BD203E08B208D0127208D20FBD7012104D7025000150A500095F690001507",
                INIT_10 => X"120320900047208DD201208BD203E08B20AAE08B20AA01272090004B208DD202",
                INIT_11 => X"1200120012001200120012031203120312031203120312031203120312031203",
                INIT_12 => X"5401454035000420140F15011000D00000611200120012001200120012001200",
                INIT_13 => X"0000000000000000000000000000000000000000000000000000000050004480",
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
               INITP_00 => X"8D936F84DBE12F82AAAAA00AAAAAA68ADCC34D37764D555549EB7828B702B0BA",
               INITP_01 => X"CFADD99DDDD8DD976A0A552D580808080808080055280000A2222230822783D4",
               INITP_02 => X"0000000000000000000000000000000000000009250FAAAAAAAAAAAAAB33FEAC",
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
