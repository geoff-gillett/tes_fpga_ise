# tcl scripts for xilinx ISE 14.7
# Geoff Gillett
package provide xilinx 14.7.3

namespace eval xilinx {
	namespace export create_projects update_version src build_bitstream versionHex
}
	
# TB_file includes .vhd extension and possible path
proc ::xilinx::Create_simset {TB_file othersimFiles} { 
	set name [file tail [file rootname $TB_file]]
	puts "Creating simulation set $name"
	create_fileset -simset $name
	set simset [get_filesets $name]
	set_property SOURCE_SET sources_1 $simset
	add_files -fileset $name -norecurse $TB_file
	set structural [file dirname $TB_file]/structural
	if {[file exists $structural]} {
		puts "adding structural simulation files"
		add_files -fileset $name $structural
	}
	if {[ llength $othersimFiles]} {
		add_files -fileset $name -norecurse $othersimFiles
	}
	#update_compile_order -fileset $name
	#update_compile_order -fileset $name
	#update_compile_order -fileset $name
	# Disabling source management mode.  
	#This is to allow the top design properties to be set without GUI intervention.
	set_property top $name $simset
	set_property top_lib {} $simset
	set_property top_arch {} $simset
	set_property top_file {} $simset
	update_compile_order -fileset $name
	set wcfgName [file rootname $TB_file].wcfg
	if {[file exists $wcfgName]} { 
		puts "Using $wcfgName"
		set_property isim.wcfg [file nativename [file normalize $wcfgName]]	$simset
	}
}
	
# add all IP cores in IP_coresDir
proc ::xilinx::Process_IP_cores {IP_coresDir} {
	puts "Processing $IP_coresDir"
	set IP_cores [glob -nocomplain $IP_coresDir/*.{xco}]
	if { [llength $IP_cores] != 0 } {
		# need to check if core has .xci and .xco if so use the .xci 
		# currently just looks for .xco
		# create a directory under IP_cores and copy .xco to it
		foreach core $IP_cores {
    	set name [file tail [file rootname $core]]
			if ![file exists $IP_coresDir/$name] {
				file mkdir $IP_coresDir/$name
			}
			if ![file exists $IP_coresDir/$name/$name.xco] {
				file copy $core $IP_coresDir/$name/$name.xco
			}
			add_files -norecurse $IP_coresDir/$name/$name.xco
		}
    generate_target {synthesis} [get_ips]
	}
}
	
# process a file named projname.deps in scriptsDir
# The file contains one dependency per line (path relative to scriptsDir)
# with optional library to add depenency to, eg
# 	dependency(file or directory) [library]
#
# If the dependency is a directory:
#		cores in IP_cores the sub-directory are added if it exists
#		vhdl files in the HDL sub-directory are added (add_files -norecurse)
# Otherwise the dependency file is directly added (add_files -norecurse)
# NOTE: paths cannot contain spaces
proc ::xilinx::Process_deps {projname buildDir scriptsDir} {
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
        		set sources [glob -nocomplain $depfile/HDL/*.{vhd,vhdl}]
        	} {
        		set sources [glob -nocomplain $depfile/*.{vhd,vhdl}]
        	}
          if [file exists $depfile/IP_cores] {
            Process_IP_cores $depfile/IP_cores
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
	  update_compile_order -fileset [current_fileset]
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
	
# optional args dependency HDL dirs 
# sourceDir is the source project directory
proc ::xilinx::create_projects {name {sourceDir "../"} {buildDir "../"} args} { 
	set scriptsDir [pwd]
	set buildDir [file normalize $buildDir]
	set sourceDir [file normalize $sourceDir]
	create_project $name $buildDir/PlanAhead -part xc6vlx240tff1156-1
	set_property board ML605 [current_project]
	set_property target_language VHDL [current_project]
	puts "Adding $sourceDir/HDL"
  add_files $sourceDir/HDL
  if [regexp {lib$} $name] {
    #puts "Adding library $name"
    set libName [string range $name 0 end-8]
    set libFiles [glob -nocomplain $sourceDir/HDL/*.{vhd,vhdl} ]
    set_property library $libName [get_files $libFiles]
    puts "Adding library $libName\n $libFiles]"
  } 
	if [file exists $sourceDir/IP_cores] { Process_IP_cores $sourceDir/IP_cores }
	Process_deps $name $buildDir $scriptsDir
	puts "Processing simulation directory"
	set simFiles [glob -nocomplain $sourceDir/simulation/*.{vhd,vhdl,tcl} ]
	set TBfiles [ lsearch -all -inline -regexp $simFiles {_TB\.(vhd|vhdl)$} ]
	set othersimFiles [ lsearch -all -inline -regexp $simFiles {[^_TB]\.(vhd|vhdl)$}]
	set tclTB [ lsearch -all -inline -regexp $simFiles {_TB\.tcl$}]
	puts "Testbenches:$TBfiles"
	puts "Other simulation files:$othersimFiles"
	puts "TCL testbench scripts:$tclTB"
	foreach TBfile $TBfiles { Create_simset $TBfile $othersimFiles}
	if { [llength $tclTB] != 0 } {
    foreach tclfile $tclTB {
      set simdir $buildDir/PlanAhead/$name.sim/[file rootname [file tail $tclfile ]]/
      file mkdir $simdir
      file link -hard $simdir/[file tail $tclfile] $tclfile
#			exec mklink 
    }
	}
	puts "Creating constraint sets"
	set constraintDirs [glob -nocomplain -type d $sourceDir/constraints/*]
	if {[llength $constraintDirs]} {
		foreach constraintDir $constraintDirs {
			set constraintName [file tail $constraintDir]
    	puts "Creating constraint set $constraintName"
    	create_fileset -constrset $constraintName
    	add_files -fileset $constraintName $constraintDir
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
	if [file exists $sourceDir/scripts/runs.tcl] {
		puts "creating runs"
		source $sourceDir/scripts/runs.tcl
	}
}


