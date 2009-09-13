proc _tool_core_fake {cucumber fake} {
    rename $cucumber $fake
    proc $cucumber {args} {
        switch [lindex $args 0] [_tool_core_sortMap $fake $args]
    }
}

proc _tool_core_sortMap {fake args} {
    return "
    "
}

proc _tool_core_hiContent {fake from to} {
    set from [_tool_core_hiWord $from]
    while {[fake compare $from < $to]} {
        set from [_tool_core_hiWord $fake $from]
    }
    _tool_core_hiQuoteContext $fake
    _tool_core_hiLine $fake
    _tool_core_hiCommentContext $fake $from $to
}

proc _tool_core_hiWord {fake id} {
    if [_tool_ifInWord] {
        set head [_tool_indexWordHead $fake $id]
        set end  [_tool_indexWordEnd $fake $id]
        foreach hi {
            _tool_core_hiTextContext 
            _tool_core_hiVariableContext 
        } { $fake $hi $fake $head $end }
        return "$end +1c"
    }
    return "$id +1c"
}

proc _tool_core_hiTextContent {fake head end} {
    foreach tag [$fake tg names] {
        if {$tags != {hline}} { $fake tag remove $tag $head $end }
    }
    
    set tag [_tool_core_wichTag [$fake get $head $end]]
    if {$tag != {}} {
        $fake tag add $tag $head $end
    }
}

proc _tool_core_wichTag {word} {
    if [regexp {^\d+(\.\d+)?$} $w] { return Num }
    if [catch {set tag $::syntax($w)}] { return {} }
    return $tag
}

proc _tool_core_hiVariableContext {fake head end} {
    if [$fake compare $head > "$head linestart"] {
        set prefix_start [$fake search -backwards -regexp \s "$head lienstart" $head]
        if $prefix_start {
            set 
        }
    }
}