#measurement_subsystem_TB
package require xilinx
namespace import ::isim::*
namespace import ::sim::*

#testbench settings
set height_min 50
set height_max 800
set low_level 10
set space_min 1
set space_max 100
set mark_min 10
set mark_max 1000
set sim_clks 100000
# The cfd breaks if the space is to longer than the cfd delay as the minima 
#occcurs at the start of the space. If the space is longer than space limit
#add a minima
set space_lim 10

#seed the prng for repeatability
expr srand(23)

proc randint {min max} {
	return [expr $min+int( rand()*($max-$min+1) ) ]
}

set channels [getsig CHANNELS unsigned]
# initialise array for random rectangular pulse stimulus
for {set c 0} {$c < $channels} {incr c} {
	set chan(state$c) 0
	set chan(next$c) 0
	set chan(last_space$c) 0
}

# open data files for binary writing
# per channel data files
set settings [open_binfiles [gen_names setting $channels]]
set traces [open_binfiles [gen_names traces $channels]]
set peaks [open_binfiles [gen_names peak $channels]]
set peakstarts [open_binfiles [gen_names peakstart $channels]]
set eventstarts [open_binfiles [gen_names eventstart $channels]]
set cfdlows [open_binfiles [gen_names cfdlow $channels]]
set cfdhighs [open_binfiles [gen_names cfdhigh $channels]]
set pulsestarts [open_binfiles [gen_names pulsestart $channels]]
set pulsestops [open_binfiles [gen_names pulsestop $channels]]
set raws [open_binfiles [gen_names raw $channels]]
set filtereds [open_binfiles [gen_names filtered $channels]]
set slopes [open_binfiles [gen_names slope $channels]]
set pulses [open_binfiles [gen_names pulse $channels]]
set slopethreshxings [open_binfiles [gen_names slopethreshxing $channels]]
set triggers [open_binfiles [gen_names trigger $channels]]
set heights [open_binfiles [gen_names height $channels]]
set eventstreams [open_binfiles [gen_names eventstream $channels]]

#single data files
set muxfull [open "../muxfull" w]
fconfigure $muxfull -translation binary

set muxoverflow [open "../muxoverflow" w]
fconfigure $muxoverflow -translation binary

set timeoverflow [open "../timeoverflow" w]
fconfigure $timeoverflow -translation binary

set peakoverflow [open "../peakoverflow" w]
fconfigure $peakoverflow -translation binary

set frameroverflow [open "../frameroverflow" w]
fconfigure $frameroverflow -translation binary

set measurementoverflow [open "../measurementoverflow" w]
fconfigure $measurementoverflow -translation binary

set cfderror [open "../cfderror" w]
fconfigure $cfderror -translation binary

set baselineerror [open "../baselineerror" w]
fconfigure $baselineerror -translation binary

set muxstream [open "../muxstream" w]
fconfigure $muxstream -translation binary

set ethernetstream [open "../ethernetstream" w]
fconfigure $ethernetstream -translation binary

set mcastream [open "../mcastream" w]
fconfigure $mcastream -translation binary

set mcasetting [open "../mcasetting" w]
fconfigure $mcasetting -translation binary

set bytestream [open "../bytestream" w]
fconfigure $bytestream -translation binary

restart

# set up wave database
wave add /measurement_overflow_TB
wave add /measurement_overflow_TB/\\chanGen(0)\\/measurementUnit
wave add /measurement_overflow_TB/\\chanGen(1)\\/measurementUnit
#wave add /measurement_overflow_TB/\\chanGen(2)\\/measurementUnit
#wave add /measurement_overflow_TB/\\chanGen(3)\\/measurementUnit
#wave add /measurement_overflow_TB/\\chanGen(4)\\/measurementUnit
#wave add /measurement_overflow_TB/\\chanGen(5)\\/measurementUnit
#wave add /measurement_overflow_TB/\\chanGen(6)\\/measurementUnit
#wave add /measurement_overflow_TB/\\chanGen(7)\\/measurementUnit
#wave add /measurement_subsystem_TB/\\chanGen(0)\\/measurementUnit/baselineEstimator/mostFrequent
wave add /measurement_overflow_TB/mux
#wave add /measurement_subsystem_TB/mux/buffers
wave add /measurement_overflow_TB/enet
wave add /measurement_overflow_TB/enet/framer
#wave add /measurement_subsystem_TB/enet/eventbuffer
#wave add /measurement_subsystem_TB/enet/eventbuffer/streambuffer
#wave add /measurement_subsystem_TB/enet/eventbuffer/lookaheadslice
#wave add /measurement_subsystem_TB/mca
#wave add /measurement_subsystem_TB/mca/MCA
#wave add /measurement_subsystem_TB/mca/mcaAdapter
#wave add /measurement_subsystem_TB/cdc

# advance past reset so settings are valid
run 8 ns 

set generic [open "../generic" w]
fconfigure $generic -translation binary
write_signal $generic CHANNELS unsigned i
close $generic

set globals [open "../globals" w]
fconfigure $globals -translation binary
write_signal $globals tick_period unsigned i
close $globals

