--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Dec 2015
--
-- Design Name: TES_digitiser
-- Module Name: simple_fifo
-- Project Name: teslib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library teslib;
use teslib.types.all;

entity simple_fifo is
generic (
	DATA_WIDTH:integer:=8;
	DEPTH:integer:=32
);
port (
  clk:in std_logic;
  reset:in std_logic;
  din:in std_logic_vector(DATA_WIDTH-1 downto 0);
  din_valid:in boolean;
  din_ready:out boolean;
  dout:out std_logic_vector(DATA_WIDTH-1 downto 0);
  dout_valid:out boolean;
  dout_ready:in boolean
);
end entity simple_fifo;
-- for shallow FIFOs
architecture distributed of simple_fifo is
	
attribute ram_extract:string;
attribute ram_style:string;
subtype data is std_logic_vector(DATA_WIDTH-1 downto 0);
type storage is array (natural range <>) of data;
signal ram:storage(0 to DEPTH-1);
attribute ram_extract of ram:signal is "YES";
attribute ram_style of ram:signal is "pipe_distributed";
signal ram_dout,ram_dout_reg,ram_dout_reg2,dout_reg:data;
signal wr_addr,rd_addr:unsigned(DEPTH-1 downto 0);
signal empty,full,rd_en,wr_en:boolean;

begin
full <= wr_addr = rd_addr-1;
empty <= rd_addr = wr_addr;
	
addr:process (clk) is
begin
if rising_edge(clk) then
  if reset = '1' then
    wr_addr <= (others => '0');
    rd_addr <= (others => '0');
  else
		if wr_en then
			ram(wr_addr) <= din;
		end if;
		if rd_en then
			ram_dout <= ram(rd_en);
		end if;
		ram_dout_reg <= ram_dout;
		ram_dout_reg2 <= ram_dout_reg;
  end if;
end if;
end process addr;


end architecture distributed;
