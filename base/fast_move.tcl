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
        
        {<Control-BackSpace> hdlBackSpaceWord}
        {<Control-Delete> hdlDeletWord}
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
    set span {}
    if [.f.content compare insert == {end - 1c}] {return}
    set start [.f.content search -forwards -regexp -nolinestop -count span {\w+\W} insert {end - 1c}]
    if {$span ne {}} {
        after idle ".f.content mark set insert \"$start + $span c - 1 c\"; .f.content see insert"
    }
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

proc hdlBackSpaceWord {} {
    set old [.f.content index insert]
    hdlMoveToPreviousWord
    after idle [list _dd insert "$old -1c"]
}

proc hdlDeletWord {} {
    set old [.f.content index insert]
    hdlMoveToNextWord
    after idle [list _dd $old insert]
}

proc _dd {f c} {
    .f.content delete $f $c
    decrLinum
}

#-------------------------------------------------------#

bindFastMove



