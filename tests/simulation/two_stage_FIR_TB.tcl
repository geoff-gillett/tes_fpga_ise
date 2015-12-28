#
package require isim
namespace import isim::*
set fp [open "../dsp_TB.long_input" r]
fconfigure $fp -buffering line
set out [open "../dsp_TB.output" w]
set rawmeasurements [open "../dsp_TB.rawmeasurements" w]
set filteredmeasurements [open "../dsp_TB.filteredmeasurements" w]
set slopemeasurements [open "../dsp_TB.slopemeasurements" w]
set mostfrequent [open "../dsp_TB.mostfrequent" w]
set pulsemeasurements [open "../dsp_TB.pulsemeasurements" w]
set pulsestarts [open "../dsp_TB.pulsestarts" w]
set peaks [open "../dsp_TB.peaks" w]
set cfd [open "../dsp_TB.cfd" w]
set slopexings [open "../dsp_TB.slopexings" w]
set settings [open "../dsp_TB.settings" w]
set mftimeout [open "../dsp_TB.mftimeout" w]
restart
wave add /
wave add /dsp_TB
wave add /dsp_TB/UUT
wave add /dsp_TB/UUT/baselineEstimator
wave add /dsp_TB/UUT/baselineEstimator/mostFrequent
wave add /dsp_TB/UUT/baselineEstimator/average
runclks
set i 0
puts -nonewline $settings [getsig baseline_subtraction dec] 
puts -nonewline $settings ","
puts -nonewline $settings [getsig adc_baseline dec] 
puts -nonewline $settings ","
puts -nonewline $settings [getsig constant_fraction dec] 
puts -nonewline $settings ","
puts -nonewline $settings [getsig pulse_threshold dec] 
puts -nonewline $settings ","
puts -nonewline $settings [getsig slope_threshold dec] 
puts -nonewline $settings ","
puts -nonewline $settings [getsig baseline_average_order dec] 
puts -nonewline $settings ","
puts $settings [getsig UUT/BASELINE_AV_FRAC dec] 
close $settings
#while {[gets $fp hexsample] >= 0} {}
while {$i < 500000} {
  gets $fp hexsample
	incr i
	setsig adc_sample $hexsample hex
	puts -nonewline $out [getsig filtered dec]
	puts -nonewline $out ","
	puts -nonewline $out [getsig slope dec]
	puts -nonewline $out ","
	puts -nonewline $out [getsig raw dec]
	puts -nonewline $out ","
	puts $out [getsig UUT/baseline_estimate dec]
	if [getsig new_raw_measurement] {
		puts -nonewline $rawmeasurements [getsig raw_area dec]
		puts -nonewline $rawmeasurements ","
		puts $rawmeasurements [getsig raw_extrema dec]
	}
	if [getsig new_filtered_measurement] {
		puts -nonewline $filteredmeasurements [getsig filtered_area dec]
		puts -nonewline $filteredmeasurements ","
		puts $filteredmeasurements [getsig filtered_extrema dec]
	}
	if [getsig new_slope_measurement] {
		puts -nonewline $slopemeasurements [getsig slope_area dec]
		puts -nonewline $slopemeasurements ","
		puts $slopemeasurements [getsig slope_extrema dec]
	}
	if [getsig UUT/baselineEstimator/new_most_frequent] {
		puts -nonewline $mostfrequent $i
		puts -nonewline $mostfrequent ","
		puts -nonewline $mostfrequent [getsig UUT/baselineEstimator/most_frequent dec]
		puts -nonewline $mostfrequent ","
		if {[string equal [getsig UUT/baselineEstimator/new_mf dec] TRUE]} {
			puts $mostfrequent 1
		} {
			puts $mostfrequent 0
		}
	}
	if [getsig new_pulse_measurement dec] {
		puts -nonewline $pulsemeasurements [getsig pulse_area dec]
		puts -nonewline $pulsemeasurements ","
		puts $pulsemeasurements [getsig pulse_extrema dec]
	}
	if [getsig pulse_detected] {
		puts -nonewline $pulsestarts $i
		puts -nonewline $pulsestarts ","
		puts $pulsestarts [getsig filtered dec]
	}
	if [getsig peak] {
		puts -nonewline $peaks $i
		puts -nonewline $peaks ","
		puts -nonewline $peaks [getsig filtered dec]
		puts -nonewline $peaks ","
		puts -nonewline $peaks [getsig minima dec]
		puts -nonewline $peaks ","
		puts $peaks [getsig slope dec]
	}
	if [getsig cfd] {
		puts -nonewline $cfd $i
		puts -nonewline $cfd ","
		puts $cfd [getsig filtered dec]
	}
	if [getsig slope_threshold_xing] {
		puts -nonewline $slopexings $i 
		puts -nonewline $slopexings ","
		puts -nonewline $slopexings [getsig filtered dec]
		puts -nonewline $slopexings ","
		puts -nonewline $slopexings [getsig slope dec]
	}
	if [getsig UUT/baselineEstimator/mostFrequent/timeout dec] {
		puts $mftimeout $i
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