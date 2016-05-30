--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:26 May 2016
--
-- Design Name: TES_digitiser
-- Module Name: axi_lite_adapter
-- Project Name: teslib
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity axi_lite_slave is
port(
  clk:in std_logic;
  resetn:in std_logic;
 	
 	-- CPU interface 
  address:in AXI_address_t;
  data:in AXI_data_t;
  -- these need to be strobes
  write:in boolean;
  read:in boolean;

  value:out AXI_data_t;
  resp:out std_logic_vector(1 downto 0);
  resp_valid: out boolean;
  
  -- AXI Lite slave interface
  awaddr:out AXI_address_t;
  awvalid:out std_logic;
  awready:in std_logic;

  wdata:out AXI_data_t;
  wvalid:out std_logic;
  wready:in std_logic;

  bresp:in std_logic_vector(1 downto 0);
  bvalid:in std_logic;
  bready:out std_logic;

  araddr:out AXI_address_t;
  arvalid:out std_logic;
  arready:in std_logic;

  rdata:in AXI_data_t;
  rresp:in std_logic_vector(1 downto 0);
  rvalid:in std_logic;
  rready:out std_logic
);
end entity axi_lite_slave;

architecture RTL of axi_lite_slave is

type FSMstate is (READING,WRITING);
signal state,nextstate:FSMstate;
signal bresp_int:std_logic_vector(1 downto 0);
signal rresp_int:std_logic_vector(AXI_DATA_BITS+2-1 downto 0);
signal bresp_valid:boolean;
signal rresp_valid:boolean;

begin

value <= rresp_int(AXI_DATA_BITS+2-1 downto 2);
resp <= rresp_int(1 downto 0) when state=READING else bresp;
resp_valid <= rresp_valid when state=READING else bresp_valid; 

awchan:entity work.axi_wr_chan
generic map(WIDTH => AXI_ADDRESS_BITS)
port map(
  clk => clk,
  resetn => resetn,
  reg_value => address,
  go => write,
  done => open,
  axi_data => awaddr,
  axi_valid => awvalid,
  axi_ready => awready
);	

wchan:entity work.axi_wr_chan
generic map(WIDTH => AXI_DATA_BITS)
port map(
  clk => clk,
  resetn => resetn,
  reg_value => data,
  go => write,
  done => open,
  axi_data => wdata,
  axi_valid => wvalid,
  axi_ready => wready
);	

bchan:entity work.axi_rd_chan
generic map(WIDTH => 2)
port map(
  clk => clk,
  resetn => resetn,
  value => bresp_int,
  go => write,
  value_valid => bresp_valid,
  axi_data => bresp,
  axi_valid => bvalid,
  axi_ready => bready
);

archan:entity work.axi_wr_chan
generic map(WIDTH => AXI_ADDRESS_BITS)
port map(
  clk => clk,
  resetn => resetn,
  reg_value => address,
  go => read,
  done => open,
  axi_data => araddr,
  axi_valid => arvalid,
  axi_ready => arready
);	

rchan:entity work.axi_rd_chan
generic map(WIDTH => AXI_DATA_BITS+2)
port map(
  clk => clk,
  resetn => resetn,
  value => rresp_int,
  go => read,
  value_valid => rresp_valid,
  axi_data => rdata & rresp,
  axi_valid => rvalid,
  axi_ready => rready
);

FSMnextstate:process (clk) is
begin
	if rising_edge(clk) then
		if resetn = '0' then
			state <= READING;
		else
			state <= nextstate;
		end if;
	end if;
end process FSMnextstate;


FSMtransition:process(state,read,write)
begin
	case state is 
	when READING =>
		if write then
			nextstate <= WRITING;
		end if;
	when WRITING =>
		if read then
			nextstate <= READING; 
		end if;
	end case;
end process FSMtransition;


end architecture RTL;
