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
	catch {  set ::extra_pos end }
    }
    
    if {$::auto_base != {}} {
        # puts {run to here 2}
        # puts $::auto_list
        if ![ifFinishSearch] {
            # puts {run to here 3}
            getNextAutoWord
        } else {
            #catch {
	    if ![ifExtraFinished] {
		getNextExtraWord
	    }
            #}
        }
        
	if ![llength $::auto_list] {
	    return 
	}

	incr ::auto_loop
	if {$::auto_loop >= [llength $::auto_list]} {
	    set ::auto_loop 0
	}
	# puts "$::wf => $::we"
        # puts "$::auto_loop => $::auto_list"
	.f.content replace $::wf [indexWordEnd $::wf] [lindex $::auto_list $::auto_loop]
	if ![catch {info args switchHighLightLine}] {
	    switchHighLightLine
	}
	if ![catch {info args hiWord}] {
	    hiWord $::wf
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
        set ::auto_loop 0
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
        set duplicate 0
        foreach w $::auto_list {
            if {$w == $word} {
                set duplicate 1
                break
            }
	}
        if $duplicate {
            if ![ifFinishSearch] {
                return [getNextAutoWord]
            }
        } else {
            lappend ::auto_list $word
        }
    }
}