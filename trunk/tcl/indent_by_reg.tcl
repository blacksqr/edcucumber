proc bindIndent {} {
    bind .f.content <Return> {+ hdlReturn}
    bind .f.content <Tab> hdlIndent
}

#-------------------------------------------------------#

proc hdlReturn {} {
    after idle {event generate .f.content <Tab>}
}

proc hdlIndent {} {
    if {[linum insert] <= 1} {
	set i [.f.content search -regexp {\S} {insert linestart} {insert lineend}]
	if {$i ne {}} {
	    .f.content mark set insert $i
	}
	return -code break
    }

    set indent 0
    if {[.f.content search -regexp {\\\s*$} {insert -1l linestart} {insert -1l lineend}] ne {}} {
	incr indent 4
    }
    
    set brc [myBraceLeft {insert -1l lineend} {insert -1l lineend}]
    set bkt [myBracketLeft {insert -1l lineend} {insert -1l lineend}]

    # puts "{$brc} {$bkt}"
    set itv 0

    if {$brc eq {} && $bkt eq {}} {
	# nothing
    } elseif {$brc eq {}} {
	foreach {_ i} [split $bkt {.}] {}
	incr indent $i
	set itv 1
    } elseif {$bkt eq {}} {
	foreach {_ i} [split [realLineHead $brc] {.}] {}
	incr indent $i
	set itv 4
    } elseif {[.f.content compare $brc < $bkt]} {
	foreach {_ i} [split $bkt {.}] {}
	incr indent $i
	set itv 1
    } else {
	foreach {_ i} [split [realLineHead $brc] {.}] {}
	incr indent $i
	set itv 4
    }
    
    set j [realLineHead]
    set f [.f.content get $j]

    if {$f ne "\}" && $f ne "\]"} {incr indent $itv}
    if {$f eq "\}" && $itv != 4}  {incr indent $itv}
    if {$f eq "\]" && $itv != 1}  {incr indent $itv}

    .f.content replace {insert linestart} $j [string repeat { } $indent]

    if ![catch {info args switchHighLightLine}] {
    	switchHighLightLine
    }

    return -code break
}

proc realLineHead {{id insert}} {
    set j [.f.content search -regexp {\S} "$id linestart" "$id lineend"]
    if {$j eq {}} {set j [.f.content index {insert lineend}]}
    return $j
}

proc myBraceLeft {id_1 id_2} {
    return [myLeft $id_1 $id_2 "\{" "\}"]
}

proc myBracketLeft {id_1 id_2} {
    return [myLeft $id_1 $id_2 "\[" "\]"]
}

proc myLeft {id_1 id_2 l r} {
    set id_1 [.f.content search -backward -nolinestop -regexp "\\$l" $id_1 1.0]
    set id_2 [.f.content search -backward -nolinestop -regexp "\\$r" $id_2 1.0]

    # puts "{$id_1} {$id_2}"

    if {$id_1 eq {}}  {return {}}
    if {$id_2 eq {}}  {return $id_1}
    if {[.f.content compare $id_1 < $id_2]} {return [myLeft $id_1 $id_2 $l $r]}
    return $id_1
}

#-------------------------------------------------------#

bindIndent
