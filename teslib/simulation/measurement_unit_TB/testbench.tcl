#
package require isim
namespace import isim::*

#TODO move this to isim package
# e=0 little endian 1=big endian
proc writeInt32 { fp signal {e 0} } {
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
	if {$e==0} { 
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

set fp [open "../input_signals/double_peak" r]
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

restart
wave add /measurement_unit_TB
wave add /measurement_unit_TB/UUT
wave add /measurement_unit_TB/UUT/SlopeXing

runclks
set clk 1
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
writeInt32 $settings height_type
writeInt32 $settings registers.capture.threshold_rel2min
writeInt32 $settings trigger_type
writeInt32 $settings event_type

close $settings

while {[gets $fp hexsample] >= 0} {
#while {$clk < 500000} {}
  #gets $fp hexsample
	if {![expr $clk % 10000]} {
		puts sample:$clk
	}
	setsig adc_sample $hexsample hex
	
	writeInt32 $traces adc_sample
	writeInt32 $traces measurements.raw.sample
	writeInt32 $traces measurements.filtered.sample
	writeInt32 $traces measurements.slope.sample
	
	if [getsig measurements.raw.zero_xing] {
		puts -nonewline $raw [binary format i $clk]
		writeInt32 $raw measurements.raw.area
		writeInt32 $raw measurements.raw.extrema
	}

	if [getsig measurements.filtered.zero_xing] {
		puts -nonewline $filtered [binary format i $clk]
		writeInt32 $filtered measurements.filtered.area
		writeInt32 $filtered measurements.filtered.extrema
	}

	if [getsig measurements.slope.zero_xing] {
		puts -nonewline $slope [binary format i $clk]
		writeInt32 $slope measurements.slope.area
		writeInt32 $slope measurements.slope.extrema
	}

	if [getsig measurements.pulse.neg_threshxing] {
		puts -nonewline $pulse [binary format i $clk]
		writeInt32 $pulse measurements.pulse.area
		writeInt32 $pulse measurements.pulse.extrema
	}
	
	if [getsig measurements.pulse.pos_threshxing] {
		puts -nonewline $pulsestarts [binary format i $clk]
	}

	if [getsig measurements.slope.pos_threshxing] {
		puts -nonewline $slopethreshxings [binary format i $clk]
	}
	
	if { [getsig measurements.peak] } {
		puts -nonewline $peaks [binary format i $clk]
		# FIXME (VHDL) peak is a closest crossing area may not be valid
		writeInt32 $peaks measurements.slope.area
	}
	
	if { [getsig measurements.peak_start] } {
		puts -nonewline $peak_starts [binary format i $clk]
	}
	
	if { [getsig measurements.height_valid] } {
		puts -nonewline $heights [binary format i $clk]
		writeInt32 $heights measurements.height
	}
	
	if { [getsig measurements.cfd_low] } {
		puts -nonewline $cfdlow [binary format i $clk]
	}
	
	if { [getsig measurements.cfd_high] } {
		puts -nonewline $cfdhigh [binary format i $clk]
	}

	if { [getsig measurements.trigger] } {
		puts -nonewline $triggers [binary format i $clk]
	}
	
	
	if { [getsig valid] && [getsig ready] } {
		writeInt32 $eventstream eventstream.data(63:32) 1
		writeInt32 $eventstream eventstream.data(31:0) 1
	}
	
	if { [getsig cfd_error] } {
		puts -nonewline $cfderrors [binary format i $clk]
	}
	
	if { [getsig time_overflow] } {
		puts -nonewline $timeoverflows [binary format i $clk]
	}
	
	if { [getsig peak_overflow] } {
		puts -nonewline $peakoverflows [binary format i $clk]
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
