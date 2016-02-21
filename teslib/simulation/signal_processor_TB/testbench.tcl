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
	if { [string equal $val X] } {
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

set fp [open "../input_signals/short" r]
fconfigure $fp -buffering line

set settings [open "../settings" w]
fconfigure $settings -translation binary

set traces [open "../traces" w]
fconfigure $traces -translation binary

set maximas [open "../maximas" w]
fconfigure $maximas -translation binary

set cfdlow [open "../cfdlow" w]
fconfigure $cfdlow -translation binary

set cfdhigh [open "../cfdhigh" w]
fconfigure $cfdhigh -translation binary

set pulsestarts [open "../pulsestarts" w]
fconfigure $pulsestarts -translation binary

set eventstarts [open "../eventstarts" w]
fconfigure $eventstarts -translation binary

set raw [open "../raw" w]
fconfigure $raw -translation binary

set filtered [open "../filtered" w]
fconfigure $filtered -translation binary

set slope [open "../slope" w]
fconfigure $slope -translation binary

set pulse [open "../pulse" w]
fconfigure $pulse -translation binary

set slopethreshxings [open "../slopethreshxings" w]
fconfigure $slopethreshxings -translation binary

set timeoverflows [open "../timeoverflows" w]
fconfigure $timeoverflows -translation binary

set peakoverflows [open "../peakoverflows" w]
fconfigure $peakoverflows -translation binary

set triggers [open "../triggers" w]
fconfigure $triggers -translation binary

set cfderrors [open "../cfderrors" w]
fconfigure $cfderrors -translation binary

set minimas [open "../minimas" w]
fconfigure $minimas -translation binary

set heights [open "../heights" w]
fconfigure $heights -translation binary

restart
wave add /signal_processor_TB
wave add /signal_processor_TB/UUT
wave add /signal_processor_TB/UUT/slopeXing
wave add /signal_processor_TB/UUT/baselineEstimator
wave add /signal_processor_TB/UUT/baselineEstimator/mostFrequent

runclks
set i 0

writeInt32 $settings registers.dsp.baseline.subtraction
writeInt32 $settings registers.dsp.baseline.offset
writeInt32 $settings registers.dsp.constant_fraction
writeInt32 $settings registers.dsp.pulse_threshold
writeInt32 $settings registers.dsp.slope_threshold 
writeInt32 $settings registers.dsp.baseline.average_order 
writeInt32 $settings UUT/BASELINE_AV_FRAC 
writeInt32 $settings registers.capture.threshold_rel2min
writeInt32 $settings event_type
writeInt32 $settings height_type
writeInt32 $settings trigger_type
close $settings

while {[gets $fp hexsample] >= 0} {
#while {$i < 500000} {}
  #gets $fp hexsample
	incr i
	if {![expr $i % 10000]} {
		puts sample:$i
	}
	setsig adc_sample $hexsample hex
	
	writeInt32 $traces UUT/sample
	writeInt32 $traces UUT/baseline_estimate
	writeInt32 $traces measurements.raw.sample
	writeInt32 $traces measurements.filtered.sample
	writeInt32 $traces measurements.slope.sample
	
	if [getsig measurements.raw.zero_xing] {
		puts -nonewline $raw [binary format i $i]
		writeInt32 $raw measurements.raw.area
		writeInt32 $raw measurements.raw.extrema
	}

	if [getsig measurements.filtered.zero_xing] {
		puts -nonewline $filtered [binary format i $i]
		writeInt32 $filtered measurements.filtered.area
		writeInt32 $filtered measurements.filtered.extrema
	}

	if [getsig measurements.slope.zero_xing] {
		puts -nonewline $slope [binary format i $i]
		writeInt32 $slope measurements.slope.area
		writeInt32 $slope measurements.slope.extrema
	}

	if [getsig measurements.pulse.neg_threshxing] {
		puts -nonewline $pulse [binary format i $i]
		writeInt32 $pulse measurements.pulse.area
		writeInt32 $pulse measurements.pulse.extrema
	}
	
	if [getsig measurements.pulse.pos_threshxing] {
		puts -nonewline $pulsestarts [binary format i $i]
		writeInt32 $pulsestarts measurements.filtered.sample
	}

	if [getsig measurements.slope.pos_threshxing] {
		puts -nonewline $slopethreshxings [binary format i $i]
		writeInt32 $slopethreshxings measurements.filtered.sample
	}
	
	if { [getsig measurements.maxima] } {
		puts -nonewline $maximas [binary format i $i]
		writeInt32 $maximas measurements.raw.sample
		writeInt32 $maximas measurements.filtered.sample
		writeInt32 $maximas measurements.slope.sample
		writeInt32 $maximas measurements.slope.area
	}

	if { [getsig measurements.minima] } {
		puts -nonewline $minimas [binary format i $i]
		writeInt32 $minimas measurements.filtered.sample
	}
	
	if { [getsig measurements.height_valid] } {
		puts -nonewline $heights [binary format i $i]
		writeInt32 $heights measurements.height
	}
	
	if { [getsig measurements.cfd_low] } {
		puts -nonewline $cfdlow [binary format i $i]
		writeInt32 $cfdlow measurements.filtered.sample
	}
	
	if { [getsig measurements.cfd_high] } {
		puts -nonewline $cfdhigh [binary format i $i]
		writeInt32 $cfdhigh measurements.filtered.sample
	}

	if { [getsig measurements.trigger] } {
		puts -nonewline $triggers [binary format i $i]
		writeInt32 $triggers measurements.filtered.sample
	}
	
	if { [getsig measurements.event_start] } {
		puts -nonewline $eventstarts [binary format i $i]
		writeInt32 $eventstarts measurements.filtered.sample
	}
	
	
	if { [getsig cfd_error] } {
		puts -nonewline $cfderrors [binary format i $i]
	}
	
	if { [getsig time_overflow] } {
		puts -nonewline $timeoverflows [binary format i $i]
	}
	
	if { [getsig peak_overflow] } {
		puts -nonewline $peakoverflows [binary format i $i]
	}
	runclks
}

close $fp
close $traces 
close $maximas 
close $minimas 
close $heights 
close $cfdlow 
close $cfdhigh 
close $pulsestarts 
close $triggers
close $raw
close $filtered
close $pulse
close $slope
close $slopethreshxings
close $timeoverflows
close $peakoverflows
close $eventstarts
close $cfderrors
