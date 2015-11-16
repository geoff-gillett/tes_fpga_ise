#
package require isim
namespace import isim::*
set fp [open "../FIR_filters_TB.input" r]
fconfigure $fp -buffering line
set out [open "../FIR_filters_TB.output" w]
restart
runclks
set i 0
while {$i < 100000} {
	gets $fp hexsample
	setsig sample $hexsample hex
	puts -nonewline $out [getsig raw_sample dec]
	puts -nonewline $out ","
	puts -nonewline $out [getsig stage1_sample dec]
	puts -nonewline $out ","
	puts $out [getsig stage2_sample dec]
	runclks
	incr i
}
close $fp
close $out
