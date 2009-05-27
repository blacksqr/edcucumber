package require treectrl
package require style::as
package require widget::scrolledwindow
style::as::init

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
    -showheader 1 \
    -showroot no \
    -showbuttons no \
    -selectmode browse \
    -xscrollincrement 20 \
    -scrollmargin 16 \
    -xscrolldelay {500 50} \
    -yscrolldelay {500 50}

.a.sw.l column create -text tokens -tag words -expand 1 -squeeze 1 -image [pngObj::produce {add.png}]
set height [font metrics [.a.sw.l cget -font] -linespace]
if {$height < 18} {
    set height 18
}
.a.sw.l configure -itemheight $height
.a.sw.l column configure all -itembackground {#F7F7F7 {}}

set bg $::style::as::highlightbg
set fg $::style::as::highlightfg

.a.sw.l element create eletext text -lines 1 -fill [list $fg {selected focus}]
.a.sw.l element create elepic image
.a.sw.l element create elerect rect -fill [list $bg {selected focus} gray {selected !focus}]

.a.sw.l style create comp -orient horizontal
.a.sw.l style elements comp {elerect elepic eletext}
.a.sw.l style layout comp elerect -union {elepic eletext} -iexpand news
.a.sw.l style layout comp eletext -squeeze x -expand ns -padx 2

.a.sw setwidget .a.sw.l
pack .a.sw -expand 1 -fill both

wm withdraw .a
wm overrideredirect .a 1


bind .a <1> "releaseGrabCheck %X %Y %x %y"
bind .a <Escape> "releaseGrab"
bind .a <Return> "releaseGrabWithComplete"

set wf {}
set we {}

#--------------------------------------------------------#

bind .f.content <Alt-/> {+ hdlAtuoComplete}

proc hdlAtuoComplete {} {
    set pos [ifInWord insert]
    if {$pos > 0} {
	set ::wf [indexWordHead insert]
	set ::we [indexWordEnd  insert]
	set base [.f.content get $::wf $::we]

	set ids [.f.content search -nolinestop -backward -all -regexp "$base" $::wf]
	
	if [llength $ids] {
	    set words [list]
	    foreach id $ids {
		set w [.f.content get $id "$id wordend"]
		set l [string length $w]
		lappend words $w
	    }
	    updateAutoList $words
	    popupAutoList
	}
    }

    return -code break
}

proc updateAutoList {ws} {
    foreach w $ws {
	set it [.a.sw.l item create -button 0 -parent 0 -visible 1]
	.a.sw.l item style set $it words comp
	.a.sw.l item text $it words "$w"
    } 
    .a.sw.l selection add {first visible}
    # puts [.a.sw.l item id {first state selected next}]
}

proc popupAutoList {} {
    foreach {x y _ _} [.f.content bbox $::we] {}
    set pw [winfo reqwidth .a]
    set ph [winfo reqheight .a]

    set rootx [winfo rootx .f.content]
    set rooty [winfo rooty .f.content]
    set x [expr $rootx + $x]
    set y [expr $rooty + $y]

    if {(($x + $pw) > [winfo screenwidth .]) || \
	    (($y + $ph) > [winfo screenheight .])} {
	set x [expr $x - $pw]
	set y [expr $y - $ph]
    }

    # puts "$x $y"

    focus .a.sw.l
    wm geometry .a +$x+$y
    wm deiconify .a
}

proc releaseGrab {} {
    wm withdraw .a
    .a.sw.l item delete first last
}

proc releaseGrabCheck {mx my ax ay} {
    set x [winfo rootx .a]
    set y [winfo rooty .a]
    set w [winfo reqwidth .a]
    set h [winfo reqheight .a]

    set t [.a.sw.l identify $ax $ay]

    if {($mx < $x) || \
	    ($my < $y) || \
	    ($mx > ($x + $w)) || \
	    ($my > ($y + $h))} {
	releaseGrab
    } else {
	if ![string first item $t] {
	    set i [lindex $t 1]
	    set t [.a.sw.l item text $i words]
	    releaseGrab
	    replaceHi $t
	}
    }
}

proc releaseGrabWithComplete {} {
    after idle {
	set t [.a.sw.l item text {first state selected} words]
	releaseGrab
	replaceHi $t
    }
}

proc replaceHi {w} {
    .f.content replace $::wf $::we $w
    if ![catch {info args switchHighLightLine}] {
	switchHighLightLine
    }
    if ![catch {info args hiSyntax}] {
	hiSyntax $::wf [indexWordEnd $::we]
    }
}