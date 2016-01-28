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
	binary scan [binary format B64 [format %064s $i]] II d1 d2
	set dec [expr {wide($d1)<<32 | wide($d2)}]
	puts -nonewline $fp [binary format w $dec]
	return $dec
}

set fp [open "../input_signals/double_peak" r]
fconfigure $fp -buffering line
set settings [open "../settings" w]
fconfigure $settings -translation binary
set traces [open "../traces" w]
fconfigure $traces -translation binary
set peaks [open "../peaks" w]
fconfigure $peaks -translation binary
set cfdlow [open "../cfdlow" w]
fconfigure $cfdlow -translation binary
set cfdhigh [open "../cfdhigh" w]
fconfigure $cfdhigh -translation binary
set pulsestarts [open "../pulsestarts" w]
fconfigure $pulsestarts -translation binary
set stream [open "../eventstream" w]
fconfigure $stream -translation binary
set muxstarts [open "../muxstarts" w]
fconfigure $muxstarts -translation binary
set rawmeasurements [open "../rawmeasurements" w]
fconfigure $rawmeasurements -translation binary
set filteredmeasurements [open "filteredmeasurements" w]
fconfigure $filteredmeasurements -translation binary
set slopemeasurements [open "../slopemeasurements" w]
fconfigure $slopemeasurements -translation binary
set slopexings [open "../slopexings" w]
fconfigure $slopexings -translation binary
set overflow [open "../overflow" w]
fconfigure $overflow -translation binary

restart
wave add /measurement_TB
wave add /measurement_TB/UUT
wave add /measurement_TB/UUT/dspProcessor
wave add /measurement_TB/UUT/framer

runclks
set i 0

writeInt32 $settings registers.dsp.baseline.subtraction
writeInt32 $settings registers.dsp.baseline.offset
writeInt32 $settings registers.dsp.constant_fraction
writeInt32 $settings registers.dsp.pulse_threshold
writeInt32 $settings registers.dsp.slope_threshold 
writeInt32 $settings registers.dsp.baseline.average_order 
writeInt32 $settings UUT/dspProcessor/BASELINE_AV_FRAC 
writeInt32 $settings registers.capture.rel_to_min
writeInt32 $settings registers.capture.use_cfd_timing
writeInt32 $settings height_slv
close $settings

while {[gets $fp hexsample] >= 0} {
#while {$i < 500000} {}
  #gets $fp hexsample
	incr i
	if {![expr $i % 10000]} {
		puts sample:$i
	}
	setsig adc_sample $hexsample hex
	
	writeInt32 $traces measurements.filtered_signal
	writeInt32 $traces measurements.slope_signal
	
	if [getsig measurements.raw.valid] {
		puts -nonewline $rawmeasurements [binary format i $i]
		writeInt32 $rawmeasurements measurements.raw.area
		writeInt32 $rawmeasurements measurements.raw.extrema
	}
	if [getsig measurements.filtered.valid] {
		puts -nonewline $filteredmeasurements [binary format i $i]
		writeInt32 $filteredmeasurements measurements.filtered.area
		writeInt32 $filteredmeasurements measurements.filtered.extrema
	}
	if [getsig measurements.slope.valid] {
		puts -nonewline $slopemeasurements [binary format i $i]
		writeInt32 $slopemeasurements measurements.slope.area
		writeInt32 $slopemeasurements measurements.slope.extrema
	}
	if [getsig measurements.pulse_start] {
		puts -nonewline $pulsestarts [binary format i $i]
		writeInt32 $pulsestarts measurements.filtered_signal
	}
	if [getsig measurements.peak_start] {
		puts -nonewline $peaks [binary format i $i]
		writeInt32 $peaks measurements.filtered_signal
	}
	if { [getsig measurements.peak] } {
		puts -nonewline $peaks [binary format i $i]
		writeInt32 $peaks measurements.filtered_signal
		writeInt32 $peaks measurements.slope_signal
		writeInt32 $peaks measurements.slope.area
		writeInt32 $peaks cfd_error
	}
	if { [getsig measurements.cfd_low] } {
		puts -nonewline $cfdlow [binary format i $i]
		writeInt32 $cfdlow measurements.filtered_signal
	}
	if { [getsig measurements.cfd_high] } {
		puts -nonewline $cfdhigh [binary format i $i]
		writeInt32 $cfdhigh measurements.filtered_signal
	}
	if { [getsig ready] && [getsig valid] } {
		puts [writeInt64 $stream eventstream.data]
	}
	if { [getsig start] } {
		puts -nonewline $muxstarts [binary format i $i]
		#writeInt32 $muxstarts measurement.filtered_signal
	}
	runclks
}

close $fp
close $traces 
close $peaks 
close $cfdlow 
close $cfdhigh 
close $pulsestarts 
close $stream 
close $muxstarts 
close $rawmeasurements 
close $filteredmeasurements 
close $slopemeasurements 
close $slopexings 
close $overflow
