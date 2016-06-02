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
-- Program defined by 'C:\TES_project\fpga_ise\teslib\PSM\IO_controller_program.psm'.
--
-- Generated by KCPSM6 Assembler: 30 May 2016 - 09:26:26. 
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
entity IO_controller_program is
    Port (      address : in std_logic_vector(11 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                 enable : in std_logic;
                    clk : in std_logic);
    end IO_controller_program;
--
architecture low_level_definition of IO_controller_program is
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
                INIT_00 => X"F10291014106F103410E410E410E410E31F04180200300E9004500271703002D",
                INIT_01 => X"201C910140062020D1001001310F4180F0042012910140062017D1001001B103",
                INIT_02 => X"0006B0C4028720C30E000021BD03BC0100D850003007400E400E400E9080F001",
                INIT_03 => X"6043D004908011FF5000D5016037D00290805000B004029BB084000601D4022B",
                INIT_04 => X"1401E05102BB02B52060D50A2048003C1400160000D350009501203D10009101",
                INIT_05 => X"204816014750605290014F004E004D004C004B004A004900480047061004205E",
                INIT_06 => X"D7C02077D70F5780206DD4005740206AD61217002067D7032067D7012067D702",
                INIT_07 => X"0090B011500000850090B0115000460F00CE500036002074B0F46075D7036077",
                INIT_08 => X"DB205000DC04DD08DE10DF2050009C049D089E109F2050000085B082008AB021",
                INIT_09 => X"20A5A0A100B30090121002105000209CA09A00B300A012005000D804D908DA10",
                INIT_0A => X"D20050004180021060B1D200500020AFA0AA00B300801208021060B1D2005000",
                INIT_0B => X"20CE573050004080E0B8500030FF1100E0B420BB400691011108500032FF60AD",
                INIT_0C => X"02A4047002A404C002A404D002A404E002A404F060CED4F0047020CE5720370F",
                INIT_0D => X"4F061F1000D850001C001D001E001F001700180019001A001B0050000037150A",
                INIT_0E => X"E0BECB30B30160F1DB2020F8DB1020C3370F1C1A1D091E1E5F054F064F064F06",
                INIT_0F => X"4430340003B01334140122D222C7D70220BE2215A152C900B00420BED90020FB",
                INIT_10 => X"02A4049002A404A002A404B002A404C002A404D002A404E002A404F0B401D240",
                INIT_11 => X"1401E12102BB212CD50A2119003C1400160000D80037150A02A4047002A40480",
                INIT_12 => X"D60A20C3D602B201211916014750612290014F004E004D004C0047061004212A",
                INIT_13 => X"D0023080002011081280124012201210120812041202120120CE572037CF20C3",
                INIT_14 => X"10005000D00200000000000030FED00250015000613D910101474200C3409302",
                INIT_15 => X"0165017DD980216160C0DC606161D83F20C0D841215DD70260BE02095000D080",
                INIT_16 => X"3080002011085000014F0C20016D02C0016D0280049020CE01650178D98020C3",
                INIT_17 => X"1201016D12005000016D1200016D12005000616E91014200C34093020147D002",
                INIT_18 => X"440E019ED0801002440E440E019ED08010010460007E1C0006C0007E5000016D",
                INIT_19 => X"21B0D40320C3007E0C60028B014F019ED0801008440E440E019ED0801004440E",
                INIT_1A => X"5000016D1208016D124001785000016D120C016D1240017821C221BCD401E1B6",
                INIT_1B => X"120E016D124001785000016D1220016D123F01785000016D1221016D123F0178",
                INIT_1C => X"124001785000016D120A016D124001785000016D120D016D124001785000016D",
                INIT_1D => X"1401016D1000D2FF454014E215010178D08010009001B0045000016D1209016D",
                INIT_1E => X"124612501200124412801241120812401221123F120012201280120021DB3500",
                INIT_1F => X"1200126612001263120012621200125712001255120012531200125212001251",
                INIT_20 => X"500042076210D2FF454014E2150112FF12001276120012751200126A12001268",
                INIT_21 => X"0221120020C30221128000D820C0221ED701221AD702220B350014021000C280",
                INIT_22 => X"D2FF454014421502B60450000C20014F013C02C0013C0280013CD980049020CE",
                INIT_23 => X"1401014F013C454035001401013CB200013C1200D680F2005000014710006234",
                INIT_24 => X"120212421202124112031240120C123F120C123E120C123D120C123C222E3500",
                INIT_25 => X"1221124E1200124D1221124C1200124B1221124A120012491221124812031243",
                INIT_26 => X"122112561200125512211254120012531221125212001251122112501200124F",
                INIT_27 => X"1200120B1210120A12701209126F1208120F1206120012051205120412001257",
                INIT_28 => X"1204229F1009113D1200229F10011100120012FF1201125A12021245120A120C",
                INIT_29 => X"9001229F10E211041200229F109411351277229F1028116B12EE229F10B411C4",
                INIT_2A => X"5000003702B0350F0540003702B0450E450E450E450E05405000629FB200B100",
                INIT_2B => X"9511900095E9900015B9500035DFD000D57B9000D5615000153A1507A2B3950A",
                INIT_2C => X"6027DA8020C0D20120BED203E0BE20DD02F55000150A500095F690001507E2C5",
                INIT_2D => X"12031203120120C3007E6182D88020C0D20220BED203E0BE20C002F520C3007A",
                INIT_2E => X"1200120012001200120012021202120012031203120312031203120312031203",
                INIT_2F => X"50004480540145403500042014DD15021000D000009412011200120012001200",
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
               INITP_00 => X"AAA9A2B730D34DDD935555527ADE0A2DC0AC2AAAAA20A1529741A5D096551BA2",
               INITP_01 => X"942DBD36D37600154A00002888888C2089E0F52364DBE136F84BE0AAAAA802AA",
               INITP_02 => X"2288B50A028882AAAACDDDEA28022D9080AAAA83769355527B7828888888888A",
               INITP_03 => X"AAAAAAAAAAAAAAA96D82B4A22A22A22A22A22A22A22A22B3CA2A85A1685A082A",
               INITP_04 => X"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA96A588AA3602288A28A2B765D9D82AAAA",
               INITP_05 => X"9250FAAAAAAAAAAAAAB333EACCCFA6777763765DA82954B56020202020202AAA",
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
-- END OF FILE IO_controller_program.vhd
--
------------------------------------------------------------------------------------