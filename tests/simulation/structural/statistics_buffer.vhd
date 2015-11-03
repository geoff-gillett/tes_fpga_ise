
-- lib statistics_buffer_lib
library IEEE; use IEEE.STD_LOGIC_1164.ALL;
library UNISIM; use UNISIM.VCOMPONENTS.ALL; 
entity mcaBuffer_blk_mem_gen_generic_cstr is
  port (
    CLKA : in STD_LOGIC;
    ENA : in STD_LOGIC;
    CLKB : in STD_LOGIC;
    ENB : in STD_LOGIC;
    INJECTSBITERR : in STD_LOGIC;
    INJECTDBITERR : in STD_LOGIC;
    SBITERR : out STD_LOGIC;
    DBITERR : out STD_LOGIC;
    RSTA : in STD_LOGIC_VECTOR ( 0 to 0 );
    REGCEA : in STD_LOGIC_VECTOR ( 0 to 0 );
    WEA : in STD_LOGIC_VECTOR ( 3 downto 0 );
    ADDRA : in STD_LOGIC_VECTOR ( 9 downto 0 );
    DINA : in STD_LOGIC_VECTOR ( 35 downto 0 );
    RSTB : in STD_LOGIC_VECTOR ( 0 to 0 );
    REGCEB : in STD_LOGIC_VECTOR ( 0 to 0 );
    WEB : in STD_LOGIC_VECTOR ( 1 downto 0 );
    ADDRB : in STD_LOGIC_VECTOR ( 10 downto 0 );
    DINB : in STD_LOGIC_VECTOR ( 17 downto 0 );
    DOUTA : out STD_LOGIC_VECTOR ( 35 downto 0 );
    DOUTB : out STD_LOGIC_VECTOR ( 17 downto 0 );
    RDADDRECC : out STD_LOGIC_VECTOR ( 10 downto 0 )
  );
end mcaBuffer_blk_mem_gen_generic_cstr;

architecture STRUCTURE of mcaBuffer_blk_mem_gen_generic_cstr is
  signal N0 : STD_LOGIC;
  signal \DBITERR^Mid\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_REGCEAREGCE_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_REGCEB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RSTREGARSTREG_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RSTREGB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 16 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 2 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  attribute XSTLIB : boolean;
  attribute XSTLIB of XST_GND : label is true;
  attribute XSTLIB of XST_VCC : label is true;
  attribute BUS_INFO : string;
  attribute BUS_INFO of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC : string;
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA : string;
  attribute SAVEDATA of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
begin
  DBITERR <= \DBITERR^Mid\;
  DOUTA(35) <= \DBITERR^Mid\;
  DOUTA(34) <= \DBITERR^Mid\;
  DOUTA(33) <= \DBITERR^Mid\;
  DOUTA(32) <= \DBITERR^Mid\;
  DOUTA(31) <= \DBITERR^Mid\;
  DOUTA(30) <= \DBITERR^Mid\;
  DOUTA(29) <= \DBITERR^Mid\;
  DOUTA(28) <= \DBITERR^Mid\;
  DOUTA(27) <= \DBITERR^Mid\;
  DOUTA(26) <= \DBITERR^Mid\;
  DOUTA(25) <= \DBITERR^Mid\;
  DOUTA(24) <= \DBITERR^Mid\;
  DOUTA(23) <= \DBITERR^Mid\;
  DOUTA(22) <= \DBITERR^Mid\;
  DOUTA(21) <= \DBITERR^Mid\;
  DOUTA(20) <= \DBITERR^Mid\;
  DOUTA(19) <= \DBITERR^Mid\;
  DOUTA(18) <= \DBITERR^Mid\;
  DOUTA(17) <= \DBITERR^Mid\;
  DOUTA(16) <= \DBITERR^Mid\;
  DOUTA(15) <= \DBITERR^Mid\;
  DOUTA(14) <= \DBITERR^Mid\;
  DOUTA(13) <= \DBITERR^Mid\;
  DOUTA(12) <= \DBITERR^Mid\;
  DOUTA(11) <= \DBITERR^Mid\;
  DOUTA(10) <= \DBITERR^Mid\;
  DOUTA(9) <= \DBITERR^Mid\;
  DOUTA(8) <= \DBITERR^Mid\;
  DOUTA(7) <= \DBITERR^Mid\;
  DOUTA(6) <= \DBITERR^Mid\;
  DOUTA(5) <= \DBITERR^Mid\;
  DOUTA(4) <= \DBITERR^Mid\;
  DOUTA(3) <= \DBITERR^Mid\;
  DOUTA(2) <= \DBITERR^Mid\;
  DOUTA(1) <= \DBITERR^Mid\;
  DOUTA(0) <= \DBITERR^Mid\;
  RDADDRECC(10) <= \DBITERR^Mid\;
  RDADDRECC(9) <= \DBITERR^Mid\;
  RDADDRECC(8) <= \DBITERR^Mid\;
  RDADDRECC(7) <= \DBITERR^Mid\;
  RDADDRECC(6) <= \DBITERR^Mid\;
  RDADDRECC(5) <= \DBITERR^Mid\;
  RDADDRECC(4) <= \DBITERR^Mid\;
  RDADDRECC(3) <= \DBITERR^Mid\;
  RDADDRECC(2) <= \DBITERR^Mid\;
  RDADDRECC(1) <= \DBITERR^Mid\;
  RDADDRECC(0) <= \DBITERR^Mid\;
  SBITERR <= \DBITERR^Mid\;
