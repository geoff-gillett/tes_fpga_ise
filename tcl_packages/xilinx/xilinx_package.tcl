# tcl scripts for xilinx ISE 14.7 and vivado 2015.4.2
# Geoff Gillett
package provide xilinx 2015.4.2

namespace eval sim {
	namespace export write_signal gen_names open_binfiles close_files \
	flush_files write_signal getbool
}

proc ::sim::gen_names {base chans} {
	for {set c 0} {$c < $chans} {incr c} {
		lappend names $base$c
	}		
	return $names
}

proc ::sim::open_binfiles names {
	foreach name $names {
		set $name [open "../$name" w]
		fconfigure [subst $$name] -translation binary
		lappend fp_list [subst $$name]
	}
	return $fp_list
}

proc ::sim::close_files fp_list {
	foreach fp $fp_list {
		close $fp
	}
}

proc ::sim::flush_files fp_list {
	foreach fp $fp_list {
		flush $fp
	}
}

proc ::sim::getbool signal {
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
	if { [string equal $val u] } {
		set val 0
	}
	if { [string equal $val U] } {
		set val 0
	}
	if { [string equal $val ?] } {
		set val 0
	}
	return $val
}

# write signal to file fp with binary format 
proc ::sim::write_signal { fp signal {getsig_type dec} {format i} } {
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
	if { [string equal $val u] } {
		set val 0
	}
	if { [string equal $val U] } {
		set val 0
	}
	if { [string equal $val ?] } {
		set val 0
	}
	puts -nonewline $fp [binary format $format $val]
}

namespace eval isim { namespace export getsig setsig write_stream }

proc ::isim::getsig {name {radix ""}} {
  if { $radix == "" } {
    return [show value $name]
  } else {
    return [show value $name -radix $radix]
  }
}

proc ::isim::setsig {name value {radix ""} } {
	if { $radix == "" } {
		put $name $value 
	} {
		put $name $value -radix $radix
	}
  return $value
}

proc ::isim::write_stream { fp stream } {
	if { [getsig $stream\_valid] && [getsig $stream\_ready] } {
		#write as two 32 bit values as isim has trouble with 64 bit ints (tcl 8.4)
		#so write two big endian 32 bit ints
		#write the stream as a big endian 64 bit value so it has the same byte order 
		#as transmission 
		write_signal $fp $stream.data(63:32) unsigned I
		write_signal $fp $stream.data(31:0) unsigned I
		write_signal $fp $stream.last(0) unsigned c
	}
}

namespace eval xsim { namespace export getsig setsig write_stream }

proc ::xsim::getsig {name {radix ""}} {
  if { $radix == "" } {
    return [get_value $name]
  } else {
    return [get_value -radix $radix $name]
  }
}

proc ::xsim::setsig {name value {radix ""} } {
	if { $radix == "" } {
		set_value $name $value
	} {
		set_value -radix $radix $name $value 
	}
  #isim force add $name $value -radix $radix
  return $value
}

proc ::xsim::write_stream { fp stream } {
	if { [getsig $stream\_valid] && [getsig $stream\_ready] } {
		#vivado 2015.4 has a bug with get_value of a vector slice within a record
		#but can handle 64 bit ints better (tcl 8.5)
		write_signal $fp $stream.data unsigned W
		write_signal $fp $stream.last(0) unsigned c
	}
}

namespace eval xilinx {
	namespace export make_project update_version src build_bitstream versionHex
}

