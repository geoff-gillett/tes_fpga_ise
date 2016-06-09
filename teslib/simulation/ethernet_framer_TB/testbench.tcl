#measurement_unit_TB
package require xilinx
package require struct
namespace import struct::record::*

#find out if script is sourced into isim or xsim
set is_isim [catch version]
if $is_isim { namespace import ::isim::* } { namespace import ::xsim::* }
namespace import ::sim::*

foreach r [record show record] {
	record delete record $r
}

record define event_flags {
	{new_window 0}
	{tick 0}
	{detection_type 0}
	{height_d 0}
	{timing_d 0}
	{channel 0}
	{height_rel2min 0}
	{peak_count 0}
}

proc flags_2hex {flags} {
	set f [$flags cget -new_window]
	set f [expr $f & ([$flags cget -tick] << 1)]
	set f [expr $f & ([$flags cget -detection_type] << 2)]
	set f [expr $f & ([$flags cget -height_d] << 4)]
	set f [expr $f & ([$flags cget -timing_d] << 6)]
	set f [expr $f & ([$flags cget -channel] << 8)]
	set f [expr $f & ([$flags cget -height_rel2min] << 11)]
	set f [expr $f & ([$flags cget -peak_count] << 12)]
	return [format %.4X $f]
}
												
record define peak_event {
	flags
	height
	minima
	rel_timestamp
}

proc peak_2hex p {
	set f [flags_2hex [$p cget -flags]]
	set t [format %.4X [$p cget -rel_timestamp]]
	set m [format %.4X [$p cget -minima]]
	set h [format %.4X [$p cget -height]]
	return $h$m$f$t
}
 
record define tick_flags {
	{window 0}
	{tick 1}
	{tick_lost 0}
	{events_lost 0}
}

proc tick_flags_2hex {flags} {
	set f [$flags cget -new_window]
	set f [expr $f & ([$flags cget -tick] << 1)]
	set f [expr $f & ([$flags cget -events_lost] << 8)]
	return [format %.4X $f]
}

record define tick_event {
	flags
	{period 0}
	{rel_timestamp 0}
	{timestamp 0}
	{errors 0}
}

proc tick_2hex {p w} {
	if {w==0} {
		set f [flags_2hex [$p cget -flags]]
		set t [format %.4X [$p cget -rel_timestamp]]
		set p [format %.8X [$p cget -period]]
		return $p$f$t
	} elseif {w==1} {
		return [format %.16X [$p cget -timestamp]]
	} elseif {w==2} {
		return [format %.16X [$p cget -errors]]
	} else {puts "w=$w out of range 0-2"}
}


set ethernetstream [open "../ethernetstream" w]
fconfigure $ethernetstream -translation binary

restart

if {$is_isim} {
	wave log /ethernet_framer_TB
	wave log /ethernet_framer_TB/UUT
#	wave add /measurement_unit_TB/UUT/framer
#	wave add /measurement_unit_TB/UUT/baselineEstimator
#	wave add /measurement_unit_TB/UUT/baselineEstimator/mostFrequent
} {
#	log_wave /measurement_unit_TB
#	log_wave /measurement_unit_TB/UUT
#	log_wave /measurement_unit_TB/UUT/baselineEstimator
#	log_wave /measurement_unit_TB/UUT/baselineEstimator/mostFrequent
}

set period [getsig CLK_PERIOD]
setsig mtu 88 unsigned
setsig tick_latency 64 unsigned

run [lindex $period 0] [lindex $period 1]

#baseline registers

set event 0
set clk 1
peak_event peak 
peak configure -flags [event_flags #auto] -height $event -minima $event \
							 -rel_timestamp $event
puts "created" 
puts [peak_2hex peak]
setsig eventstream.data [peak_2hex peak] hex

while {$event < 10} {
	#puts "ready:[getsig eventstream_ready]"
	write_stream $ethernetstream ethernetstream
	run [lindex $period 0] [lindex $period 1]
  incr clk	
  setsig eventstream_valid 1 bin 
	if {[getbool eventstream_ready]} {
#		puts "ready:[getsig eventstream_ready]"
		incr event
		peak configure height $event
		peak configure minima $event
		peak configure rel_timestamp $event
#		puts "$clk:event:$event [peak_2hex peak]"
		set s [peak_2hex peak]
#		puts [string range $s 0 7]
#		puts [string range $s 8 15]
		setsig eventstream.data(63:32) [string range $s 0 7] hex
		setsig eventstream.data(31:0) [string range $s 8 15] hex
	}
}
run [lindex $period 0] [lindex $period 1]

	if {[getbool eventstream_ready]} {
#		puts "ready:[getsig eventstream_ready]"
		incr event
		peak configure height 0
		peak configure minima 0
		peak configure rel_timestamp $event
#		puts "$clk:event:$event [peak_2hex peak]"
		set s [peak_2hex peak]
#		puts [string range $s 0 7]
#		puts [string range $s 8 15]
		setsig eventstream.data(63:32) [string range $s 0 7] hex
		setsig eventstream.data(31:0) [string range $s 8 15] hex
	}


setsig eventstream_valid 0 bin 

close $ethernetstream