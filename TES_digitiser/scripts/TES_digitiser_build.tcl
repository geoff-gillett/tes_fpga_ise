# takes implementation name as an arg
# use src instead of source to invoke from planahead tcl
package require xilinx
if {$argc==0} {set implementation xe_n} {set implementation [lindex $argv 0]} 
if ![file exists ../PlanAhead/TES_digitiser.ppr] {
	source create_planahead.tcl
} else {
  if [catch {current_project}] {open_project ../PlanAhead/TES_digitiser.ppr}
}
exec make ../../channel/PSM/channel_program.vhd 
exec make ../../control_unit/PSM/IO_controller_program.vhd
update_version TES_synth
build_bitstream TES_digitiser TES_synth $implementation
if ![file exists ../Bitstreams] {
	file mkdir {../Bitstreams}
}
file copy -force \
     ../PlanAhead/TES_digitiser.runs/$implementation/TES_digitiser.bit \
		 ../Bitstreams