set c 0
foreach fp $settings {
	#baseline registers
	write_signal $fp registers($c).baseline.offset unsigned i 
	write_signal $fp registers($c).baseline.subtraction bin i
  write_signal $fp registers($c).baseline.timeconstant unsigned i
  write_signal $fp registers($c).baseline.threshold unsigned i
  write_signal $fp registers($c).baseline.count_threshold unsigned i
  write_signal $fp registers($c).baseline.average_order unsigned i
	
  #capture registers
  write_signal $fp registers($c).capture.cfd_rel2min bin i
  write_signal $fp registers($c).capture.constant_fraction unsigned i
  write_signal $fp registers($c).capture.pulse_threshold unsigned i
  write_signal $fp registers($c).capture.slope_threshold  unsigned i
  write_signal $fp registers($c).capture.area_threshold dec i
  write_signal $fp height_types($c) unsigned i
  write_signal $fp registers($c).capture.threshold_rel2min bin i
  write_signal $fp trigger_types($c) unsigned i
  write_signal $fp detection_types($c) unsigned i
  write_signal $fp registers($c).capture.height_rel2min bin i
  close $fp
	incr c
}

#mca registers
write_signal $mcasetting mca_registers.channel unsigned i
write_signal $mcasetting mca_registers.bin_n unsigned i
write_signal $mcasetting mca_registers.last_bin unsigned i
write_signal $mcasetting mca_registers.lowest_value dec i
write_signal $mcasetting mca_value_type unsigned i
write_signal $mcasetting mca_trigger_type unsigned i
write_signal $mcasetting mca_registers.ticks unsigned i
close $mcasetting

set clk 0
set ifg 0
set packet_last 0

