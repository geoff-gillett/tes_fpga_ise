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

set chansettings [open "../chansettings" w]
fconfigure $chansettings -translation binary

set mcasettings [open "../mcasettings" w]
fconfigure $mcasettings -translation binary

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

set timing [open "../timing" w]
fconfigure $timing -translation binary

set rawmeasurements [open "../rawmeasurements" w]
fconfigure $rawmeasurements -translation binary

set filteredmeasurements [open "filteredmeasurements" w]
fconfigure $filteredmeasurements -translation binary

set slopemeasurements [open "../slopemeasurements" w]
fconfigure $slopemeasurements -translation binary

set pulsemeasurements [open "../puslemeasurements0" w]
fconfigure $pulsemeasurements -translation binary

set slopexings [open "../slopexings" w]
fconfigure $slopexings -translation binary

set overflow [open "../overflow" w]
fconfigure $overflow -translation binary

set mcastream [open "../mcastream" w]
fconfigure $mcastream -translation binary

set ethstream [open "../ethstream" w]
fconfigure $ethstream -translation binary
restart
wave add /meas_mux_mca_eth_TB
wave add /meas_mux_mca_eth_TB/eventstreamMux
wave add /meas_mux_mca_eth_TB/mca
wave add /meas_mux_mca_eth_TB/\\changen(0)\\/measurement
wave add /meas_mux_mca_eth_TB/ethernet

runclks
set i 0

writeInt32 $chansettings measurement_registers(0).dsp.baseline.subtraction
writeInt32 $chansettings measurement_registers(0).dsp.baseline.offset
writeInt32 $chansettings measurement_registers(0).dsp.constant_fraction
writeInt32 $chansettings measurement_registers(0).dsp.pulse_threshold
writeInt32 $chansettings measurement_registers(0).dsp.slope_threshold 
writeInt32 $chansettings measurement_registers(0).dsp.baseline.average_order 
writeInt32 $chansettings \\changen(0)\\/measurement/SignalProcessor/BASELINE_AV_FRAC 
writeInt32 $chansettings measurement_registers(0).capture.rel_to_min
writeInt32 $chansettings measurement_registers(0).capture.use_cfd_timing
writeInt32 $chansettings height_unsigneds(0)

close $chansettings
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
	
	writeInt32 $traces measurements(0).filtered_signal
	writeInt32 $traces measurements(0).slope_signal
	writeInt32 $traces1 measurements(1).filtered_signal
	writeInt32 $traces1 measurements(1).slope_signal

#	if {$toggle} {
#		setsig mca_update_asap 0
#		setsig mca_update_on_completion 0
#		set toggle 0
#	}
	
#	if {[string equal [getsig mca_initialising] FALSE] && ~$initialised } {
#		set initialised 1
#		setsig mca_update_asap 1
#		set toggle 1
#		puts "MCA Initialised"
#	}
	
	if [getsig measurements(0).raw.valid] {
		puts -nonewline $rawmeasurements [binary format i $i]
		writeInt32 $rawmeasurements measurements(0).raw.area
		writeInt32 $rawmeasurements measurements(0).raw.extrema
	}

	if [getsig measurements(0).filtered.valid] {
		puts -nonewline $filteredmeasurements [binary format i $i]
		writeInt32 $filteredmeasurements measurements(0).filtered.area
		writeInt32 $filteredmeasurements measurements(0).filtered.extrema
	}

	if [getsig measurements(0).slope.valid] {
		puts -nonewline $slopemeasurements [binary format i $i]
		writeInt32 $slopemeasurements measurements(0).slope.area
		writeInt32 $slopemeasurements measurements(0).slope.extrema
	}

	if [getsig measurements(0).pulse.valid] {
		puts -nonewline $pulsemeasurements [binary format i $i]
		writeInt32 $pulsemeasurements measurements(0).pulse.area
		writeInt32 $pulsemeasurements measurements(0).pulse.extrema
	}
	
	if [getsig measurements(0).pulse_start] {
		puts -nonewline $pulsestarts [binary format i $i]
		writeInt32 $pulsestarts measurements(0).filtered_signal
	}

	if [getsig measurements(0).slope_xing] {
		puts -nonewline $slopexings [binary format i $i]
		writeInt32 $slopexings measurements(0).filtered_signal
	}
	
	if [getsig measurements(0).peak_start] {
		puts -nonewline $peaks [binary format i $i]
		writeInt32 $peaks measurements(0).filtered_signal
	}

	if { [getsig measurements(0).peak] } {
		puts -nonewline $peaks [binary format i $i]
		writeInt32 $peaks measurements(0).filtered_signal
		writeInt32 $peaks measurements(0).slope_signal
		writeInt32 $peaks measurements(0).slope.area
		writeInt32 $peaks cfd_errors(0)
	}

	if { [getsig measurements(0).cfd_low] } {
		puts -nonewline $cfdlow [binary format i $i]
		writeInt32 $cfdlow measurements(0).filtered_signal
	}

	if { [getsig measurements(0).cfd_high] } {
		puts -nonewline $cfdhigh [binary format i $i]
		writeInt32 $cfdhigh measurements(0).filtered_signal
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
	
	if { [getsig ethernetstream_ready] && [getsig ethernetstream_valid] } {
		writeInt32 $ethstream eventstream.data(31:0)
		writeInt32 $ethstream eventstream.data(63:32)
	}

	if { [getsig starts(0)] } {
		puts -nonewline $timing [binary format i $i]
		#writeInt32 $muxstarts measurement.filtered_signal
	}
	
	if { [getsig overflows(0)] } {
		puts -nonewline $overflow [binary format i $i]
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
close $timing 
close $rawmeasurements 
close $filteredmeasurements 
close $slopemeasurements 
close $pulsemeasurements 
close $slopexings 
close $overflow
close $mcastream
close $ethstream
