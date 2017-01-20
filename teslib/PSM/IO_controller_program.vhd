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
-- Program defined by 'c:\TES_project\fpga_ise\teslib\PSM\IO_controller_program.psm'.
--
-- Generated by KCPSM6 Assembler: 19 Jan 2017 - 18:42:52. 
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
                INIT_00 => X"600DD0029080209B0E000252BD03BC0100B0200400C1001B0007170302370291",
                INIT_01 => X"201E00121400160000AB500095012013100091016019D004908011FF5000D501",
                INIT_02 => X"4E004D004C004B004A00490048004706100420341401E027022B02252036D50A",
                INIT_03 => X"57402040D6121700203DD703203DD701203DD702201E16014750602890014F00",
                INIT_04 => X"5000460F00A650003600204AB0F4604BD703604DD7C0204DD70F57802043D400",
                INIT_05 => X"9D089E109F205000005D0000B0820062B0210068B0115000005D00000068B011",
                INIT_06 => X"A072008B00A012005000D804D908DA10DB205000DC04DD08DE10DF2050009C04",
                INIT_07 => X"A082008B0080120802106089D2005000207DA079008B00901210021050002074",
                INIT_08 => X"E08C2093400691011108500032FF6085D2005000418002106089D20050002087",
                INIT_09 => X"021404F060A6D4F0047020A65720370F20A6573050004080E090500030FF1100",
                INIT_0A => X"1700180019001A001B005000000D150A02140470021404C0021404D0021404E0",
                INIT_0B => X"370F1C2A1D121E135F014F064F064F064F061F1100B050001C001D001E001F00",
                INIT_0C => X"209621E1A171C900B0042096D90020D3E096CB30B30120C9DB2020D0DB10209B",
                INIT_0D => X"021404D0021404E0021404F0B401D2404430340003B0130C140122632258D702",
                INIT_0E => X"160000B0000D150A021404700214048002140490021404A0021404B0021404C0",
                INIT_0F => X"90014F004E004D004C004706100421021401E0F9022B2104D50A20F100121400",
                INIT_10 => X"120812041202120120A6572037CF209BD60A209BD602B20120F11601475060FA",
                INIT_11 => X"91014200C3409302D00230FED0025001D0023080002011081280124012201210",
                INIT_12 => X"0135028004905000D08010005000D00200000000000030FED002500150006115",
                INIT_13 => X"5000613691014200C34093020122D0023080002011085000012A0C20013502C0",
                INIT_14 => X"1221123F12001220128012005000013512010135120050000135120001351200",
                INIT_15 => X"1200125512001253120012521200125112461250120012441280124112081240",
                INIT_16 => X"12001276120012751200126A1200126812001266120012631200126212001257",
                INIT_17 => X"209B012D0145D98021806098DC606180D83F2098D841217CD702609601D512FF",
                INIT_18 => X"019FD0801002440E440E019FD0801001046000551C0006C020A6012D0140D980",
                INIT_19 => X"D403209B00550C6001FB012A019FD0801008440E440E019FD0801004440E440E",
                INIT_1A => X"0135120801351240014050000135120C01351240014021C321BDD401E1B721B1",
                INIT_1B => X"0135124001405000013512200135123F01405000013512210135123F01405000",
                INIT_1C => X"014050000135120A01351240014050000135120D01351240014050000135120E",
                INIT_1D => X"350014021000C2805000420761DCD2FF4540144A150150000135120901351240",
                INIT_1E => X"0114D980049020A601ED1200209B01ED128000B0209821EAD70121E6D70221D7",
                INIT_1F => X"1204220F1009113D1200220F10011100120050000C20012A011402C001140280",
                INIT_20 => X"9001220F10E211041200220F109411351277220F1028116B12EE220F10B411C4",
                INIT_21 => X"5000000D0220350F0540000D0220450E450E450E450E05405000620FB200B100",
                INIT_22 => X"9511900095E9900015B9500035DFD000D57B9000D5615000153A1507A223950A",
                INIT_23 => X"91014106F103410E410E410E410E31F041805000150A500095F690001507E235",
                INIT_24 => X"910140062251D1001001310F4180F0042243910140062248D1001001B103F102",
                INIT_25 => X"DA802098D2012096D203E09620B502865000301F400E400E400E9080F001224D",
                INIT_26 => X"12031201209B00556184D8802098D2022096D203E09620980286209B00506007",
                INIT_27 => X"1200120012001200120212021203120312031203120312031203120312031203",
                INIT_28 => X"44805401454035000420146E15021000D000006C120112001200120012001200",
                INIT_29 => X"5000B004020B020BB084020B2294D040908002FC02A00237B0C401F7B0E45000",
                INIT_2A => X"14010114B20001141200D680F20050000122100062A9D2FF454014B71502B604",
                INIT_2B => X"1240120C123F120C123E120C123D120C123C22A335001401012A011445403500",
                INIT_2C => X"124C1200124B1221124A12001249122112481203124312021242120212411203",
                INIT_2D => X"1254120012531221125212001251122112501200124F1221124E1200124D1221",
                INIT_2E => X"1209126F1208120F120612001205120512041200125712211256120012551221",
                INIT_2F => X"D08010009001B00412FF1201125A12021245120A120C1200120B1210120A1270",
                INIT_30 => X"00000000000000000000000023033500140101351000D2FF4540144A15010140",
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
               INITP_00 => X"E136F84BE0AAAAA8028AAA8A9A2B730D34DDD935555527ADE0A2DC0AC220AE8A",
               INITP_01 => X"55527B7828888888888A942DBD36D37600154A00002888888C2089E0F52364DB",
               INITP_02 => X"AAB3777AAAAAAAAAAAAAAAAAAAAA2288B50A0288828A008B508880AAAA837693",
               INITP_03 => X"20202288A28A2B765D9D8288A88A88A88A88A88A88A88ACF28AA1685A16820AA",
               INITP_04 => X"AAAAAAAAAACCCFAB333E854A5D069742595466777763765DA82954B560202020",
               INITP_05 => X"B4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5A9622A8D80AAAC2AAA4943EAAA",
               INITP_06 => X"0000000000000000000000000000000000000000000000000000000000096D82",
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
