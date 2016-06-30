#measurement_subsystem_TB
package require xil

#find out if script is sourced into isim or xsim
set is_isim [catch version]
if $is_isim { namespace import ::isim::* } { namespace import ::xsim::* }
namespace import ::sim::*

# set up wave database
if {$is_isim} {
  wave log /measurement_subsystem_TB
  wave log /measurement_subsystem_TB/enet
	wave log /measurement_subsystem_TB/mca
} {
  log_wave /measurement_subsystem_TB
  log_wave /measurement_subsystem_TB/\\chanGen(0)\\/measurementUnit
  log_wave /measurement_subsystem_TB/mux
  log_wave /measurement_subsystem_TB/enet
  log_wave /measurement_subsystem_TB/cdc
}

restart
