set auto_comp_word  {}
set auto_comp_start {}
set auto_comp_end   {}
set auto_comp_pos   {}
set auto_comp_list  {}
set auto_comp_list_id 0
bind .f.content <Alt-/> {+ hdlAutoComp}

proc initAutoComp {} {
    if [ifInWord insert] {
        set ::auto_comp_start [indexWordHead insert]
        set ::auto_comp_end   [.f.content index insert]
        set ::auto_comp_pos   [.f.content index "$::auto_comp_start -1c"]
        set ::auto_comp_word  [.f.content get $::auto_comp_start $::auto_comp_end]
        set ::auto_comp_list  [list $::auto_comp_word]
        set ::auto_comp_list_id 0
    } else {
        set ::auto_comp_start {}
        set ::auto_comp_end   {}
        set ::auto_comp_pos   {}
        set ::auto_comp_list  {}
        set ::auto_comp_list_id 0
        set ::auto_comp_word  {}
    }
}

proc ifAutoCompSearchFinished {} {
    if {$::auto_comp_pos == {}} {return 1}
    return [.f.content compare $::auto_comp_pos == $::auto_comp_start]
}

proc getNextAutoWord {} {
    set old_pos $::auto_comp_pos
    set ::auto_comp_pos [.f.content search -nolinestop -backwards -regexp $::auto_comp_word $old_pos]
    while {[.f.content compare $::auto_comp_pos != [indexWordHead $::auto_comp_pos]]} {
        set ::auto_comp_pos [.f.content search -nolinestop -backwards -regexp $::auto_comp_word $::auto_comp_pos]
    }
    
    set word [.f.content get $::auto_comp_pos "$::auto_comp_pos wordend"]
    set duplicate 0
    foreach w $::auto_comp_list {
        if {$w == $word} {
            set duplicate 1
            break
        }
    }
    if $duplicate {
        if ![ifAutoCompSearchFinished] {
            return [getNextAutoWord]
        }
    } else {
        lappend ::auto_comp_list $word
    }
}

proc _hi {} {
    if ![catch {info args switchHighLightLine}] {
        switchHighLightLine
    }
    if ![catch {info args hiWord}] {
        hiWord $::auto_comp_start
    }
}

proc hdlAutoComp {} {
    if {($::auto_comp_end == {}) \
	    || [.f.content compare $::auto_comp_end != insert] \
	    || ![regexp "^$::auto_comp_word" [.f.content get $::auto_comp_start $::auto_comp_end]]} {
	#puts {run to here}
        initAutoComp
    }
    
    if {$::auto_comp_word != {}} {
        if ![ifAutoCompSearchFinished] {
            getNextAutoWord
        }
        
        set list_length [llength $::auto_comp_list]
        if [expr ! $list_length] {
            return
        }
        
        incr ::auto_comp_list_id
        if {$::auto_comp_list_id >= $list_length} {
            set ::auto_comp_list_id 0
        }
        .f.content replace $::auto_comp_start $::auto_comp_end [lindex $::auto_comp_list $::auto_comp_list_id]
        after idle [list set ::auto_comp_end [.f.content index insert]]
        _hi
    }
}