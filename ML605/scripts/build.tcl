# takes top and implementation name as args
# use src instead of source to invoke from planahead tcl with arguments
package require xilinx
set ::env(XIL_PAR_DESIGN_CHECK_VERBOSE) 1
exec make 
if {$argc==0} {
	set implementation default
	set top TES_digitiser
} elseif {$argc==1} {
	set top [lindex $argv 0]
	set implementation default
} elseif {$argc==2} {
	set top [lindex $argv 0]
	set implementation [lindex $argv 1]
} 
if ![file exists ../PlanAhead/TES_digitiser.ppr] {
	source create_planahead.tcl
} else {
  if {[catch {current_project} ] } {open_project ../PlanAhead/TES_digitiser.ppr}
}
update_version TES_synth
build_bitstream $top TES_synth $implementation
if {[string equal [get_property status [get_runs $implementation]] \
    "Bitgen Complete!"]} {
]
  if ![file exists ../Bitstreams/$implementation] {
    file mkdir ../Bitstreams/$implementation
  }
	file copy -force \
		../PlanAhead/TES_digitiser.runs/$implementation/$top.bit \
		../Bitstreams/$implementation
}