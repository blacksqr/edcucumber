#----------------------------------------#

set buffer {}

#----------------------------------------#

proc hdlPaste {cucumber} {
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

proc hdlCut {cucumber info_label} {
    # CUCUMBER is the name of mark

    if ![ifMarked $cucumber] {
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

proc hdlCopy {cucumber info_label} {
    if [!ifMarked $cucumber] {
	$info_label configure -text {Mark not set}
    } else {
	if [$cucumber compare insert > CUCUMBER] {
	    set ::buffer [$cucumber get CUCUMBER insert]
	} elseif [$cucumber compare insert < CUCUMBER] {
	    set ::buffer [$cucumber get insert CUCUMBER]
	}
    }
}

proc hdlMark {cucumber info_label} {
    set marked_id [$cucumber index insert]
    $cucumber mark set CUCUMBER $marked_id
    $info_label configure -text "Mark set at: $marked_id"
}