while { $clk < $sim_clks } {
	
	if {![expr $clk % 10000]} {
		# print progress and flush files every 10000 clks
		puts sample:$clk
		flush_files $traces
		flush_files $raws
		flush_files $filtereds
		flush_files $slopes
		flush_files $pulses
		flush_files $pulsestarts
		flush_files $pulsestops
		flush_files $slopethreshxings
		flush_files $peaks
		flush_files $peakstarts
		flush_files $eventstarts
		flush_files $heights
		flush_files $cfdlows
		flush_files $cfdhighs
		flush_files $triggers
		flush_files $eventstreams
		flush $muxstream
		flush $cfderror
		flush $timeoverflow
		flush $peakoverflow
		flush $muxfull
		flush $muxoverflow
		flush $measurementoverflow
		flush $ethernetstream
		flush $mcastream
		flush $frameroverflow
		flush $baselineerror
		flush $bytestream
	}
	
	for {set c 0} {$c < $channels} {incr c} {
		if { $chan(next$c) == $clk } {
			if { $chan(state$c) } {
				if { $chan(last_space$c) > $space_lim } {
					set chan(next$c) [expr $clk + 10]
					setsig adc_samples($c) 0 dec
					set chan(last_space$c) 0
				} {
					setsig adc_samples($c) [randint $height_min $height_max] unsigned
					set chan(state$c) 0
					set t [randint $mark_min $mark_max]
					set chan(next$c) [expr $clk + $t]
					#puts "$clk:next mark$c:$t next:$chan(next$c)"
				}
			} {
        setsig adc_samples($c) $low_level dec
        set chan(state$c) 1
        set t [randint $space_min $space_max]
				set chan(last_space$c) [expr $clk + $t]
        set chan(next$c) [expr $clk + $t]
				#puts "$clk - next space$c:$t next:$chan(next$c)"
			}
		}
	}
	
	set c 0
	foreach fp $traces {
		write_signal $fp measurements($c).raw.sample dec s
		write_signal $fp measurements($c).filtered.sample dec s
		write_signal $fp measurements($c).slope.sample dec s
		incr c
	}
	
	set c 0
	foreach fp $raws {
    if [getsig measurements($c).raw.zero_xing] {
      puts -nonewline $fp [binary format i $clk]
      write_signal $fp measurements($c).raw.area dec i
      write_signal $fp measurements(0).raw.extrema dec s
    }
		incr c
	}

	set c 0
	foreach fp $filtereds {
    if [getsig measurements($c).filtered.zero_xing] {
      puts -nonewline $fp [binary format i $clk]
      write_signal $fp measurements($c).filtered.area dec i
      write_signal $fp measurements($c).filtered.extrema dec s
    }
		incr c
	}

	set c 0
	foreach fp $slopes {
    if [getsig measurements($c).slope.zero_xing] {
      puts -nonewline $fp [binary format i $clk]
      write_signal $fp measurements($c).slope.area dec i
      write_signal $fp measurements($c).slope.extrema dec s
    }
	}

	set c 0
	foreach fp $pulses {
    if [getsig measurements($c).pulse.neg_threshxing] {
      puts -nonewline $fp [binary format i $clk]
      write_signal $fp measurements($c).pulse.area dec i
      write_signal $fp measurements($c).pulse.extrema dec s
    }
		incr c
	}
	
	set c 0
	foreach fp $pulsestarts {
    if [getsig measurements($c).pulse.pos_threshxing] {
      puts -nonewline $fp [binary format i $clk]
    }
	}
	
	set c 0
	foreach fp $pulsestops {
    if [getsig measurements($c).pulse.neg_threshxing] {
      puts -nonewline $fp [binary format i $clk]
    }
	}

	set c 0
	foreach fp $slopethreshxings {
    if [getsig measurements($c).slope.pos_threshxing] {
      puts -nonewline $fp [binary format i $clk]
    }
		incr c
	}
	
	set c 0
	foreach fp $peaks {
    if { [getsig measurements($c).peak] } {
      puts -nonewline $fp [binary format i $clk]
    }
		incr c
	}
	
	set c 0
	foreach fp $peakstarts {
    if { [getsig measurements($c).peak_start] } {
      puts -nonewline $fp [binary format i $clk]	
    }
		incr c
	}
	
	set c 0
	foreach fp $eventstarts {
    if { [getsig measurements($c).event_start] } {
      puts -nonewline $fp [binary format i $clk]	
    }
		incr c
	}
	
	set c 0
	foreach fp $heights {
    if { [getsig measurements($c).height_valid] } {
      puts -nonewline $fp [binary format i $clk]
      write_signal $fp measurements($c).height dec s
    }
		incr c
	}
	
	set c 0
	foreach fp $cfdlows {
    if { [getsig measurements($c).cfd_low] } {
      puts -nonewline $fp [binary format i $clk]
    }
		incr c
	}
	
	set c 0
	foreach fp $cfdhighs {
    if { [getsig measurements($c).cfd_high] } {
      puts -nonewline $fp [binary format i $clk]
    }
		incr c
	}

	set c 0
	foreach fp $triggers {
    if { [getsig measurements($c).trigger] } {
      puts -nonewline $fp [binary format i $clk]
    }
		incr c
	}

	set c 0
	foreach fp $eventstreams {
		if { [getsig eventstreams_ready($c)] && [getsig eventstreams_valid($c)] } {
			write_signal $fp eventstreams($c).data(63:32) unsigned I
			write_signal $fp eventstreams($c).data(31:0) unsigned I
			write_signal $fp eventstreams($c).last(0) unsigned c
		}
		incr c
	}

	write_stream $muxstream muxstream
	write_stream $mcastream mcastream
	write_stream $ethernetstream ethernetstream
	
	if { [getsig cfd_errors_u unsigned] != 0 } {
		puts -nonewline $cfderror [binary format i $clk]
		write_signal $cfderror cfd_errors_u unsigned c 
	}
	
	if { [getsig time_overflows_u unsigned] != 0 } {
		puts -nonewline $timeoverflow [binary format i $clk]
		write_signal $timeoverflow time_overflows_u unsigned c 
	}
	
	if { [getsig peak_overflows_u unsigned] != 0 } {
		puts -nonewline $peakoverflow [binary format i $clk]
		write_signal $peakoverflow peak_overflows_u unsigned c 
	}

	if { [getsig mux_full] } {
		puts -nonewline $muxfull [binary format i $clk]
	}
	
	if { [getsig mux_overflows_u unsigned] != 0 } {
		puts -nonewline $muxoverflow [binary format i $clk]
		write_signal $muxoverflow mux_overflows_u unsigned c
	}
	
	if { [getsig framer_overflows_u unsigned] != 0 } {
		puts -nonewline $frameroverflow [binary format i $clk]
		write_signal $frameroverflow framer_overflows_u unsigned c
	}

	if { [getsig baseline_errors_u unsigned] != 0 } {
		puts -nonewline $baselineerror [binary format i $clk]
		write_signal $baselineerror baseline_errors_u unsigned c
	}
	
	if {![expr $clk % 2]} {   # rising edge of IO_clk
		if {![getsig bytestream_ready]} {
			# ifg = interframe gap
			incr ifg
			if {$ifg == 19} {setsig bytestream_ready 1 bin}
		}
		if {$packet_last} {
			setsig bytestream_ready 0 bin
			set packet_last 0
			set ifg 0
		} else {
      if { [getsig bytestream_valid] && [getsig bytestream_ready] } {
        puts -nonewline $bytestream [binary format i $clk]
        write_signal $bytestream bytestream unsigned c
        write_signal $bytestream bytestream_last unsigned c
        set packet_last [getsig bytestream_last]
      }
		}
	}
	
  # run SAMPLE_CLK_PERIOD 
	run 4 ns 
	incr clk 
}

close_files $traces
close_files $raws
close_files $filtereds
close_files $slopes
close_files $pulses
close_files $pulsestarts
close_files $pulsestops
close_files $slopethreshxings
close_files $peaks
close_files $peakstarts
close_files $eventstarts
close_files $heights
close_files $cfdlows
close_files $cfdhighs
close_files $triggers
close_files $eventstreams
close $muxstream
close $cfderror
close $timeoverflow
close $peakoverflow
close $muxfull
close $muxoverflow
close $measurementoverflow
close $ethernetstream
close $mcastream
close $frameroverflow
close $baselineerror
