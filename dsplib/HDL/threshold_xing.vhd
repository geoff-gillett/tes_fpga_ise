library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
-- latency 3
-- flags the closest to threshold so it maybe the sample just before the 
-- threshold is crossed.
entity threshold_xing is
generic(
  THRESHOLD_BITS:integer:=18
);
port(
  clk:in std_logic;
  reset:in std_logic;
  --
  threshold:in signed(THRESHOLD_BITS-1 downto 0);
  signal_in:in signed(THRESHOLD_BITS-1 downto 0);
  -- in registered arch these signals 
  pos_xing:out boolean;
  closest_pos_xing:out boolean;
  neg_xing:out boolean;
  closest_neg_xing:out boolean;
  signal_out:out signed(THRESHOLD_BITS-1 downto 0)
);
end entity threshold_xing;

architecture closest of threshold_xing is

signal above,below,was_above,was_below:boolean;
signal diff,diff_reg:signed(THRESHOLD_BITS-1 downto 0);
signal signal_reg,signal_reg2:signed(THRESHOLD_BITS-1 downto 0);
signal pos,neg,pos_reg,neg_reg:boolean;
signal first_closest:boolean;
signal pos_xing_now,pos_xing_next:boolean;
signal neg_xing_now,neg_xing_next:boolean;

begin

below <= signal_reg < threshold;
above <= signal_reg > threshold;
neg <= not above and was_above;
pos <= not below and was_below;

first_closest <= diff_reg < diff;

outputReg:process(clk)
begin
if rising_edge(clk) then
	if reset='1' then
		was_above <= FALSE;
		was_below <= FALSE;
	else
    was_above <= above;
    was_below <= below;
    signal_reg <= signal_in;
    signal_reg2 <= signal_reg;
		signal_out <= signal_reg2;
		pos_reg <= pos;
		neg_reg <= neg;
    
    diff <= abs(threshold-signal_in);
    diff_reg <= diff;
   
    pos_xing_now <= pos and first_closest;
    pos_xing_next <= pos and not first_closest;
    neg_xing_now <= neg and first_closest;
    neg_xing_next <= neg and not first_closest;
   	
   	pos_xing <= pos_reg; 
   	neg_xing <= neg_reg; 
   	
    closest_pos_xing <= (pos and first_closest) or pos_xing_next;
    closest_neg_xing <= (neg and first_closest) or neg_xing_next;
      
  end if;
end if;
end process outputReg;
end architecture closest;