#expects either *.xci or *.xco having both will cause an error *.xci prefered
proc ::xilinx::process_cores {vivado cores_dir} {
	
	set cores [glob -nocomplain $cores_dir/*.{xci,xco}]

	puts "Processing IP in $cores_dir"

  #create a dir for each core and copy core file to it and generate
  if { [llength $cores] != 0 } {
		
    foreach corepath $cores {
			set corefile [file tail $corepath]
      set name [file rootname $corefile]
			#create a build directory
      if ![file exists $cores_dir/$name] {
        file mkdir $cores_dir/$name
      }
			# copy core file to it
      if ![file exists $cores_dir/$name/$corefile] {
        file copy $corepath $cores_dir/$name/$corefile
      } 
      add_files -norecurse $cores_dir/$name/$corefile
    }
    generate_target all [get_ips]
  }
}
		
#return a list of all vhdl sources under dir searches sub-dirs
proc ::xilinx::get_sources {dir} {
	
  set sources [glob -nocomplain $dir/*.{vhd,vhdl}]
  set subdirs [glob -nocomplain -type d $dir/*]
	
  foreach subdir $subdirs {
    set sources [concat $sources [get_sources $subdir]]
  }
	puts "get_sources:$sources"
	return $sources
}

# process a file named projname.deps in scriptsDir
# The file contains one dependency per line (path relative to scriptsDir)
# with optional library to add depenency to, eg
# 	dependency(file or directory) [library]
#
# If the dependency is a directory:
#		cores in IP_cores sub-directory are added if it exists
#		vhdl files under the HDL sub-directory are recursively added 
# Otherwise the dependency file is directly added (add_files -norecurse)
# NOTE: paths cannot contain spaces
#
#FIXME need separate vivado/planahead depsfile?
# 
proc ::xilinx::process_deps {vivado projname buildDir scriptsDir} {
	if [file exists $scriptsDir/$projname.dep] {
    puts "Processing dependency file $scriptsDir/$projname.dep"
    set depsfile [open $scriptsDir/$projname.dep]
    foreach depline [split [read $depsfile] \n] {
      if {![string is space $depline] && ([string index $depline 0] != "#")} {
				
				set dependency [regexp -all -inline {\S+} $depline]
				puts $dependency
				set depfile $scriptsDir/[lindex $dependency 0]
        set depfile [file normalize $depfile]
				
        if { [file isdirectory $depfile]} {
					
        	if {[file exists $depfile/HDL]} {
        		set sources [get_sources $depfile/HDL]
        	} {
        		set sources [glob -nocomplain $depfile/*.{vhd,vhdl}]
        	}
					
					if $vivado {
            if [file exists $depfile/vivado_IP] {
              process_cores $vivado $depfile/vivado_IP
            }
					} {
            if [file exists $depfile/IP_cores] {
              process_cores $vivado $depfile/IP_cores
            }
					}
        } {
          set sources $depfile
        }
				
			  add_files $sources -norecurse
				if {[llength $dependency] == 2} {  
					# have library name
					set_property library [lindex $dependency 1] [get_files $sources]
          #puts "Adding to library $libName\n $libFiles"
				}
      }
    }
    close $depsfile
	} else {
		puts "No .dep file found"
	}
}

# source a script but with args
proc ::xilinx::src {file args} {
  set argv $::argv
  set argc $::argc
  set ::argv $args
  set ::argc [llength $args]
  set code [catch {uplevel [list source $file]} return]
  set ::argv $argv
  set ::argc $argc
  return -code $code $return
}	

# assumes project open and runs created
proc ::xilinx::build_bitstream {top  synth implementation} {
	set imp [get_runs $implementation]
	set syn [get_runs $synth]
	if {[get_property top [current_fileset]]!=$top} {
	  set_property top $top [current_fileset]
	  set_property top_lib {} [current_fileset]
	  set_property top_arch {} [current_fileset]
	  set_property top_file {} [current_fileset]
	  #update_compile_order -fileset [current_fileset]
	}
	set synthOK [string equal [get_property status $syn] "XST Complete!"]
	set synthDirty [get_property needs_refresh $syn]
	puts "synthOK: $synthOK synthDirty:$synthDirty"
	if { [expr $synthDirty || ! $synthOK] } {
		reset_run $syn
		launch_runs $syn;wait_on_run $syn
	}
	set synthDirty [get_property needs_refresh $syn]
	set synthOK [string equal [get_property status $syn] "XST Complete!"]
	set impDirty [get_property needs_refresh $imp]
	set notstarted [string equal [get_property status $imp]  "Not started"]
	set impOK [string equal [get_property status $imp] "Bitgen Complete!"]
	puts "notstarted:$notstarted impDirty:$impDirty impOK:$impOK synthDirty:$synthDirty synthOK:$synthOK"
	if { [expr ($impDirty || $notstarted || ! $impOK) && $synthOK] } {
		reset_run $imp
  	launch_runs $imp -to_step Bitgen;wait_on_run $imp
	}
	set synthDirty [get_property needs_refresh $syn]
	set synthOK [string equal [get_property status $syn] "XST Complete!"]
	set impDirty [get_property needs_refresh $imp]
	set notstarted [string equal [get_property status $imp]  "Not started"]
	set impOK [string equal [get_property status $imp] "Bitgen Complete!"]
	puts "notstarted:$notstarted impDirty:$impDirty impOK:$impOK synthDirty:$synthDirty synthOK:$synthOK"
}

#provides a 28 bit value as hex string for the VHDL generic VERSION
proc ::xilinx::versionHex {} {
	 return [exec git rev-parse --short HEAD]
}

#sets the XST option to override the top level HDL generic VERSION
proc ::xilinx::update_version {synth} {
	if { ![catch {set version [versionHex]}] } {
		set current_opt \
				[get_property {steps.xst.args.more options} [get_runs $synth]]
	  set opt "-generics \{VERSION=h0$version\}"
		if {![string equal $opt $current_opt]} {
			set_property -name {steps.xst.args.more options} -value $opt \
					-objects [get_runs $synth]
		}
	}
}
	
proc ::xilinx::process_simdir {vivado sim_dir projname buildDir} {
	# add linkfiles file
	#handle structural
	
	puts "processing $sim_dir"
	set files [glob -nocomplain  $sim_dir/*]
	set TB_file [ lsearch -all -inline -regexp $files {_TB\.(vhd|vhdl)$} ]
	set vhdl_files [ lsearch -all -inline -regexp $files {\.(vhd|vhdl)$} ]
	set viv_wfcgs [lsearch -all -inline -regexp $files {_behav\.wcfg$} ]
	
	if {[llength $TB_file] != 1} {
		error "$dir should contain exactly one test-bench file (*_TB.vhd)"
	}
	
	#Create_simset $TBfiles
	set name [file tail [file rootname $TB_file]]
	puts "Creating simulation set $name"
	create_fileset -simset $name
	set simset [get_filesets $name]
	set_property SOURCE_SET sources_1 $simset
	add_files -fileset $name -norecurse $vhdl_files
	#FIXME viv change was $builddir/PlanAhead
  set tooldir $buildDir/$projname.sim/$name
  file mkdir $tooldir
	
	# add any structural sim files if using planahead
	if { !$vivado } { 
    if {[file exists $sim_dir/structural]} {
      puts "adding structural simulation files"
      set struct [open $sim_dir/structural]
      foreach sfile [split [read $struct] \n] {
        add_files -fileset $name -norecurse $sfile
        puts $sfile
      }
    }
	}
	
	set_property top $name $simset
	set_property top_lib {} $simset
	set_property top_arch {} $simset
	set_property top_file {} $simset
	
	if { $vivado } {
		#vivado can add multiple wfcgs
		foreach wfcg $vivado_wfcgs {
      add_files -fileset $TB_file -norecurse $wcfg
      set_property xsim.view $wfcg [get_filesets $TB_file]	
		}
		set vivado_wfcgs [glob -nocomplian  ]
	} {
    set wcfgName [file rootname $TB_file].wcfg
    if {[file exists $wcfgName]} { 
      set_property isim.wcfg [file nativename [file normalize $wcfgName]]	$simset
    }
	}
	
	if [file exists $sim_dir/linkfiles] {
    set links [open $sim_dir/linkfiles]
    foreach lfile [split [read $links] \n] {
      file link $tooldir/[file tail $lfile] $lfile
    }
	}
	
}

# optional args dependency HDL dirs 
# sourceDir is the source project directory
proc ::xilinx::make_project {tool name {sourceDir "../"} {buildDir "../"} args} {
	set vivado [string equal $tool vivado]

	set scriptsDir [pwd]
	set buildDir [file normalize $buildDir]
	set sourceDir [file normalize $sourceDir]
	
	if { $vivado } {
		set buildDir $buildDir/Vivado
		create_project $name $buildDir -part xc7vx485tffg1761-2
		set_property board_part xilinx.com:vc707:part0:1.2 [current_project]
	} {
		set buildDir $buildDir/PlanAhead
    create_project $name $buildDir -part xc6vlx240tff1156-1
    set_property board ML605 [current_project]
	}
		
	set_property target_language VHDL [current_project]
	puts "Adding $sourceDir/HDL"
  add_files $sourceDir/HDL 
	
	process_deps $vivado $name $buildDir $scriptsDir
	
	#FIXME changed
	if $vivado {
    if [file exists $sourceDir/vivado_IP] { 
      process_cores $vivado $sourceDir/vivado_IP 
    }
	} {
    if [file exists $sourceDir/IP_cores] { 
      process_cores $vivado $sourceDir/IP_cores 
    }
	}
	
	puts "Processing simulation directorys"
	set sim_dirs [glob -nocomplain -type d $sourceDir/simulation/*_TB]
	foreach sim_dir $sim_dirs { process_simdir $vivado $sim_dir $name $buildDir }
	
	#TODO add vivado constraints
	puts "Creating constraint sets"
	set constraintDirs [glob -nocomplain -type d $sourceDir/constraints/*]
	if {[llength $constraintDirs]} {
		foreach constraintDir $constraintDirs {
			set constraintName [file tail $constraintDir]
    	puts "Creating constraint set $constraintName"
    	create_fileset -constrset $constraintName
    	import_files -fileset $constraintName $constraintDir
		}
	}
	
	set constraints [glob -nocomplain $sourceDir/constraints/*.ucf]
	if {[ llength $constraints]!=0} {
    foreach constraint $constraints {
    	set constraintName [file tail [file rootname $constraint]]
    	puts "Creating constraint set $constraintName"
    	create_fileset -constrset $constraintName
    	add_files -fileset $constraintName -norecurse $constraint
    }	
	}
	if [file exists $sourceDir/scripts/runs.tcl ] {
		puts "creating runs"
		source $sourceDir/scripts/runs.tcl
	}
	
}


