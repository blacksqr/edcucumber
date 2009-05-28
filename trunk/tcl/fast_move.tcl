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
	{<Alt-m>       hdlMoveToContentHead}
    }
}

#-------------------------------------------------------#

proc hdlMoveToContentHead {} {
    .f.content mark set insert [.f.content search -regexp {\w} {insert linestart} {insert lineend}]
    .f.content see insert
}

proc hdlMoveToLineEnd {} {
    .f.content mark set insert {insert lineend}
    .f.content see insert
}

proc hdlMoveToLineStart {} {
    .f.content mark set insert {insert linestart}
    .f.content see insert
}

proc hdlMoveToPreviousWord {} {
    set bw 1
    while {[regexp {\W} [.f.content get "insert - $bw c"]]} {
        if [.f.content compare "insert - $bw c" == 1.0] {
            break
        }
        incr bw
    }
    after idle ".f.content mark set insert \"insert - $bw c wordstart\"; .f.content see insert"
}

proc hdlMoveToNextWord {} {
    if [.f.content compare insert == {end - 1c}] {return}
    set start [.f.content search -forwards -regexp -nolinestop -count span {\w+\W} insert {end - 1c}]
    after idle ".f.content mark set insert \"$start + $span c - 1 c\"; .f.content see insert"
}

proc hdlMoveToDocHead {} {
    after idle {
	.f.content mark set insert 1.0
	.f.content see insert
    }
}

proc hdlMoveToDocEnd {} {
    after idle {
	.f.content mark set insert {end - 1c}
	.f.content see insert
    }
}


#-------------------------------------------------------#

bindFastMove