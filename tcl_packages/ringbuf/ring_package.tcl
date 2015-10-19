#!/bin/sh
# rinbuf_package.tcl \
# ring buffer

package provide ring 14.7
#ring of 4 arrays for storing stuff
namespace eval ring {

	namespace export -clean buf
	
	variable b0
	variable b1
	variable b2
	variable b3
	variable bx
  variable r 0 
	variable w 0
  array set b0 {}
  array set b1 {}
  array set b2 {}
  array set b3 {}
	array set bx {}
}
	
# The last arg modifies target buffer
# 	r - current read buffer 
#		w - current write buffer 
#		n - next write buffer
#		x - extra buffer (not in ring)
#
# Commands
# buf init -- clear all buffers and set read and write to same buffer
# buf clear            (r|w|n|x)              -- clear the buffer
# buf incr   key       (r|w|n|x)  (default w) -- increment value (key must be integer or empty)
# buf get    key       (r|w|n|x)  (default r) -- get value
# buf set    key value (r|w|n|x)  (default w) -- set value 
# buf exists key       (r|w|n|x)  (default w) -- key exists in buffer
# buf nextwrite                               -- move to next write buffer
# buf nextread                                -- clear current read buffer move to next

proc ::ring::buf {command args} {
  
  variable b0
  variable b1
  variable b2
  variable b3
  variable bx
  variable r 
  variable w 
  
  set key [lindex $args 0]
  set value [lindex $args 1]
  set buffer [lindex $args end]
  
  proc next {buf} {
    return [expr int(fmod($buf+1,4))]
  }
	
  #buffer target modifier
  proc bm {} {
    upvar 1 buffer buffer
    upvar 1 command command
    variable r
    variable w
    switch $buffer {
      w {return $w}
      r {return $r}
      n {return [next $w]}
      x {return x}
      #default {if {[string equal $command get]} {return $r} {return $w}}
      default {if {[string equal $command get]} {return $r} {return $w}}
    }
  }

  switch $command {
    get {
      #set b [a2b] 
      if {[info exists b[bm]\($key)]} {
        return  [lindex [array get b[bm] $key] 1]
      } else {if {[string is integer $key]} {return 0} {return}}
    }
		#returns 1 if new key created
    incr { 
      if {[info exists b[bm]($key)]} {
				return [incr b[bm]($key)] 
      } else {
				return [set b[bm]($key) 1]
      }
    }
    init { 
      set r 0
      set w 0
      array unset b0 *
      array unset b1 *
      array unset b2 *
      array unset b3 *
      array unset bx *
    }
    nextread {
      if {$r == 0} {array unset b0 *}
      if {$r == 1} {array unset b1 *}
      if {$r == 2} {array unset b2 *}
      if {$r == 3} {array unset b3 *}
      return [set r [next $r]]
    }
    nextwrite {return [set w [next $w]]}
    set {set b[bm]($key) $value}
    clear {
    	if {$buffer=={}} {error "buf:clear command requires a buffer"}
			array unset b[bm] *
    }
		exists { return [info exists b[bm]($key)] }
    default {error "buf:unknown command $command"}
  }
}