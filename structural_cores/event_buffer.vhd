
-- lib event_buffer_lib
library IEEE; use IEEE.STD_LOGIC_1164.ALL;
library UNISIM; use UNISIM.VCOMPONENTS.ALL; 
entity eventbuffer_blk_mem_gen_generic_cstr is
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
    WEA : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ADDRA : in STD_LOGIC_VECTOR ( 11 downto 0 );
    DINA : in STD_LOGIC_VECTOR ( 71 downto 0 );
    RSTB : in STD_LOGIC_VECTOR ( 1 downto 0 );
    REGCEB : in STD_LOGIC_VECTOR ( 0 to 0 );
    WEB : in STD_LOGIC_VECTOR ( 1 downto 0 );
    ADDRB : in STD_LOGIC_VECTOR ( 13 downto 0 );
    DINB : in STD_LOGIC_VECTOR ( 17 downto 0 );
    DOUTA : out STD_LOGIC_VECTOR ( 71 downto 0 );
    DOUTB : out STD_LOGIC_VECTOR ( 17 downto 0 );
    RDADDRECC : out STD_LOGIC_VECTOR ( 13 downto 0 )
  );
end eventbuffer_blk_mem_gen_generic_cstr;

architecture STRUCTURE of eventbuffer_blk_mem_gen_generic_cstr is
  signal N0 : STD_LOGIC;
  signal ena_array : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal enb_array : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \has_mux_b.B/sel_pipe\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \has_mux_b.B/sel_pipe_d1\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \ramloop[0].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \ramloop[1].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \ramloop[2].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \ramloop[3].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \ramloop[4].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \ramloop[5].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \ramloop[6].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \ramloop[7].ram.ram_doutb\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \DBITERR^Mid\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 31 downto 8 );
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 downto 1 );
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 4 );
  attribute XSTLIB : boolean;
  attribute XSTLIB of XST_GND : label is true;
  attribute XSTLIB of XST_VCC : label is true;
  attribute XSTLIB of \bindec_a.bindec_inst_a/Mmux_ENOUT<0>11\ : label is true;
  attribute XSTLIB of \bindec_a.bindec_inst_a/Mmux_ENOUT<1>11\ : label is true;
  attribute XSTLIB of \bindec_a.bindec_inst_a/Mmux_ENOUT<2>11\ : label is true;
  attribute XSTLIB of \bindec_a.bindec_inst_a/Mmux_ENOUT<3>11\ : label is true;
  attribute XSTLIB of \bindec_b.bindec_inst_b/Mmux_ENOUT<0>11\ : label is true;
  attribute XSTLIB of \bindec_b.bindec_inst_b/Mmux_ENOUT<1>11\ : label is true;
  attribute XSTLIB of \bindec_b.bindec_inst_b/Mmux_ENOUT<2>11\ : label is true;
  attribute XSTLIB of \bindec_b.bindec_inst_b/Mmux_ENOUT<3>11\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux101\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux11\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux111\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux121\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux131\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux141\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux151\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux161\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux171\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux181\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux21\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux31\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux41\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux51\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux61\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux71\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux81\ : label is true;
  attribute XSTLIB of \has_mux_b.B/Mmux_dout_mux91\ : label is true;
  attribute XSTLIB of \has_mux_b.B/sel_pipe_0\ : label is true;
  attribute XSTLIB of \has_mux_b.B/sel_pipe_1\ : label is true;
  attribute XSTLIB of \has_mux_b.B/sel_pipe_d1_0\ : label is true;
  attribute XSTLIB of \has_mux_b.B/sel_pipe_d1_1\ : label is true;
  attribute BUS_INFO : string;
  attribute BUS_INFO of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC : string;
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA : string;
  attribute SAVEDATA of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
  attribute BUS_INFO of \ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA of \ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
  attribute BUS_INFO of \ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA of \ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
  attribute BUS_INFO of \ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA of \ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
  attribute BUS_INFO of \ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA of \ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
  attribute BUS_INFO of \ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA of \ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
  attribute BUS_INFO of \ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA of \ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
  attribute BUS_INFO of \ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "4:INPUT:WEA<3:0>";
  attribute OPTIMIZE_PRIMITIVES_NGC of \ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "no";
  attribute SAVEDATA of \ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is "FALSE";
  attribute XSTLIB of \ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\ : label is true;
begin
  DBITERR <= \DBITERR^Mid\;
  RDADDRECC(13) <= \DBITERR^Mid\;
  RDADDRECC(12) <= \DBITERR^Mid\;
  RDADDRECC(11) <= \DBITERR^Mid\;
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
\bindec_a.bindec_inst_a/Mmux_ENOUT<0>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"10"
    )
    port map (
      I0 => ADDRA(10),
      I1 => ADDRA(11),
      I2 => ENA,
      O => ena_array(0)
    );
\bindec_a.bindec_inst_a/Mmux_ENOUT<1>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
    port map (
      I0 => ADDRA(11),
      I1 => ADDRA(10),
      I2 => ENA,
      O => ena_array(1)
    );
\bindec_a.bindec_inst_a/Mmux_ENOUT<2>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
    port map (
      I0 => ADDRA(10),
      I1 => ADDRA(11),
      I2 => ENA,
      O => ena_array(2)
    );
\bindec_a.bindec_inst_a/Mmux_ENOUT<3>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
    port map (
      I0 => ADDRA(10),
      I1 => ADDRA(11),
      I2 => ENA,
      O => ena_array(3)
    );
\bindec_b.bindec_inst_b/Mmux_ENOUT<0>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"10"
    )
    port map (
      I0 => ADDRB(12),
      I1 => ADDRB(13),
      I2 => ENB,
      O => enb_array(0)
    );
\bindec_b.bindec_inst_b/Mmux_ENOUT<1>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
    port map (
      I0 => ADDRB(13),
      I1 => ADDRB(12),
      I2 => ENB,
      O => enb_array(1)
    );
\bindec_b.bindec_inst_b/Mmux_ENOUT<2>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
    port map (
      I0 => ADDRB(12),
      I1 => ADDRB(13),
      I2 => ENB,
      O => enb_array(2)
    );
\bindec_b.bindec_inst_b/Mmux_ENOUT<3>11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
    port map (
      I0 => ADDRB(12),
      I1 => ADDRB(13),
      I2 => ENB,
      O => enb_array(3)
    );
\has_mux_b.B/Mmux_dout_mux101\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(1),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(1),
      I4 => \ramloop[0].ram.ram_doutb\(1),
      I5 => \ramloop[2].ram.ram_doutb\(1),
      O => DOUTB(1)
    );
\has_mux_b.B/Mmux_dout_mux11\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(0),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(0),
      I4 => \ramloop[0].ram.ram_doutb\(0),
      I5 => \ramloop[2].ram.ram_doutb\(0),
      O => DOUTB(0)
    );
\has_mux_b.B/Mmux_dout_mux111\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(2),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(2),
      I4 => \ramloop[0].ram.ram_doutb\(2),
      I5 => \ramloop[2].ram.ram_doutb\(2),
      O => DOUTB(2)
    );
\has_mux_b.B/Mmux_dout_mux121\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(3),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(3),
      I4 => \ramloop[0].ram.ram_doutb\(3),
      I5 => \ramloop[2].ram.ram_doutb\(3),
      O => DOUTB(3)
    );
\has_mux_b.B/Mmux_dout_mux131\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(4),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(4),
      I4 => \ramloop[0].ram.ram_doutb\(4),
      I5 => \ramloop[2].ram.ram_doutb\(4),
      O => DOUTB(4)
    );
\has_mux_b.B/Mmux_dout_mux141\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(5),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(5),
      I4 => \ramloop[0].ram.ram_doutb\(5),
      I5 => \ramloop[2].ram.ram_doutb\(5),
      O => DOUTB(5)
    );
