set search_targets  {.f.content .extra}
set extra_targets {}
set extra_pos end

set extra_files [list ]
proc initExtraFiles {} {
    text .extra
    foreach f $::extra_files {
        set fd [open $f r]
        .extra insert end [read $fd]
    }
}

#-----------------------------------------

set auto_comp_word  {}
set auto_comp_start {}
set auto_comp_end   {}
set auto_comp_pos   {}
set auto_comp_list  {}
set auto_comp_list_id 0
bind .f.content <Alt-/> {+ hdlAutoComp %W}

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

proc ifAutoCompSearchFinished {limit} {
    if {$::auto_comp_pos == {}} {return 1}
    return [.f.content compare $::auto_comp_pos == $limit]
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
        if ![ifAutoCompSearchFinished $::auto_comp_start] {
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

proc hdlAutoComp {evt_widget} {
    if {($::auto_comp_end == {}) \
            || [.f.content compare $::auto_comp_end != insert] \
            || ![regexp "^$::auto_comp_word" [.f.content get $::auto_comp_start $::auto_comp_end]]} {
                initAutoComp
                set widget_index [lsearch $::search_targets $evt_widget]
                set ::extra_targets [lreplace $::search_targets $widget_index $widget_index]
            }
    
    if {$::auto_comp_word != {}} {
        if ![ifAutoCompSearchFinished $::auto_comp_start] {
            getNextAutoWord
        } else {
            getExtraNextWord
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

#-----------------------EXTRA---------------------#

proc ifExtraFinished {} {
    return ![llength $::extra_targets]
}

proc ifAutoCompPosInvaild {} {
    return [expr {$::extra_pos == {1.0} || $::extra_pos == {}}]
}

proc getExtraNextWord {} {
    if [ifExtraFinished] {return 0}
    
    if [ifAutoCompPosInvaild] {
        set ::extra_targets [lreplace $::extra_targets 0 0]
        set ::extra_pos end
        return [getExtraNextWord]
    }
    
    set target [lindex $::extra_targets 0]
    set ::extra_pos [$target search -nolinestop -backwards -regexp $::auto_comp_word $::extra_pos 1.0]
    if {$::extra_pos == {}} { return [getExtraNextWord] }
    while {($::extra_pos != {}) && [$target compare $::extra_pos != [_tool_indexWordHead $target $::extra_pos]]} {
        set ::extra_pos [$target search -nolinestop -backwards -regexp $::auto_comp_word $::extra_pos 1.0]
    }
    if {$::extra_pos == {}} { return [getExtraNextWord] }
    
    set word [$target get $::extra_pos "$::extra_pos wordend"]
    set duplicate 0
    foreach w $::auto_comp_list {
        if {$w == $word} {
            set duplicate 1
            break
        }
    }
    if $duplicate {
        return [getExtraNextWord]
    } else {
        lappend ::auto_comp_list $word
    }
}