--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:11 Mar. 2018
--
-- Design Name: TES_digitiser
-- Module Name: framer_queue
-- Project Name: teslib 
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.types.all;


entity framer_queue is
generic(
  BUS_CHUNKS:natural:=BUS_CHUNKS;
  ADDRESS_BITS:natural:= 10
--  QUEUE_ADDRESS_BITS:natural:=9
);
port(
  clk:in std_logic;
  reset:in std_logic;
  
  -- 3 simultaneous inputs
  data0:in streambus_t;
  we0:in boolean_vector(BUS_CHUNKS-1 downto 0);
  address0:in unsigned(ADDRESS_BITS-1 downto 0);
  commit0:in boolean;
  length0:in unsigned(ADDRESS_BITS downto 0);
  
  data1:in streambus_t;
  we1:in boolean_vector(BUS_CHUNKS-1 downto 0);
  address1:in unsigned(ADDRESS_BITS-1 downto 0);
  commit1:in boolean;
  length1:in unsigned(ADDRESS_BITS downto 0);
  
  data2:in streambus_t;
  we2:in boolean_vector(BUS_CHUNKS-1 downto 0);
  address2:in unsigned(ADDRESS_BITS-1 downto 0);
  commit2:in boolean;
  length2:in unsigned(ADDRESS_BITS downto 0);
  
  --outputs
  --free including queued writes
  free:out unsigned(ADDRESS_BITS downto 0);
  ready1:out boolean;
  ready2:out boolean;
  
  --inputs from framer
  framer_free:in unsigned(ADDRESS_BITS downto 0);
  
  --outputs to framer
  data:out streambus_t;
  we:out boolean_vector(BUS_CHUNKS-1 downto 0);
  length:out unsigned(ADDRESS_BITS downto 0);
  commit:out boolean
  
);
end entity framer_queue;

architecture RTL of framer_queue is
--------------------------------------------------------------------------------
-- Xilinx IP
--------------------------------------------------------------------------------
component framer_fifo
port (
  clk:in std_logic;
  srst:in std_logic;
  din:in std_logic_vector(143 downto 0);
  wr_en:in std_logic;
  rd_en:in std_logic;
  dout:out std_logic_vector(143 downto 0);
  full:out std_logic;
  almost_full:out std_logic;
  empty:out std_logic;
  almost_empty:out std_logic
 
);
end component;

constant Q_BITS:natural:=
--commit|    length    |    we    |  address   |       data      
       1+ADDRESS_BITS+1+BUS_CHUNKS+ADDRESS_BITS+BUS_CHUNKS*CHUNK_BITS;
constant DATA_BIT:natural:=BUS_CHUNKS*CHUNK_BITS;
constant ADDRESS_BIT:natural:=ADDRESS_BITS+BUS_CHUNKS*CHUNK_BITS;
constant WE_BIT:natural:=BUS_CHUNKS+ADDRESS_BITS+BUS_CHUNKS*CHUNK_BITS;
constant LENGTH_BIT:natural:=
         ADDRESS_BITS+1+BUS_CHUNKS+ADDRESS_BITS+BUS_CHUNKS*CHUNK_BITS;

--------------------------------------------------------------------------------
-- Queue signals
--------------------------------------------------------------------------------
-- FIFO
signal q_din,q_0,q_1,q_2:std_logic_vector(143 downto 0);
signal q_wr_en:std_logic;
signal q_rd_en:std_logic;
signal q_dout:std_logic_vector(143 downto 0);
signal q_full:std_logic;
signal q_almost_full:std_logic;
signal q_empty:std_logic;
signal q_almost_empty:std_logic;

--number of words in queue
signal queued,queued_p,queued_m:signed(ADDRESS_BITS+1 downto 0);
-- framer free adjusted for words queued
signal free_int:signed(ADDRESS_BITS+1 downto 0);

--strorage registers
signal reg1,reg2:std_logic_vector(143 downto 0);
signal reg1_we,reg2_we:boolean;
--------------------------------------------------------------------------------
signal data_int:streambus_t;
signal we_int:boolean_vector(BUS_CHUNKS-1 downto 0);
signal length_int:unsigned(ADDRESS_BITS downto 0);
signal address_int:unsigned(ADDRESS_BITS-1 downto 0);
signal commit_int:boolean;
signal ready1_int,ready2_int:boolean;
  
begin
free <= unsigned(free_int(ADDRESS_BITS downto 0));
data <= data_int;
we <= we_int;
commit <= commit_int;
length <= length_int;
ready1 <= ready1_int;
ready2 <= ready2_int;

queueCount:process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      queued <= (others => '0');
      queued_p <= (0 => '1', others => '0');
      queued_m <= to_signed(-1,ADDRESS_BITS+2);
      free_int <= (ADDRESS_BITS => '1', others => '0');
    else
      if q_almost_full='1' then
        free_int <= (others => '0');
      else
        if to_boolean(q_rd_en) xor to_boolean(q_wr_en) then
          if q_rd_en='1' then
            free_int <= signed('0' & framer_free)-queued_m;
            queued <= queued_m;
            queued_m <= queued_m-1;
            queued_p <= queued_p-1;
          else
            free_int <= signed('0' & framer_free)-queued_p;
            queued <= queued_p;
            queued_m <= queued_m+1;
            queued_p <= queued_p+1;
          end if;
        else
          free_int <= signed('0' & framer_free)-queued;
        end if;
      end if;
    end if;
  end if;
