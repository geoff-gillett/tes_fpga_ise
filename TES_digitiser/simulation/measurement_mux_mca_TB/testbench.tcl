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
	puts $i
	binary scan [binary format B64 [format %064s $i]] II d1 d2
	set dec [expr {wide($d1)<<32 | wide($d2)}]
	puts -nonewline $fp [binary format w $dec]
	return $dec
}

set fp [open "../input_signals/double_peak" r]
fconfigure $fp -buffering line

set settings0 [open "../settings0" w]
fconfigure $settings0 -translation binary
set settings1 [open "../settings1" w]
fconfigure $settings1 -translation binary

set mcasettings [open "../mcasettings" w]
fconfigure $mcasettings -translation binary

set traces0 [open "../traces0" w]
fconfigure $traces0 -translation binary
set traces1 [open "../traces1" w]
fconfigure $traces1 -translation binary

set peaks0 [open "../peaks0" w]
fconfigure $peaks0 -translation binary
set peaks1 [open "../peaks1" w]
fconfigure $peaks1 -translation binary

set cfdlow0 [open "../cfdlow0" w]
fconfigure $cfdlow0 -translation binary
set cfdlow1 [open "../cfdlow1" w]
fconfigure $cfdlow1 -translation binary

set cfdhigh0 [open "../cfdhigh0" w]
fconfigure $cfdhigh0 -translation binary
set cfdhigh1 [open "../cfdhigh1" w]
fconfigure $cfdhigh1 -translation binary

set pulsestarts0 [open "../pulsestarts0" w]
fconfigure $pulsestarts0 -translation binary
set pulsestarts1 [open "../pulsestarts1" w]
fconfigure $pulsestarts1 -translation binary

set stream [open "../eventstream" w]
fconfigure $stream -translation binary

set timing0 [open "../timing0" w]
fconfigure $timing0 -translation binary
set timing1 [open "../timing1" w]
fconfigure $timing1 -translation binary

set rawmeasurements0 [open "../rawmeasurements0" w]
fconfigure $rawmeasurements0 -translation binary
set rawmeasurements1 [open "../rawmeasurements1" w]
fconfigure $rawmeasurements1 -translation binary

set filteredmeasurements0 [open "filteredmeasurements0" w]
fconfigure $filteredmeasurements0 -translation binary
set filteredmeasurements1 [open "filteredmeasurements1" w]
fconfigure $filteredmeasurements1 -translation binary

set slopemeasurements0 [open "../slopemeasurements0" w]
fconfigure $slopemeasurements0 -translation binary
set slopemeasurements1 [open "../slopemeasurements1" w]
fconfigure $slopemeasurements1 -translation binary

set pulsemeasurements0 [open "../puslemeasurements0" w]
fconfigure $pulsemeasurements0 -translation binary
set pulsemeasurements1 [open "../puslemeasurements1" w]
fconfigure $pulsemeasurements1 -translation binary

set slopexings0 [open "../slopexings0" w]
fconfigure $slopexings0 -translation binary
set slopexings1 [open "../slopexings1" w]
fconfigure $slopexings1 -translation binary

set overflow0 [open "../overflow0" w]
fconfigure $overflow0 -translation binary
set overflow1 [open "../overflow1" w]
fconfigure $overflow1 -translation binary

set mcastream [open "../mcastream" w]
fconfigure $mcastream -translation binary

restart
wave add /measurement_mux_mca_TB
wave add /measurement_mux_mca_TB/eventstreamMux
wave add /measurement_mux_mca_TB/mca
wave add /measurement_mux_mca_TB/\\changen(0)\\/measurement

runclks
set i 0