\has_mux_b.B/Mmux_dout_mux151\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(6),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(6),
      I4 => \ramloop[0].ram.ram_doutb\(6),
      I5 => \ramloop[2].ram.ram_doutb\(6),
      O => DOUTB(6)
    );
\has_mux_b.B/Mmux_dout_mux161\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(7),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(7),
      I4 => \ramloop[0].ram.ram_doutb\(7),
      I5 => \ramloop[2].ram.ram_doutb\(7),
      O => DOUTB(7)
    );
\has_mux_b.B/Mmux_dout_mux171\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[3].ram.ram_doutb\(8),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[1].ram.ram_doutb\(8),
      I4 => \ramloop[0].ram.ram_doutb\(8),
      I5 => \ramloop[2].ram.ram_doutb\(8),
      O => DOUTB(8)
    );
\has_mux_b.B/Mmux_dout_mux181\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(0),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(0),
      I4 => \ramloop[4].ram.ram_doutb\(0),
      I5 => \ramloop[6].ram.ram_doutb\(0),
      O => DOUTB(9)
    );
\has_mux_b.B/Mmux_dout_mux21\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(1),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(1),
      I4 => \ramloop[4].ram.ram_doutb\(1),
      I5 => \ramloop[6].ram.ram_doutb\(1),
      O => DOUTB(10)
    );
\has_mux_b.B/Mmux_dout_mux31\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(2),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(2),
      I4 => \ramloop[4].ram.ram_doutb\(2),
      I5 => \ramloop[6].ram.ram_doutb\(2),
      O => DOUTB(11)
    );
\has_mux_b.B/Mmux_dout_mux41\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(3),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(3),
      I4 => \ramloop[4].ram.ram_doutb\(3),
      I5 => \ramloop[6].ram.ram_doutb\(3),
      O => DOUTB(12)
    );
\has_mux_b.B/Mmux_dout_mux51\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(4),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(4),
      I4 => \ramloop[4].ram.ram_doutb\(4),
      I5 => \ramloop[6].ram.ram_doutb\(4),
      O => DOUTB(13)
    );
\has_mux_b.B/Mmux_dout_mux61\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(5),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(5),
      I4 => \ramloop[4].ram.ram_doutb\(5),
      I5 => \ramloop[6].ram.ram_doutb\(5),
      O => DOUTB(14)
    );
\has_mux_b.B/Mmux_dout_mux71\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(6),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(6),
      I4 => \ramloop[4].ram.ram_doutb\(6),
      I5 => \ramloop[6].ram.ram_doutb\(6),
      O => DOUTB(15)
    );
\has_mux_b.B/Mmux_dout_mux81\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(7),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(7),
      I4 => \ramloop[4].ram.ram_doutb\(7),
      I5 => \ramloop[6].ram.ram_doutb\(7),
      O => DOUTB(16)
    );
\has_mux_b.B/Mmux_dout_mux91\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"DFD5DAD08F858A80"
    )
    port map (
      I0 => \has_mux_b.B/sel_pipe_d1\(0),
      I1 => \ramloop[7].ram.ram_doutb\(8),
      I2 => \has_mux_b.B/sel_pipe_d1\(1),
      I3 => \ramloop[5].ram.ram_doutb\(8),
      I4 => \ramloop[4].ram.ram_doutb\(8),
      I5 => \ramloop[6].ram.ram_doutb\(8),
      O => DOUTB(17)
    );
\has_mux_b.B/sel_pipe_0\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => CLKB,
      CE => ENB,
      D => ADDRB(12),
      Q => \has_mux_b.B/sel_pipe\(0)
    );
\has_mux_b.B/sel_pipe_1\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => CLKB,
      CE => ENB,
      D => ADDRB(13),
      Q => \has_mux_b.B/sel_pipe\(1)
    );
\has_mux_b.B/sel_pipe_d1_0\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => CLKB,
      CE => REGCEB(0),
      D => \has_mux_b.B/sel_pipe\(0),
      Q => \has_mux_b.B/sel_pipe_d1\(0)
    );
\has_mux_b.B/sel_pipe_d1_1\: unisim.vcomponents.FDE
    generic map(
      INIT => '0'
    )
    port map (
      C => CLKB,
      CE => REGCEB(0),
      D => \has_mux_b.B/sel_pipe\(1),
      Q => \has_mux_b.B/sel_pipe_d1\(1)
    );
\ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
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
      DIADI(31 downto 24) => DINA(61 downto 54),
      DIADI(23 downto 16) => DINA(43 downto 36),
      DIADI(15 downto 8) => DINA(25 downto 18),
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
      DIPADIP(3) => DINA(62),
      DIPADIP(2) => DINA(44),
      DIPADIP(1) => DINA(26),
      DIPADIP(0) => DINA(8),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[0].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[0].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(0),
      ENBWREN => enb_array(0),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[0].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
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
\ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(61 downto 54),
      DIADI(23 downto 16) => DINA(43 downto 36),
      DIADI(15 downto 8) => DINA(25 downto 18),
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
      DIPADIP(3) => DINA(62),
      DIPADIP(2) => DINA(44),
      DIPADIP(1) => DINA(26),
      DIPADIP(0) => DINA(8),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[1].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[1].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(1),
      ENBWREN => enb_array(1),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
      SBITERR => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[1].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
\ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(61 downto 54),
      DIADI(23 downto 16) => DINA(43 downto 36),
      DIADI(15 downto 8) => DINA(25 downto 18),
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
      DIPADIP(3) => DINA(62),
      DIPADIP(2) => DINA(44),
      DIPADIP(1) => DINA(26),
      DIPADIP(0) => DINA(8),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[2].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[2].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(2),
      ENBWREN => enb_array(2),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
      SBITERR => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[2].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
\ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(61 downto 54),
      DIADI(23 downto 16) => DINA(43 downto 36),
      DIADI(15 downto 8) => DINA(25 downto 18),
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
      DIPADIP(3) => DINA(62),
      DIPADIP(2) => DINA(44),
      DIPADIP(1) => DINA(26),
      DIPADIP(0) => DINA(8),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[3].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[3].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(3),
      ENBWREN => enb_array(3),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
      SBITERR => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[3].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
\ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(70 downto 63),
      DIADI(23 downto 16) => DINA(52 downto 45),
      DIADI(15 downto 8) => DINA(34 downto 27),
      DIADI(7 downto 0) => DINA(16 downto 9),
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
      DIPADIP(3) => DINA(71),
      DIPADIP(2) => DINA(53),
      DIPADIP(1) => DINA(35),
      DIPADIP(0) => DINA(17),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[4].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[4].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(0),
      ENBWREN => enb_array(0),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
      SBITERR => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[4].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
\ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(70 downto 63),
      DIADI(23 downto 16) => DINA(52 downto 45),
      DIADI(15 downto 8) => DINA(34 downto 27),
      DIADI(7 downto 0) => DINA(16 downto 9),
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
      DIPADIP(3) => DINA(71),
      DIPADIP(2) => DINA(53),
      DIPADIP(1) => DINA(35),
      DIPADIP(0) => DINA(17),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[5].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[5].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(1),
      ENBWREN => enb_array(1),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
      SBITERR => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[5].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
\ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(70 downto 63),
      DIADI(23 downto 16) => DINA(52 downto 45),
      DIADI(15 downto 8) => DINA(34 downto 27),
      DIADI(7 downto 0) => DINA(16 downto 9),
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
      DIPADIP(3) => DINA(71),
      DIPADIP(2) => DINA(53),
      DIPADIP(1) => DINA(35),
      DIPADIP(0) => DINA(17),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[6].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[6].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(2),
      ENBWREN => enb_array(2),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
      SBITERR => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[6].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
\ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram\: unisim.vcomponents.RAMB36E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
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
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
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
      ADDRBWRADDR(14 downto 3) => ADDRB(11 downto 0),
      ADDRBWRADDR(2) => \DBITERR^Mid\,
      ADDRBWRADDR(1) => \DBITERR^Mid\,
      ADDRBWRADDR(0) => \DBITERR^Mid\,
      CASCADEINA => \DBITERR^Mid\,
      CASCADEINB => \DBITERR^Mid\,
      CASCADEOUTA => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTA_UNCONNECTED\,
      CASCADEOUTB => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_CASCADEOUTB_UNCONNECTED\,
      CLKARDCLK => CLKA,
      CLKBWRCLK => CLKB,
      DBITERR => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DBITERR_UNCONNECTED\,
      DIADI(31 downto 24) => DINA(70 downto 63),
      DIADI(23 downto 16) => DINA(52 downto 45),
      DIADI(15 downto 8) => DINA(34 downto 27),
      DIADI(7 downto 0) => DINA(16 downto 9),
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
      DIPADIP(3) => DINA(71),
      DIPADIP(2) => DINA(53),
      DIPADIP(1) => DINA(35),
      DIPADIP(0) => DINA(17),
      DIPBDIP(3) => \DBITERR^Mid\,
      DIPBDIP(2) => \DBITERR^Mid\,
      DIPBDIP(1) => \DBITERR^Mid\,
      DIPBDIP(0) => \DBITERR^Mid\,
      DOADO(31 downto 0) => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOADO_UNCONNECTED\(31 downto 0),
      DOBDO(31 downto 8) => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOBDO_UNCONNECTED\(31 downto 8),
      DOBDO(7 downto 0) => \ramloop[7].ram.ram_doutb\(7 downto 0),
      DOPADOP(3 downto 0) => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPADOP_UNCONNECTED\(3 downto 0),
      DOPBDOP(3 downto 1) => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_DOPBDOP_UNCONNECTED\(3 downto 1),
      DOPBDOP(0) => \ramloop[7].ram.ram_doutb\(8),
      ECCPARITY(7 downto 0) => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_ECCPARITY_UNCONNECTED\(7 downto 0),
      ENARDEN => ena_array(3),
      ENBWREN => enb_array(3),
      INJECTDBITERR => \DBITERR^Mid\,
      INJECTSBITERR => \DBITERR^Mid\,
      RDADDRECC(8 downto 0) => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_RDADDRECC_UNCONNECTED\(8 downto 0),
      REGCEAREGCE => \DBITERR^Mid\,
      REGCEB => REGCEB(0),
      RSTRAMARSTRAM => \DBITERR^Mid\,
      RSTRAMB => \DBITERR^Mid\,
      RSTREGARSTREG => \DBITERR^Mid\,
      RSTREGB => RSTB(1),
      SBITERR => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_SBITERR_UNCONNECTED\,
      WEA(3) => WEA(0),
      WEA(2) => WEA(0),
      WEA(1) => WEA(0),
      WEA(0) => WEA(0),
      WEBWE(7 downto 4) => \NLW_ramloop[7].ram.r/v6_noinit.ram/SDP.SIMPLE_PRIM36.ram_WEBWE_UNCONNECTED\(7 downto 4),
      WEBWE(3) => \DBITERR^Mid\,
      WEBWE(2) => \DBITERR^Mid\,
      WEBWE(1) => \DBITERR^Mid\,
      WEBWE(0) => \DBITERR^Mid\
    );
end STRUCTURE;

-- lib event_buffer_lib
library IEEE; use IEEE.STD_LOGIC_1164.ALL;
library UNISIM; use UNISIM.VCOMPONENTS.ALL; 
entity event_buffer is
  port (
    wr_clk : in STD_LOGIC;
    wr_rst : in STD_LOGIC;
    rd_clk : in STD_LOGIC;
    rd_rst : in STD_LOGIC;
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    full : out STD_LOGIC;
    empty : out STD_LOGIC;
    prog_full : out STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 71 downto 0 );
    prog_full_thresh : in STD_LOGIC_VECTOR ( 11 downto 0 );
    dout : out STD_LOGIC_VECTOR ( 17 downto 0 )
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of event_buffer : entity is true;
  attribute \TYPE\ : string;
  attribute \TYPE\ of event_buffer : entity is "event_buffer";
  attribute BUS_INFO : string;
  attribute BUS_INFO of event_buffer : entity is "18:OUTPUT:dout<17:0>";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of event_buffer : entity is "fifo_generator_v9_3, Xilinx CORE Generator 14.7";
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of event_buffer : entity is "event_buffer,fifo_generator_v9_3,{}";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of event_buffer : entity is "event_buffer,fifo_generator_v9_3,{c_add_ngc_constraint=0,c_application_type_axis=0,c_application_type_rach=0,c_application_type_rdch=0,c_application_type_wach=0,c_application_type_wdch=0,c_application_type_wrch=0,c_axi_addr_width=32,c_axi_aruser_width=1,c_axi_awuser_width=1,c_axi_buser_width=1,c_axi_data_width=64,c_axi_id_width=4,c_axi_ruser_width=1,c_axi_type=0,c_axi_wuser_width=1,c_axis_tdata_width=64,c_axis_tdest_width=4,c_axis_tid_width=8,c_axis_tkeep_width=4,c_axis_tstrb_width=4,c_axis_tuser_width=4,c_axis_type=0,c_common_clock=0,c_count_type=0,c_data_count_width=12,c_default_value=BlankString,c_din_width=72,c_din_width_axis=1,c_din_width_rach=32,c_din_width_rdch=64,c_din_width_wach=32,c_din_width_wdch=64,c_din_width_wrch=2,c_dout_rst_val=0,c_dout_width=18,c_enable_rlocs=0,c_enable_rst_sync=0,c_error_injection_type=0,c_error_injection_type_axis=0,c_error_injection_type_rach=0,c_error_injection_type_rdch=0,c_error_injection_type_wach=0,c_error_injection_type_wdch=0,c_error_injection_type_wrch=0,c_family=virtex6,c_full_flags_rst_val=0,c_has_almost_empty=0,c_has_almost_full=0,c_has_axi_aruser=0,c_has_axi_awuser=0,c_has_axi_buser=0,c_has_axi_rd_channel=0,c_has_axi_ruser=0,c_has_axi_wr_channel=0,c_has_axi_wuser=0,c_has_axis_tdata=0,c_has_axis_tdest=0,c_has_axis_tid=0,c_has_axis_tkeep=0,c_has_axis_tlast=0,c_has_axis_tready=1,c_has_axis_tstrb=0,c_has_axis_tuser=0,c_has_backup=0,c_has_data_count=0,c_has_data_counts_axis=0,c_has_data_counts_rach=0,c_has_data_counts_rdch=0,c_has_data_counts_wach=0,c_has_data_counts_wdch=0,c_has_data_counts_wrch=0,c_has_int_clk=0,c_has_master_ce=0,c_has_meminit_file=0,c_has_overflow=0,c_has_prog_flags_axis=0,c_has_prog_flags_rach=0,c_has_prog_flags_rdch=0,c_has_prog_flags_wach=0,c_has_prog_flags_wdch=0,c_has_prog_flags_wrch=0,c_has_rd_data_count=0,c_has_rd_rst=0,c_has_rst=1,c_has_slave_ce=0,c_has_srst=0,c_has_underflow=0,c_has_valid=0,c_has_wr_ack=0,c_has_wr_data_count=0,c_has_wr_rst=0,c_implementation_type=2,c_implementation_type_axis=1,c_implementation_type_rach=1,c_implementation_type_rdch=1,c_implementation_type_wach=1,c_implementation_type_wdch=1,c_implementation_type_wrch=1,c_init_wr_pntr_val=0,c_interface_type=0,c_memory_type=1,c_mif_file_name=BlankString,c_msgon_val=1,c_optimization_mode=0,c_overflow_low=0,c_preload_latency=0,c_preload_regs=1,c_prim_fifo_type=4kx9,c_prog_empty_thresh_assert_val=4,c_prog_empty_thresh_assert_val_axis=1022,c_prog_empty_thresh_assert_val_rach=1022,c_prog_empty_thresh_assert_val_rdch=1022,c_prog_empty_thresh_assert_val_wach=1022,c_prog_empty_thresh_assert_val_wdch=1022,c_prog_empty_thresh_assert_val_wrch=1022,c_prog_empty_thresh_negate_val=5,c_prog_empty_type=0,c_prog_empty_type_axis=0,c_prog_empty_type_rach=0,c_prog_empty_type_rdch=0,c_prog_empty_type_wach=0,c_prog_empty_type_wdch=0,c_prog_empty_type_wrch=0,c_prog_full_thresh_assert_val=4093,c_prog_full_thresh_assert_val_axis=1023,c_prog_full_thresh_assert_val_rach=1023,c_prog_full_thresh_assert_val_rdch=1023,c_prog_full_thresh_assert_val_wach=1023,c_prog_full_thresh_assert_val_wdch=1023,c_prog_full_thresh_assert_val_wrch=1023,c_prog_full_thresh_negate_val=4092,c_prog_full_type=3,c_prog_full_type_axis=0,c_prog_full_type_rach=0,c_prog_full_type_rdch=0,c_prog_full_type_wach=0,c_prog_full_type_wdch=0,c_prog_full_type_wrch=0,c_rach_type=0,c_rd_data_count_width=14,c_rd_depth=16384,c_rd_freq=1,c_rd_pntr_width=14,c_rdch_type=0,c_reg_slice_mode_axis=0,c_reg_slice_mode_rach=0,c_reg_slice_mode_rdch=0,c_reg_slice_mode_wach=0,c_reg_slice_mode_wdch=0,c_reg_slice_mode_wrch=0,c_synchronizer_stage=2,c_underflow_low=0,c_use_common_overflow=0,c_use_common_underflow=0,c_use_default_settings=0,c_use_dout_rst=0,c_use_ecc=0,c_use_ecc_axis=0,c_use_ecc_rach=0,c_use_ecc_rdch=0,c_use_ecc_wach=0,c_use_ecc_wdch=0,c_use_ecc_wrch=0,c_use_embedded_reg=1,c_use_fifo16_flags=0,c_use_fwft_data_count=0,c_valid_low=0,c_wach_type=0,c_wdch_type=0,c_wr_ack_low=0,c_wr_data_count_width=12,c_wr_depth=4096,c_wr_depth_axis=1024,c_wr_depth_rach=16,c_wr_depth_rdch=1024,c_wr_depth_wach=16,c_wr_depth_wdch=1024,c_wr_depth_wrch=16,c_wr_freq=1,c_wr_pntr_width=12,c_wr_pntr_width_axis=10,c_wr_pntr_width_rach=4,c_wr_pntr_width_rdch=10,c_wr_pntr_width_wach=4,c_wr_pntr_width_wdch=10,c_wr_pntr_width_wrch=4,c_wr_response_latency=1,c_wrch_type=0}";
  attribute SHREG_MIN_SIZE : string;
  attribute SHREG_MIN_SIZE of event_buffer : entity is "-1";
  attribute SHREG_EXTRACT_NGC : string;
  attribute SHREG_EXTRACT_NGC of event_buffer : entity is "Yes";
  attribute NLW_UNIQUE_ID : integer;
  attribute NLW_UNIQUE_ID of event_buffer : entity is 0;
  attribute NLW_MACRO_TAG : integer;
  attribute NLW_MACRO_TAG of event_buffer : entity is 0;
  attribute NLW_MACRO_ALIAS : string;
  attribute NLW_MACRO_ALIAS of event_buffer : entity is "event_buffer_event_buffer";
