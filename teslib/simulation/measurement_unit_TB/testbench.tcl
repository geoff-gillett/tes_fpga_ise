#measurement_unit_TB
package require xilinx

#find out if script is sourced into isim or xsim
set is_isim [catch version]
if $is_isim { namespace import ::isim::* } { namespace import ::xsim::* }
namespace import ::sim::*

set fp [open "../input_signals/double_peak" r]
fconfigure $fp -buffering line

set settings [open "../setting" w]
fconfigure $settings -translation binary

set eventstream [open "../eventstream" w]
fconfigure $eventstream -translation binary

set traces [open "../traces" w]
fconfigure $traces -translation binary

set peaks [open "../peak" w]
fconfigure $peaks -translation binary

set peakstart [open "../peakstart" w]
fconfigure $peakstart -translation binary

set eventstart [open "../eventstart" w]
fconfigure $eventstart -translation binary

set cfdlow [open "../cfdlow" w]
fconfigure $cfdlow -translation binary

set cfdhigh [open "../cfdhigh" w]
fconfigure $cfdhigh -translation binary

set pulsestarts [open "../pulsestart" w]
fconfigure $pulsestarts -translation binary

set pulsestops [open "../pulsestop" w]
fconfigure $pulsestops -translation binary

set raw [open "../raw" w]
fconfigure $raw -translation binary

set filtered [open "../filtered" w]
fconfigure $filtered -translation binary

set slope [open "../slope" w]
fconfigure $slope -translation binary

set pulse [open "../pulse" w]
fconfigure $pulse -translation binary

set slopethreshxings [open "../slopethreshxing" w]
fconfigure $slopethreshxings -translation binary

set timeoverflows [open "../timeoverflow" w]
fconfigure $timeoverflows -translation binary

set peakoverflows [open "../peakoverflow" w]
fconfigure $peakoverflows -translation binary

set triggers [open "../trigger" w]
fconfigure $triggers -translation binary

set cfderrors [open "../cfderror" w]
fconfigure $cfderrors -translation binary

set baselineerrors [open "../baselineerror" w]
fconfigure $baselineerrors -translation binary

set heights [open "../height" w]
fconfigure $heights -translation binary

restart

if {$is_isim} {
	wave add /measurement_unit_TB
	wave add /measurement_unit_TB/UUT
	wave add /measurement_unit_TB/UUT/framer
#	wave add /measurement_unit_TB/UUT/baselineEstimator
#	wave add /measurement_unit_TB/UUT/baselineEstimator/mostFrequent
} {
	log_wave /measurement_unit_TB
	log_wave /measurement_unit_TB/UUT
#	log_wave /measurement_unit_TB/UUT/baselineEstimator
#	log_wave /measurement_unit_TB/UUT/baselineEstimator/mostFrequent
}

set period [getsig CLK_PERIOD]
run [lindex $period 0] [lindex $period 1]

set clk 0
#baseline registers
write_signal $settings registers.baseline.offset unsigned 
write_signal $settings registers.baseline.subtraction unsigned 
write_signal $settings registers.baseline.timeconstant unsigned 
write_signal $settings registers.baseline.threshold unsigned 
write_signal $settings registers.baseline.count_threshold unsigned 
write_signal $settings registers.baseline.average_order unsigned 
#capture registers
write_signal $settings registers.capture.cfd_rel2min unsigned 
write_signal $settings registers.capture.constant_fraction unsigned
write_signal $settings registers.capture.pulse_threshold unsigned
write_signal $settings registers.capture.slope_threshold unsigned
write_signal $settings registers.capture.area_threshold dec
write_signal $settings height_type unsigned
write_signal $settings registers.capture.threshold_rel2min unsigned
write_signal $settings trigger_type unsigned
write_signal $settings event_type unsigned
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
		flush $pulsestops
		flush $slopethreshxings
		flush $peaks
		flush $peakstart
		flush $eventstart
		flush $heights
		flush $cfdlow
		flush $cfdhigh
		flush $triggers
		flush $eventstream
		flush $cfderrors
		flush $timeoverflows
		flush $peakoverflows
		flush $baselineerrors
	}
	setsig adc_sample $hexsample hex
	
	write_signal $traces adc_sample unsigned s
	write_signal $traces measurements.raw.sample dec s
	write_signal $traces measurements.filtered.sample dec s
	write_signal $traces measurements.slope.sample dec s
	
	if [getsig measurements.raw.zero_xing] {
		puts -nonewline $raw [binary format i $clk]
		write_signal $raw measurements.raw.area
		write_signal $raw measurements.raw.extrema
	}

	if [getsig measurements.filtered.zero_xing] {
		puts -nonewline $filtered [binary format i $clk]
		write_signal $filtered measurements.filtered.area
		write_signal $filtered measurements.filtered.extrema
	}

	if [getsig measurements.slope.zero_xing] {
		puts -nonewline $slope [binary format i $clk]
		write_signal $slope measurements.slope.area
		write_signal $slope measurements.slope.extrema
	}

	if [getsig measurements.pulse.neg_threshxing] {
		puts -nonewline $pulsestops [binary format i $clk]
		puts -nonewline $pulse [binary format i $clk]
		write_signal $pulse measurements.pulse.area
		write_signal $pulse measurements.pulse.extrema
	}
	
	if [getsig measurements.pulse.pos_threshxing] {
		puts -nonewline $pulsestarts [binary format i $clk]
	}
	

	if [getsig measurements.slope.pos_threshxing] {
		puts -nonewline $slopethreshxings [binary format i $clk]
	}
	
	if { [getsig measurements.peak] } {
		puts -nonewline $peaks [binary format i $clk]
		#write_signal $peaks measurements.slope.area
	}
	
	if { [getsig measurements.peak_start] } {
		puts -nonewline $peakstart [binary format i $clk]	
		#write_signal $peakstart measurements.filtered.sample
	}
	
	if { [getsig measurements.event_start] } {
		puts -nonewline $eventstart [binary format i $clk]	
		#write_signal $peakstart measurements.filtered.sample
	}
	
	if { [getsig measurements.height_valid] } {
		puts -nonewline $heights [binary format i $clk]
		write_signal $heights measurements.height unsigned s
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
	
	write_stream $eventstream eventstream
	
	if { [getsig cfd_error] } {
		puts -nonewline $cfderrors [binary format i $clk]
	}
	
	if { [getsig baseline_error] } {
		puts -nonewline $baselineerrors [binary format i $clk]
	}
	
	if { [getsig time_overflow] } {
		puts -nonewline $timeoverflows [binary format i $clk]
	}
	
	if { [getsig peak_overflow] } {
		puts -nonewline $peakoverflows [binary format i $clk]
	}
	
	run [lindex $period 0] [lindex $period 1]
	incr clk 
}

close $fp
close $traces 
close $peaks 
close $peakstart 
close $eventstart 
close $heights 
close $cfdlow 
close $cfdhigh 
close $pulsestarts 
close $pulsestops 
close $triggers
close $raw
close $filtered
close $pulse
close $slope
close $slopethreshxings
close $timeoverflows
close $peakoverflows
close $cfderrors
close $baselineerrors
close $eventstream
