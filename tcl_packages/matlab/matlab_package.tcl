package provide matlab 0.1

proc ::matlab::create {filename {headertext "TCL CREATED MATFILE 5.0"}} {
	
	fp = [open $filename w]
	fconfigure $fp -translation binary
	if {[string length $headertext] > 116} {
		error "Header text maximum length 116"
	}
	
	if {[string length $headertext] < 4} {
		error "Header text minimum length 4"
	}
	
	return  $fp 
}

proc ::matlab::createarray {fp name type cols} {
	return fp type cols fileloc as ap
}

proc ::matlab::writecol {ap data} {
	
}

proc ::matlab::closearray {ap numrows} {
	
}

proc ::matlab::close {fp} {
	
}