end event_buffer;

architecture STRUCTURE of event_buffer is
  signal N0 : STD_LOGIC;
  signal N01 : STD_LOGIC;
  signal N1 : STD_LOGIC;
  signal N10 : STD_LOGIC;
  signal N12 : STD_LOGIC;
  signal N14 : STD_LOGIC;
  signal N16 : STD_LOGIC;
  signal N18 : STD_LOGIC;
  signal N2 : STD_LOGIC;
  signal N20 : STD_LOGIC;
  signal N4 : STD_LOGIC;
  signal N6 : STD_LOGIC;
  signal N8 : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[0]_RD_PNTR[1]_XOR_92_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[10]_RD_PNTR[11]_XOR_82_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[11]_RD_PNTR[12]_XOR_81_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[12]_RD_PNTR[13]_XOR_80_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[1]_RD_PNTR[2]_XOR_91_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[2]_RD_PNTR[3]_XOR_90_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[3]_RD_PNTR[4]_XOR_89_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[4]_RD_PNTR[5]_XOR_88_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[5]_RD_PNTR[6]_XOR_87_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[6]_RD_PNTR[7]_XOR_86_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[7]_RD_PNTR[8]_XOR_85_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[8]_RD_PNTR[9]_XOR_84_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[9]_RD_PNTR[10]_XOR_83_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[0]_WR_PNTR[1]_XOR_13_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[10]_WR_PNTR[11]_XOR_3_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[1]_WR_PNTR[2]_XOR_12_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[2]_WR_PNTR[3]_XOR_11_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[3]_WR_PNTR[4]_XOR_10_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[4]_WR_PNTR[5]_XOR_9_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[5]_WR_PNTR[6]_XOR_8_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[6]_WR_PNTR[7]_XOR_7_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[7]_WR_PNTR[8]_XOR_6_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[8]_WR_PNTR[9]_XOR_5_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[9]_WR_PNTR[10]_XOR_4_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\ : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\ : STD_LOGIC_VECTOR ( 13 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\ : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\ : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\ : STD_LOGIC_VECTOR ( 13 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\ : STD_LOGIC_VECTOR ( 13 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\ : STD_LOGIC_VECTOR ( 13 downto 2 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_20_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_21_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_22_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_23_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_24_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_25_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_26_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_27_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_28_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_29_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\ : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_10_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_11_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_12_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_13_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_14_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_15_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_16_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_7_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_8_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_9_o\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/mmux_ram_rd_en_fwft11\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_17_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/next_fwft_state\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\ : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\ : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_15_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp1\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rd_pntr_plus1\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\ : STD_LOGIC_VECTOR ( 12 downto 0 );
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<0>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<10>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<11>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<12>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<1>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<2>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<3>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<4>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<5>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<6>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<7>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<8>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<9>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_xor<13>_rt\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\ : STD_LOGIC_VECTOR ( 13 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\ : STD_LOGIC_VECTOR ( 13 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\ : STD_LOGIC_VECTOR ( 13 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\ : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\ : STD_LOGIC_VECTOR ( 12 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi1\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi2\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi3\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi4\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi5\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\ : STD_LOGIC_VECTOR ( 12 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\ : STD_LOGIC_VECTOR ( 11 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>_bdd0\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>_bdd0\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_l1\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\ : STD_LOGIC_VECTOR ( 12 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\ : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\ : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_comp2_OR_21_o\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp2\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\ : STD_LOGIC_VECTOR ( 10 downto 0 );
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<10>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<2>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<3>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<4>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<5>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<6>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<7>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<8>_rt\ : STD_LOGIC;
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<9>_rt\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_xor<11>_rt\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\ : STD_LOGIC_VECTOR ( 11 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\ : STD_LOGIC_VECTOR ( 11 downto 2 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\ : STD_LOGIC_VECTOR ( 11 downto 1 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\ : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\ : STD_LOGIC_VECTOR ( 11 downto 2 );
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_regout_en\ : STD_LOGIC;
  signal \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\ : STD_LOGIC;
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_SBITERR_UNCONNECTED\ : STD_LOGIC;
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DOUTA_UNCONNECTED\ : STD_LOGIC_VECTOR ( 71 downto 0 );
  signal \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_RDADDRECC_UNCONNECTED\ : STD_LOGIC_VECTOR ( 13 downto 0 );
  attribute PK_HLUTNM : string;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[0]_RD_PNTR[1]_XOR_92_o_xo<0>1\ : label is "___XLNM___23___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_91_o_xo<0>1";
  attribute XSTLIB : boolean;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[0]_RD_PNTR[1]_XOR_92_o_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[10]_RD_PNTR[11]_XOR_82_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[11]_RD_PNTR[12]_XOR_81_o_xo<0>1\ : label is "___XLNM___21___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[12]_RD_PNTR[13]_XOR_80_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[11]_RD_PNTR[12]_XOR_81_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[12]_RD_PNTR[13]_XOR_80_o_xo<0>1\ : label is "___XLNM___21___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[12]_RD_PNTR[13]_XOR_80_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[12]_RD_PNTR[13]_XOR_80_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_91_o_xo<0>1\ : label is "___XLNM___23___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_91_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_91_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[2]_RD_PNTR[3]_XOR_90_o_xo<0>1\ : label is "___XLNM___24___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_89_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[2]_RD_PNTR[3]_XOR_90_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_89_o_xo<0>1\ : label is "___XLNM___24___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_89_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_89_o_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[4]_RD_PNTR[5]_XOR_88_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_87_o_xo<0>1\ : label is "___XLNM___25___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_86_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_87_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_86_o_xo<0>1\ : label is "___XLNM___25___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_86_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_86_o_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[7]_RD_PNTR[8]_XOR_85_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[8]_RD_PNTR[9]_XOR_84_o_xo<0>1\ : label is "___XLNM___26___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_83_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[8]_RD_PNTR[9]_XOR_84_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_83_o_xo<0>1\ : label is "___XLNM___26___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_83_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_83_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_13_o_xo<0>1\ : label is "___XLNM___22___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_13_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_13_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[10]_WR_PNTR[11]_XOR_3_o_xo<0>1\ : label is "___XLNM___27___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[10]_WR_PNTR[11]_XOR_3_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[10]_WR_PNTR[11]_XOR_3_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[1]_WR_PNTR[2]_XOR_12_o_xo<0>1\ : label is "___XLNM___22___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_13_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[1]_WR_PNTR[2]_XOR_12_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[2]_WR_PNTR[3]_XOR_11_o_xo<0>1\ : label is "___XLNM___28___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_10_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[2]_WR_PNTR[3]_XOR_11_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_10_o_xo<0>1\ : label is "___XLNM___28___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_10_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_10_o_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[4]_WR_PNTR[5]_XOR_9_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_8_o_xo<0>1\ : label is "___XLNM___29___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[6]_WR_PNTR[7]_XOR_7_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_8_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[6]_WR_PNTR[7]_XOR_7_o_xo<0>1\ : label is "___XLNM___29___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[6]_WR_PNTR[7]_XOR_7_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[6]_WR_PNTR[7]_XOR_7_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_6_o_xo<0>1\ : label is "___XLNM___30___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_6_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_6_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_5_o_xo<0>1\ : label is "___XLNM___30___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_6_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_5_o_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[9]_WR_PNTR[10]_XOR_4_o_xo<0>1\ : label is "___XLNM___27___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[10]_WR_PNTR[11]_XOR_3_o_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[9]_WR_PNTR[10]_XOR_4_o_xo<0>1\ : label is true;
  attribute ASYNC_REG : boolean;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_0\ : label is true;
  attribute MSGON : string;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_0\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_0\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_1\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_1\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_1\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_10\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_10\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_10\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_11\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_11\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_11\ : label is true;
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
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_11\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_11\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_11\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_12\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_12\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_12\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_13\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_13\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_13\ : label is true;
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
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_10\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_10\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_10\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_11\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_11\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_11\ : label is true;
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
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_11\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_11\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_11\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_12\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_12\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_12\ : label is true;
  attribute ASYNC_REG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_13\ : label is true;
  attribute MSGON of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_13\ : label is "TRUE";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_13\ : label is true;
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
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_12\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_13\ : label is true;
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
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_12\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_13\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_9\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o1\ : label is "___XLNM___20___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_20_o1\ : label is "___XLNM___20___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_20_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_211_xo<0>1\ : label is "___XLNM___8___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_211_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_211_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_221_xo<0>1\ : label is "___XLNM___8___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_211_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_221_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_231_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_241_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_241_xo<0>_SW0\ : label is "___XLNM___17___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_241_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_241_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_251_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_251_xo<0>_SW0\ : label is "___XLNM___17___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_241_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_251_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_261_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_261_xo<0>_SW0\ : label is "___XLNM___9___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_271_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_261_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_271_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_271_xo<0>_SW0\ : label is "___XLNM___9___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_271_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_271_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_281_xo<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_281_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_11\ : label is true;
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
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_101_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_111_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_111_xo<0>_SW0\ : label is "___XLNM___19___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_121_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_111_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_121_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_121_xo<0>_SW0\ : label is "___XLNM___19___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_121_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_121_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_131_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_131_xo<0>_SW0\ : label is "___XLNM___10___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_131_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_131_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_141_xo<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_141_xo<0>_SW0\ : label is "___XLNM___10___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_131_xo<0>_SW0";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_141_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_151_xo<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_151_xo<0>_SW0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>3\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o1\ : label is "___XLNM___18___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_7_o1\ : label is "___XLNM___18___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_7_o1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_81_xo<0>1\ : label is "___XLNM___11___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_91_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_81_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_91_xo<0>1\ : label is "___XLNM___11___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_91_xo<0>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_91_xo<0>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11\ : label is "___XLNM___6___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11_1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/RAM_REGOUT_EN1\ : label is "___XLNM___13___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/RAM_REGOUT_EN1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/RAM_REGOUT_EN1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In1\ : label is "___XLNM___6___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd1-In1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_FSM_FFd2-In1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_17_o1\ : label is "___XLNM___13___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/RAM_REGOUT_EN1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_17_o1\ : label is true;
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
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[6].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[6].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<4>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<5>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<6>1\ : label is true;
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
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[6].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[6].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<4>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<5>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<6>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_15_o1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<0>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<10>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<10>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<11>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<11>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<12>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<12>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<1>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<1>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<2>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<3>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<4>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<5>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<5>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<6>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<6>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<7>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<7>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<8>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<8>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<9>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<9>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<10>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<11>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<12>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<13>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<13>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<1>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<5>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<6>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<7>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<8>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<9>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_12\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_13\ : label is true;
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
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_12\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_13\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<10>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<11>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<1>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<5>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<6>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<7>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<8>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<9>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<10>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<11>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<12>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<1>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<5>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<6>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<7>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<8>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<9>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<10>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<11>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<12>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<1>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<5>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<6>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<7>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<8>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<9>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<1>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<5>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<0>\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___0___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<0>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<1>\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___1___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<1>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<2>\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___2___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi2";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<2>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<3>\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___3___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi3";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<3>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<4>\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___4___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi4";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<4>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<5>\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___5___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi5";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<5>\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___0___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi1\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___1___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi2\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___2___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi2";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi2\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi3\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___3___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi3";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi3\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi4\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___4___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi4";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi4\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi5\ : label is "U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/___XLNM___5___Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi5";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi5\ : label is true;
  attribute XILINX_LEGACY_PRIM : string;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Msub_gpf3.gpf3a.prog_full_thresh_sub_extra_words_xor<1>11_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Msub_gpf3.gpf3a.prog_full_thresh_sub_extra_words_xor<1>11_INV_0\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Msub_gpf3.gpf3a.prog_full_thresh_sub_extra_words_xor<2>11\ : label is "___XLNM___16___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<3>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Msub_gpf3.gpf3a.prog_full_thresh_sub_extra_words_xor<2>11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_12\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>1_SW0\ : label is "___XLNM___14___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>1_SW0\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>2\ : label is "___XLNM___15___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>2";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>2\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<11>1\ : label is "___XLNM___15___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>2";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<11>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<3>1\ : label is "___XLNM___16___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<3>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<3>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<4>1\ : label is "___XLNM___7___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<4>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<4>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>11\ : label is "___XLNM___14___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>11";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>11\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>2\ : label is "___XLNM___7___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<4>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<6>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<7>1\ : label is "___XLNM___12___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<7>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<7>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<8>1\ : label is "___XLNM___12___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<7>1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<8>1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<9>1\ : label is "___XLNM___31___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1_1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<9>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_cy\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_cy1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut1\ : label is true;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut_INV_0\ : label is true;
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
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[5].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[5].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<4>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<5>1\ : label is true;
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
  attribute OPTIMIZE_PRIMITIVES_NGC of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[5].gms.ms\ : label is "no";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[5].gms.ms\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<0>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<1>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<2>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<3>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<4>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<5>1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_comp2_OR_21_o1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1\ : label is true;
  attribute PK_HLUTNM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1_1\ : label is "___XLNM___31___U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1_1";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<0>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<10>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<10>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<1>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<2>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<3>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<4>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<5>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<5>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<6>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<6>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<7>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<7>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<8>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<8>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<9>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<9>_rt\ : label is true;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut<0>_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut<0>_INV_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<10>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<11>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<11>_rt\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<2>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<3>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<4>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<5>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<6>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<7>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<8>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<9>\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_0\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_1\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_9\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_10\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_11\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_2\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_3\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_4\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_5\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_6\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_7\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_8\ : label is true;
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_9\ : label is true;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<1>_inv1_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<1>_inv1_INV_0\ : label is true;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv1_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv1_INV_0\ : label is true;
  attribute BMM_INFO_ADDRESS_RANGE : string;
  attribute BMM_INFO_ADDRESS_RANGE of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is "/*_*_RANGE *";
  attribute BUS_INFO of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is "14:OUTPUT:RDADDRECC<13:0>";
  attribute NLW_MACRO_ALIAS of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is "blk_mem_gen_generic_cstr_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr";
  attribute NLW_MACRO_TAG of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is 1;
  attribute NLW_UNIQUE_ID of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\ : label is 0;
  attribute XILINX_LEGACY_PRIM of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rd_pntr<0>_inv1_INV_0\ : label is "INV";
  attribute XSTLIB of \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/rd_pntr<0>_inv1_INV_0\ : label is true;
  attribute XSTLIB of XST_GND : label is true;
  attribute XSTLIB of XST_VCC : label is true;
begin
  empty <= \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\;
  full <= \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\;
  prog_full <= \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i\;
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[0]_RD_PNTR[1]_XOR_92_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[0]_RD_PNTR[1]_XOR_92_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[10]_RD_PNTR[11]_XOR_82_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(11),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[10]_RD_PNTR[11]_XOR_82_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[11]_RD_PNTR[12]_XOR_81_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(12),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[11]_RD_PNTR[12]_XOR_81_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[12]_RD_PNTR[13]_XOR_80_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(13),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[12]_RD_PNTR[13]_XOR_80_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[1]_RD_PNTR[2]_XOR_91_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[1]_RD_PNTR[2]_XOR_91_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[2]_RD_PNTR[3]_XOR_90_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[2]_RD_PNTR[3]_XOR_90_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[3]_RD_PNTR[4]_XOR_89_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[3]_RD_PNTR[4]_XOR_89_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[4]_RD_PNTR[5]_XOR_88_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[4]_RD_PNTR[5]_XOR_88_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[5]_RD_PNTR[6]_XOR_87_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[5]_RD_PNTR[6]_XOR_87_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[6]_RD_PNTR[7]_XOR_86_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[6]_RD_PNTR[7]_XOR_86_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[7]_RD_PNTR[8]_XOR_85_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[7]_RD_PNTR[8]_XOR_85_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[8]_RD_PNTR[9]_XOR_84_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[8]_RD_PNTR[9]_XOR_84_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_RD_PNTR[9]_RD_PNTR[10]_XOR_83_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[9]_RD_PNTR[10]_XOR_83_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[0]_WR_PNTR[1]_XOR_13_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[0]_WR_PNTR[1]_XOR_13_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[10]_WR_PNTR[11]_XOR_3_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(11),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[10]_WR_PNTR[11]_XOR_3_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[1]_WR_PNTR[2]_XOR_12_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[1]_WR_PNTR[2]_XOR_12_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[2]_WR_PNTR[3]_XOR_11_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[2]_WR_PNTR[3]_XOR_11_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[3]_WR_PNTR[4]_XOR_10_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[3]_WR_PNTR[4]_XOR_10_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[4]_WR_PNTR[5]_XOR_9_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[4]_WR_PNTR[5]_XOR_9_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[5]_WR_PNTR[6]_XOR_8_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[5]_WR_PNTR[6]_XOR_8_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[6]_WR_PNTR[7]_XOR_7_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[6]_WR_PNTR[7]_XOR_7_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[7]_WR_PNTR[8]_XOR_6_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[7]_WR_PNTR[8]_XOR_6_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[8]_WR_PNTR[9]_XOR_5_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[8]_WR_PNTR[9]_XOR_5_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/Mxor_WR_PNTR[9]_WR_PNTR[10]_XOR_4_o_xo<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[9]_WR_PNTR[10]_XOR_4_o\
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/Q_reg_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(11)
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_12\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(12),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/Q_reg_13\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(13),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(13)
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/D\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11)
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_12\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(12),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg_13\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/D\(13),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13)
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_21_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_20_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_12\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_13\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(13)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_29_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_28_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_27_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_26_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_25_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_24_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_23_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_22_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[0]_RD_PNTR[1]_XOR_92_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[1]_RD_PNTR[2]_XOR_91_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[10]_RD_PNTR[11]_XOR_82_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[11]_RD_PNTR[12]_XOR_81_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_12\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[12]_RD_PNTR[13]_XOR_80_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_13\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(13),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(13)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[2]_RD_PNTR[3]_XOR_90_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[3]_RD_PNTR[4]_XOR_89_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[4]_RD_PNTR[5]_XOR_88_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[5]_RD_PNTR[6]_XOR_87_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[6]_RD_PNTR[7]_XOR_86_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[7]_RD_PNTR[8]_XOR_85_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[8]_RD_PNTR[9]_XOR_84_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/RD_PNTR[9]_RD_PNTR[10]_XOR_83_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].wr_stg_inst/D\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_19_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_20_o1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_20_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_211_xo<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_21_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_221_xo<0>1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"96696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_22_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_231_xo<0>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_23_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_241_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I5 => N2,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_24_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_241_xo<0>_SW0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      O => N2
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_251_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I5 => N6,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_25_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_251_xo<0>_SW0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"69"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      O => N6
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_261_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I5 => N8,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_26_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_261_xo<0>_SW0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      O => N8
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_271_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I5 => N4,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_27_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_271_xo<0>_SW0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"69969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      O => N4
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_281_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I5 => N10,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_28_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_281_xo<0>_SW0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      O => N10
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(13),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(11),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(2),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(5),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(8),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].wr_stg_inst/Q_reg\(9),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo\(0),
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_291_xo<0>1\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_gc_asreg_last[13]_reduce_xor_29_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_16_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_15_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_14_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_13_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_12_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_11_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_10_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_9_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_8_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_7_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_0\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[0]_WR_PNTR[1]_XOR_13_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[1]_WR_PNTR[2]_XOR_12_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[10]_WR_PNTR[11]_XOR_3_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[2]_WR_PNTR[3]_XOR_11_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[3]_WR_PNTR[4]_XOR_10_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[4]_WR_PNTR[5]_XOR_9_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[5]_WR_PNTR[6]_XOR_8_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[6]_WR_PNTR[7]_XOR_7_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[7]_WR_PNTR[8]_XOR_6_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[8]_WR_PNTR[9]_XOR_5_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/WR_PNTR[9]_WR_PNTR[10]_XOR_4_o\,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[1].rd_stg_inst/D\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_101_xo<0>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_10_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_111_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I5 => N14,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_11_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_111_xo<0>_SW0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      O => N14
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_121_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I5 => N12,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_12_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_121_xo<0>_SW0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"69"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      O => N12
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_131_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I5 => N18,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_13_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_131_xo<0>_SW0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      O => N18
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_141_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9669699669969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I5 => N20,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_14_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_141_xo<0>_SW0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"69969669"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(2),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      O => N20
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_151_xo<0>\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I5 => N16,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_15_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_151_xo<0>_SW0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      O => N16
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(0),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(2),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"6996966996696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(5),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo\(0),
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_161_xo<0>1\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_16_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_6_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_7_o1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_7_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_81_xo<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_8_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_91_xo<0>1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"96696996"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(8),
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/gsync_stage[2].rd_stg_inst/Q_reg\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_gc_asreg_last[11]_reduce_xor_9_o\
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/Mmux_RAM_RD_EN_FWFT11_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2333"
    )
    port map (
      I0 => rd_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I3 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/mmux_ram_rd_en_fwft11\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/RAM_REGOUT_EN1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"A2"
    )
    port map (
      I0 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I2 => rd_en,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_regout_en\
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_17_o\,
      PRE => rd_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_17_o\,
      PRE => rd_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_17_o1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8E8A"
    )
    port map (
      I0 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/empty_fwft_fb\,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I3 => rd_en,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/going_empty_fwft_leaving_empty_fwft_OR_17_o\
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
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(5),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.gm[6].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/gmux.carrynet\(5),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<5>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(11),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1<6>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8421"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(12),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(13),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c0/v1\(6)
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
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(5),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.gm[6].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/gmux.carrynet\(5),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp1\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<0>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"4"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<5>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1<6>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(13),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(12),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/wr_pntr_bin\(10),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/c1/v1\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_15_o1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFF23330000"
    )
    port map (
      I0 => rd_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\,
      I2 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd1\,
      I3 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/curr_fwft_state_fsm_ffd2\,
      I4 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp1\,
      I5 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_15_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\: unisim.vcomponents.FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/comp0_comp1_OR_15_o\,
      PRE => rd_rst,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gras.rsts/ram_empty_fb_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<0>\: unisim.vcomponents.MUXCY
    port map (
      CI => N1,
      DI => N0,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(0),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<0>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<0>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(0),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<0>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<10>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(9),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(10),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<10>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<10>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(10),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<10>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<11>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(10),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(11),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<11>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<11>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(11),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<11>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<12>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(11),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(12),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<12>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<12>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(12),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<12>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<1>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(0),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(1),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<1>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<1>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(1),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<1>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<2>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(1),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(2),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<2>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<2>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(2),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<2>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<3>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(2),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(3),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<3>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<3>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(3),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<3>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<4>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(3),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(4),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<4>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<4>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(4),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<4>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<5>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(4),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(5),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<5>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<5>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(5),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<5>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<6>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(5),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(6),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<6>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<6>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(6),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<6>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<7>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(6),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(7),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<7>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<7>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(7),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<7>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<8>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(7),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(8),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<8>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<8>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(8),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<8>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<9>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(8),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(9),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<9>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy<9>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(9),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<9>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<10>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(9),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<10>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<11>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(10),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<11>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<12>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(11),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<12>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<13>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(12),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_xor<13>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(13)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<13>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(13),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_xor<13>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<1>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(0),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<1>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<2>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(1),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<2>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<3>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(2),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<3>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<4>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(3),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<4>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<5>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(4),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<5>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<6>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(5),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<6>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<7>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(6),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<7>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<8>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(7),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<8>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_xor<9>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/Madd_gc0.count[13]_GND_693_o_add_0_OUT_cy\(8),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/madd_gc0.count[13]_gnd_693_o_add_0_out_cy<9>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_1\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(1),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_11\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_12\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(12),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_13\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(13),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(13)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(2),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(3),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(4),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(5),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(6),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(7),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(8),
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
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count[13]_GND_693_o_add_0_OUT\(9),
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_11\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_12\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(12),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1_13\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/tmp_ram_rd_en\,
      CLR => rd_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count\(13),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(13)
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<0>\: unisim.vcomponents.MUXCY
    port map (
      CI => N1,
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(0),
      S => N1
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<10>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(9),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(10),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<11>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(10),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(10),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(11),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<1>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(0),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(1),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<2>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(1),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(2),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<3>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(2),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(3),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<4>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(3),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(4),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<5>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(4),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(5),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<6>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(5),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(6),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<7>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(6),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(7),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<8>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(7),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(8),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy<9>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(8),
      DI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(9),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<10>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(11),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<11>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(12),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<12>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(13),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<1>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<2>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(1),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<3>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<4>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<5>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<6>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<7>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<8>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut<9>\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(10),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<10>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(9),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(10),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<11>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(10),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(11),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<12>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(11),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(12),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<1>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(0),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<2>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(1),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<3>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(2),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(3),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<4>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(3),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<5>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(4),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(5),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<6>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(5),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<7>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(6),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(7),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<8>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(7),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_xor<9>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_cy\(8),
      LI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Madd_wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT_lut\(9),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<0>\: unisim.vcomponents.MUXCY
    port map (
      CI => N0,
      DI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(0),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<1>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(0),
      DI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi1\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(1),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<2>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(1),
      DI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi2\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(2),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<3>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(2),
      DI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi3\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(3),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<4>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(3),
      DI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi4\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(4),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy<5>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_cy\(4),
      DI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi5\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<0>\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => prog_full_thresh(0),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(1),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<1>\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(3),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<2>\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(5),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<3>\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<4>\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(9),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(10),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut<5>\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(11),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(12),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lut\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"08AE"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(2),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(1),
      I2 => prog_full_thresh(0),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(1),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"08AE"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(4),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(3),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"08AE"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(6),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(5),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi2\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"08AE"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(8),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(7),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi3\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi4\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"08AE"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(10),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(9),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi4\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_lutdi5\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"08AE"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(12),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(11),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/mcompar_gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_lessthan_8_o_lutdi5\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Msub_gpf3.gpf3a.prog_full_thresh_sub_extra_words_xor<1>11_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => prog_full_thresh(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/Msub_gpf3.gpf3a.prog_full_thresh_sub_extra_words_xor<2>11\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
    port map (
      I0 => prog_full_thresh(2),
      I1 => prog_full_thresh(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_1\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_10\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_11\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_12\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(12),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(12)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_2\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_3\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_4\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_5\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_6\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_7\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_8\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad_9\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/wr_pntr_plus1_pad[12]_adjusted_rd_pntr_wr_inv_pad[12]_add_3_OUT\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/diff_pntr_pad\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000001"
    )
    port map (
      I0 => prog_full_thresh(8),
      I1 => prog_full_thresh(7),
      I2 => prog_full_thresh(6),
      I3 => prog_full_thresh(5),
      I4 => prog_full_thresh(4),
      I5 => N01,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>_bdd0\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>1_SW0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"FE"
    )
    port map (
      I0 => prog_full_thresh(3),
      I1 => prog_full_thresh(2),
      I2 => prog_full_thresh(1),
      O => N01
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"9C"
    )
    port map (
      I0 => prog_full_thresh(9),
      I1 => prog_full_thresh(10),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>_bdd0\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<11>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"C9CC"
    )
    port map (
      I0 => prog_full_thresh(9),
      I1 => prog_full_thresh(11),
      I2 => prog_full_thresh(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>_bdd0\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<3>1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"A9"
    )
    port map (
      I0 => prog_full_thresh(3),
      I1 => prog_full_thresh(1),
      I2 => prog_full_thresh(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"CCC9"
    )
    port map (
      I0 => prog_full_thresh(3),
      I1 => prog_full_thresh(4),
      I2 => prog_full_thresh(1),
      I3 => prog_full_thresh(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>11\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0001"
    )
    port map (
      I0 => prog_full_thresh(1),
      I1 => prog_full_thresh(2),
      I2 => prog_full_thresh(3),
      I3 => prog_full_thresh(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>_bdd0\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAAAAA9"
    )
    port map (
      I0 => prog_full_thresh(5),
      I1 => prog_full_thresh(1),
      I2 => prog_full_thresh(2),
      I3 => prog_full_thresh(3),
      I4 => prog_full_thresh(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<6>1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCCCCCCCCCCCCCC9"
    )
    port map (
      I0 => prog_full_thresh(5),
      I1 => prog_full_thresh(6),
      I2 => prog_full_thresh(1),
      I3 => prog_full_thresh(2),
      I4 => prog_full_thresh(3),
      I5 => prog_full_thresh(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<7>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"C9CC"
    )
    port map (
      I0 => prog_full_thresh(5),
      I1 => prog_full_thresh(7),
      I2 => prog_full_thresh(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>_bdd0\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<8>1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAAA9AA"
    )
    port map (
      I0 => prog_full_thresh(8),
      I1 => prog_full_thresh(5),
      I2 => prog_full_thresh(7),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<5>_bdd0\,
      I4 => prog_full_thresh(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<9>1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => prog_full_thresh(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words<10>_bdd0\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot\,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_cy\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o\,
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_l1\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_cy1\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/gpf3.gpf3a.prog_full_thresh_sub_extra_words[11]_diff_pntr[11]_LessThan_8_o_l1\,
      DI => N0,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot\,
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"7"
    )
    port map (
      I0 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i\,
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.gpf.wrpf/prog_full_i_rstpot_lut\
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
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(4),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.gm[5].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/gmux.carrynet\(4),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1<5>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(13),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(12),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(10),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c1/v1\(5)
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
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(4),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.gm[5].gms.ms\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/gmux.carrynet\(4),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp2\,
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<0>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0990"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(3),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(1),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(2),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<1>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(5),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(3),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(4),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(2),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<2>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(7),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(5),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(6),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(4),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<3>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(9),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(7),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(8),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(6),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<4>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(11),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(9),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(10),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(8),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1<5>1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(13),
      I1 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(11),
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gcx.clkx/rd_pntr_bin\(12),
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(10),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/c2/v1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_comp2_OR_21_o1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FF20"
    )
    port map (
      I0 => wr_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\,
      I2 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp2\,
      I3 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_comp2_OR_21_o\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_comp2_OR_21_o\,
      Q => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i\: unisim.vcomponents.FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/comp1_comp2_OR_21_o\,
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
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => wr_en,
      I1 => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_fb_i\,
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<0>\: unisim.vcomponents.MUXCY
    port map (
      CI => N1,
      DI => N0,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(0),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<10>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(9),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(10),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<10>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<10>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(10),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<10>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<1>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(0),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(1),
      S => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<2>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(1),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(2),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<2>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<2>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(2),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<2>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<3>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(2),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(3),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<3>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<3>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(3),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<3>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<4>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(3),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(4),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<4>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<4>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(4),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<4>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<5>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(4),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(5),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<5>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<5>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(5),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<5>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<6>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(5),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(6),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<6>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<6>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(6),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<6>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<7>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(6),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(7),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<7>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<7>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(7),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<7>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<8>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(7),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(8),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<8>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<8>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(8),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<8>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<9>\: unisim.vcomponents.MUXCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(8),
      DI => N1,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(9),
      S => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<9>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy<9>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(9),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<9>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut<0>_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(0),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<10>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(9),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<10>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<11>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(10),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_xor<11>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<11>_rt\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(11),
      O => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_xor<11>_rt\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<2>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(1),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<2>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<3>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(2),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<3>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<4>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(3),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<4>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<5>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(4),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<5>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<6>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(5),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<6>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<7>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(6),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<7>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<8>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(7),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<8>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_xor<9>\: unisim.vcomponents.XORCY
    port map (
      CI => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_cy\(8),
      LI => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/madd_gic0.gc1.count[11]_gnd_708_o_add_0_out_cy<9>_rt\,
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_10\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_11\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count[11]_GND_708_o_add_0_OUT\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_1\: unisim.vcomponents.FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(1),
      PRE => wr_rst,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_10\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_11\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_0\: unisim.vcomponents.FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut\(0),
      PRE => wr_rst,
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(0)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_1\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(1),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_10\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_11\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_10\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(10),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(10)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_11\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(11),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(11)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_2\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(2),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(2)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_3\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(3),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(3)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_4\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(4),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(4)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_5\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(5),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(5)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_6\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(6),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(6)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_7\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(7),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(7)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_8\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(8),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(8)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3_9\: unisim.vcomponents.FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      CLR => wr_rst,
      D => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(9),
      Q => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(9)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus1<1>_inv1_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d2\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count\(1)
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv1_INV_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d1\(1),
      O => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv\
    );
\U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr\: entity work.eventBuffer_blk_mem_gen_generic_cstr
    port map (
      ADDRA(11 downto 2) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/gic0.gc1.count_d3\(11 downto 2),
      ADDRA(1) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wr_pntr_plus2<1>_inv\,
      ADDRA(0) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/wpntr/Madd_gic0.gc1.count[11]_GND_708_o_add_0_OUT_lut\(0),
      ADDRB(13 downto 0) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/rpntr/gc0.count_d1\(13 downto 0),
      CLKA => wr_clk,
      CLKB => rd_clk,
      DBITERR => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DBITERR_UNCONNECTED\,
      DINA(71 downto 54) => din(17 downto 0),
      DINA(53 downto 36) => din(35 downto 18),
      DINA(35 downto 18) => din(53 downto 36),
      DINA(17 downto 0) => din(71 downto 54),
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
      DOUTA(71 downto 0) => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_DOUTA_UNCONNECTED\(71 downto 0),
      DOUTB(17 downto 0) => dout(17 downto 0),
      ENA => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/ram_wr_en_i1\,
      ENB => \^u0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.rd/gr1.rfwft/mmux_ram_rd_en_fwft11\,
      INJECTDBITERR => N1,
      INJECTSBITERR => N1,
      RDADDRECC(13 downto 0) => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_RDADDRECC_UNCONNECTED\(13 downto 0),
      REGCEA(0) => N0,
      REGCEB(0) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_regout_en\,
      RSTA(0) => N1,
      RSTB(1) => N1,
      RSTB(0) => N1,
      SBITERR => \NLW_U0/xst_fifo_generator/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgb.ngecc.bmg/gnativebmg.native_blk_mem_gen/valid.cstr_SBITERR_UNCONNECTED\,
      WEA(7) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      WEA(6) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      WEA(5) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
      WEA(4) => \U0/xst_fifo_generator/gconvfifo.rf/grf.rf/ram_wr_en\,
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
XST_GND: unisim.vcomponents.GND
    port map (
      G => N1
    );
XST_VCC: unisim.vcomponents.VCC
    port map (
      P => N0
    );
end STRUCTURE;
