#-------------------------------------------------------#
proc bindFastMove {} {
    foreach eh [fastMoveEvents] {
        foreach {e h} $eh {}
	# without + to overload TK ORIGIN BINDINGS
        bind .f.content $e $h
    }
}

proc fastMoveEvents {} {
    return {
        {<Control-e>   hdlMoveToLineEnd}
        {<Control-a>   hdlMoveToLineStart}
        {<Alt-b>       hdlMoveToPreviousWord}
        {<Alt-f>       hdlMoveToNextWord}
        {<Alt-<>       hdlMoveToDocHead}
        {<Alt-greater> hdlMoveToDocEnd}
	{<Alt-/>       hdlMoveToContentHead}
    }
}

#-------------------------------------------------------#

proc hdlMoveToContentHead {} {
    .f.content mark set insert [.f.content search -regexp {\w} {insert linestart} {insert lineend}]
}

proc hdlMoveToLineEnd {} {
    .f.content mark set insert {insert lineend}
}

proc hdlMoveToLineStart {} {
    .f.content mark set insert {insert linestart}
}

proc hdlMoveToPreviousWord {} {
    set bw 1
    while {[regexp {\W} [.f.content get "insert - $bw c"]]} {
        if [.f.content compare "insert - $bw c" == 1.0] {
            break
        }
        incr bw
    }
    after idle [list .f.content mark set insert "insert - $bw c wordstart"]
}

proc hdlMoveToNextWord {} {
    if [.f.content compare insert == {end - 1c}] {return}
    set start [.f.content search -forwards -regexp -nolinestop -count span {\w+\W} insert {end - 1c}]
    after idle [list .f.content mark set insert "$start + $span c - 1 c"]
}

proc hdlMoveToDocHead {} {
    after idle {.f.content mark set insert 1.0}
}

proc hdlMoveToDocEnd {} {
    after idle {.f.content mark set insert {end - 1c}}
}


#-------------------------------------------------------#

bindFastMove