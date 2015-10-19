################################################################################
# TES_digitiser design
# ML605 pin-outs
# Engineer: Geoff Gillett
################################################################################
#CONFIG PART = xc6vlx240tff1156-1;
#-------------------------------------------------------------------------------
# 200MHz Differential Clock From the ML605
#-------------------------------------------------------------------------------
set_property IOSTANDARD LVDS_25 [get_ports clk_p]
set_property DIFF_TERM 1 [get_ports clk_p]
set_property PACKAGE_PIN J9 [get_ports clk_p]

set_property IOSTANDARD LVDS_25 [get_ports clk_n]
set_property DIFF_TERM 1 [get_ports clk_n]
set_property PACKAGE_PIN H9 [get_ports clk_n]
#-------------------------------------------------------------------------------
# USB-UART between hot PC and ML605
#-------------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS25 [get_ports main_rx]
set_property PACKAGE_PIN J24 [get_ports main_rx]

set_property IOSTANDARD LVCMOS25 [get_ports main_tx]
set_property PACKAGE_PIN J25 [get_ports main_tx]
set_property DRIVE 4 [get_ports main_tx]
set_property SLEW SLOW [get_ports main_tx]
#-------------------------------------------------------------------------------
# Global reset switch
#-------------------------------------------------------------------------------
set_property PACKAGE_PIN H10 [get_ports global_reset]
#-------------------------------------------------------------------------------
# LEDs for debugging
#-------------------------------------------------------------------------------
set i 0
foreach pin {AC22 AC24 AE22 AE23 AB23 AG23 AE24 AD24} {
  set_property package_pin $pin [get_ports LEDs[$i]]
  incr i
}
################################################################################
# FMC108 ADC mezzanine card Texas instruments ADS62P49 dual ADC chips 
################################################################################
# Chip have individual clocks
#-------------------------------------------------------------------------------
set i 0
foreach pin {AF21 AL19 AM27 AJ25} {
  set_property package_pin $pin [get_ports chip_clk_n[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports chip_clk_n[$i]]
  set_property DIFF_TERM 1 [get_ports chip_clk_n[$i]]
  incr i
}

set i 0
foreach pin {AF20 AK19 AN27 AH25} {
  set_property package_pin $pin [get_ports chip_clk_p[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports chip_clk_p[$i]]
  set_property DIFF_TERM 1 [get_ports chip_clk_p[$i]]
  incr i
}
#-------------------------------------------------------------------------------
# LVDS ADC A 
#-------------------------------------------------------------------------------
set i 0
foreach pin {AE19 AD19 AD20 AG21 AH22 AJ21 AJ22} {
  set_property package_pin $pin [get_ports adc_0_n[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_0_n[$i]]
  set_property DIFF_TERM 1 [get_ports adc_0_n[$i]]
  incr i
}

set i 0
foreach pin {AF19 AC19 AC20 AG20 AG22 AK21 AK22} {
  set_property package_pin $pin [get_ports adc_0_p[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_0_p[$i]]
  set_property DIFF_TERM 1 [get_ports adc_0_p[$i]]
  incr i
}
#-------------------------------------------------------------------------------
# LVDS ADC B 
#-------------------------------------------------------------------------------
set i 0
foreach pin {AC27 AC25 AA29 AB26 AB31 AC28 Y26} {
  set_property package_pin $pin [get_ports adc_1_n[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_1_n[$i]]
  set_property DIFF_TERM 1 [get_ports adc_1_n[$i]]
  incr i
}

set i 0
foreach pin {AB27 AB25 AA28 AA26 AB30 AB28 AA25} {
  set_property package_pin $pin [get_ports adc_1_p[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_1_p[$i]]
  set_property DIFF_TERM 1 [get_ports adc_1_p[$i]]
  incr i
}
#-------------------------------------------------------------------------------
# LVDS ADC C 
#-------------------------------------------------------------------------------
set i 0
foreach pin {AN22 AL21 AL20 AL18 AN18 AL23 AN20} {
  set_property package_pin $pin [get_ports adc_2_n[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_2_n[$i]]
  set_property DIFF_TERM 1 [get_ports adc_2_n[$i]]
  incr i
}

set i 0
foreach pin {AM22 AM21 AM20 AM18 AP19 AM23 AN19} {
  set_property package_pin $pin [get_ports adc_2_p[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_2_p[$i]]
  set_property DIFF_TERM 1 [get_ports adc_2_p[$i]]
  incr i
}
#-------------------------------------------------------------------------------
# LVDS ADC D 
#-------------------------------------------------------------------------------
set i 0
foreach pin {AA31 AC32 AD31 AE32 AC34 AG32 AF31} {
  set_property package_pin $pin [get_ports adc_3_n[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_3_n[$i]]
  set_property DIFF_TERM 1 [get_ports adc_3_n[$i]]
  incr i
}

set i 0
foreach pin {AA30 AB32 AE31 AD32 AD34 AG33 AG31} {
  set_property package_pin $pin [get_ports adc_3_p[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_3_p[$i]]
  set_property DIFF_TERM 1 [get_ports adc_3_p[$i]]
  incr i
}
#-------------------------------------------------------------------------------
# LVDS ADC E 
#-------------------------------------------------------------------------------
set i 0
foreach pin {AA31 AC32 AD31 AE32 AC34 AG32 AF31} {
  set_property package_pin $pin [get_ports adc_4_n[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_4_n[$i]]
  set_property DIFF_TERM 1 [get_ports adc_4_n[$i]]
  incr i
}

set i 0
foreach pin {AA30 AB32 AE31 AD32 AD34 AG33 AG31} {
  set_property package_pin $pin [get_ports adc_4_p[$i]] 
  set_property IOSTANDARD LVDS_25 [get_ports adc_4_p[$i]]
  set_property DIFF_TERM 1 [get_ports adc_4_p[$i]]
  incr i
}

#
NET "adc_1_n[0]" LOC = AC27;
NET "adc_1_n[0]" IOSTANDARD = LVDS_25;
NET "adc_1_n[0]" DIFF_TERM = "TRUE";
NET "adc_1_p[0]" LOC = AB27;
NET "adc_1_p[0]" IOSTANDARD = LVDS_25;
NET "adc_1_p[0]" DIFF_TERM = "TRUE";
NET "adc_1_n[1]" LOC = AC25;
NET "adc_1_n[1]" IOSTANDARD = LVDS_25;
NET "adc_1_n[1]" DIFF_TERM = "TRUE";
NET "adc_1_p[1]" LOC = AB25;
NET "adc_1_p[1]" IOSTANDARD = LVDS_25;
NET "adc_1_p[1]" DIFF_TERM = "TRUE";
NET "adc_1_n[2]" LOC = AA29;
NET "adc_1_n[2]" IOSTANDARD = LVDS_25;
NET "adc_1_n[2]" DIFF_TERM = "TRUE";
NET "adc_1_p[2]" LOC = AA28;
NET "adc_1_p[2]" IOSTANDARD = LVDS_25;
NET "adc_1_p[2]" DIFF_TERM = "TRUE";
NET "adc_1_n[3]" LOC = AB26;
NET "adc_1_n[3]" IOSTANDARD = LVDS_25;
NET "adc_1_n[3]" DIFF_TERM = "TRUE";
NET "adc_1_p[3]" LOC = AA26;
NET "adc_1_p[3]" IOSTANDARD = LVDS_25;
NET "adc_1_p[3]" DIFF_TERM = "TRUE";
NET "adc_1_n[4]" LOC = AB31;
NET "adc_1_n[4]" IOSTANDARD = LVDS_25;
NET "adc_1_n[4]" DIFF_TERM = "TRUE";
NET "adc_1_p[4]" LOC = AB30;
NET "adc_1_p[4]" IOSTANDARD = LVDS_25;
NET "adc_1_p[4]" DIFF_TERM = "TRUE";
NET "adc_1_n[5]" LOC = AC28;
NET "adc_1_n[5]" IOSTANDARD = LVDS_25;
NET "adc_1_n[5]" DIFF_TERM = "TRUE";
NET "adc_1_p[5]" LOC = AB28;
NET "adc_1_p[5]" IOSTANDARD = LVDS_25;
NET "adc_1_p[5]" DIFF_TERM = "TRUE";
NET "adc_1_n[6]" LOC = Y26;
NET "adc_1_n[6]" IOSTANDARD = LVDS_25;
NET "adc_1_n[6]" DIFF_TERM = "TRUE";
NET "adc_1_p[6]" LOC = AA25;
NET "adc_1_p[6]" IOSTANDARD = LVDS_25;
NET "adc_1_p[6]" DIFF_TERM = "TRUE";
#
NET "adc_2_n[0]" LOC = AN22;
NET "adc_2_n[0]" IOSTANDARD = LVDS_25;
NET "adc_2_n[0]" DIFF_TERM = "TRUE";
NET "adc_2_p[0]" LOC = AM22;
NET "adc_2_p[0]" IOSTANDARD = LVDS_25;
NET "adc_2_p[0]" DIFF_TERM = "TRUE";
NET "adc_2_n[1]" LOC = AL21;
NET "adc_2_n[1]" IOSTANDARD = LVDS_25;
NET "adc_2_n[1]" DIFF_TERM = "TRUE";
NET "adc_2_p[1]" LOC = AM21;
NET "adc_2_p[1]" IOSTANDARD = LVDS_25;
NET "adc_2_p[1]" DIFF_TERM = "TRUE";
NET "adc_2_n[2]" LOC = AL20;
NET "adc_2_n[2]" IOSTANDARD = LVDS_25;
NET "adc_2_n[2]" DIFF_TERM = "TRUE";
NET "adc_2_p[2]" LOC = AM20;
NET "adc_2_p[2]" IOSTANDARD = LVDS_25;
NET "adc_2_p[2]" DIFF_TERM = "TRUE";
NET "adc_2_n[3]" LOC = AL18;
NET "adc_2_n[3]" IOSTANDARD = LVDS_25;
NET "adc_2_n[3]" DIFF_TERM = "TRUE";
NET "adc_2_p[3]" LOC = AM18;
NET "adc_2_p[3]" IOSTANDARD = LVDS_25;
NET "adc_2_p[3]" DIFF_TERM = "TRUE";
NET "adc_2_n[4]" LOC = AN18;
NET "adc_2_n[4]" IOSTANDARD = LVDS_25;
NET "adc_2_n[4]" DIFF_TERM = "TRUE";
NET "adc_2_p[4]" LOC = AP19;
NET "adc_2_p[4]" IOSTANDARD = LVDS_25;
NET "adc_2_p[4]" DIFF_TERM = "TRUE";
NET "adc_2_n[5]" LOC = AL23;
NET "adc_2_n[5]" IOSTANDARD = LVDS_25;
NET "adc_2_n[5]" DIFF_TERM = "TRUE";
NET "adc_2_p[5]" LOC = AM23;
NET "adc_2_p[5]" IOSTANDARD = LVDS_25;
NET "adc_2_p[5]" DIFF_TERM = "TRUE";
NET "adc_2_n[6]" LOC = AN20;
NET "adc_2_n[6]" IOSTANDARD = LVDS_25;
NET "adc_2_n[6]" DIFF_TERM = "TRUE";
NET "adc_2_p[6]" LOC = AN19;
NET "adc_2_p[6]" IOSTANDARD = LVDS_25;
NET "adc_2_p[6]" DIFF_TERM = "TRUE";
#
NET "adc_3_n[1]" LOC = AA31;
NET "adc_3_n[1]" IOSTANDARD = LVDS_25;
NET "adc_3_n[1]" DIFF_TERM = "TRUE";
NET "adc_3_p[1]" LOC = AA30;
NET "adc_3_p[1]" IOSTANDARD = LVDS_25;
NET "adc_3_p[1]" DIFF_TERM = "TRUE";
NET "adc_3_n[2]" LOC = AC32;
NET "adc_3_n[2]" IOSTANDARD = LVDS_25;
NET "adc_3_n[2]" DIFF_TERM = "TRUE";
NET "adc_3_p[2]" LOC = AB32;
NET "adc_3_p[2]" IOSTANDARD = LVDS_25;
NET "adc_3_p[2]" DIFF_TERM = "TRUE";
NET "adc_3_n[0]" LOC = AD31;
NET "adc_3_n[0]" IOSTANDARD = LVDS_25;
NET "adc_3_n[0]" DIFF_TERM = "TRUE";
NET "adc_3_p[0]" LOC = AE31;
NET "adc_3_p[0]" IOSTANDARD = LVDS_25;
NET "adc_3_p[0]" DIFF_TERM = "TRUE";
NET "adc_3_n[3]" LOC = AE32;
NET "adc_3_n[3]" IOSTANDARD = LVDS_25;
NET "adc_3_n[3]" DIFF_TERM = "TRUE";
NET "adc_3_p[3]" LOC = AD32;
NET "adc_3_p[3]" IOSTANDARD = LVDS_25;
NET "adc_3_p[3]" DIFF_TERM = "TRUE";
NET "adc_3_n[4]" LOC = AC34;
NET "adc_3_n[4]" IOSTANDARD = LVDS_25;
NET "adc_3_n[4]" DIFF_TERM = "TRUE";
NET "adc_3_p[4]" LOC = AD34;
NET "adc_3_p[4]" IOSTANDARD = LVDS_25;
NET "adc_3_p[4]" DIFF_TERM = "TRUE";
NET "adc_3_n[5]" LOC = AG32;
NET "adc_3_n[5]" IOSTANDARD = LVDS_25;
NET "adc_3_n[5]" DIFF_TERM = "TRUE";
NET "adc_3_p[5]" LOC = AG33;
NET "adc_3_p[5]" IOSTANDARD = LVDS_25;
NET "adc_3_p[5]" DIFF_TERM = "TRUE";
NET "adc_3_n[6]" LOC = AF31;
NET "adc_3_n[6]" IOSTANDARD = LVDS_25;
NET "adc_3_n[6]" DIFF_TERM = "TRUE";
NET "adc_3_p[6]" LOC = AG31;
NET "adc_3_p[6]" IOSTANDARD = LVDS_25;
NET "adc_3_p[6]" DIFF_TERM = "TRUE";
#
NET "adc_4_n[0]" LOC = AM26;
NET "adc_4_n[0]" IOSTANDARD = LVDS_25;
NET "adc_4_n[0]" DIFF_TERM = "TRUE";
NET "adc_4_p[0]" LOC = AL26;
NET "adc_4_p[0]" IOSTANDARD = LVDS_25;
NET "adc_4_p[0]" DIFF_TERM = "TRUE";
NET "adc_4_n[1]" LOC = AN24;
NET "adc_4_n[1]" IOSTANDARD = LVDS_25;
NET "adc_4_n[1]" DIFF_TERM = "TRUE";
NET "adc_4_p[1]" LOC = AN25;
NET "adc_4_p[1]" IOSTANDARD = LVDS_25;
NET "adc_4_p[1]" DIFF_TERM = "TRUE";
NET "adc_4_n[2]" LOC = AL24;
NET "adc_4_n[2]" IOSTANDARD = LVDS_25;
NET "adc_4_n[2]" DIFF_TERM = "TRUE";
NET "adc_4_p[2]" LOC = AK23;
NET "adc_4_p[2]" IOSTANDARD = LVDS_25;
NET "adc_4_p[2]" DIFF_TERM = "TRUE";
NET "adc_4_n[3]" LOC = AN23;
NET "adc_4_n[3]" IOSTANDARD = LVDS_25;
NET "adc_4_n[3]" DIFF_TERM = "TRUE";
NET "adc_4_p[3]" LOC = AP22;
NET "adc_4_p[3]" IOSTANDARD = LVDS_25;
NET "adc_4_p[3]" DIFF_TERM = "TRUE";
NET "adc_4_n[4]" LOC = AP26;
NET "adc_4_n[4]" IOSTANDARD = LVDS_25;
NET "adc_4_n[4]" DIFF_TERM = "TRUE";
NET "adc_4_p[4]" LOC = AP27;
NET "adc_4_p[4]" IOSTANDARD = LVDS_25;
NET "adc_4_p[4]" DIFF_TERM = "TRUE";
NET "adc_4_n[5]" LOC = AL25;
NET "adc_4_n[5]" IOSTANDARD = LVDS_25;
NET "adc_4_n[5]" DIFF_TERM = "TRUE";
NET "adc_4_p[5]" LOC = AM25;
NET "adc_4_p[5]" IOSTANDARD = LVDS_25;
NET "adc_4_p[5]" DIFF_TERM = "TRUE";
NET "adc_4_n[6]" LOC = AP29;
NET "adc_4_n[6]" IOSTANDARD = LVDS_25;
NET "adc_4_n[6]" DIFF_TERM = "TRUE";
NET "adc_4_p[6]" LOC = AN29;
NET "adc_4_p[6]" IOSTANDARD = LVDS_25;
NET "adc_4_p[6]" DIFF_TERM = "TRUE";
#
NET "adc_5_n[0]" LOC = AN34;
NET "adc_5_n[0]" IOSTANDARD = LVDS_25;
NET "adc_5_n[0]" DIFF_TERM = "TRUE";
NET "adc_5_p[0]" LOC = AN33;
NET "adc_5_p[0]" IOSTANDARD = LVDS_25;
NET "adc_5_p[0]" DIFF_TERM = "TRUE";
NET "adc_5_n[1]" LOC = AG30;
NET "adc_5_n[1]" IOSTANDARD = LVDS_25;
NET "adc_5_n[1]" DIFF_TERM = "TRUE";
NET "adc_5_p[1]" LOC = AF30;
NET "adc_5_p[1]" IOSTANDARD = LVDS_25;
NET "adc_5_p[1]" DIFF_TERM = "TRUE";
NET "adc_5_n[2]" LOC = AK34;
NET "adc_5_n[2]" IOSTANDARD = LVDS_25;
NET "adc_5_n[2]" DIFF_TERM = "TRUE";
NET "adc_5_p[2]" LOC = AL34;
NET "adc_5_p[2]" IOSTANDARD = LVDS_25;
NET "adc_5_p[2]" DIFF_TERM = "TRUE";
NET "adc_5_n[3]" LOC = AL33;
NET "adc_5_n[3]" IOSTANDARD = LVDS_25;
NET "adc_5_n[3]" DIFF_TERM = "TRUE";
NET "adc_5_p[3]" LOC = AM33;
NET "adc_5_p[3]" IOSTANDARD = LVDS_25;
NET "adc_5_p[3]" DIFF_TERM = "TRUE";
NET "adc_5_n[4]" LOC = AM32;
NET "adc_5_n[4]" IOSTANDARD = LVDS_25;
NET "adc_5_n[4]" DIFF_TERM = "TRUE";
NET "adc_5_p[4]" LOC = AN32;
NET "adc_5_p[4]" IOSTANDARD = LVDS_25;
NET "adc_5_p[4]" DIFF_TERM = "TRUE";
NET "adc_5_n[5]" LOC = AP33;
NET "adc_5_n[5]" IOSTANDARD = LVDS_25;
NET "adc_5_n[5]" DIFF_TERM = "TRUE";
NET "adc_5_p[5]" LOC = AP32;
NET "adc_5_p[5]" IOSTANDARD = LVDS_25;
NET "adc_5_p[5]" DIFF_TERM = "TRUE";
NET "adc_5_n[6]" LOC = AM31;
NET "adc_5_n[6]" IOSTANDARD = LVDS_25;
NET "adc_5_n[6]" DIFF_TERM = "TRUE";
NET "adc_5_p[6]" LOC = AL30;
NET "adc_5_p[6]" IOSTANDARD = LVDS_25;
NET "adc_5_p[6]" DIFF_TERM = "TRUE";
#
NET "adc_6_n[0]" LOC = AK28;
NET "adc_6_n[0]" IOSTANDARD = LVDS_25;
NET "adc_6_n[0]" DIFF_TERM = "TRUE";
NET "adc_6_p[0]" LOC = AL28;
NET "adc_6_p[0]" IOSTANDARD = LVDS_25;
NET "adc_6_p[0]" DIFF_TERM = "TRUE";
NET "adc_6_n[1]" LOC = AP31;
NET "adc_6_n[1]" IOSTANDARD = LVDS_25;
NET "adc_6_n[1]" DIFF_TERM = "TRUE";
NET "adc_6_p[1]" LOC = AP30;
NET "adc_6_p[1]" IOSTANDARD = LVDS_25;
NET "adc_6_p[1]" DIFF_TERM = "TRUE";
NET "adc_6_n[2]" LOC = AM30;
NET "adc_6_n[2]" IOSTANDARD = LVDS_25;
NET "adc_6_n[2]" DIFF_TERM = "TRUE";
NET "adc_6_p[2]" LOC = AN30;
NET "adc_6_p[2]" IOSTANDARD = LVDS_25;
NET "adc_6_p[2]" DIFF_TERM = "TRUE";
NET "adc_6_n[3]" LOC = AM28;
NET "adc_6_n[3]" IOSTANDARD = LVDS_25;
NET "adc_6_n[3]" DIFF_TERM = "TRUE";
NET "adc_6_p[3]" LOC = AN28;
NET "adc_6_p[3]" IOSTANDARD = LVDS_25;
NET "adc_6_p[3]" DIFF_TERM = "TRUE";
NET "adc_6_n[4]" LOC = AJ27;
NET "adc_6_n[4]" IOSTANDARD = LVDS_25;
NET "adc_6_n[4]" DIFF_TERM = "TRUE";
NET "adc_6_p[4]" LOC = AK27;
NET "adc_6_p[4]" IOSTANDARD = LVDS_25;
NET "adc_6_p[4]" DIFF_TERM = "TRUE";
NET "adc_6_n[5]" LOC = AK24;
NET "adc_6_n[5]" IOSTANDARD = LVDS_25;
NET "adc_6_n[5]" DIFF_TERM = "TRUE";
NET "adc_6_p[5]" LOC = AJ24;
NET "adc_6_p[5]" IOSTANDARD = LVDS_25;
NET "adc_6_p[5]" DIFF_TERM = "TRUE";
NET "adc_6_n[6]" LOC = AK29;
NET "adc_6_n[6]" IOSTANDARD = LVDS_25;
NET "adc_6_n[6]" DIFF_TERM = "TRUE";
NET "adc_6_p[6]" LOC = AL29;
NET "adc_6_p[6]" IOSTANDARD = LVDS_25;
NET "adc_6_p[6]" DIFF_TERM = "TRUE";
#
NET "adc_7_n[0]" LOC = AH32;
NET "adc_7_n[0]" IOSTANDARD = LVDS_25;
NET "adc_7_n[0]" DIFF_TERM = "TRUE";
NET "adc_7_p[0]" LOC = AH33;
NET "adc_7_p[0]" IOSTANDARD = LVDS_25;
NET "adc_7_p[0]" DIFF_TERM = "TRUE";
NET "adc_7_n[1]" LOC = AF29;
NET "adc_7_n[1]" IOSTANDARD = LVDS_25;
NET "adc_7_n[1]" DIFF_TERM = "TRUE";
NET "adc_7_p[1]" LOC = AF28;
NET "adc_7_p[1]" IOSTANDARD = LVDS_25;
NET "adc_7_p[1]" DIFF_TERM = "TRUE";
NET "adc_7_n[2]" LOC = AD27;
NET "adc_7_n[2]" IOSTANDARD = LVDS_25;
NET "adc_7_n[2]" DIFF_TERM = "TRUE";
NET "adc_7_p[2]" LOC = AE27;
NET "adc_7_p[2]" IOSTANDARD = LVDS_25;
NET "adc_7_p[2]" DIFF_TERM = "TRUE";
NET "adc_7_n[3]" LOC = AE29;
NET "adc_7_n[3]" IOSTANDARD = LVDS_25;
NET "adc_7_n[3]" DIFF_TERM = "TRUE";
NET "adc_7_p[3]" LOC = AE28;
NET "adc_7_p[3]" IOSTANDARD = LVDS_25;
NET "adc_7_p[3]" DIFF_TERM = "TRUE";
NET "adc_7_n[4]" LOC = AJ32;
NET "adc_7_n[4]" IOSTANDARD = LVDS_25;
NET "adc_7_n[4]" DIFF_TERM = "TRUE";
NET "adc_7_p[4]" LOC = AJ31;
NET "adc_7_p[4]" IOSTANDARD = LVDS_25;
NET "adc_7_p[4]" DIFF_TERM = "TRUE";
NET "adc_7_n[5]" LOC = AJ30;
NET "adc_7_n[5]" IOSTANDARD = LVDS_25;
NET "adc_7_n[5]" DIFF_TERM = "TRUE";
NET "adc_7_p[5]" LOC = AJ29;
NET "adc_7_p[5]" IOSTANDARD = LVDS_25;
NET "adc_7_p[5]" DIFF_TERM = "TRUE";
NET "adc_7_n[6]" LOC = AK32;
NET "adc_7_n[6]" IOSTANDARD = LVDS_25;
NET "adc_7_n[6]" DIFF_TERM = "TRUE";
NET "adc_7_p[6]" LOC = AK33;
NET "adc_7_p[6]" IOSTANDARD = LVDS_25;
NET "adc_7_p[6]" DIFF_TERM = "TRUE";
#-------------------------------------------------------------------------------
#  ADS62P49 SPI pins
#  TI labels the SPI pins as follows
#     spi_clk  -> SCLK     serial clock
#     spi_ce_n -> SEN      low active chip enable
#     spi_mosi -> SDATA    data to chip 
#     spi_miso -> SDOUT    data from chip
#-------------------------------------------------------------------------------
NET "spi_ce_n[0]" LOC = V33;
NET "spi_ce_n[1]" LOC = U31;
NET "spi_ce_n[2]" LOC = U30;
NET "spi_ce_n[3]" LOC = U28;
NET "spi_miso[0]" LOC = AE33;
NET "spi_miso[1]" LOC = AF33;
NET "spi_miso[2]" LOC = AD29;
NET "spi_miso[3]" LOC = AC29;
NET "spi_mosi" LOC = U27;
NET "spi_clk" LOC = U26;
#-------------------------------------------------------------------------------
# AD9510 PLL
#-------------------------------------------------------------------------------
NET "FMC_internal_clk_en" LOC = AH29;
#-------------------------------------------------------------------------------
# other FMC108 pins
#-------------------------------------------------------------------------------
NET "FMC_reset" LOC = V29;
NET "FMC_power_good" LOC = J27;
NET "FMC_present_n" LOC = AP25;
#-------------------------------------------------------------------------------
NET "chip_clk_p[0]" TNM_NET = "adc_chip_0_clk_p";
TIMESPEC TS_adc_chip_clk_0_p = PERIOD "adc_chip_0_clk_p" 250 MHz HIGH 50 %;

NET "chip_clk_p[1]" TNM_NET = "adc_chip_1_clk_p";
TIMESPEC TS_adc_chip_clk_1_p = PERIOD "adc_chip_1_clk_p" 250 MHz HIGH 50 %;

NET "chip_clk_p[2]" TNM_NET = "adc_chip_2_clk_p";
TIMESPEC TS_adc_chip_clk_2_p = PERIOD "adc_chip_2_clk_p" 250 MHz HIGH 50 %;

NET "chip_clk_p[3]" TNM_NET = "adc_chip_3_clk_p";
TIMESPEC TS_adc_chip_clk_3_p = PERIOD "adc_chip_3_clk_p" 250 MHz HIGH 50 %;
################################################################################
# VIRTEX 6 embedded (HARD) MAC
################################################################################
#### Module LEDs_8Bit constraints
NET "frame_error" LOC = AH28;
NET "frame_error" IOSTANDARD = LVCMOS25;
NET "frame_errorn" LOC = AH27;
NET "frame_errorn" IOSTANDARD = LVCMOS25;

#### Module Push_Buttons_4Bit constraints
NET "update_speed" LOC = G26;
NET "update_speed" IOSTANDARD = LVCMOS15;
NET "serial_command" LOC = G17;
NET "serial_command" IOSTANDARD = LVCMOS15;
NET "pause_req_s" LOC = A19;
NET "pause_req_s" IOSTANDARD = LVCMOS15;
NET "reset_error" LOC = A18;
NET "reset_error" IOSTANDARD = LVCMOS15;

#### Module DIP_Switches_4Bit constraints
NET "mac_speed[0]" LOC = D22;
NET "mac_speed[0]" IOSTANDARD = LVCMOS15;
NET "mac_speed[1]" LOC = C22;
NET "mac_speed[1]" IOSTANDARD = LVCMOS15;
#Net gen_tx_data      LOC = L21  | IOSTANDARD = LVCMOS15;
#Net chk_tx_data      LOC = L20  | IOSTANDARD = LVCMOS15;
#Net swap_address     LOC = C18  | IOSTANDARD = LVCMOS15;

NET "phy_resetn" TIG;
NET "phy_resetn" LOC = AH13;
NET "phy_resetn" IOSTANDARD = LVCMOS25;
NET "mdc" LOC = AP14;
NET "mdc" IOSTANDARD = LVCMOS25;
NET "mdio" LOC = AN14;
NET "mdio" IOSTANDARD = LVCMOS25;

# lock to unused header
NET "serial_response" S = "TRUE";
#LOC = AN23 | IOSTANDARD = LVCMOS25;
NET "tx_statistics_s" S = "TRUE";
#LOC = AP22 | IOSTANDARD = LVCMOS25;
NET "rx_statistics_s" S = "TRUE";
#LOC = AG21 | IOSTANDARD = LVCMOS25;

NET "gmii_rxd[7]" LOC = AC13;
NET "gmii_rxd[7]" IOSTANDARD = LVCMOS25;
NET "gmii_rxd[6]" LOC = AC12;
NET "gmii_rxd[6]" IOSTANDARD = LVCMOS25;
NET "gmii_rxd[5]" LOC = AD11;
NET "gmii_rxd[5]" IOSTANDARD = LVCMOS25;
NET "gmii_rxd[4]" LOC = AM12;
NET "gmii_rxd[4]" IOSTANDARD = LVCMOS25;
NET "gmii_rxd[3]" LOC = AN12;
NET "gmii_rxd[3]" IOSTANDARD = LVCMOS25;
NET "gmii_rxd[2]" LOC = AE14;
NET "gmii_rxd[2]" IOSTANDARD = LVCMOS25;
NET "gmii_rxd[1]" LOC = AF14;
NET "gmii_rxd[1]" IOSTANDARD = LVCMOS25;
NET "gmii_rxd[0]" LOC = AN13;
NET "gmii_rxd[0]" IOSTANDARD = LVCMOS25;

NET "gmii_txd[7]" IOSTANDARD = LVCMOS25;
NET "gmii_txd[6]" IOSTANDARD = LVCMOS25;
NET "gmii_txd[5]" IOSTANDARD = LVCMOS25;
NET "gmii_txd[4]" IOSTANDARD = LVCMOS25;
NET "gmii_txd[3]" IOSTANDARD = LVCMOS25;
NET "gmii_txd[2]" IOSTANDARD = LVCMOS25;
NET "gmii_txd[1]" IOSTANDARD = LVCMOS25;
NET "gmii_txd[0]" IOSTANDARD = LVCMOS25;
NET "gmii_tx_en" LOC = AJ10;
NET "gmii_tx_er" LOC = AH10;
NET "gmii_txd[0]" LOC = AM11;
NET "gmii_txd[1]" LOC = AL11;
NET "gmii_txd[2]" LOC = AG10;
NET "gmii_txd[3]" LOC = AG11;
NET "gmii_txd[4]" LOC = AL10;
NET "gmii_txd[5]" LOC = AM10;
NET "gmii_txd[6]" LOC = AE11;
NET "gmii_txd[7]" LOC = AF11;
NET "gmii_txd[7]" SLEW = FAST;
NET "gmii_txd[6]" SLEW = FAST;
NET "gmii_txd[5]" SLEW = FAST;
NET "gmii_txd[4]" SLEW = FAST;
NET "gmii_txd[3]" SLEW = FAST;
NET "gmii_txd[2]" SLEW = FAST;
NET "gmii_txd[1]" SLEW = FAST;
NET "gmii_txd[0]" SLEW = FAST;


NET "gmii_col" LOC = AK13;
NET "gmii_col" IOSTANDARD = LVCMOS25;
NET "gmii_crs" LOC = AL13;
NET "gmii_crs" IOSTANDARD = LVCMOS25;
NET "mii_tx_clk" LOC = AD12;
NET "mii_tx_clk" IOSTANDARD = LVCMOS25;

NET "gmii_tx_en" IOSTANDARD = LVCMOS25;
NET "gmii_tx_er" IOSTANDARD = LVCMOS25;
NET "gmii_tx_clk" LOC = AH12;
NET "gmii_tx_clk" IOSTANDARD = LVCMOS25;

NET "gmii_rx_dv" LOC = AM13;
NET "gmii_rx_dv" IOSTANDARD = LVCMOS25;
NET "gmii_rx_er" LOC = AG12;
NET "gmii_rx_er" IOSTANDARD = LVCMOS25;
# P20 - GCLK7
NET "gmii_rx_clk" LOC = AP11;
NET "gmii_rx_clk" IOSTANDARD = LVCMOS25;
################################################################################
# Ethernet GTX_CLK high quality 125 MHz reference clock
NET "embededMAC/gtx_clk_bufg" TNM_NET = "ref_gtx_clk";
TIMEGRP v6_emac_v2_3_0_clk_ref_gtx =  "ref_gtx_clk";
TIMESPEC TS_v6_emac_v2_3_0_clk_ref_gtx = PERIOD "v6_emac_v2_3_0_clk_ref_gtx" 8 ns HIGH 50 %;

# Multiplexed 1 Gbps, 10/100 Mbps output inherits constraint from GTX_CLK
NET "*tx_mac_aclk*" TNM_NET = "clk_tx_mac";
TIMEGRP v6_emac_v2_3_0_clk_ref_mux =  "clk_tx_mac";
TIMESPEC TS_v6_emac_v2_3_0_clk_ref_mux = PERIOD "v6_emac_v2_3_0_clk_ref_mux" TS_v6_emac_v2_3_0_clk_ref_gtx  HIGH 50 %;

# Ethernet GMII PHY-side receive clock
NET "gmii_rx_clk" TNM_NET = "phy_clk_rx";
TIMEGRP v6_emac_v2_3_0_clk_phy_rx =  "phy_clk_rx";
TIMESPEC TS_v6_emac_v2_3_0_clk_phy_rx = PERIOD "v6_emac_v2_3_0_clk_phy_rx" 7.5 ns HIGH 50 %;

# Constrain the host interface clock to an example frequency of 125 MHz
NET "*s_axi_aclk" TNM_NET = "clk_axi";
TIMEGRP v6_emac_v2_3_0_config_clk =  "clk_axi";
TIMESPEC TS_v6_emac_v2_3_0_config_clk = PERIOD "v6_emac_v2_3_0_config_clk" 8 ns HIGH 50 %;

# define TIGs between unrelated clock domains
TIMESPEC TS_clock_path_gtx2cpu = FROM "clockTree_clkout0" TO "clockTree_clkout1" TIG ;
TIMESPEC TS_clock_path_gtx2ref = FROM "clockTree_clkout0" TO "clockTree_clkout2" TIG ;
TIMESPEC TS_clock_path_cpu2gtx = FROM "clockTree_clkout1" TO "clockTree_clkout0" TIG ;
TIMESPEC TS_clock_path_sample2IO = FROM "clockTree_clkout0" TO "clkTree_clkout3" TIG ;
TIMESPEC TS_clock_path_IO2sample = FROM "clockTree_clkout3" TO "clkTree_clkout0" TIG ;
##
PIN "*bufgmux_speed_clk.I1" TIG;
PIN "*bufgmux_speed_clk.CE0" TIG;

# define TIGs on reset synchronizer FDPE PRE inputs
PIN "*reset_sync1.PRE" TIG;
PIN "*reset_sync2.PRE" TIG;

#
####
#######
##########
#############
#################
#FIFO BLOCK CONSTRAINTS


###############################################################################
# AXI FIFO CONSTRAINTS
# The following constraints are necessary for proper operation of the AXI
# FIFO. If you choose to not use the FIFO Block level of wrapper hierarchy,
# these constraints should be removed.
###############################################################################

# AXI FIFO transmit-side constraints
# -----------------------------------------------------------------------------

# Group the clock crossing signals into timing groups
INST "*user_side_FIFO?tx_fifo_i?rd_tran_frame_tog" TNM = "tx_fifo_rd_to_wr";
INST "*user_side_FIFO?tx_fifo_i?rd_retran_frame_tog" TNM = "tx_fifo_rd_to_wr";
INST "*user_side_FIFO?tx_fifo_i?rd_col_window_pipe_1" TNM = "tx_fifo_rd_to_wr";
INST "*user_side_FIFO?tx_fifo_i?rd_addr_txfer*" TNM = "tx_fifo_rd_to_wr";
INST "*user_side_FIFO?tx_fifo_i?rd_txfer_tog" TNM = "tx_fifo_rd_to_wr";
INST "*user_side_FIFO?tx_fifo_i?wr_frame_in_fifo" TNM = "tx_fifo_wr_to_rd";

TIMESPEC TS_tx_fifo_rd_to_wr = FROM "tx_fifo_rd_to_wr" TO "v6_emac_v2_3_0_clk_ref_mux" 8 ns DATAPATHONLY;
TIMESPEC TS_tx_fifo_wr_to_rd = FROM "tx_fifo_wr_to_rd" TO "v6_emac_v2_3_0_clk_ref_mux" 8 ns DATAPATHONLY;

# Reduce clock period to allow for metastability settling time
INST "*user_side_FIFO?tx_fifo_i?wr_rd_addr*" TNM = "tx_metastable";
INST "*user_side_FIFO?tx_fifo_i?wr_col_window_pipe_0" TNM = "tx_metastable";
TIMESPEC TS_tx_meta_protect = FROM "tx_metastable" 5 ns DATAPATHONLY;

# Transmit-side AXI FIFO address bus timing
INST "*user_side_FIFO?tx_fifo_i?rd_addr_txfer*" TNM = "tx_addr_rd";
INST "*user_side_FIFO?tx_fifo_i?wr_rd_addr*" TNM = "tx_addr_wr";
TIMESPEC TS_tx_fifo_addr = FROM "tx_addr_rd" TO "tx_addr_wr" 10 ns;

# AXI FIFO receive-side constraints
# -----------------------------------------------------------------------------

# Group the clock crossing signals into timing groups
INST "*user_side_FIFO?rx_fifo_i?wr_store_frame_tog" TNM = "rx_fifo_wr_to_rd";
INST "*user_side_FIFO?rx_fifo_i?rd_addr*" TNM = "rx_fifo_rd_to_wr";

TIMESPEC TS_rx_fifo_wr_to_rd = FROM "rx_fifo_wr_to_rd" TO "v6_emac_v2_3_0_clk_ref_gtx" 8 ns DATAPATHONLY;
TIMESPEC TS_rx_fifo_rd_to_wr = FROM "rx_fifo_rd_to_wr" TO "v6_emac_v2_3_0_clk_phy_rx" 8 ns DATAPATHONLY;


#
####
#######
##########
#############
#################
#BLOCK CONSTRAINTS

# Locate the Tri-Mode Ethernet MAC instance
INST "embededMAC/v6emac_fifo_block/v6emac_block/v6emac_core/BU2/U0/v6_emac" LOC = TEMAC_X0Y0;

###############################################################################
# PHYSICAL INTERFACE CONSTRAINTS
# The following constraints are necessary for proper operation, and are tuned
# for this example design. They should be modified to suit your design.
###############################################################################

# GMII physical interface constraints
# -----------------------------------------------------------------------------

# Set the IDELAY values on the PHY inputs, tuned for this example design.
# These values should be modified to suit your design.
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/delay_gmii_rx_dv" IDELAY_VALUE = 23;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/delay_gmii_rx_er" IDELAY_VALUE = 23;
INST "*v6emac_block*gmii_interface*delay_gmii_rxd" IDELAY_VALUE = 23;

# Group all IDELAY-related blocks to use a single IDELAYCTRL
INST "*dlyctrl" IODELAY_GROUP = "gmii_idelay";
INST "*v6emac_block*gmii_interface*delay_gmii_rx_dv" IODELAY_GROUP = "gmii_idelay";
INST "*v6emac_block*gmii_interface*delay_gmii_rx_er" IODELAY_GROUP = "gmii_idelay";
INST "*v6emac_block*gmii_interface*delay_gmii_rxd" IODELAY_GROUP = "gmii_idelay";

# The following constraints work in conjunction with IDELAY_VALUE settings to
# check that the GMII receive bus remains in alignment with the rising edge of
# GMII_RX_CLK, to within 2 ns setup time and 0 ns hold time.
INST "gmii_rxd[?]" TNM = "gmii_rx";
INST "gmii_rx_dv" TNM = "gmii_rx";
INST "gmii_rx_er" TNM = "gmii_rx";
TIMEGRP "gmii_rx" OFFSET = IN 2 ns VALID 2 ns BEFORE "gmii_rx_clk" RISING;

# Constrain the GMII physical interface flip-flops to IOBs
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_0" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_1" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_2" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_3" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_4" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_5" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_6" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rxd_to_mac_7" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rx_dv_to_mac" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/rx_er_to_mac" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_7" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_6" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_5" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_4" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_3" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_2" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_1" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_txd_0" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_tx_en" IOB =TRUE;
INST "embededMAC/v6emac_fifo_block/v6emac_block/gmii_interface/gmii_tx_er" IOB =TRUE;

# Location constraints are chosen for this example design.
# These values should be modified to suit your design.
# * Note that regional clocking imposes certain requirements
#   on the location of the physical interface pins and the TEMAC instance.
#   Please refer to the Virtex-6 FPGA Embedded Tri-Mode Ethernet MAC
#   User Guide for additional details. *

# Locate the GMII physical interface pins
# Locate the 125 MHz reference clock buffer
INST "embededMAC/v6emac_fifo_block/v6emac_block/BUFGMUX_SPEED_CLK" LOC = BUFGCTRL_X0Y6;
###############################################################################
NET "reset1" TIG;
NET "reset0" TIG;
NET "CPU_reset" TIG;
NET "channel_tx*" TNM_NET = "TNMG_TXTOCHANS";
NET "spi_*" TNM_NET = "TNMG_SPI";
NET 
#NET "register_write_data*" TNM_NET = "TNMG_CHANREGISTERS";
#NET "register_address*" TNM_NET = "TNMG_CHANREGISTERS";
#NET "register_write*" TNM_NET = "TNMG_CHANREGISTERS";
#NET "register_read_data*" TNM_NET = "TNMG_CHANREGISTERS";
NET "channel_rx*" TNM_NET = "TNMG_TXFROMCHANS";
##general registers
#NET "mca_bin_n*" TIG;
#NET "mca_lowest_value*" TIG;
#NET "mca_last_bin*" TIG;
#NET "mca_ticks*" TIG;
#NET "mca_channel_sel*" TIG;
#NET "mca_value_sel*" TIG;
#NET "tick_period*" TIG;
#NET "max_payload*" TIG;
#NET "event_threshold*" TIG;
#NET "event_timeout*" TIG;
#NET "mca_updated*" TIG;
NET "main_Rx*" TIG;
NET "main_Tx*" TIG;
####
TIMESPEC TS_SPISIGNALS = FROM "TNMG_SPI" TIG ;
#TIMESPEC TS_CHANNELREGISTERS = FROM "TNMG_CHANREGISTERS" TIG;
TIMESPEC TS_TXTOCHANS = FROM "TNMG_TXTOCHANS" TIG ;
TIMESPEC TS_TXFROMCHANS = FROM "TNMG_TXFROMCHANS" TIG ;