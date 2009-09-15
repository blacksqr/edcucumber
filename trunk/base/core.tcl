proc _tool_core_fake {cucumber fake} {
    rename $cucumber $fake
    proc $cucumber {args} {
        after idle [_tool_core_sortMap $fake $args]
    }
}

proc _tool_core_sortMap {fake args} {
    switch $args {
        insert* {
            set from [$fake index [lindex $args 1]]
            set to "$from + [string length [lindex $args 2]]c"
            return "_tool_core_hiContent $fake $from $to"
        }
        delete* {
            set from [$fake index [lindex $args 1]]
            if [set to [lindex $args 2]] {
                return "_tool_core_hiContent $fake $from $to"
            } else {
                return "_tool_core_hiContent $fake $from $from"
            }
        }
        {mark set insert*} { return "_tool_core_hiLine $fake" }
    }
}

proc _tool_core_tags {fake} {
    $fake tag configure C1 -foreground #0000FF
    $fake tag configure C2 -foreground #FF0000
    $fake tag configure C3 -foreground #EE9A00

    $fake tag configure Num -foreground #FF0000
    $fake tag configure Com -foreground #FF0000
    $fake tag configure Var -foreground #B23AEE
    $fake tag configure Quo -foreground #FF34B3
    
    foreach t {C1 C2 C3 Num} { $fake tag lower $t Var }
    $fake tag lower Var Com
    $fake tag lower Com Quo
    
    $fake tag configure Lin -bckground #9ACD32
    $fake tag lower Lin
}

proc _tool_core_initSyntax {file} {
    array set ::syntax {}
    set fid [open $file r]
    while {![eif $fid]} {
        set line [string trim [get $fid]]
        if [regexp {\/(C[0-9]).*} $line match t] {
            set tag $t
            continue
        }
        foreach w $line {array set ::syntax "$w $tag"}
    }
    close $fid
}

proc _tool_core_hiContent {fake from to} {
    set from [_tool_core_hiWord $from]
    while {[fake compare $from <= $to]} {
        set from [_tool_core_hiWord $fake $from]
    }
    if [regexp {\"} [$fake get $from $to]] {
        _tool_core_hiQuoteContext $fake
    }
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
    if [regexp {^\d+$} $w] { return Num }
    if [catch {set tag $::syntax($w)}] { return {} }
    return $tag
}

proc _tool_core_hiVariableContext {fake head end} {
    if [$fake compare $head > "$head linestart"] {
        if {([$fake search -backwards -regexp {[^\\]*\$\{[^\}]*} $head "$head linestart"] \
                && [$fake search -regexp {[^\\]*\}} $end "$end lineend"]) \
            || [$fake search -backwards -regexp {[^\\]*\$(::)?\w*} $head "$head linestart"]} {
                $fake tag add Var $head $end
            }
    }
}

proc _tool_core_hiQuoteContext {fake} {
    catch {after cancel [_hiQuoteContext $fake]}
    after 1000 [_hiQuoteContext $fake]
}

proc _hiQuoteContext {fake} {
    if {[$fake get 1.0] == "\""} { set rid [list 1.0] } else { set rid {} }
    set qid [$fake search -nolinestop -overlap -all -regexp {[^\\]\"} 1.0 end]
    foreach id $qid { lappend rid [$fake index [$fake index "$id + 1c"]] }
    
    if ![set e [llength $rid]] {return}
    set now [lindex $rid 0]
    $fake tag remove Quo 1.0 "$now +1c"
    
    set i 1
    while {$i < $e} {
        set old $now
        set now [lindex $rid $i]
        if [expr $i % 2] {
            $fake tag add Quo $old "$now +1c"
        } else {
            $fake tag remove Quo $old "$now +1c"
        }
        incr i
    }
    
    if [expr $e % 2] {
        $fake tag add Quo $now end
    } else {
        $fake tag remove Quo $now end
    }
}

proc _tool_core_hiCommentContext {fake from to} {
    set f [_tool_linum $fake $from]
    set t [_tool_linum $fake $to]
    while {$f <= $t} {
        if [$fake search -regexp {(^\s*#)|(\;\s*\#)} "$f.0" "$f.0 lineend"] {
            $fake tag add [$fake search {#} "$f.0" "$.0 lineend"] "$f.0 lineend"
        }
        incr f
    }
}

proc _tool_core_hiLine {$fake} {
    
}