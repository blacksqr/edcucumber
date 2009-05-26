if 1 {
    package require Tk
    frame .f
    text .f.content
    pack .f .f.content
}

bind .f.content <Alt-/> {+ hdlAtuoComplete}

proc hdlAtuoComplete {} {
    set pos [ifInWord insert]
    if {$pos > 0} {
	set f [indexWordHead $id]
	set e [indexWordEnd  $id]
	set base [.f.content get $f $e]
	
	set ids [.f.content search -backward -all $base insert]
	
    }

    return -code break
}

proc popupList {} {
    
}