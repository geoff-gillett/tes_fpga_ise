library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tes;


entity ml605_startup_test is
port (
  sys_clk_p:in std_logic;
  sys_clk_n:in std_logic
);
end entity ml605_startup_test;

architecture RTL of ml605_startup_test is
component clk_wiz_v3_6_0
port
 (-- Clock in ports
  CLK_IN1_P:in std_logic;
  CLK_IN1_N:in std_logic;
  -- Clock out ports
  CLK_OUT1:out std_logic;
  -- Status and control signals
  RESET:in std_logic;
  LOCKED:out std_logic
 );
end component;
  
signal boot_clk:std_logic;

signal counter:unsigned(15 downto 0);
signal locked,trigger:std_logic;
signal reset:std_logic;

attribute S:string;
attribute S of counter:signal is "TRUE";
attribute s of trigger:signal is "TRUE";

attribute MARK_DEBUG:string;
attribute MARK_DEBUG of counter:signal is "TRUE";
attribute MARK_DEBUG of reset:signal is "TRUE";
begin

MMCM:clk_wiz_v3_6_0
  port map
   (-- Clock in ports
    CLK_IN1_P => sys_clk_p,
    CLK_IN1_N => sys_clk_n,
    -- Clock out ports
    CLK_OUT1 => boot_clk,
    -- Status and control signals
    RESET  => '0',
    LOCKED => locked);

glbl_reset_gen:entity tes.reset_sync
port map(
  clk => boot_clk,
  enable => trigger,
  reset_in => '0',
  reset_out => reset
);

test:process (boot_clk) is
begin
  if rising_edge(boot_clk) then
    if reset='1' then
      counter <= (others => '0');
    else
      counter <= counter+1;
    end if;
  end if;
end process test;

end architecture RTL;
