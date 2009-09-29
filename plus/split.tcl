package require Tk
set globalLbID 1
set globalTxID 1
set textList {}

proc splitFrame {path new dir} {
    # puts [place info $path]
    array set info [place info $path]
    # puts [array names info]
    set o_x $info(-relx)
    set o_y $info(-rely)
    set w $info(-relwidth)
    set h $info(-relheight)
    if {$w eq {1}} { set w "$w.0" }
    if {$h eq {1}} { set h "$h.0"}
    
    if {$dir == {vertical}} {
        set o_w $w
        set o_h [expr $h / 2]
        set n_x $o_x
        set n_y [expr $o_y + $o_h]
    } else {
        set o_w [expr $w / 2]
        set o_h $h
        set n_x [expr $o_x + $o_w]
        set n_y $o_y
    }
    set n_w $o_w
    set n_h $o_h
    #puts "$o_x $o_y $o_w $o_h"
    place forget $path
    place $path -relx $o_x -rely $o_y -relwidth $o_w -relheight $o_h
    place $new  -relx $n_x -rely $n_y -relwidth $n_w -relheight $n_h
}

proc newLabelFrame {title sibling} {
    set nm ".lb$::globalLbID"
    labelframe $nm -text $title
    incr ::globalLbID
    
    foreach t $::textList {
        ".$t" peer create "$nm.$t"
        bind "$nm.$t" <Control-k> [list killBuffer %W $t]
        bind "$nm.$t" <Control-Left> [list rotateBuffer %W $t left]
        bind "$nm.$t" <Control-Right> [list rotateBuffer %W $t right]
        if [winfo ismap "$sibling.$t"] {
            pack "$nm.$t" -fill both -expand 1
        }
    }

    return $nm
}

proc newText {textname} {
    foreach t $::textList {if {$t == $textname} {return}}
    lappend ::textList $textname
    set ::textID [expr [llength $::textList] -1]
    text ".$textname"
    set temp $::globalLbID
    while {$temp > 0} {
        if [winfo exists ".lb$temp"] {
            foreach t $::textList {
                pack forget ".lb$temp.$t"
            }
            set nm ".lb$temp.$textname"
            
            ".$textname" peer create $nm
	    pack $nm -fill both -expand 1
	    bind $nm <Control-k> [list killBuffer %W $textname]
	    bind $nm <Control-Left> [list rotateBuffer %W $textname left]
	    bind $nm <Control-Right> [list rotateBuffer %W $textname right]
	}
	incr temp -1
    }
}

proc killBuffer {pathname textname} {
    set where [lsearch $::textList $textname]
    set ::textList [lreplace $::textList $where $where]
    set len [llength $::textList]
    if {$len == 0} {exit}

    destroy ".$textname"
    set temp $::globalLbID
    while {$temp > 0} {	
        if [winfo exists ".lb$temp"] {
            set pn ".lb$temp.$textname"
            destroy $pn
            if {$where == $len} {set where 0}
            set t ".lb$temp.[lindex $::textList $where]"
            pack $t -fill both -expand 1
            if {$pn == $pathname} {focus $pn}
	}
	incr temp -1
    }
}

proc rotateBuffer {pathname textname dir} {
    set len [llength $::textList]
    if {$len == 1} {return}
    set now [lsearch $::textList $textname]
    if {$dir == {left}} {
	incr now -1
	if {$now < 0} {
	    set now [expr $len -1]
	}
    } else {
	incr now
	if {$now == $len} {
	    set now 0
	}
    }

    pack forget $pathname
    set t "[regsub {(.+)\..+} $pathname {\1}].[lindex $::textList $now]"
    pack $t -fill both -expand 1
    focus $t
}

if 1 {
    button .bt1 -text {new frame} -command test_newframe
    button .bt2 -text {new text} -command  "newText \$::globalTxID; incr ::globalTxID"
    
    set nm ".lb$::globalLbID"
    labelframe $nm -text test
    incr ::globalLbID
    place $nm -relx 0 -rely 0 -relwidth 1.0 -relheight 0.8
    
    newText $::globalTxID
    incr ::globalTxID
    
    place .bt1 -relx 0.3 -rely 0.9
    place .bt2 -relx 0.7 -rely 0.9
}

proc test_newframe {} {
    splitFrame .lb1 [newLabelFrame [lindex {niho shijie wodemingzi jiao jinhao} [expr int(5*rand())]] .lb1] horizontal
}