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
	return i
}

set fp [open "../dsp_TB.long_input" r]
fconfigure $fp -buffering line
set out [open "../dsp_TB.output" w]
fconfigure $out -translation binary
set rawmeasurements [open "../dsp_TB.rawmeasurements" w]
fconfigure $rawmeasurements -translation binary
set filteredmeasurements [open "../dsp_TB.filteredmeasurements" w]
fconfigure $filteredmeasurements -translation binary
set slopemeasurements [open "../dsp_TB.slopemeasurements" w]
fconfigure $slopemeasurements -translation binary
set mostfrequent [open "../dsp_TB.mostfrequent" w]
fconfigure $mostfrequent -translation binary
set pulsemeasurements [open "../dsp_TB.pulsemeasurements" w]
fconfigure $pulsemeasurements -translation binary
set pulsestarts [open "../dsp_TB.pulsestarts" w]
fconfigure $pulsestarts -translation binary
set peaks [open "../dsp_TB.peaks" w]
fconfigure $peaks -translation binary
set cfd [open "../dsp_TB.cfd" w]
fconfigure $cfd -translation binary
set slopexings [open "../dsp_TB.slopexings" w]
fconfigure $slopexings -translation binary
set settings [open "../dsp_TB.settings" w]
fconfigure $settings -translation binary
set mftimeout [open "../dsp_TB.mftimeout" w]
fconfigure $mftimeout -translation binary
restart
wave add /
wave add /dsp_TB
wave add /dsp_TB/UUT
wave add /dsp_TB/UUT/baselineEstimator
wave add /dsp_TB/UUT/baselineEstimator/mostFrequent
wave add /dsp_TB/UUT/baselineEstimator/average
runclks
set i 0

writeInt32 $settings baseline_subtraction
writeInt32 $settings adc_baseline
writeInt32 $settings constant_fraction
writeInt32 $settings pulse_threshold
writeInt32 $settings slope_threshold 
writeInt32 $settings baseline_average_order 
writeInt32 $settings UUT/BASELINE_AV_FRAC 
close $settings
while {[gets $fp hexsample] >= 0} {
#while {$i < 500000} {}
  #gets $fp hexsample
	incr i
	if {![expr $i % 10000]} {
		puts sample:$i
	}
	setsig adc_sample $hexsample hex
	writeInt32 $out filtered
	writeInt32 $out slope
	writeInt32 $out UUT/stage1_input
	writeInt32 $out UUT/sample
	writeInt32 $out UUT/baseline_estimate
	if [getsig new_raw_measurement] {
		writeInt32 $rawmeasurements raw_area
		writeInt32 $rawmeasurements raw_extrema
	}
	if [getsig new_filtered_measurement] {
		writeInt32 $filteredmeasurements filtered_area
		writeInt32 $filteredmeasurements filtered_extrema
	}
	if [getsig new_slope_measurement] {
		writeInt32 $slopemeasurements slope_area
		writeInt32 $slopemeasurements slope_extrema
	}
	if [getsig UUT/baselineEstimator/new_most_frequent] {
		puts -nonewline $mostfrequent [binary format i $i]
		writeInt32 $mostfrequent UUT/baselineEstimator/most_frequent
		writeInt32 $mostfrequent UUT/baselineEstimator/new_mf
	}
	if [getsig new_pulse_measurement dec] {
		puts -nonewline $pulsemeasurements [binary format i $i]
		writeInt32 $pulsemeasurements pulse_area
		writeInt32 $pulsemeasurements pulse_extrema
	}
	if [getsig pulse_detected] {
		puts -nonewline $pulsestarts [binary format i $i]
		writeInt32 $pulsestarts filtered
	}
	if [getsig peak_start] {
		puts -nonewline $peaks [binary format i $i]
		writeInt32 $peaks filtered
	}
	if { [getsig peak] } {
		puts -nonewline $peaks [binary format i $i]
		writeInt32 $peaks filtered
		writeInt32 $peaks minima
		writeInt32 $peaks slope
		writeInt32 $peaks slope_area
		writeInt32 $peaks cfd_error
	}
	if [getsig cfd] {
		puts -nonewline $cfd [binary format i $i]
		writeInt32 $cfd filtered
	}
	if [getsig slope_threshold_xing] {
		puts -nonewline $slopexings [binary format i $i]
		writeInt32 $slopexings filtered
		writeInt32 $slopexings slope
	}
	if [getsig UUT/baselineEstimator/mostFrequent/timeout dec] {
		puts -nonewline $mftimeout [binary format i $i]
	}
	runclks
}
close $fp
close $out
close $rawmeasurements
close $slopemeasurements
close $filteredmeasurements
close $mostfrequent
close $pulsemeasurements
close $pulsestarts
close $peaks
close $cfd
close $slopexings
close $mftimeout