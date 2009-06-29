set wf {}
set we {}
set action 0
set auto_base {}
set auto_loop 0
set auto_search_pos {}
set auto_list [list ]
bind .f.content <Alt-/> {+ hdlAutoComplete}

proc hdlAutoComplete {} {
    if $action {
	set ::auto_base [getBase]
	set ::auto_insert_pos $::wf
    }
    
    if {$::auto_base != {}} {
	if ![ifFinishSearch] {
	    getNextAutoWord
	}
	incr ::auto_loop
	if {$::auto_loop >= [llength $::auto_list]} {
	    set ::auto_loop 0
	}
	.f.content replace $::wf $::we [lindex $::auto_list $::auto_loop]
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
	set ::auto_insert_pos "insert -1c"
	set ::auto_base [.f.content get $::wf insert]
	lappend ::auto_list $::auto_base
    }
    return {}
}

proc ifFinishSearch {} {
    if {$::auto_search_pos == {}} { return 1 }
    return [.f.content compare $::auto_search_pos == $wf]
}

proc getNextAutoWord {} {
    set ::auto_search_pos [.f.content search -nolinestop -backword \
			       -regexp $::auto_base $::auto_search_pos]
    if [$::auto_search_pos != {}] {
	set word [.f.content get $::auto_search_pos "$::auto_search_pos wordend"]
	foreach w $::auto_list {
	    if {$w == $word} {
		return
	    }
	}
	lappend ::auto_list $word
    }
}