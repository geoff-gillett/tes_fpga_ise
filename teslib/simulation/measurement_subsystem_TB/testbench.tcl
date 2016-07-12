#measurement_subsystem_TB
package require xil

#find out if script is sourced into isim or xsim
set is_isim [catch version]
if $is_isim { namespace import ::isim::* } { namespace import ::xsim::* }
namespace import ::sim::*

# set up wave database

restart
vcd dumpfile ../vcd.dump

if {$is_isim} {
	vcd dumpvars -u / -l 1
  vcd dumpvars /UUT -l 1
	vcd dumpvars /UUT/mca -l 1
	vcd dumpvars /UUT/mca/MCA -l l
	vcd dumpvars /UUT/mux -l l
	vcd dumpvars /UUT/nopacketgen/enet -l 1
	vcd dumpvars /UUT/nopacketgen/enet/framer -l 1
	vcd dumpvars /UUT/nopacketgen/enet/framer/frameRam -l 1
} {
  log_wave /measurement_subsystem_TB
  log_wave /measurement_subsystem_TB/\\chanGen(0)\\/measurementUnit
  log_wave /measurement_subsystem_TB/mux
  log_wave /measurement_subsystem_TB/enet
  log_wave /measurement_subsystem_TB/cdc
}

run 4 ms
vcd dumpflush