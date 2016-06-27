
set period [show value CLK_PERIOD]

set count [open "../count" w]
fconfigure $count -translation binary

wave add /

restart
onerror {stop}

#run past reset
run [lindex $period 0] [lindex $period 1]]

for {set clk 0} {$clk < 10} {incr clk} {
	run [lindex $period 0] [lindex $period 1]]

	if {[catch {run 0 ns}]} {break}
	puts -nonewline $count [binary format I [show value counters(0) -radix unsigned]]
	if {[expr $clk%1000]} {puts $clk}
}

close $count