writeInt32 $settings0 measurement_registers(0).dsp.baseline.subtraction
writeInt32 $settings1 measurement_registers(1).dsp.baseline.subtraction
writeInt32 $settings0 measurement_registers(0).dsp.baseline.offset
writeInt32 $settings1 measurement_registers(1).dsp.baseline.offset
writeInt32 $settings0 measurement_registers(0).dsp.constant_fraction
writeInt32 $settings1 measurement_registers(1).dsp.constant_fraction
writeInt32 $settings0 measurement_registers(0).dsp.pulse_threshold
writeInt32 $settings1 measurement_registers(1).dsp.pulse_threshold
writeInt32 $settings0 measurement_registers(0).dsp.slope_threshold 
writeInt32 $settings1 measurement_registers(1).dsp.slope_threshold 
writeInt32 $settings0 measurement_registers(0).dsp.baseline.average_order 
writeInt32 $settings1 measurement_registers(1).dsp.baseline.average_order 
writeInt32 $settings0 \\changen(0)\\/measurement/SignalProcessor/BASELINE_AV_FRAC 
writeInt32 $settings1 \\changen(1)\\/measurement/SignalProcessor/BASELINE_AV_FRAC 
writeInt32 $settings0 measurement_registers(0).capture.rel_to_min
writeInt32 $settings1 measurement_registers(1).capture.rel_to_min
writeInt32 $settings0 measurement_registers(0).capture.use_cfd_timing
writeInt32 $settings1 measurement_registers(1).capture.use_cfd_timing
writeInt32 $settings0 height_unsigneds(0)
writeInt32 $settings1 height_unsigneds(1)

close $settings0
close $settings1

set initialised 0
set toggle 0