XST_GND: unisim.vcomponents.GND
    port map (
      G => \DBITERR^Mid\
    );
XST_VCC: unisim.vcomponents.VCC
    port map (
      P => N0
    );
\ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 0,
      DOB_REG => 0,
      EN_ECC_READ => false,
      EN_ECC_WRITE => false,
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
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
      INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_A => X"000000000",
      INIT_B => X"000000000",
      INIT_FILE => "NONE",
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",
      RAM_MODE => "TDP",
      RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
      READ_WIDTH_A => 18,
      READ_WIDTH_B => 18,
      RSTREG_PRIORITY_A => "REGCE",
      RSTREG_PRIORITY_B => "REGCE",
      SIM_COLLISION_CHECK => "ALL",
      SIM_DEVICE => "VIRTEX6",
      SRVAL_A => X"000000000",
      SRVAL_B => X"000000000",
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
      WRITE_WIDTH_A => 36,
      WRITE_WIDTH_B => 36
    )
    port map (
      ADDRARDADDR(15) => N0,
      ADDRARDADDR(14 downto 5) => ADDRA(9 downto 0),
      ADDRARDADDR(4) => \DBITERR^Mid\,
      ADDRARDADDR(3) => \DBITERR^Mid\,
      ADDRARDADDR(2) => \DBITERR^Mid\,
      ADDRARDADDR(1) => \DBITERR^Mid\,
      ADDRARDADDR(0) => \DBITERR^Mid\,
      ADDRBWRADDR(15) => N0,
      ADDRBWRADDR(14 downto 4) => ADDRB(10 downto 0),
      ADDRBWRADDR(3) => \DBITERR^Mid\,
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(34 downto 27),
      DIADI(23 downto 16) => DINA(25 downto 18),
      DIADI(15 downto 8) => DINA(16 downto 9),
      DIADI(7 downto 0) => DINA(7 downto 0),
      DIBDI(31) => \DBITERR^Mid\,
      DIBDI(30) => \DBITERR^Mid\,
      DIBDI(29) => \DBITERR^Mid\,
      DIBDI(28) => \DBITERR^Mid\,
      DIBDI(27) => \DBITERR^Mid\,
      DIBDI(26) => \DBITERR^Mid\,
      DIBDI(25) => \DBITERR^Mid\,
      DIBDI(24) => \DBITERR^Mid\,
      DIBDI(23) => \DBITERR^Mid\,
      DIBDI(22) => \DBITERR^Mid\,
      DIBDI(21) => \DBITERR^Mid\,
      DIBDI(20) => \DBITERR^Mid\,
      DIBDI(19) => \DBITERR^Mid\,
      DIBDI(18) => \DBITERR^Mid\,
      DIBDI(17) => \DBITERR^Mid\,
      DIBDI(16) => \DBITERR^Mid\,
      DIBDI(15) => \DBITERR^Mid\,
      DIBDI(14) => \DBITERR^Mid\,
      DIBDI(13) => \DBITERR^Mid\,
      DIBDI(12) => \DBITERR^Mid\,
      DIBDI(11) => \DBITERR^Mid\,
      DIBDI(10) => \DBITERR^Mid\,
      DIBDI(9) => \DBITERR^Mid\,
      DIBDI(8) => \DBITERR^Mid\,
      DIBDI(7) => \DBITERR^Mid\,
      DIBDI(6) => \DBITERR^Mid\,
      DIBDI(5) => \DBITERR^Mid\,
      DIBDI(4) => \DBITERR^Mid\,
      DIBDI(3) => \DBITERR^Mid\,
      DIBDI(2) => \DBITERR^Mid\,
      DIBDI(1) => \DBITERR^Mid\,
      DIBDI(0) => \DBITERR^Mid\,
      DIPADIP(3) => DINA(35),
      DIPADIP(2) => DINA(26),
      DIPADIP(1) => DINA(17),
      DIPADIP(0) => DINA(8),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 16) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 16),
      DOBDO(15 downto 8) => DOUTB(16 downto 9),
      DOBDO(7 downto 0) => DOUTB(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 2) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 2),
      DOPBDOP(1) => DOUTB(17),
      DOPBDOP(0) => DOUTB(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ENA,
      ENBWREN => ENB,
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_REGCEAREGCE_UNCONNECTED\,
      REGCEB => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_REGCEB_UNCONNECTED\,
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => RSTB(0),
      RSTREGARSTREG => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RSTREGARSTREG_UNCONNECTED\,
      RSTREGB => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RSTREGB_UNCONNECTED\,
      SBITERR => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
end STRUCTURE;

-- lib statistics_buffer_lib
library IEEE; use IEEE.STD_LOGIC_1164.ALL;
library UNISIM; use UNISIM.VCOMPONENTS.ALL; 
entity statistics_buffer is
  port (
    wr_clk : in STD_LOGIC;
    wr_rst : in STD_LOGIC;
    rd_clk : in STD_LOGIC;
    rd_rst : in STD_LOGIC;
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    full : out STD_LOGIC;
    empty : out STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 35 downto 0 );
    dout : out STD_LOGIC_VECTOR ( 17 downto 0 )
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of statistics_buffer : entity is true;
  attribute \TYPE\ : string;
  attribute \TYPE\ of statistics_buffer : entity is "statistics_buffer";
  attribute BUS_INFO : string;
  attribute BUS_INFO of statistics_buffer : entity is "18:OUTPUT:dout<17:0>";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of statistics_buffer : entity is "fifo_generator_v9_3, Xilinx CORE Generator 14.7";
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of statistics_buffer : entity is "statistics_buffer,fifo_generator_v9_3,{}";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of statistics_buffer : entity is "statistics_buffer,fifo_generator_v9_3,{c_add_ngc_constraint=0,c_application_type_axis=0,c_application_type_rach=0,c_application_type_rdch=0,c_application_type_wach=0,c_application_type_wdch=0,c_application_type_wrch=0,c_axi_addr_width=32,c_axi_aruser_width=1,c_axi_awuser_width=1,c_axi_buser_width=1,c_axi_data_width=64,c_axi_id_width=4,c_axi_ruser_width=1,c_axi_type=0,c_axi_wuser_width=1,c_axis_tdata_width=64,c_axis_tdest_width=4,c_axis_tid_width=8,c_axis_tkeep_width=4,c_axis_tstrb_width=4,c_axis_tuser_width=4,c_axis_type=0,c_common_clock=0,c_count_type=0,c_data_count_width=10,c_default_value=BlankString,c_din_width=36,c_din_width_axis=1,c_din_width_rach=32,c_din_width_rdch=64,c_din_width_wach=32,c_din_width_wdch=64,c_din_width_wrch=2,c_dout_rst_val=0,c_dout_width=18,c_enable_rlocs=0,c_enable_rst_sync=0,c_error_injection_type=0,c_error_injection_type_axis=0,c_error_injection_type_rach=0,c_error_injection_type_rdch=0,c_error_injection_type_wach=0,c_error_injection_type_wdch=0,c_error_injection_type_wrch=0,c_family=virtex6,c_full_flags_rst_val=1,c_has_almost_empty=0,c_has_almost_full=0,c_has_axi_aruser=0,c_has_axi_awuser=0,c_has_axi_buser=0,c_has_axi_rd_channel=0,c_has_axi_ruser=0,c_has_axi_wr_channel=0,c_has_axi_wuser=0,c_has_axis_tdata=0,c_has_axis_tdest=0,c_has_axis_tid=0,c_has_axis_tkeep=0,c_has_axis_tlast=0,c_has_axis_tready=1,c_has_axis_tstrb=0,c_has_axis_tuser=0,c_has_backup=0,c_has_data_count=0,c_has_data_counts_axis=0,c_has_data_counts_rach=0,c_has_data_counts_rdch=0,c_has_data_counts_wach=0,c_has_data_counts_wdch=0,c_has_data_counts_wrch=0,c_has_int_clk=0,c_has_master_ce=0,c_has_meminit_file=0,c_has_overflow=0,c_has_prog_flags_axis=0,c_has_prog_flags_rach=0,c_has_prog_flags_rdch=0,c_has_prog_flags_wach=0,c_has_prog_flags_wdch=0,c_has_prog_flags_wrch=0,c_has_rd_data_count=0,c_has_rd_rst=0,c_has_rst=1,c_has_slave_ce=0,c_has_srst=0,c_has_underflow=0,c_has_valid=0,c_has_wr_ack=0,c_has_wr_data_count=0,c_has_wr_rst=0,c_implementation_type=2,c_implementation_type_axis=1,c_implementation_type_rach=1,c_implementation_type_rdch=1,c_implementation_type_wach=1,c_implementation_type_wdch=1,c_implementation_type_wrch=1,c_init_wr_pntr_val=0,c_interface_type=0,c_memory_type=1,c_mif_file_name=BlankString,c_msgon_val=1,c_optimization_mode=0,c_overflow_low=0,c_preload_latency=0,c_preload_regs=1,c_prim_fifo_type=1kx36,c_prog_empty_thresh_assert_val=4,c_prog_empty_thresh_assert_val_axis=1022,c_prog_empty_thresh_assert_val_rach=1022,c_prog_empty_thresh_assert_val_rdch=1022,c_prog_empty_thresh_assert_val_wach=1022,c_prog_empty_thresh_assert_val_wdch=1022,c_prog_empty_thresh_assert_val_wrch=1022,c_prog_empty_thresh_negate_val=5,c_prog_empty_type=0,c_prog_empty_type_axis=0,c_prog_empty_type_rach=0,c_prog_empty_type_rdch=0,c_prog_empty_type_wach=0,c_prog_empty_type_wdch=0,c_prog_empty_type_wrch=0,c_prog_full_thresh_assert_val=1021,c_prog_full_thresh_assert_val_axis=1023,c_prog_full_thresh_assert_val_rach=1023,c_prog_full_thresh_assert_val_rdch=1023,c_prog_full_thresh_assert_val_wach=1023,c_prog_full_thresh_assert_val_wdch=1023,c_prog_full_thresh_assert_val_wrch=1023,c_prog_full_thresh_negate_val=1020,c_prog_full_type=0,c_prog_full_type_axis=0,c_prog_full_type_rach=0,c_prog_full_type_rdch=0,c_prog_full_type_wach=0,c_prog_full_type_wdch=0,c_prog_full_type_wrch=0,c_rach_type=0,c_rd_data_count_width=11,c_rd_depth=2048,c_rd_freq=1,c_rd_pntr_width=11,c_rdch_type=0,c_reg_slice_mode_axis=0,c_reg_slice_mode_rach=0,c_reg_slice_mode_rdch=0,c_reg_slice_mode_wach=0,c_reg_slice_mode_wdch=0,c_reg_slice_mode_wrch=0,c_synchronizer_stage=2,c_underflow_low=0,c_use_common_overflow=0,c_use_common_underflow=0,c_use_default_settings=0,c_use_dout_rst=0,c_use_ecc=0,c_use_ecc_axis=0,c_use_ecc_rach=0,c_use_ecc_rdch=0,c_use_ecc_wach=0,c_use_ecc_wdch=0,c_use_ecc_wrch=0,c_use_embedded_reg=0,c_use_fifo16_flags=0,c_use_fwft_data_count=0,c_valid_low=0,c_wach_type=0,c_wdch_type=0,c_wr_ack_low=0,c_wr_data_count_width=10,c_wr_depth=1024,c_wr_depth_axis=1024,c_wr_depth_rach=16,c_wr_depth_rdch=1024,c_wr_depth_wach=16,c_wr_depth_wdch=1024,c_wr_depth_wrch=16,c_wr_freq=1,c_wr_pntr_width=10,c_wr_pntr_width_axis=10,c_wr_pntr_width_rach=4,c_wr_pntr_width_rdch=10,c_wr_pntr_width_wach=4,c_wr_pntr_width_wdch=10,c_wr_pntr_width_wrch=4,c_wr_response_latency=1,c_wrch_type=0}";
  attribute SHREG_MIN_SIZE : string;
  attribute SHREG_MIN_SIZE of statistics_buffer : entity is "-1";
  attribute SHREG_EXTRACT_NGC : string;
  attribute SHREG_EXTRACT_NGC of statistics_buffer : entity is "Yes";
  attribute NLW_UNIQUE_ID : integer;
  attribute NLW_UNIQUE_ID of statistics_buffer : entity is 0;
  attribute NLW_MACRO_TAG : integer;
  attribute NLW_MACRO_TAG of statistics_buffer : entity is 0;
  attribute NLW_MACRO_ALIAS : string;
  attribute NLW_MACRO_ALIAS of statistics_buffer : entity is "statistics_buffer_statistics_buffer";
end statistics_buffer;

architecture STRUCTURE of statistics_buffer is
  signal N0 : STD_LOGIC;
  signal N01 : STD_LOGIC;
  signal N1 : STD_LOGIC;
  signal N10 : STD_LOGIC;
  signal N12 : STD_LOGIC;
  signal N2 : STD_LOGIC;
  signal N4 : STD_LOGIC;
  signal N6 : STD_LOGIC;
  signal N8 : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[0]_RD_PNTR[1]_XOR_64_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[1]_RD_PNTR[2]_XOR_63_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[2]_RD_PNTR[3]_XOR_62_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[3]_RD_PNTR[4]_XOR_61_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[4]_RD_PNTR[5]_XOR_60_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[5]_RD_PNTR[6]_XOR_59_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[6]_RD_PNTR[7]_XOR_58_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[7]_RD_PNTR[8]_XOR_57_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[8]_RD_PNTR[9]_XOR_56_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[9]_RD_PNTR[10]_XOR_55_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[0]_WR_PNTR[1]_XOR_9_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[1]_WR_PNTR[2]_XOR_8_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[2]_WR_PNTR[3]_XOR_7_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[3]_WR_PNTR[4]_XOR_6_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[4]_WR_PNTR[5]_XOR_5_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[5]_WR_PNTR[6]_XOR_4_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[6]_WR_PNTR[7]_XOR_3_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[7]_WR_PNTR[8]_XOR_2_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[8]_WR_PNTR[9]_XOR_1_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\ : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\ : STD_LOGIC_VECTOR ( 10 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\ : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\ : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\ : STD_LOGIC_VECTOR ( 10 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\ : STD_LOGIC_VECTOR ( 10 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\ : STD_LOGIC_VECTOR ( 10 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_17_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_19_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_20_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_21_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_22_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_23_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_24_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_25_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\ : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_10_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_11_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_12_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_13_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_14_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_6_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_8_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_9_o\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_8_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/next_fwft_state\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_6_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp1\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rd_pntr_plus1\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>11\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[10]_gnd_255_o_add_0_out_xor<8>11\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\ : STD_LOGIC_VECTOR ( 10 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\ : STD_LOGIC_VECTOR ( 10 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\ : STD_LOGIC_VECTOR ( 10 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_GND_271_o_MUX_46_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp2\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc0.count[9]_gnd_269_o_add_0_out_xor<6>11\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\ : STD_LOGIC_VECTOR ( 9 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\ : STD_LOGIC_VECTOR ( 9 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\ : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\ : STD_LOGIC_VECTOR ( 9 downto 2 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<0>_inv\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\ : STD_LOGIC_VECTOR ( 17 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\ : STD_LOGIC_VECTOR ( 17 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/rst_full_gen\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d1\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d3\ : STD_LOGIC;
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DOUTA_UNCONNECTED\ : STD_LOGIC_VECTOR ( 35 downto 0 );
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 10 downto 0 );
  attribute PK_HLUTNM : string;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[0]_RD_PNTR[1]_XOR_64_o_xo<0>1\ : label is "___XLNM___14___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_63_o_xo<0>1";
  attribute XSTLIB : boolean;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[0]_RD_PNTR[1]_XOR_64_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_63_o_xo<0>1\ : label is "___XLNM___14___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_63_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_63_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[2]_RD_PNTR[3]_XOR_62_o_xo<0>1\ : label is "___XLNM___16___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_61_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[2]_RD_PNTR[3]_XOR_62_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_61_o_xo<0>1\ : label is "___XLNM___16___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_61_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_61_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[4]_RD_PNTR[5]_XOR_60_o_xo<0>1\ : label is "___XLNM___17___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_59_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[4]_RD_PNTR[5]_XOR_60_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_59_o_xo<0>1\ : label is "___XLNM___17___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_59_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_59_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_58_o_xo<0>1\ : label is "___XLNM___18___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_58_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_58_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[7]_RD_PNTR[8]_XOR_57_o_xo<0>1\ : label is "___XLNM___18___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_58_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[7]_RD_PNTR[8]_XOR_57_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[8]_RD_PNTR[9]_XOR_56_o_xo<0>1\ : label is "___XLNM___15___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_55_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[8]_RD_PNTR[9]_XOR_56_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_55_o_xo<0>1\ : label is "___XLNM___15___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_55_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_55_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_9_o_xo<0>1\ : label is "___XLNM___13___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_9_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_9_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[1]_WR_PNTR[2]_XOR_8_o_xo<0>1\ : label is "___XLNM___13___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_9_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[1]_WR_PNTR[2]_XOR_8_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[2]_WR_PNTR[3]_XOR_7_o_xo<0>1\ : label is "___XLNM___20___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_6_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[2]_WR_PNTR[3]_XOR_7_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_6_o_xo<0>1\ : label is "___XLNM___20___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_6_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_6_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[4]_WR_PNTR[5]_XOR_5_o_xo<0>1\ : label is "___XLNM___21___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_4_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[4]_WR_PNTR[5]_XOR_5_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_4_o_xo<0>1\ : label is "___XLNM___21___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_4_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_4_o_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[6]_WR_PNTR[7]_XOR_3_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_2_o_xo<0>1\ : label is "___XLNM___19___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_1_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_2_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_1_o_xo<0>1\ : label is "___XLNM___19___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_1_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_1_o_xo<0>1\ : label is true;
  attribute ASYNC_REG : boolean;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_0\ : label is true;
  attribute MSGON : string;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_0\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_0\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_1\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_1\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_1\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_2\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_2\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_2\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_3\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_3\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_3\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_4\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_4\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_4\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_5\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_5\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_5\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_6\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_6\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_6\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_7\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_7\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_7\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_8\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_8\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_8\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_9\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_9\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_9\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_0\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_0\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_0\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_1\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_1\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_1\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_10\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_10\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_10\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_2\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_2\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_2\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_3\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_3\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_3\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_4\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_4\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_4\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_5\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_5\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_5\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_6\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_6\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_6\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_7\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_7\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_7\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_8\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_8\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_8\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_9\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_9\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_9\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_0\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_0\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_0\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_1\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_1\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_1\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_2\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_2\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_2\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_3\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_3\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_3\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_4\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_4\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_4\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_5\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_5\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_5\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_6\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_6\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_6\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_7\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_7\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_7\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_8\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_8\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_8\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_9\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_9\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_9\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_0\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_0\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_0\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_1\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_1\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_1\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_10\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_10\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_10\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_2\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_2\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_2\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_3\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_3\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_3\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_4\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_4\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_4\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_5\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_5\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_5\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_6\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_6\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_6\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_7\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_7\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_7\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_8\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_8\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_8\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_9\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_9\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_17_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o1\ : label is "___XLNM___6___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_191_xo<0>1\ : label is "___XLNM___6___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_191_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_201_xo<0>1\ : label is "___XLNM___2___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_201_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_201_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_211_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_221_xo<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_221_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_231_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_231_xo<0>_SW0\ : label is "___XLNM___7___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_231_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_231_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_241_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_241_xo<0>_SW0\ : label is "___XLNM___7___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_231_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_241_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_251_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_251_xo<0>_SW0\ : label is "___XLNM___2___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_201_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_251_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_101_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_111_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_111_xo<0>_SW0\ : label is "___XLNM___12___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_111_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_111_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_121_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_121_xo<0>_SW0\ : label is "___XLNM___12___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_111_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_121_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_131_xo<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_141_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_141_xo<0>_SW0\ : label is "___XLNM___4___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_81_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_141_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_6_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o1\ : label is "___XLNM___8___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_81_xo<0>1\ : label is "___XLNM___4___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_81_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_81_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_91_xo<0>1\ : label is "___XLNM___8___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_91_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11\ : label is "___XLNM___5___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In1\ : label is "___XLNM___5___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd2-In1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_8_o1\ : label is "___XLNM___9___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_8_o1\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC : string;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[0].gm1.m1\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[0].gm1.m1\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[1].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[1].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[2].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[2].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[3].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[3].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[4].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[4].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[5].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[5].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<4>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<5>1\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[0].gm1.m1\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[0].gm1.m1\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[1].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[1].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[2].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[2].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[3].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[3].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[4].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[4].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[5].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[5].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<4>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<5>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_6_o1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<10>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<1>11\ : label is "___XLNM___10___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<2>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<1>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<2>11\ : label is "___XLNM___10___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<2>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<2>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>111\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>12\ : label is "___XLNM___1___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<4>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>12\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<4>11\ : label is "___XLNM___1___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<4>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<4>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<5>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<6>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<7>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<8>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<8>111\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<9>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/Mmux_comp1_GND_271_o_MUX_46_o11\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[0].gm1.m1\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[0].gm1.m1\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[1].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[1].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[2].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[2].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[3].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[3].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[4].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[4].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<4>1\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[0].gm1.m1\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[0].gm1.m1\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[1].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[1].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[2].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[2].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[3].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[3].gms.ms\ : label is true;
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[4].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[4].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<4>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<1>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<2>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<3>11\ : label is "___XLNM___0___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<4>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<3>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<4>11\ : label is "___XLNM___0___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<4>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<4>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<5>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<6>11\ : label is "___XLNM___11___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<7>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<6>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<6>111\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<7>11\ : label is "___XLNM___11___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<7>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<7>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<8>11\ : label is "___XLNM___3___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<9>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<8>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<9>11\ : label is "___XLNM___3___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<9>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<9>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_9\ : label is true;
  attribute XILINX_LEGACY_PRIM : string;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<0>_inv1_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<0>_inv1_INV_0\ : label is true;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv1_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv1_INV_0\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv1\ : label is "___XLNM___9___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_12\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_13\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_14\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_15\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_16\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_17\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_9\ : label is true;
  attribute BMM_INFO_ADDRESS_RANGE : string;
  attribute BMM_INFO_ADDRESS_RANGE of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is "/*_*_RANGE *";
  attribute BUS_INFO of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is "11:OUTPUT:RDADDRECC<10:0>";
  attribute NLW_MACRO_ALIAS of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is "blk_mem_gen_generic_cstr_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr";
  attribute NLW_MACRO_TAG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is 1;
  attribute NLW_UNIQUE_ID of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is 0;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rd_pntr<0>_inv1_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rd_pntr<0>_inv1_INV_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/RST_FULL_GEN\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d1\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d1\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d1\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d3\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d3\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d3\ : label is true;
  attribute XSTLIB of XST_GND : label is true;
  attribute XSTLIB of XST_VCC : label is true;
begin
  dout(17 downto 0) <= \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(17 downto 0);
  empty <= \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\;
  full <= \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\;
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[0]_RD_PNTR[1]_XOR_64_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[0]_RD_PNTR[1]_XOR_64_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_63_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[1]_RD_PNTR[2]_XOR_63_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[2]_RD_PNTR[3]_XOR_62_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[2]_RD_PNTR[3]_XOR_62_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_61_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[3]_RD_PNTR[4]_XOR_61_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[4]_RD_PNTR[5]_XOR_60_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[4]_RD_PNTR[5]_XOR_60_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_59_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[5]_RD_PNTR[6]_XOR_59_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_58_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[6]_RD_PNTR[7]_XOR_58_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[7]_RD_PNTR[8]_XOR_57_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[7]_RD_PNTR[8]_XOR_57_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[8]_RD_PNTR[9]_XOR_56_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[8]_RD_PNTR[9]_XOR_56_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_55_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[9]_RD_PNTR[10]_XOR_55_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_9_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[0]_WR_PNTR[1]_XOR_9_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[1]_WR_PNTR[2]_XOR_8_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[1]_WR_PNTR[2]_XOR_8_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[2]_WR_PNTR[3]_XOR_7_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[2]_WR_PNTR[3]_XOR_7_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_6_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[3]_WR_PNTR[4]_XOR_6_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[4]_WR_PNTR[5]_XOR_5_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[4]_WR_PNTR[5]_XOR_5_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_4_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[5]_WR_PNTR[6]_XOR_4_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[6]_WR_PNTR[7]_XOR_3_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[6]_WR_PNTR[7]_XOR_3_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_2_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[7]_WR_PNTR[8]_XOR_2_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_1_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[8]_WR_PNTR[9]_XOR_1_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(0),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(0),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(0),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(0),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_25_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_24_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_23_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_22_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_21_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_20_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_19_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_17_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[0]_RD_PNTR[1]_XOR_64_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[1]_RD_PNTR[2]_XOR_63_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[2]_RD_PNTR[3]_XOR_62_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[3]_RD_PNTR[4]_XOR_61_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[4]_RD_PNTR[5]_XOR_60_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[5]_RD_PNTR[6]_XOR_59_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[6]_RD_PNTR[7]_XOR_58_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[7]_RD_PNTR[8]_XOR_57_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[8]_RD_PNTR[9]_XOR_56_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[9]_RD_PNTR[10]_XOR_55_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_17_o1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_17_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_18_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_191_xo<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_19_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_201_xo<0>1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"96696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_20_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_211_xo<0>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_21_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_221_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I5 => N2,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_22_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_221_xo<0>_SW0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      O => N2
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_231_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I5 => N4,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_23_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_231_xo<0>_SW0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"69"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      O => N4
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_241_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I5 => N6,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_24_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_241_xo<0>_SW0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      O => N6
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_251_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(1),
      I5 => N8,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_25_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[10]_reduce_xor_251_xo<0>_SW0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"69969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      O => N8
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_14_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_13_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_12_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_11_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_10_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_9_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_8_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_6_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[0]_WR_PNTR[1]_XOR_9_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[1]_WR_PNTR[2]_XOR_8_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[2]_WR_PNTR[3]_XOR_7_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[3]_WR_PNTR[4]_XOR_6_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[4]_WR_PNTR[5]_XOR_5_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[5]_WR_PNTR[6]_XOR_4_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[6]_WR_PNTR[7]_XOR_3_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[7]_WR_PNTR[8]_XOR_2_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[8]_WR_PNTR[9]_XOR_1_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_101_xo<0>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_10_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_111_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I5 => N10,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_11_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_111_xo<0>_SW0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      O => N10
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_121_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I5 => N12,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_12_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_121_xo<0>_SW0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"69"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      O => N12
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_131_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(1),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_8_o\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_13_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_141_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(1),
      I5 => N01,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_14_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_141_xo<0>_SW0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"69969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      O => N01
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_6_o1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_6_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_7_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_81_xo<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_8_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_91_xo<0>1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"96696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[9]_reduce_xor_9_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2333"
    )
    port map (
      I0 => rd_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I3 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In\,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"55D5"
    )
    port map (
      I0 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I3 => rd_en,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/next_fwft_state\(0),
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd2-In1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AE"
    )
    port map (
      I0 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I2 => rd_en,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/next_fwft_state\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_8_o\,
      PRE => rd_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_8_o\,
      PRE => rd_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_8_o1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8E8A"
    )
    port map (
      I0 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I3 => rd_en,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_8_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[0].gm1.m1\: unisim.vcomponents.MUXCY
    port map (
      CI => N0,
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(0),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[1].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(0),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(1),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[2].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(1),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(2),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[3].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(2),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(3),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[4].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(3),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(4),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[5].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(4),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<0>1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"09"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(4),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(6),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(8),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<5>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[0].gm1.m1\: unisim.vcomponents.MUXCY
    port map (
      CI => N0,
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(0),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[1].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(0),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(1),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[2].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(1),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(2),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[3].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(2),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(3),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[4].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(3),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(4),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[5].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(4),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp1\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<0>1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"90"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8241"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(4),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(6),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(8),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<5>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_6_o1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF2333FFFF0000"
    )
    port map (
      I0 => rd_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I3 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0\,
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp1\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_6_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_6_o\,
      PRE => rd_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<10>11\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AA6A"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8),
      I3 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[10]_gnd_255_o_add_0_out_xor<8>11\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<1>11\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<2>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"9A"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>111\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"F7"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>11\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>12\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9AAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<4>11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"9AAAAAAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<5>11\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9AAAAAAAAAAAAAAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<6>11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"9AAAAAAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>11\,
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<7>11\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9AAAAAAAAAAAAAAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>11\,
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<8>11\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8),
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[10]_gnd_255_o_add_0_out_xor<8>11\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<8>111\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFF7FFFFFFF"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<3>11\,
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[10]_gnd_255_o_add_0_out_xor<8>11\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[10]_GND_255_o_add_0_OUT_xor<9>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"A6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8),
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[10]_gnd_255_o_add_0_out_xor<8>11\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_1\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_10\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[10]_GND_255_o_add_0_OUT\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_0\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rd_pntr_plus1\(0),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_1\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_10\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/Mmux_comp1_GND_271_o_MUX_46_o11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"33023300"
    )
    port map (
      I0 => wr_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/rst_full_gen\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\,
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1\,
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp2\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_GND_271_o_MUX_46_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[0].gm1.m1\: unisim.vcomponents.MUXCY
    port map (
      CI => N0,
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(0),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[1].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(0),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(1),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[2].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(1),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(2),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[3].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(2),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(3),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[4].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(3),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(1),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(3),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(9),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[0].gm1.m1\: unisim.vcomponents.MUXCY
    port map (
      CI => N0,
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(0),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[1].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(0),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(1),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[2].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(1),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(2),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[3].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(2),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(3),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[4].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(3),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp2\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0990"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(1),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(3),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(9),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_GND_271_o_MUX_46_o\,
      PRE => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_GND_271_o_MUX_46_o\,
      PRE => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => wr_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<1>11\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<2>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"9A"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<3>11\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9AAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<4>11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"9AAAAAAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<5>11\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9AAAAAAAAAAAAAAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(3),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<6>11\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(6),
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc0.count[9]_gnd_269_o_add_0_out_xor<6>11\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<6>111\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF7FFFFFFFFFFF"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(4),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(3),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc0.count[9]_gnd_269_o_add_0_out_xor<6>11\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<7>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"9A"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(7),
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc0.count[9]_gnd_269_o_add_0_out_xor<6>11\,
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<8>11\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9AAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(8),
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc0.count[9]_gnd_269_o_add_0_out_xor<6>11\,
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc0.count[9]_GND_269_o_add_0_OUT_xor<9>11\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAA6AAA"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(8),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(6),
      I4 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc0.count[9]_gnd_269_o_add_0_out_xor<6>11\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_1\: unisim.vcomponents.FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(1),
      PRE => wr_rst,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count[9]_GND_269_o_add_0_OUT\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_0\: unisim.vcomponents.FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<0>_inv\,
      PRE => wr_rst,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_1\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<0>_inv1_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<0>_inv\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv1_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"4404"
    )
    port map (
      I0 => rd_rst,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I3 => rd_en,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_0\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(0),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_1\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_10\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_11\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_12\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(12),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_13\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(13),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(13)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_14\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(14),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(14)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_15\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(15),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(15)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_16\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(16),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(16)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_17\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(17),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(17)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_2\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_3\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_4\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_5\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_6\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_7\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_8\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i_9\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/_n0025_inv\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/dout_i\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\: entity work.mcaBuffer_blk_mem_gen_generic_cstr
    port map (
      ADDRA(9 downto 2) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc0.count_d2\(9 downto 2),
      ADDRA(1) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv\,
      ADDRA(0) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<0>_inv\,
      ADDRB(10 downto 0) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10 downto 0),
      CLKA => wr_clk,
      CLKB => rd_clk,
      DBITERR => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DBITERR_UNCONNECTED\,
      DINA(35 downto 18) => din(17 downto 0),
      DINA(17 downto 0) => din(35 downto 18),
      DINB(17) => N1,
      DINB(16) => N1,
      DINB(15) => N1,
      DINB(14) => N1,
      DINB(13) => N1,
      DINB(12) => N1,
      DINB(11) => N1,
      DINB(10) => N1,
      DINB(9) => N1,
      DINB(8) => N1,
      DINB(7) => N1,
      DINB(6) => N1,
      DINB(5) => N1,
      DINB(4) => N1,
      DINB(3) => N1,
      DINB(2) => N1,
      DINB(1) => N1,
      DINB(0) => N1,
      DOUTA(35 downto 0) => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DOUTA_UNCONNECTED\(35 downto 0),
      DOUTB(17 downto 0) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/doutb_i\(17 downto 0),
      ENA => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      ENB => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      INJECTDBITERR => N1,
      INJECTSBITERR => N1,
      RDADDRECC(10 downto 0) => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_RDADDRECC_UNCONNECTED\(10 downto 0),
      REGCEA(0) => N0,
      REGCEB(0) => N0,
      RSTA(0) => N1,
      RSTB(0) => N1,
      SBITERR => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmga.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_SBITERR_UNCONNECTED\,
      WEA(3) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      WEA(2) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      WEA(1) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      WEA(0) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      WEB(1) => N1,
      WEB(0) => N1
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rd_pntr<0>_inv1_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rd_pntr_plus1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/RST_FULL_GEN\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d3\,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/rst_full_gen\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d1\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      D => N1,
      PRE => wr_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      D => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d1\,
      PRE => wr_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d3\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      D => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d2\,
      PRE => wr_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/rstblk/grstd1.grst_full.rst_d3\
    );
XST_GND: unisim.vcomponents.GND
    port map (
      G => N1
    );
XST_VCC: unisim.vcomponents.VCC
    port map (
      P => N0
    );
end STRUCTURE;
