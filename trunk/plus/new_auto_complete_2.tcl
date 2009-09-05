set auto_comp_word  {}
set auto_comp_limit {}
set auto_comp_end   {}
set auto_comp_pos   {}
set auto_comp_list  {}
set auto_comp_list_id 0
set search_target   {}
bind .f.content <Alt-/> {+ hdlAutoComp}

proc ifAutoCompSearchFinished {} {
    if {$::auto_comp_pos == {}} {return 1}
    return [$::auto_comp_target compare $::auto_comp_pos == $::auto_comp_limit]
}

proc initAutoComp {} {
    if [ifInWord insert] {
        set ::auto_comp_end   [.f.content index insert]
        set ::auto_comp_word  [.f.content get [indexWordHead insert] $::auto_comp_end]
        set ::auto_comp_list  [list $::auto_comp_word]
        set ::search_target   [list ".f.content insert" ".extra end"]
        set ::auto_comp_list_id 0
        initGetNextWord
    }
}

proc initGetNextWord {} {
    if ![llength $::search_target] { return 0 }

    set ::target_item [lindex $::search_target 0]
    lreplace $::search_target 0 0
    set ::auto_comp_target [lindex $target_item 0]
    set ::auto_comp_limit [$::auto_comp_target search -nolinestop -backwards -regexp "$::auto_comp_word" [lindex $target_item 1]]
    if {$::auto_comp_limit != {}} {
        set fake_limit $::auto_comp_limit
        if [$::auto_comp_target compare $::auto_comp_limit != [indexWordHead $::auto_comp_limit]] {
            set ::auto_comp_limit [$::auto_comp_target search -nolinestop -backwards -regexp $::auto_comp_word "$fake_limit -1c"]
            while {([$::auto_comp_target compare $::auto_comp_limit != [indexWordHead $::]]) \
                    && ([$::auto_comp_target compare $fake_limit != $::auto_comp_limit]) } {
                        set ::auto_comp_limit [$::auto_comp_target search -nolinestop -backwards -regexp $::auto_comp_word $::auto_comp_limit]
                    }
            if [$::auto_comp_target compare $fake_limit == $::auto_comp_limit] {
                return [initGetNextWord]
            }
        }
    }
    set ::auto_comp_pos [$::auto_comp_target index "$::auto_comp_limit -1c"]
    return 1
}
                            
proc getNextWord {} {
    set ::auto_comp_pos [$::auto_comp_target search -nolinestop -backwards -regexp $::auto_comp_word $::auto_comp_pos]
    if [ifAutoCompSearchFinished] { if [initGetNextWord] {return [getNextWord]} }
    
    while {[$::auto_comp_target compare $::auto_comp_pos != [indexWordHead $::auto_comp_pos]] \
            && ![ifAutoCompSearchFinished]} {
                set ::auto_comp_pos [$::auto_comp_target search -nolinestop -backwards -regexp $::auto_comp_word $::auto_comp_pos]
            }
    if [ifAutoCompSearchFinished] { if [initGetNextWord] {return [getNextWord]} } 

    set word [$::auto_comp_target get $::auto_comp_pos "$::auto_comp_pos wordend"]
    set duplicate 0
    foreach w $::auto_comp_list {
        if {$w == $word} {
            set duplicate 1
            break
        }
    }
    if $duplicate {
        if ![ifAutoCompSearchFinished] {
            return [getNextWord]
        } else {
            if [initGetNextWord] {return [getNextWord]}
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
        initAutoComp
    }
    
    if [ifInWord insert] {
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