while {[gets $fp hexsample] >= 0} {
#while {$i < 500000} {}
  #gets $fp hexsample
	incr i
	if {![expr $i % 10000]} {
		puts sample:$i
	}
	setsig adc_sample $hexsample hex
	
	writeInt32 $traces0 measurements(0).filtered_signal
	writeInt32 $traces0 measurements(0).slope_signal
	writeInt32 $traces1 measurements(1).filtered_signal
	writeInt32 $traces1 measurements(1).slope_signal

	if {$toggle} {
		setsig mca_update_asap 0
		setsig mca_update_on_completion 0
		set toggle 0
	}
	
	if {[string equal [getsig mca_initialising] TRUE] && ~$initialised } {
		set initialised 1
		setsig mca_update_asap 1
		set toggle 1
		pus "MCA Initialised"
	}
	
	if [getsig measurements(0).raw.valid] {
		puts -nonewline $rawmeasurements0 [binary format i $i]
		writeInt32 $rawmeasurements0 measurements(0).raw.area
		writeInt32 $rawmeasurements0 measurements(0).raw.extrema
	}
	if [getsig measurements(1).raw.valid] {
		puts -nonewline $rawmeasurements1 [binary format i $i]
		writeInt32 $rawmeasurements1 measurements(1).raw.area
		writeInt32 $rawmeasurements1 measurements(1).raw.extrema
	}

	if [getsig measurements(0).filtered.valid] {
		puts -nonewline $filteredmeasurements0 [binary format i $i]
		writeInt32 $filteredmeasurements0 measurements(0).filtered.area
		writeInt32 $filteredmeasurements0 measurements(0).filtered.extrema
	}
	if [getsig measurements(1).filtered.valid] {
		puts -nonewline $filteredmeasurements1 [binary format i $i]
		writeInt32 $filteredmeasurements1 measurements(1).filtered.area
		writeInt32 $filteredmeasurements1 measurements(1).filtered.extrema
	}

	if [getsig measurements(0).filtered.valid] {
		puts -nonewline $filteredmeasurements0 [binary format i $i]
		writeInt32 $filteredmeasurements0 measurements(0).filtered.area
		writeInt32 $filteredmeasurements0 measurements(0).filtered.extrema
	}
	if [getsig measurements(1).filtered.valid] {
		puts -nonewline $filteredmeasurements1 [binary format i $i]
		writeInt32 $filteredmeasurements1 measurements(1).filtered.area
		writeInt32 $filteredmeasurements1 measurements(1).filtered.extrema
	}
	
	if [getsig measurements(0).slope.valid] {
		puts -nonewline $slopemeasurements0 [binary format i $i]
		writeInt32 $slopemeasurements0 measurements(0).slope.area
		writeInt32 $slopemeasurements0 measurements(0).slope.extrema
	}
	if [getsig measurements(1).slope.valid] {
		puts -nonewline $slopemeasurements1 [binary format i $i]
		writeInt32 $slopemeasurements1 measurements(1).slope.area
		writeInt32 $slopemeasurements1 measurements(1).slope.extrema
	}

	if [getsig measurements(0).pulse.valid] {
		puts -nonewline $pulsemeasurements0 [binary format i $i]
		writeInt32 $pulsemeasurements0 measurements(0).pulse.area
		writeInt32 $pulsemeasurements0 measurements(0).pulse.extrema
	}
	if [getsig measurements(0).pulse.valid] {
		puts -nonewline $pulsemeasurements0 [binary format i $i]
		writeInt32 $pulsemeasurements0 measurements(0).pulse.area
		writeInt32 $pulsemeasurements0 measurements(0).pulse.extrema
	}
	
	if [getsig measurements(0).pulse_start] {
		puts -nonewline $pulsestarts0 [binary format i $i]
		writeInt32 $pulsestarts0 measurements(0).filtered_signal
	}
	if [getsig measurements(1).pulse_start] {
		puts -nonewline $pulsestarts1 [binary format i $i]
		writeInt32 $pulsestarts1 measurements(1).filtered_signal
	}

	if [getsig measurements(0).slope_xing] {
		puts -nonewline $slopexings0 [binary format i $i]
		writeInt32 $slopexings0 measurements(0).filtered_signal
	}
	if [getsig measurements(1).slope_xing] {
		puts -nonewline $slopexings1 [binary format i $i]
		writeInt32 $slopexings1 measurements(1).filtered_signal
	}
	
	if [getsig measurements(0).peak_start] {
		puts -nonewline $peaks0 [binary format i $i]
		writeInt32 $peaks0 measurements(0).filtered_signal
	}
	if [getsig measurements(1).peak_start] {
		puts -nonewline $peaks1 [binary format i $i]
		writeInt32 $peaks1 measurements(1).filtered_signal
	}

	if { [getsig measurements(0).peak] } {
		puts -nonewline $peaks0 [binary format i $i]
		writeInt32 $peaks0 measurements(0).filtered_signal
		writeInt32 $peaks0 measurements(0).slope_signal
		writeInt32 $peaks0 measurements(0).slope.area
		writeInt32 $peaks0 cfd_errors(0)
	}
	if { [getsig measurements(1).peak] } {
		puts -nonewline $peaks0 [binary format i $i]
		writeInt32 $peaks1 measurements(1).filtered_signal
		writeInt32 $peaks1 measurements(1).slope_signal
		writeInt32 $peaks1 measurements(1).slope.area
		writeInt32 $peaks1 cfd_errors(1)
	}

	if { [getsig measurements(0).cfd_low] } {
		puts -nonewline $cfdlow0 [binary format i $i]
		writeInt32 $cfdlow0 measurements(0).filtered_signal
	}
	if { [getsig measurements(1).cfd_low] } {
		puts -nonewline $cfdlow1 [binary format i $i]
		writeInt32 $cfdlow1 measurements(1).filtered_signal
	}

	if { [getsig measurements(0).cfd_high] } {
		puts -nonewline $cfdhigh0 [binary format i $i]
		writeInt32 $cfdhigh0 measurements(0).filtered_signal
	}
	if { [getsig measurements(1).cfd_high] } {
		puts -nonewline $cfdhigh1 [binary format i $i]
		writeInt32 $cfdhigh1 measurements(1).filtered_signal
	}

	if { [getsig eventstream_ready] && [getsig eventstream_valid] } {
		puts "sample $i:stream [getsig eventstream.data hex]"
		writeInt32 $stream eventstream.data(31:0)
		writeInt32 $stream eventstream.data(63:32)
	}
	
	if { [getsig mcastream_ready] && [getsig mcastream_valid] } {
		writeInt32 $mcastream eventstream.data(31:0)
		writeInt32 $mcastream eventstream.data(63:32)
	}

	if { [getsig starts(0)] } {
		puts -nonewline $timing0 [binary format i $i]
		#writeInt32 $muxstarts measurement.filtered_signal
	}
	if { [getsig starts(1)] } {
		puts -nonewline $timing1 [binary format i $i]
		#writeInt32 $muxstarts measurement.filtered_signal
	}
	
	if { [getsig overflows(0)] } {
		puts -nonewline $overflow0 [binary format i $i]
	}
	if { [getsig overflows(1)] } {
		puts -nonewline $overflow1 [binary format i $i]
	}
	
	runclks
}

close $fp
close $traces0 
close $traces1 
close $peaks0 
close $peaks1 
close $cfdlow0 
close $cfdlow1 
close $cfdhigh0 
close $cfdhigh1 
close $pulsestarts0 
close $pulsestarts1 
close $stream 
close $timing0 
close $timing1 
close $rawmeasurements0 
close $rawmeasurements1 
close $filteredmeasurements0 
close $filteredmeasurements1 
close $slopemeasurements0 
close $slopemeasurements1 
close $slopexings0 
close $slopexings1 
close $overflow0
close $overflow1
