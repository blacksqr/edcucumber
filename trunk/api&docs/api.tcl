#----------------------------------------#

set buffer         {}
set linum           1
set linum_png_width 2
set any_action      0  ;# false

#----------------------------------------#

proc _data_defaultEvents {cucumber line_number_column info_label} {
    return {
        [list <Delete>    [list [list _tool_decrLinum $line_number_column]]]
        [list <BackSapce> [list [list _tool_decrLinum $line_number_column]]]
        [list <Return>    [list [list _tool_incrLinum $line_number_column]]]
        [list <Alt-w>     [list [list _hdl_default_copy $cucumber $info_label]]]
        [list <Control-@> [list [list _hdl_default_mark $cucumber $info_label]]]
        [list <Control-v> [list [list _tool_incrLinum $line_number_column]]]
        [list <Control-w> [list [list _hdl_default_cut $cucumber $info_label] [list _tool_decrLinum $line_number_column]]]
        [list <Control-k> [list [list _tool_decrLinum $line_number_column]]]
        [list <Control-x> [list [list _tool_decrLinum $line_number_column]]]
        [list <Control-y> [list [list _hdl_default_paste $cucumber] [list _tool_incrLinum $line_number_column]]]
        [list <Control-z> [list [list _tool_incrLinum $line_number_column] [list _tool_decrLinum $line_number_column]]]
    }
}

proc _data_moveEvents {} {
    return {
        {<Control-a>   _hdl_move_toLineStart}
        {<Control-e>   _hdl_move_toLineEnd}
        {<Alt-b>       _hdl_move_toPrevWord}
        {<Alt-b>       _hdl_move_toNextWord}
        {<Alt-<>       _hdl_move_toDocHead}
        {<Alt-greater> _hdl_move_toDocEnd}
        {<Alt-m>       _hdl_move_toContentHead}
        {<Control-BackSapce> _hdl_move_backSpaceWord}
        {<Control-Delete>    _hdl_move_deleteWord}
    }
}

proc _data_plusEvents {} {
    return {
        {<Alt-/> _hdl_plus_autoComplete}
    }
}

proc _bind_defaultEvents {cucumber line_number_column} {
    foreach {evt handles} [_data_defaultEvents] {
        foreach hdl $handles {
            bind $cucumber $evt "+ after idle $hdl"
        }
    }
    
    bind $cucumber <Any-Key> {+
        if [_tool_ifSelected $cucumber] {
            after idle {_tool_decrLinum; _tool_incrLinum}
        }
    }
}

proc _bind_moveEvents {cucumber} {
    foreach {evt hdl} [_data_moveEvents] {
        bind $cucumber $evt "$hdl $cucumber"
    }
}

#----------------------------------------#

proc _hdl_default_paste {cucumber} {
    if {$::buffer eq {}} {
	return
    }
    
    if [ifSelected $cucumber] {
	set i [$cucumber index sel.first]
	$cucumber delete sel.first sel.last
    } else {
	set i [$cucumber index insert]
    }

    $cucumber insert $i $::buffer
}

proc _hdl_default_cut {cucumber info_label} {
    # CUCUMBER is the name of mark

    if ![_tool_ifMarked $cucumber] {
	$info_label configure -text {Mark not set}
    } else {
	if [$cucumber compare insert > CUCUMBER] {
	    set ::buffer [$cucumber get CUCUMBER insert]
	    $cucumber delete CUCUMBER insert
	} elseif [$cucumber compare insert < CUCUMBER] {
	    set ::buffer [$cucumber get insert CUCUMBER]
	}
    }
}

proc _hdl_default_copy {cucumber info_label} {
    if ![_tool_ifMarked $cucumber] {
	$info_label configure -text {Mark not set}
    } else {
	if [$cucumber compare insert > CUCUMBER] {
	    set ::buffer [$cucumber get CUCUMBER insert]
	} elseif [$cucumber compare insert < CUCUMBER] {
	    set ::buffer [$cucumber get insert CUCUMBER]
	}
    }
}

proc _hdl_default_mark {cucumber info_label} {
    set marked_id [$cucumber index insert]
    $cucumber mark set CUCUMBER $marked_id
    $info_label configure -text "Mark set at: $marked_id"
}

proc _hdl_move_toContentHead {cucumber} {
    set id [$cucumber search -regexp {\S} {insert linestart} {insert lineend}]
    if {$id != {}} {
        $cucumber mark set insert $id
        $cucumber see insert
    }
    return -code break
}

proc _hdl_move_toLineStart {cucumber} {
    $cucumber mark set insert {insert linestart}
    $cucumber see insert
}

proc _hdl_move_toLineEnd {cucumber} {
    $cucumber mark set insert {insert lineend}
    $cucumber see insert
}

proc _hdl_move_toPrevWord {cucumber} {
    set n 1
    while {[regexp {\W} [$cucumber get "insert - $n c"]]} {
        if [$cucumber compare "insert - $n c" == 1.0] {
            break
        }
        incr n
    }
    after idle "$cucumber mark set insert \"insert - $n c wordstart\"; $cucumber see insert"
}

