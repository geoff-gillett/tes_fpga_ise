#
package require isim
namespace import isim::*

#TODO move this to isim package
proc writeInt32 { fp signal } {
	set val [getsig $signal dec]
	if { [string equal $val TRUE] } {
		set val 1
  } 
	if { [string equal $val FALSE] } {
		set val 0
  } 
	if { [string equal $val x] } {
		set val 0
	}
	set i [binary format i $val]
	puts -nonewline $fp $i
	return $i
}

proc writeInt64 { fp signal } { 
	set i [getsig $signal bin]
	puts $i
	binary scan [binary format B64 [format %064s $i]] II d1 d2
	set dec [expr {wide($d1)<<32 | wide($d2)}]
	puts -nonewline $fp [binary format w $dec]
	return $dec
}

set fp [open "../input_signals/double_peak" r]
fconfigure $fp -buffering line

set traces [open "../traces" w]
fconfigure $traces -translation binary


restart
wave add /two_stage_fir_TB
wave add /two_stage_fir_TB/UUT

runclks
set i 0


while {[gets $fp hexsample] >= 0} {
#while {$i < 500000} {}
  #gets $fp hexsample
	incr i
	if {![expr $i % 10000]} {
		puts sample:$i
	}
	setsig adc_sample $hexsample hex
	
	writeInt32 $traces adc_sample
	writeInt32 $traces stage1
	writeInt32 $traces stage2
	
	runclks
}

close $fp
close $traces 
