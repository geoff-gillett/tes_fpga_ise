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

proc writeInt64 { fp signal } {
	set i [getsig $signal dec]
	puts -nonewline $fp [binary format W $i]
	return $i
}

set fp [open "../input_signals/double_peak" r]
fconfigure $fp -buffering line
set settings [open "../dsp_capture_TB.settings" w]
fconfigure $settings -translation binary
set out [open "../dsp_capture_TB.output" w]
fconfigure $out -translation binary
set peaks [open "../dsp_capture_TB.peaks" w]
fconfigure $peaks -translation binary
set cfdlow [open "../dsp_capture_TB.cfdlow" w]
fconfigure $cfdlow -translation binary
set cfdhigh [open "../dsp_capture_TB.cfdhigh" w]
fconfigure $cfdhigh -translation binary
set pulsestarts [open "../dsp_capture_TB.pulsestarts" w]
fconfigure $pulsestarts -translation binary
set stream [open "../dsp_capture_TB.stream" w]
fconfigure $stream -translation binary
set timing [open "../dsp_capture_TB.timing" w]
fconfigure $timing -translation binary
restart
wave add /
wave add /dsp_capture_TB
wave add /dsp_capture_TB/eventCapture
runclks
set i 0

writeInt32 $settings baseline_subtraction
writeInt32 $settings adc_baseline
writeInt32 $settings constant_fraction
writeInt32 $settings pulse_threshold
writeInt32 $settings slope_threshold 
writeInt32 $settings baseline_average_order 
writeInt32 $settings dspProcessor/BASELINE_AV_FRAC 
writeInt32 $settings rel_to_min
writeInt32 $settings use_cfd_timing
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
	writeInt32 $out filtered
	writeInt32 $out slope
	if [getsig pulse_pos_xing] {
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
		writeInt32 $peaks peak_minima
		writeInt32 $peaks slope
		writeInt32 $peaks slope_area
		writeInt32 $peaks cfd_error
	}
	if { [getsig cfd_low] } {
		puts -nonewline $cfdlow [binary format i $i]
		writeInt32 $cfdlow filtered
	}
	if { [getsig cfd_high] } {
		puts -nonewline $cfdhigh [binary format i $i]
		writeInt32 $cfdhigh filtered
	}
	if { [getsig ready] && [getsig valid] } {
		writeInt32 $stream event_LE(63:32)
		writeInt32 $stream event_LE(31:0)
	}
	if { [getsig enqueue] } {
		puts -nonewline $timing [binary format i $i]
		writeInt32 $timing filtered
	}
	runclks
}
close $fp
close $out
close $pulsestarts
close $peaks
close $cfdlow
close $cfdhigh
close $stream
close $timing
