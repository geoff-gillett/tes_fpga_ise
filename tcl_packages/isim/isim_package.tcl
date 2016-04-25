#!/bin/sh
# isim_package.tcl \
#exec tclsh "$0" ${1+"$@"}

package provide isim 14.7

namespace eval isim {
	namespace export -clean irand getsig setsig lin simsig waitsig \
	vrand dec2bin bin2dec bits randbit setrandbit validsig getbool setsigp nrand \
	write_signal gen_names open_binfiles close_files flush_files write_stream
	
#	variable period
#	variable timeunit
#	set period [lindex [show value CLK_PERIOD] 0]
#	set timeunit [lindex [show value CLK_PERIOD] 1]
}

proc ::isim::gen_names {base chans} {
	for {set c 0} {$c < $chans} {incr c} {
		lappend names $base$c
	}		
	return $names
}

proc ::isim::open_binfiles names {
	foreach name $names {
		set $name [open "../$name" w]
		fconfigure [subst $$name] -translation binary
		lappend fp_list [subst $$name]
	}
	return $fp_list
}

proc ::isim::close_files fp_list {
	foreach fp $fp_list {
		close $fp
	}
}

proc ::isim::flush_files fp_list {
	foreach fp $fp_list {
		flush $fp
	}
}

proc ::isim::write_stream stream {
	upvar 1 $stream s
	if { [getsig $stream\_valid] && [getsig $stream\_ready] } {
		#write as two 32 bit values as isim has trouble with 64 bit ints 
		#write as a little endian 64 bit value
		write_signal $s $stream.data(63:32) unsigned I
		write_signal $s $stream.data(31:0) unsigned I
		write_signal $s $stream.last(0) bin c
	}
}

# write signal to file fp with binary format 
proc ::isim::write_signal { fp signal {getsig_type dec} {format i} } {
	set val [getsig $signal $getsig_type]
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
	puts -nonewline $fp [binary format $format $val]
}

# random integer x in range min <= x < max
proc ::isim::irand {min max} {
  return [lindex [split [expr $min+floor(rand()*($max-$min))] .] 0]
}

proc ::isim::getsig {name {radix ""}} {
  if { $radix == "" } {
    return [show value $name]
  } else {
    return [show value $name -radix $radix]
  }
}

#proc ::isim::runclks {{clks 1}} {
#  variable period 
#  variable timeunit
#  return [run [expr $clks*$period] $timeunit]
#}

proc ::isim::setsig {name value {radix bin} } {
  put $name $value -radix $radix
  #isim force add $name $value -radix $radix
  return $value
}

#set binary signal with probability p
proc ::isim::setsigp {name prob} {
  if {[expr rand()]<$prob} { 
    return [setsig $name 1] 
  } else {
    return [setsig $name 0]
  }
}

proc ::isim::lin {list element} {
  if {[lsearch -exact $list $element] == -1} {return 0} {return 1}
}

#sets value and value_valid returns value_valid value must be a binary string
proc ::isim::setsig&valid {signal_name value valid_name {radix bin} \
												  {valid_prob 1} } {
  #puts "stimulus $name $value"
  setsig $signal_name $value $radix
	return [setrandbit $validname $valid_prob]
}

#p is the probably of returning 1
proc ::isim::randbit {{p 0.5}} {return [expr rand() < $p]}

proc ::isim::setrandbit {name {p 1} } {
  return [setsig $name [randbit $p] bin]
}

proc ::isim::getbool {name} {
  if {[string equal [getsig $name bin] TRUE]} {return 1} {return 0}
}

proc ::isim::waitsig {condition} {
  isim condition add $condition {stop} -label sigWait
  run all
  isim condition remove -label sigWait
}

#random integer of width bits
proc ::isim::vrand {bits {min ""} {max ""}} {
  if {$min == "" && $max == ""} {
    return [irand [expr -pow(2,$bits-1)] [expr pow(2,$bits-1)]]
  } elseif {$max == ""} {
    return [irand $min [expr pow(2,$bits-1)]]
  } else {
    return [irand $min $max]
  }
}

#Box-Muller normal distribution
proc ::isim::nrand {mean stddev} {
	variable savednormalrandom
	if {[info exists savednormalrandom]} {
		return [expr {$savednormalrandom*$stddev + $mean}][unset savednormalrandom]
	}
	set r [expr {sqrt(-2*log(rand()))}]
	set theta [expr {2*3.1415927*rand()}]
	set savednormalrandom [expr {$r*sin($theta)}]
	expr {$r*cos($theta)*$stddev + $mean}
}

proc ::isim::pulse {t {tc 0.006}} {
	return [expr (1-exp(-$t*$tc))*exp(-$t*10*$tc)]
}

#NOTE max 32 bits 
proc ::isim::dec2bin {string {bits ""}} {
  binary scan [binary format I $string] B32 str
  if {$bits != ""} {
    return [string range $str end-[expr $bits-1] end]
  } else {
    return [string trimleft $str 0]
  }
}

proc ::isim::bin2dec {string {type u}} {
  if {$type == {s}} {
    if {[string index $string 0] == 1} {
      set string "[string repeat 1 [expr 32-[string length $string]]]$string"
    }
  }
  set string [format %032s $string]
  binary scan [binary format B32 $string] I str
  return $str
}

proc ::isim::bits {v} {
  proc log2 x "expr {int(ceil(log(\$x)/[expr log(2)]))}"
  if {$v < 2} {expr 1} {log2 $v}
}

