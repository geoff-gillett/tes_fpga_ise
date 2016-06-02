#
package require isim
namespace import isim::*

#TODO move this to isim package
# e=0 little endian 1=big endian
proc writeInt32 { fp signal {type dec} {e little} } {
	set val [getsig $signal $type]
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
	if { [string equal $e little] } { 
		set i [binary format i $val]
	} {
		set i [binary format I $val]
	}
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

set eventstream [open "../eventstream" w]
fconfigure $eventstream -translation binary

set traces [open "../traces" w]
fconfigure $traces -translation binary

set peaks [open "../peaks" w]
fconfigure $peaks -translation binary

set peak_starts [open "../peak_starts" w]
fconfigure $peak_starts -translation binary

set cfdlow [open "../cfdlow" w]
fconfigure $cfdlow -translation binary

set cfdhigh [open "../cfdhigh" w]
fconfigure $cfdhigh -translation binary

set pulsestarts [open "../pulsestarts" w]
fconfigure $pulsestarts -translation binary

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

set heights [open "../heights" w]
fconfigure $heights -translation binary

set muxfull [open "../muxfull" w]
fconfigure $muxfull -translation binary

set muxoverflows [open "../muxoverflows" w]
fconfigure $muxoverflows -translation binary

restart

wave add /measurement_mux_TB
wave add /measurement_mux_TB/\\chanGen(0)\\/measurementUnit
wave add /measurement_mux_TB/mux
wave add /measurement_mux_TB/mux/tickstreamer
wave add /measurement_mux_TB/mux/buffers

runclks
set clk 0
#baseline registers
writeInt32 $settings registers.baseline.offset
writeInt32 $settings registers.baseline.subtraction
writeInt32 $settings registers.baseline.timeconstant
writeInt32 $settings registers.baseline.threshold
writeInt32 $settings registers.baseline.count_threshold
writeInt32 $settings registers.baseline.average_order 
#capture registers
writeInt32 $settings registers.capture.cfd_relative
writeInt32 $settings registers.capture.constant_fraction
writeInt32 $settings registers.capture.pulse_threshold
writeInt32 $settings registers.capture.slope_threshold 
writeInt32 $settings registers.capture.pulse_area_threshold 
writeInt32 $settings height_type unsigned
writeInt32 $settings registers.capture.threshold_rel2min
writeInt32 $settings trigger_type unsigned
writeInt32 $settings event_type unsigned
writeInt32 $settings tick_period unsigned
close $settings

while {[gets $fp hexsample] >= 0} {
#while {$clk < 500000} {}
  #gets $fp hexsample
	if {![expr $clk % 10000]} {
		# print progress and flush files every 10000 clks
		puts sample:$clk
		flush $traces
		flush $raw
		flush $filtered
		flush $slope
		flush $pulse
		flush $pulsestarts
		flush $slopethreshxings
		flush $peaks
		flush $peak_starts
		flush $heights
		flush $cfdlow
		flush $cfdhigh
		flush $triggers
		flush $eventstream
		flush $cfderrors
		flush $timeoverflows
		flush $peakoverflows
		flush $muxfull
		flush $muxoverflows
	}
	setsig adc_sample $hexsample hex
	
	writeInt32 $traces adc_sample
	writeInt32 $traces measurements(0).raw.sample
	writeInt32 $traces measurements(0).filtered.sample
	writeInt32 $traces measurements(0).slope.sample
	
	
	if [getsig measurements(0).raw.zero_xing] {
		puts -nonewline $raw [binary format i $clk]
		writeInt32 $raw measurements(0).raw.area
		writeInt32 $raw measurements(0).raw.extrema
	}

	if [getsig measurements(0).filtered.zero_xing] {
		puts -nonewline $filtered [binary format i $clk]
		writeInt32 $filtered measurements(0).filtered.area
		writeInt32 $filtered measurements(0).filtered.extrema
	}

	if [getsig measurements(0).slope.zero_xing] {
		puts -nonewline $slope [binary format i $clk]
		writeInt32 $slope measurements(0).slope.area
		writeInt32 $slope measurements(0).slope.extrema
	}

	if [getsig measurements(0).pulse.neg_threshxing] {
		puts -nonewline $pulse [binary format i $clk]
		writeInt32 $pulse measurements(0).pulse.area
		writeInt32 $pulse measurements(0).pulse.extrema
	}
	
	if [getsig measurements(0).pulse.pos_threshxing] {
		puts -nonewline $pulsestarts [binary format i $clk]
	}

	if [getsig measurements(0).slope.pos_threshxing] {
		puts -nonewline $slopethreshxings [binary format i $clk]
	}
	
	if { [getsig measurements(0).peak] } {
		puts -nonewline $peaks [binary format i $clk]
		#writeInt32 $peaks measurements.slope.area
	}
	
	if { [getsig measurements(0).peak_start] } {
		puts -nonewline $peak_starts [binary format i $clk]	
		#writeInt32 $peak_starts measurements.filtered.sample
	}
	
	if { [getsig measurements(0).height_valid] } {
		puts -nonewline $heights [binary format i $clk]
		writeInt32 $heights measurements(0).height
	}
	
	if { [getsig measurements(0).cfd_low] } {
		puts -nonewline $cfdlow [binary format i $clk]
	}
	
	if { [getsig measurements(0).cfd_high] } {
		puts -nonewline $cfdhigh [binary format i $clk]
	}

	if { [getsig measurements(0).trigger] } {
		puts -nonewline $triggers [binary format i $clk]
	}
	
	if { [getsig muxstream_valid] && [getsig muxstream_ready] } {
		writeInt32 $eventstream muxstream.data(63:32) unsigned big
		writeInt32 $eventstream muxstream.data(31:0) unsigned big
	}
	
	if { [getsig cfd_errors(0)] } {
		puts -nonewline $cfderrors [binary format i $clk]
	}
	
	if { [getsig time_overflows(0)] } {
		puts -nonewline $timeoverflows [binary format i $clk]
	}
	
	if { [getsig peak_overflows(0)] } {
		puts -nonewline $peakoverflows [binary format i $clk]
	}
	
	if { [getsig mux_full] } {
		puts -nonewline $muxfull [binary format i $clk]
	}
	
	if { [getsig mux_overflows_u unsigned] != 0 } {
		puts -nonewline $muxoverflows [binary format i $clk]
		writeInt32 $muxstream mux_overflows_u unsigned
	}
	
	runclks
	#move incr to top for matlab indexing
	incr clk 
}

close $fp
close $traces 
close $peaks 
close $peak_starts 
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
close $cfderrors
close $eventstream
close $muxfull
close $muxoverflows