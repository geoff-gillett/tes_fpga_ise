#measurement_subsystem_TB
package require xil

#find out if script is sourced into isim or xsim
set is_isim [catch version]
if $is_isim { namespace import ::isim::* } { namespace import ::xsim::* }
namespace import ::sim::*

# set up wave database


log_wave -r [get_objects /measurement_subsystem_TB/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/mux/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/mux/buffers/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/enet/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/mca/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/mca/MCA/*]
log_wave -r [get_objects /measurement_subsystem_TB/UUT/mca/MCA/MCA/*]

current_scope /measurement_subsystem_TB/UUT/\\tesChannel(0)\\/processingChannel
log_wave -r [get_objects]
current_scope /measurement_subsystem_TB/UUT/\\tesChannel(0)\\/processingChannel/framer
log_wave -r [get_objects]
current_scope /measurement_subsystem_TB/UUT/\\tesChannel(0)\\/processingChannel/measure
log_wave -r [get_objects]
