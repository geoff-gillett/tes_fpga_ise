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
	#puts $t
	set m [format %.4X [$p cget -minima]]
	set h [format %.4X [$p cget -height]]
	return $h$m$f$t
}
 
record define tick_flags {
	{new_window 0}
	{tick 1}
	{tick_lost 0}
	{events_lost 0}
}

proc tick_flags_2hex {flags} {
	set f [$flags cget -new_window]
	set f [expr $f | ([$flags cget -tick] << 1)]
#	puts [$flags cget -tick]
	set f [expr $f | ([$flags cget -events_lost] << 8)]
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
	if {$w==0} {
		set f [tick_flags_2hex [$p cget -flags]]
		set t [format %.4X [$p cget -rel_timestamp]]
		set p [format %.8X [$p cget -period]]
		return $p$f$t
	} elseif {$w==1} {
		return [format %.16X [$p cget -timestamp]]
	} elseif {$w==2} {
		return [format %.16X [$p cget -errors]]
	} else {puts "w=$w out of range 0-2"}
}

proc write_bytestream {fp} {
	if {[getbool bytestream_valid] && [getbool bytestream_ready]} {
		write_signal $fp bytestream unsigned c
		write_signal $fp bytestream_last unsigned c
	}
}

set ethernetstream [open "../ethernetstream" w]
fconfigure $ethernetstream -translation binary
set bytestream [open "../bytestream" w]
fconfigure $bytestream -translation binary

restart

if {$is_isim} {
	#isim set arraydisplaylength 72
	wave log /ethernet_framer_TB
	wave log /ethernet_framer_TB/UUT
	wave log /ethernet_framer_TB/enetCdc
#	wave add /measurement_unit_TB/UUT/framer
#	wave add /measurement_unit_TB/UUT/baselineEstimator
#	wave add /measurement_unit_TB/UUT/baselineEstimator/mostFrequent
} {
#	log_wave /measurement_unit_TB
#	log_wave /measurement_unit_TB/UUT
#	log_wave /measurement_unit_TB/UUT/baselineEstimator
#	log_wave /measurement_unit_TB/UUT/baselineEstimator/mostFrequent
}

set period [getsig SIGNAL_PERIOD]
setsig mtu 88 unsigned
setsig tick_latency 100 unsigned
set tick_period 100

setsig eventdata 0 hex
setsig eventlast 0 bin
setsig eventstream_valid 1 bin

setsig mcadata 0 hex
setsig mcalast 0 bin
setsig mcastream_valid 0 bin

#run past reset
run [lindex $period 0] [lindex $period 1]
run [lindex $period 0] [lindex $period 1]
setsig reset 0 bin
setsig bytestream_ready 1 bin

set event_count 0
set mca_count 0
set clk 0

peak_event peak 
peak configure -flags [event_flags #auto] -height $event_count \
							 -minima $event_count -rel_timestamp $clk

tick_event tick
tick configure -flags [tick_flags #auto] -period $tick_period \
							 -rel_timestamp $clk -timestamp $clk -errors 0

							 
for {set clk 0} {$clk < 500} {incr clk} {
	write_stream $ethernetstream ethernetstream
	if {~[expr $clk%2]} {write_bytestream $bytestream}
	if {[expr $clk%$tick_period] == 0 } {
		set tickword 0
		tick configure -rel_timestamp $clk -timestamp $clk
	}
	if {$tickword < 3 } {
		setsig eventstream_valid 1 bin 
		set s [tick_2hex tick $tickword]
#			puts "tick:$clk $s"
    setsig eventdata $s hex
    if {$tickword == 2} {setsig eventlast 1 bin} {setsig eventlast 0 bin}
		if {[getbool eventstream_ready]} {
			incr tickword
		}
		
	} {	
		if {[expr $clk%100] < 11} {
			setsig eventstream_valid 1 bin 
      peak configure -height $event_count -minima $event_count \
      							 -rel_timestamp $clk
      set s [peak_2hex peak]
  #		puts $clk
      #puts $s
      setsig eventdata $s hex
      setsig eventlast 1 bin
    } {
      setsig eventstream_valid 0 bin
      setsig eventlast 0 bin
    }
	}
	
	if {[expr $mca_count%100 == 0]} {
		setsig mcastream_valid 0 bin
	}
	
	if {[expr $clk%200] == 100} {
		setsig mcastream_valid 1 bin
	}
	
	if {[getbool mcastream_valid]} {
    set s [format %.16X $mca_count]
    #puts $s
    setsig mcadata $s hex
    if {[expr $mca_count%100 == 99]} {
      setsig mcalast 1 bin
    } {
      setsig mcalast 0 bin
    }
	}

	#puts "run"
	
	if {[getbool eventstream_valid] && [getbool eventstream_ready]} {
		incr event_count
		#puts "event:$event_count"
	}
	
	if {[getbool mcastream_valid] && [getbool mcastream_ready]} {
		incr mca_count
		#puts "mca:$mca_count"
	}
	
	run [lindex $period 0] [lindex $period 1]
}

close $ethernetstream
close $bytestream