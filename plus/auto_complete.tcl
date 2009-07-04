set wf {}
set we {}
set action 0
set auto_base {}
set auto_loop 0
set auto_search_pos {}
set auto_list [list ]
bind .f.content <Alt-/> {+ hdlAutoComplete}

proc hdlAutoComplete {} {
    if $::action {
	# puts {run to here 1}
	getBase
    }
    
    if {$::auto_base != {}} {
	# puts {run to here 2}
	# puts $::auto_list
	if ![ifFinishSearch] {
	    # puts {run to here 3}
	    getNextAutoWord
	}

	if ![llength $::auto_list] {
	    return 
	}

	incr ::auto_loop
	if {$::auto_loop >= [llength $::auto_list]} {
	    set ::auto_loop 0
	}
	# puts "$::wf => $::we"
	.f.content replace $::wf [indexWordEnd $::wf] [lindex $::auto_list $::auto_loop]
	if ![catch {info args switchHighLightLine}] {
	    switchHighLightLine
	}
	if ![catch {info args hiSyntax}] {
	    hiSyntax $::wf [indexWordEnd $::we]
	}
	after idle {set ::action 0}
    }
}

proc getBase {} {
    set pos [ifInWord insert]
    if {$pos > 0} {
	set ::wf [indexWordHead insert]
	set ::we [.f.content index insert]
	set ::auto_search_pos [.f.content index "$::wf -1c"]
	set ::auto_base [.f.content get $::wf insert]
	set ::auto_list [list $::auto_base]
    }
}

proc ifFinishSearch {} {
    if {$::auto_search_pos == {}} { return 1 }
    set ret [.f.content compare $::auto_search_pos == $::wf]
    # puts $ret
    return $ret
}

proc getNextAutoWord {} {
    set old $::auto_search_pos
    set ::auto_search_pos [.f.content search -nolinestop -backward \
			       -regexp $::auto_base $::auto_search_pos]
    while {[.f.content compare $::auto_search_pos != [indexWordHead $::auto_search_pos]]} {
        set ::auto_search_pos [.f.content search -nolinestop -backward \
                                   -regexp $::auto_base $::auto_search_pos]
    }
    if {$::auto_search_pos != {}} {
	set word [.f.content get $::auto_search_pos "$::auto_search_pos wordend"]
	# puts $word
        # puts "$word => $::auto_list"
	foreach w $::auto_list {
	    if {$w == $word} {
		return
	    }
	}
	lappend ::auto_list $word
    }
}









