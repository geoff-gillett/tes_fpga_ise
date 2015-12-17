package require isim
namespace import isim::*
package require math::statistics

set noise [open "../baseline_estimator_TB.input" w]
set mf [open "../baseline_estimator_TB.mostfrequent" w]
set av [open "../baseline_estimator_TB.baseline" w]

set ::rseed 1000

restart 
set i 0
runclks 
 while {$i < 500000} {
	 incr i
	 set s [math::statistics::random-normal 0 80 1]
	 set si [expr round($s)]
	 puts $noise $si
	 setsig sample $si dec
	 runclks 
	 if [getsig UUT/new_most_frequent] {
		 puts -nonewline $mf $i
		 puts -nonewline $mf ","
		 puts $mf [getsig UUT/most_frequent dec]
	 }
	 puts $av [getsig baseline_estimate dec]
 }
 close $noise
 close $mf
 close $av