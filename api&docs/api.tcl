#----------------------------------------#

set buffer         {}
set linum           1
set linum_png_width 2

set auto_comp_word  {}
set auto_comp_start {}
set auto_comp_end   {}
set auto_comp_pos   {}
set auto_comp_list  {}
set auto_comp_list_id 0

set auto_targets  {.f.content .extra}
set extra_pos     end
set extra_targets {}

set indent_width 4

set search_word {}
set regexp 0

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
        [list <Alt-z>     [list [list _hdl_defaut_redo $cucumber] [list _tool_incrLinum $line_number_column] [list _tool_decrLinum $line_number_column]]]
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
        {<Control-bracketleft>  _hdl_move_searchNextWord}
        {<Control-bracketright> _hdl_move_searchPrevWord}
    }
}

proc _data_plusEvents {} {
    return {
        {<Alt-/>     _hdl_plus_autoComplete}
        {<Tab>       _hdl_plus_autoIndent}
        {<Return>    _hdl_plus_autoIndent}
        {<Control-r> _hdl_plus_run}
    }
}

#----------------------------------------#

proc _bind_defaultEvents {cucumber line_number_column} {
    foreach {evt handles} [_data_defaultEvents] {
        foreach hdl $handles {
            bind $cucumber $evt "+ $hdl"
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

proc _bind_plusEvents {cucumber} {
    foreach {evt hdl} [_data_plusEvents] {
        bind $cucumber $evt "+ $hdl $cucumber"
    }
}

#----------------------------------------#

proc _hdl_defaut_redo {cucumber} {
    catch {$cucumber edit redo}
}

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
    set h [_tool_indexLineContentHead $cucumber]
    if $h {
        $cucumber mark set insert $h
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
    if {(($::auto_comp_end == {}) \
            || [$cucumber compare $::auto_comp_end != insert] \
            || ![regexp "^$::auto_comp_word" [$cucumber get $::auto_comp_start $::auto_comp_end]]) && [_tool_ifInWord $cucumber insert]} {
                _tool_autoComp_init
                set widget_index [lsearch $::search_targets $cucumber]
                set ::extra_targets [lreplace $::auto_targets $widget_index $widget_index]
                set ::extra_pos end
            }
    # set ::extra_pos end
    if [_tool_ifInWord $cucumber insert] {
        if ![_tool_autoComp_ifSearchFinished] {
            _tool_autoComp_getNextWord
        } else {
            _tool_autoComp_getNextExtraWord
        }
        
        set list_length [llength $::auto_comp_list]
        if [expr ! $list_length] {
            return
        }        
        incr ::auto_comp_list_id
        if {$::auto_comp_list_id >= $list_length} {
            set ::auto_comp_list_id 0
        }
        $cucumber replace $::auto_comp_start $::auto_comp_end [lindex $::auto_comp_list $::auto_comp_list_id]
        after idle [list set ::auto_comp_end [$cucumber index insert]]
        _tool_hi
    }
}

proc _hdl_plus_autoIndent {cucumber} {
    if {[_tool_linum $cucumber] > 1]} {
        set indet_span [expr [_tool_indexLineContentHead $cucumber {insert -1 l}] - [_tool_linum {insert -1 l}]]
        $cucumber replace {insert linestart} [_tool_indexLineContentHead $cucumber insert] [string repeat { } $indet_span]
    }
    return -code break
}

proc _hdl_move_searchNextWord {cucumber} {
    if $::regexp { set mod {-regexp} } else { set mod {-exact} }
    set sw [string trim $::search_word]
    if {$sw nw {}} {
        set old [$cucumber index insert]
        set now [$cucumber search $mod $sw insert]
        if {$now eq {}} {
            focus $cucumber
            return
        }
        $cucumber mark set insert $now
        if [$cucumber compare $old == insert] {
            $cucumber mark ser insert [$cucumber search $mod $sw "insert +1 c"]
        }
    }
    focus $cucumber
    $cucumber see insert
}

proc _hdl_move_searchPrevWord {cucumber} {
    if $::regexp { set mod {-regexp} } else { set mod {-exact} }
    
    set sw [string trim $::search_word]
    if {$sw ne {}} {
        set now [$cucumber search -backward $mod $sw insert]
        if {$now eq {}} {
            focus $cucumber
            return
        }
        $cucumber mark set insert $now
    }
    focus $cucumber
    $cucumber see insert
}

proc _hdl_plus_run {cucumber} {
    catch {interp delete foo}
    interp create foo
    interp eval foo {
        rename puts _puts
        proc puts {args} {
            _puts $args
            return $args
        }
    }
    set err [interp eval foo [$cucumber get 1.0 end]]
    .sf.lb configure -text "result: $err"
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

proc _incrLinum {line_number_column} {
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

proc _tool_incrLinum {line_number_column} {
    after idle [list _incrLinum $line_number_column]
}

proc _decrLinum {line_number_column} {
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

proc _tool_decrLinum {line_number_width} {
    after idle [list _decrLinum $list]
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

proc _tool_autoComp_loadFiles {file_names} {
    text .loadedfiles
    foreach f $file_names {
        set fd [open $f r]
        .loadedfiles insert end [read $fd]
        close $fd
    }
}

proc _tool_autoComp_init {cucumber} {
    set ::auto_comp_start [_tool_indexWordHead insert]
    set ::auto_comp_end   [$cucumber index insert]
    set ::auto_comp_pos   [$cucumber index "$::auto_comp_start -1c"]
    set ::auto_comp_word  [$cucumber get $::auto_comp_start $::auto_comp_end]
    set ::auto_comp_list  [list $::auto_comp_word]
    set ::auto_comp_list_id 0
}

proc _tool_autoComp_ifSearchFinished {cucumber} {
    if {$::auto_comp_pos == {}} {return 1}
    return [$cucumber compare $::auto_comp_pos == $::auto_comp_start]
}

proc _tool_autoComp_getNextWord {cucumber} {
    set ::auto_comp_pos [$cucumber search -nolinestop -backwards -regexp $::auto_comp_word $::auto_comp_pos]
    while {[$cucumber compare $::auto_comp_pos != [_tool_indexWordHead $::auto_comp_pos]]} {
        set ::auto_comp_pos [$cucumber search -nolinestop -backwards -regexp $::auto_comp_word $::auto_comp_pos]
    }
    
    set word [$cucumber get $::auto_comp_pos "$::auto_comp_pos wordend"]
    set duplicate 0
    foreach w $::auto_comp_list {
        if {$w == $word} {
            set duplicate 1
            break
        }
    }
    if $duplicate {
        if ![_tool_autoComp_ifSearchFinished $cucumber] {
            return [_tool_autoComp_getNextWord $cucumber]
        }
    } else {
        lappend ::auto_comp_list $word
    }
}

proc _tool_hi {cucumber} {
    if ![catch {info args _tool_hi_line}] {
        _tool_hi_switchHighlightLine $cucumber
    }
    if ![catch {info args _tool_hi_word}] {
        _tool_hi_word $cucumber
    }
}

proc _tool_autoComp_ifExtraFinished {} {
    return ![llength $::extra_targets]
}

proc _tool_autoComp_ifExtraPosInvalid {} {
    return [expr {$::extra_pos == {1.0} || $::extra_pos == {}}]
}

proc _tool_autoComp_getNextExtraWord {} {
    if [_tool_autoComp_ifExtraFinished] {return 0}
    
    if [_tool_autoComp_ifExtraPosInvalid] {
        set ::extra_targets [lreplace $::extra_targets 0 0]
        set ::extra_pos end
        return [_tool_autoComp_getNextExtraWord]
    }
    
    set target [lindex $::extra_targets 0]
    set ::extra_pos [$target search -nolinestop -backwards -regexp $::auto_comp_word $::extra_pos 1.0]
    while {($::extra_pos != {}) && [$target compare $::extra_pos != [_tool_indexWordHead $target $::extra_pos]]} {
        set ::extra_pos [$target search -nolinestop -backwards -regexp $::auto_comp_word $::extra_pos 1.0]
    }
    if {$::extra_pos == {}} {return [_tool_autoComp_getNextExtraWord]}
    
    set word [$target get $::extra_pos "$::extra_pos wordend"]
    set duplicate 0
    foreach w $::auto_comp_list {
        if {$w == $word} {
            set duplicate 1
            break
        }
    }
    if $duplicate {
        return [_tool_autoComp_getNextExtraWord]
    } else {
        lappend ::auto_comp_list $word
    }
}

proc _tool_indexLineContentHead {cucumber {position insert}} {
    set j [$cucumber search -regexp {\S} "$position linestart" "$position lineend"]
    return $j
}

proc _tool_indexContextMargin {cucumber id_l id_r l r} {
    set id_l [$cucumber search -backward -nolinestop -regexp "\\$l" $id_l 1.0]
    set id_r [$cucumber search -backward -nolinestop -regexp "\\$r" $id_r 1.0]

    if {$id_l eq {}}  {return 1.0}
    if {$id_r eq {}}  {return $id_l}
    if {[$cucumber compare $id_l < $id_r]} {return [_tool_indexContextMargin $id_l $id_r $l $r]}
    return $id_l
}

proc _tool_evtGenerator {cucumber event} {
    event generate $cucumber $event
}