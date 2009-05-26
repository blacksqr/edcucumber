package require treectrl
package require style::as
package require widget::scrolledwindow

if 0 {
    package require Tk
    frame .f
    text .f.content
    pack .f .f.content
}

toplevel .a -height 40
widget::scrolledwindow .a.sw 

treectrl .a.sw.l \
    -highlightthickness 0 \
    -borderwidth 0 \
    -showheader 0 \
    -showroot no \
    -showbuttons no \
    -selectmode browse \
    -xscrollincrement 20 \
    -scrollmargin 16 \
    -xscrolldelay {500 50} \
    -yscrolldelay {500 50}

set bg $::style::as::highlightbg
set fg $::style::as::highlightfg

.a.sw.l element create eletext text -lines 1 -fill [list $fg {selected focus}]
.a.sw.l element create elepic image
.a.sw.l element create elerect rect -fill [list $bg {selected focus} gray {selected !focus}]

.a.sw.l style create comp -orient horizontal
.a.sw.l style elements comp {elerect elepic eletext}
.a.sw.l style layout comp elerect -union {elepic eletext} -iexpand news
.a.sw.l style layout comp eletext -squeeze x -expand ns -padx 2

.a.sw.l column create -tag words

pack .a.sw -expand 1 -fill both
.a.sw setwidget .a.sw.l

wm withdraw .a
wm overrideredirect .a 1

#--------------------------------------------------------#

bind .f.content <Alt-/> {+ hdlAtuoComplete}
set rootx [winfo rootx .f.content]
set rooty [winfo rooty .f.content]

proc hdlAtuoComplete {} {
    set pos [ifInWord insert]
    if {$pos > 0} {
	set f [indexWordHead $id]
	set e [indexWordEnd  $id]
	set base [.f.content get $f $e]
	
	set ids [.f.content search -backward -all $base insert]
	
	if [llength $ids] {
	    set words [list]
	    set max_l 0
	    foreach id $ids {
		set w [.f.content get $id "$id wordend"]
		set l [string length $w]
		if {$l > $max_l} {
		    set max_l $l
		}
		lappend words $w
	    }
	    updateAutoList $words $max_l
	    popupAutopList
	}
    }

    return -code break
}

proc updateAutoList {ws l} {
    .a.sw.l column configure words -width $l
    foreach w $ws {
	set it [.a.sw.l item create -button 0 -parent 0 -visible 1]
	.a.sw.l item style set $it words comp
	.a.sw.l item text $it words "$w"
    } 
    .a.sw.l selection first
}

proc popupAutoList {} {
    foreach {x y _ _} [.f.content bbox insert] {}
    set pw [winfo reqwidth .a]
    set ph [winfo reqheight .a]

    set x [expr $::rootx + $x]
    set y [expr $::rooty + $y]

    if {(($x + $pw) > [winfo screenwidth .]) || \
	    (($y + $ph) > [winfo screenheight .])} {
	set x [expr $x - $pw]
	set y [expr $y - $ph]
    }

    focus .a.sw.l
    wm geometry .a +$x+$y
    wm deiconify .a
    bind .a <1> "releaseGrabCheck %X %Y"
    bind .a <Escape> "releaseGrab"
    bind .a <Return> "releaseGrabWithComplete"
    bind .a.sw.l <Alt-/> ".a.sw.l selection below"
    bind .a.sw.l <Ctrl-/> ".a.sw.l selection above"
}

proc releaseGrab {} {
    wm withdraw .a
    .a.sw.l item delete first last
}

proc releaseGrabChech {mx my} {
    set x [winfo rootx .a]
    set y [winfo rooty .a]
    set w [winfo reqwidth .a]
    set h [winfo reqheight .a]

    if {($mx < $x) || \
	    ($my < $y) || \
	    ($mx > ($x + $w)) || \
	    ($my > ($y + $h))} {
	releaseGrab
    } else {
	# nearest x y
    }
}