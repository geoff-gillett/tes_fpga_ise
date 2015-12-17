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
restart
wave add /
wave add /dsp_TB
wave add /dsp_TB/UUT
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
puts $settings [getsig slope_threshold dec] 
close $settings
while {[gets $fp hexsample] >= 0} {
#while {$i < 50000} {}
#  gets $fp hexsample
	incr i
	setsig adc_sample $hexsample hex
	puts -nonewline $out [getsig filtered dec]
	puts -nonewline $out ","
	puts -nonewline $out [getsig slope dec]
	puts -nonewline $out ","
	puts -nonewline $out [getsig raw dec]
	puts -nonewline $out ","
	puts $out [getsig baseline dec]
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
		puts $mostfrequent [getsig UUT/baselineEstimator/most_frequent dec]
	}
	if [getsig new_pulse_measurement dec] {
		puts -nonewline $pulsemeasurements [getsig pulse_area dec]
		puts -nonewline $pulsemeasurements ","
		puts -nonewline $pulsemeasurements [getsig pulse_extrema dec]
		puts -nonewline $pulsemeasurements ","
		puts $pulsemeasurements [getsig pulse_length dec]
	}
	if [getsig pulse_detected] {
		puts $pulsestarts $i
	}
	if [getsig peak] {
		puts $peaks $i
	}
	if [getsig cfd] {
		puts $cfd $i
	}
	if [getsig slope_threshold_xing] {
		puts $slopexings $i 
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