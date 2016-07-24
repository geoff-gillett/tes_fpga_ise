#measurement_subsystem_TB
package require xil

#find out if script is sourced into isim or xsim
set is_isim [catch version]
if $is_isim { namespace import ::isim::* } { namespace import ::xsim::* }
namespace import ::sim::*

# set up wave database

restart
vcd dumpfile ../dump.vcd

vcd dumpvars -m / -l 1
vcd dumpvars -m /UUT -l 1
vcd dumpvars -m /UUT/mca -l 1
vcd dumpvars -m /UUT/mca/MCA -l 1
vcd dumpvars -m /UUT/mux -l 1
vcd dumpvars -m /UUT/nopacketgen/enet -l 1
vcd dumpvars -m /UUT/nopacketgen/enet/framer -l 1
vcd dumpvars -m /UUT/nopacketgen/enet/framer/frameRam -l 1

run 4 ms
vcd dumpflush