proc _hdl_move_toNextWord {cucumber} {
    set span {}
    if [$cucumber compare insert == {end -1c}] {return}
    set start [$cucumber search -regexp -nolinestop -count span {\w\W} insert {end -1c}]
    if {$span ne {}} {
        after idle "$cucumber mark set insert \"$start + $span c -1c\"; $cucumber see insert"
    }
}

proc _hdl_move_toDocHead {cucumber} {
    after idle "$cucumber mark set insert 1.0; $cucumber see insert"
}

proc _hdl_move_toDocEnd {cucumber} {
    after idle "$cucumber mark set insert {end -1c}; $cucumber see insert"
}

proc _hdl_move_backSpaceWord {cucumber} {
    set old_insert [$cucumber index insert]
    _hdl_move_toPrevWord $cucumber
    after idle "$cucumber delete insert $old_insert; _tool_decrLinum $cucumber"
    return -code break
}

proc _hdl_move_deleteWord {cucumber} {
    set old_insert [$cucumber index insert]
    _hdl_move_toNextWord $cucumber
    after idle "$cucumber delete $old_insert insert; _tool_decrLinum $cucumber"
    return -code break
}

proc _hdl_plus_autoComplete {cucumber} {
    if $::any_action {
        _tool_getBase $cucumber
    }
}

#----------------------------------------#

proc _tool_ifSelected {cucumber} {
    return [expr ![catch "$cucumber index sel.first"]]
}

proc _tool_ifInQuote {cucumber {id insert}} {
    return [expr [llength [$cucumber search -backward -all -regexp {[^\\]\"} id]] % 2]
}

proc _tool_contentYScroll {scrollbar line_number_column first last} {
    $scrollbar set $first $last
    $line_number_column yview moveto $first
}

proc _tool_linum {cucumber id} {
    return [expr int($cucumber index $id)]
}

proc _tool_incrLinum {line_number_column} {
    set text_end_num [_tool_linum {end -1c}]
    set linum_diff [expr $text_end_num - $::linum]
    
    if {$linum_diff > 0} {
        $line_number_column configure -state normal
        while {$::linum < $text_end_num} {
            incr ::linum
            $line_number_column insert end "\n$::linum" justright
            set line_number_width [string length $::linum]
            if {$line_number_width < $::linum_png_width} {
                set line_number_width $::linum_png_width
            }
            $line_number_column configure -width $line_number_width
        }
        $line_number_column configure -state disable
    }
}

proc _tool_decrLinum {line_number_column} {
    set text_end_num [_tool_linum {end -1c}]
    
    if {$text_end_num < $::linum} {
        $line_number_column configure -state normal
        $line_number_column delete "$text_end_num.end" end
        set ::linum $text_end_num
        $line_number_column configure -state disable
        
        set line_number_width [string length $::linum]
        if {$line_number_width < $linum_png_width} {
            set line_number_width $linum_png_width
        }
        $line_number_column configure -width $line_number_width
    }
}

proc _tool_ifInWord {cucumber id} {
    # -1 => word head
    # 1  => word end
    # 2  => in word
    # 0  => not in word
    
    if [$cucumber compare $id == "$id linestart"] {
        if [regexp {\W} [$cucumber get $id]] {
            return 0
        }
        return -1
    }
    
    if [$cucumber compare $id == "$id lineend"] {
        if [regexp {\W} [$cucumber get "$id -1c"]] {
            return 0
        }
        return 1
    }
    
    set word "[$cucumber get {$id -1c}][$cucumber get $id]"
    
    if [regexp {\W{2}} $word] {
        return 0
    } 
    if [regexp {\w\W} $word] {
        return 1
    }
    if [regexp {\W\w} $word] {
        return -1
    }
    return 2
}

proc _tool_indexWordHead {cucumber id} {
    if [$cucumber compare $id == "$id linestart"] {
        return [$cucumber index $id]
    } else {
        set n 1
        while {![regexp {\W} [$cucumber get "$id - $n c"]]} {
            if [$cucumber compare "$id - $n c" == "$id linestart"] {
                return [$cucumber index {insert linestart}]
            }
            incr n
        }
        return [$cucumber index "$id - $n c + 1c"]
    }
}

proc _tool_indexWordEnd {cucumber id} {
    if [$cucumber compare $id == "$id lineend"] {
        return [$cucumber index $id]
    } else {
        set n 1
        while {![regexp {\W} [$cucumber get "$id + $n c "]]} {
            incr n
            if [$cucumber compare "$id + $n c" == "$id lineend"] {
                break
            }
        }
        return [$cucumber index "$id + $n c"]
    }
}

_proc _tool_initAutoComp {cucumber} {
    if [_tool_ifInWord $cucumber] {
        set ::auto_comp_word_start [_tool_indexWordHead $cucumber insert]
        set ::auto_comp_search_pos [$cucumber index "$::auto_comp_word_start -1c"]
        set ::auto_comp_word [$cucumber get $::auto_comp_word_start insert]
        set ::auto_comp_list_id 0
        set ::auto_comp_list {}
    }
}