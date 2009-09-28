package require Tk
set globalLbID 1
set globalTxID 1
set textList {}

proc newLabelFrame {title} {
    set nm ".lb$::globalLbID"
    labelframe $nm -text $title
    incr ::globalLbID
    return $nm
}

proc newText {textname} {
    foreach t $::textList {if {$t == $textname} {return}}
    lappend ::textList $textname
    set ::textID [expr [llength $::textList] -1]
    text ".$textname"
    set temp $::globalLbID
    while {$temp > 0} {
	if [winfo exists ".lb$temp"] {
	    foreach t $::textList {
		pack forget ".lb$temp.$t"
	    }
	    set nm ".lb$temp.$textname"
	    ".$textname" peer create $nm
	    pack $nm -fill both -expand 1
	    bind $nm <Control-k> [list killBuffer $textname]
	    bind $nm <Control-Left> [list rotateBuffer $textname left]
	    bind $nm <Control-Right> [list rotateBuffer $textname right]
	}
	incr temp -1
    }
}

proc killBuffer {textname} {
    set where [lsearch $::textList $textname]
    set ::textList [lreplace $::textList $where $where]
    set len [llength $::textList]
    if {$len == 0} {exit}

    destroy ".$textname"
    set temp $::globalLbID
    while {$temp > 0} {	
	if [winfo exists ".lb$temp"] {
	    destroy ".lb$temp.$textname"
	    if {$where == $len} {set where 0}
	    pack ".lb$temp.[lindex $::textList $where]" -fill both -expand 1
	}
	incr temp -1
    }
}

proc rotateBuffer {textname dir} {
    set len [llength $::textList]
    if {$len == 1} {return}
    set now [lsearch $::textList $textname]
    if {$dir == {left}} {
	incr now -1
	if {$now < 0} {
	    set now [expr $len -1]
	}
    } else {
	incr now
	if {$now == $len} {
	    set now 0
	}
    }

    set temp $::globalLbID
    while {$temp > 0} {
	if [winfo exists ".lb$temp"] {
	    pack forget ".lb$temp.$textname"
	    pack ".lb$temp.[lindex $::textList $now]" -fill both -expand 1
	}
        incr temp -1
    }
}

if 1 {
    set sample {niho shijie wodemingzi jiao jinhao}
    button .bt1 -text {new frame} -command [list newLabelFrame [lindex $sample [expr int(5*rand())]]]
    button .bt2 -text {new text} -command  "newText \$::globalTxID; incr ::globalTxID"
    pack [newLabelFrame test] -fill both -expand 1
    newText $::globalTxID; incr $::globalTxID
    pack .bt1 .bt2 -side left
}