end process queueCount;

--din commit(1):length(ADDRESS_BITS+1):we(BUS_CHUNKS):address(ADDRESS_BITS)+data(72)
q_0(143 downto Q_BITS) <= (others => '-');
q_0(Q_BITS-1) <= to_std_logic(commit0);
q_0(LENGTH_BIT-1 downto LENGTH_BIT-ADDRESS_BITS-1) <= to_std_logic(length0);
q_0(WE_BIT-1 downto WE_BIT-BUS_CHUNKS) <= to_std_logic(we0);
q_0(ADDRESS_BIT-1 downto ADDRESS_BIT-ADDRESS_BITS) <= to_std_logic(address0);
q_0(DATA_BIT-1 downto 0) <= to_std_logic(data0);
q_1(143 downto Q_BITS) <= (others => '-');
q_1(Q_BITS-1) <= to_std_logic(commit1);
q_1(LENGTH_BIT-1 downto LENGTH_BIT-ADDRESS_BITS-1) <= to_std_logic(length1);
q_1(WE_BIT-1 downto WE_BIT-BUS_CHUNKS) <= to_std_logic(we1);
q_1(ADDRESS_BIT-1 downto ADDRESS_BIT-ADDRESS_BITS) <= to_std_logic(address1);
q_1(DATA_BIT-1 downto 0) <= to_std_logic(data1);
q_2(143 downto Q_BITS) <= (others => '-');
q_2(Q_BITS-1) <= to_std_logic(commit2);
q_2(LENGTH_BIT-1 downto LENGTH_BIT-ADDRESS_BITS-1) <= to_std_logic(length2);
q_2(WE_BIT-1 downto WE_BIT-BUS_CHUNKS) <= to_std_logic(we2);
q_2(ADDRESS_BIT-1 downto ADDRESS_BIT-ADDRESS_BITS) <= to_std_logic(address2);
q_2(DATA_BIT-1 downto 0) <= to_std_logic(data2);
reg1_we <= unaryOR(reg1(WE_BIT-1 downto WE_BIT-BUS_CHUNKS));
reg2_we <= unaryOR(reg2(WE_BIT-1 downto WE_BIT-BUS_CHUNKS));
queueing:process (clk) is
begin
  if rising_edge(clk) then
    if reset='1' then
      q_wr_en <= '0';
      ready1_int <= TRUE;
      ready2_int <= TRUE;
      q_din(143 downto Q_BITS) <= (others => '-');
    else
      q_wr_en <= '0';
      if unaryOR(we0) then
        assert q_full='0' report "queue FIFO overflow" severity FAILURE;
        q_din <= q_0;
        q_wr_en <= '1';
        
        --WANT to change this to be a mini queue with 2 registers
        -- input ports dictate priority
        -- but any can be used
        -- 
        
        
        
        
        if unaryOR(we1) then
          ready1_int <= FALSE;
          assert ready1_int report "write overflow port 1" severity FAILURE;
          reg1 <= q_1;
        end if;
        if unaryOR(we2) then
          ready2_int <= FALSE;
          assert ready2_int report "write overflow port 2" severity FAILURE;
          reg2 <= q_2;
        end if;
      elsif unaryOR(we1) then
        assert q_full='0' report "queue FIFO overflow" severity FAILURE;
        --FIXME change these to use constants instaed of concatenation
        q_din <= q_1;
        q_wr_en <= '1';
        
        reg1 <= q_1;
        ready1_int <= unaryOR(we1);
        
        if unaryOR(we2) then
          assert not reg2_we
          report "write overflow port 2" severity FAILURE;
          ready2_int <= FALSE;
          reg2 <= q_2;
        end if;
      elsif unaryOR(we2) then
        assert q_full='0' report "queue FIFO overflow" severity FAILURE;
        q_din <= q_2;
        q_wr_en <= '1';
        
        if unaryOR(we1) then
          assert not reg1_we 
          report "write overflow port 1" severity FAILURE;
          ready1_int <= FALSE;
          reg1 <= q_1;
        end if;
        reg2 <= q_2;
        ready2_int <= unaryOR(we2);
      end if;
    end if;
  end if;
end process queueing;
  
queue:framer_fifo
port map (
  clk => clk,
  srst => reset,
  din => q_din,
  wr_en => q_wr_en,
  rd_en => q_rd_en,
  dout => q_dout,
  full => q_full,
  almost_full => q_almost_full,
  empty => q_empty,
  almost_empty => q_almost_empty
 
);
q_rd_en <= not q_empty;

queueRead:process(clk)
begin
  if rising_edge(clk) then
    commit_int <= to_boolean(q_dout(Q_BITS-1));
    address_int 
      <= unsigned(q_dout(ADDRESS_BIT-1 downto ADDRESS_BIT-ADDRESS_BITS));
    length_int 
      <= unsigned(q_dout(LENGTH_BIT-1 downto LENGTH_BIT-ADDRESS_BITS-1));
    if q_empty = '0' then
      we_int <= to_boolean(q_dout(WE_BIT-1 downto WE_BIT-BUS_CHUNKS));
      commit_int <= to_boolean(q_dout(Q_BITS-1));
    else
      we_int <= (others => FALSE);
      commit_int <= FALSE;
    end if;
    data_int <= to_streambus(q_dout(DATA_BIT-1 downto 0));
  end if;
end process queueRead;

end architecture RTL;
