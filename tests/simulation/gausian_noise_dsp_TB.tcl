#
package require isim
namespace import isim::*
package require math::statistics

#set fp [open "../dsp_TB.input" r]
#fconfigure $fp -buffering line
#set out [open "../dsp_TB.output" w]
set rawarea [open "../dsp_TB.rawarea" w]
set signalarea [open "../dsp_TB.signalarea" w]
set slopearea [open "../dsp_TB.slopearea" w]
set rawextrema [open "../dsp_TB.rawextrema" w]
set signalextrema [open "../dsp_TB.signalextrema" w]
set slopeextrema [open "../dsp_TB.slopeextrema" w]
set mostfrequent [open "../dsp_TB.mostfrequent" w]

restart
runclks
set i 0
setsig adc_basline 0

#while {[gets $fp hexsample] >= 0} {}
while {$i < 5000000} {}
  #gets $fp hexsample
	setsig adc_sample $hexsample hex
	puts -nonewline $out [getsig filtered dec]
	puts -nonewline $out ","
	puts -nonewline $out [getsig slope dec]
	puts -nonewline $out ","
	puts -nonewline $out [getsig raw dec]
	puts -nonewline $out ","
	puts $out [getsig baseline dec]
	if [getsig new_raw_area] {
		puts $rawarea [getsig raw_area dec]
		puts $rawextrema [getsig raw_extrema dec]
	}
	if [getsig new_stage1_area] {
		puts $signalarea [getsig stage1_area dec]
		puts $signalextrema [getsig stage1_extrema dec]
	}
	if [getsig new_stage2_area] {
		puts $slopearea [getsig stage2_area dec]
		puts $slopeextrema [getsig stage2_extrema dec]
	}
	if [getsig UUT/baselineEstimator/new_most_frequent] {
		puts $mostfrequent [getsig UUT/baselineEstimator/most_frequent dec]
	}
	runclks
	incr i
}
close $fp
close $out
close $rawarea
close $slopearea
close $signalarea
close $rawextrema
close $signalextrema
close $slopeextrema
close $mostfrequent
