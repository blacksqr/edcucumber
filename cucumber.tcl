#-------------------------------------------------------#
# DECLARATION
package require Tk
package require tile

set linum 1
set linum_png_width 2
set fg_linum   #656565
set buffer {}

#-------------------------------------------------------#
# GUI

proc gui {} {
    ttk::frame .toolframe
    set ::searchWord {}
    LabelEntry .toolframe.srh -textvariable ::searchWord -justify center
    pack .toolframe.srh -padx {5 0} -anchor w -side left
    pack .toolframe -fill x -pady {5 0}

    ttk::labelframe .f -text {new file}
    text .f.linum -width $::linum_png_width -bg gray -bd 0 -fg $::fg_linum
    .f.linum tag configure justright -justify right
    .f.linum insert end 1 justright
    .f.linum configure -state disable
    text .f.content -bd 0 -undo 1 -yscrollcommand contentYScroll -wrap none
    ttk::scrollbar .f.sb -command {.f.content yview}

    pack .f.linum -side left -fill y -pady {0 6}
    pack .f.content -side left -fill both -expand 1 -pady {0 6}
    pack .f.sb -side right -fill y -pady {0 6}

    frame .sf
    ttk::label .sf.lb
    ttk::sizegrip .sf.sg

    pack .sf.sg -side right
    pack .sf.lb -side left -fill x -anchor w

    pack .sf -side bottom -fill x
    pack .f -fill both -expand 1 -pady {2 0} -side bottom

    wm title . cucumber
    package require img::png
    wm iconphoto . [pngObj::produce {face-monkey.png}] ;#[image create photo -file face-monkey.png -format png]

    focus .f.content
}

#-------------------------------------------------------#
# BINDINGS
proc bindDefaultEvents {} {
    foreach eh {
        {<Control-@> hdlMark}
        {<Alt-w>     hdlCopy}
	{<Control-w> hdlCut}
	{<Control-y> hdlPaste}
    } {
        foreach {e h} $eh {}
        bind .f.content $e "+ after idle $h"
    }

    foreach e {
	<Return>
	<Control-y>
	<Control-v>
	<Control-z>
    } {
	bind .f.content $e {+ after idle incrLinum} 
    }
    foreach e {
	<Delete>
	<BackSpace>
	<Control-w>
	<Control-x>
	<Control-z>
	<Control-k>
    } {
	bind .f.content $e {+ after idle decrLinum}
    }

    bind .f.content <Any-Key> {+
	if [ifSelected] {
	    after idle {
		decrLinum
		incrLinum
	    }
	}
    }
}

#-------------------------------------------------------#
# HDL

proc hdlPaste {} {
    if {$::buffer eq {}} {return}
    
    if [ifSelected] {
	set i [.f.content index sel.first]
	.f.content delete sel.first sel.last
    } else {
	set i [.f.content index insert]
    }

    .f.content insert $i $::buffer
}

proc hdlCut {} {
    if ![ifMarked] {
        .sf.lb configure -text {Mark not set}
    } else {
        if [.f.content compare insert > CUCUMBER] {
            set ::buffer [.f.content get CUCUMBER insert]
	    .f.content delete CUCUMBER insert
        } elseif [.f.content compare insert < CUCUMBER] {
            set ::buffer [.f.content get insert CUCUMBER]
            .f.content delete insert CUCUMBER
        }
    }
}

proc hdlCopy {} {
    if ![ifMarked] {
        .sf.lb configure -text {Mark not set}
    } else {
        if [.f.content compare insert > CUCUMBER] {
            set ::buffer [.f.content get CUCUMBER insert]
        } elseif [.f.content compare insert < CUCUMBER] {
            set ::buffer [.f.content get insert CUCUMBER]
        }
    }
}

proc hdlMark {} {
    set rid [.f.content index insert]
    .f.content mark set CUCUMBER $rid
    .sf.lb configure -text "Mark set at : $rid"
}

#-------------------------------------------------------#
# PROCEDURES

# if content selected
proc ifSelected {} {
    return [expr ![catch {.f.content index sel.first}]]
}

# if the position of id is in quotes
proc ifInQuote {{id insert}} {
    return [expr [llength [.f.content reaseach -backward -all -regexp {[^\\]\"} id]] % 2]
}

# if mark has been set
proc ifMarked {} {
    return ![catch {.f.content index CUCUMBER}]
}

# for .f.content to set .f.sb as well as .f.linum
proc contentYScroll {first last} {
    .f.sb set $first $last
    .f.linum yview moveto $first
}

# increase line number
proc incrLinum {} {
    set num [linum "end - 1c"]
    set diff [expr $num - $::linum]
    if {$diff > 0} {
        .f.linum configure -state normal
        while {$::linum < $num} {
            incr ::linum
            .f.linum insert end "\n$::linum" justright
	    set w [string length $::linum]
	    if {$w < $::linum_png_width} {
		set w $::linum_png_width
	    }
            .f.linum configure -width $w
        }
        .f.linum configure -state disable
    }
}

# decrese line number
proc decrLinum {} {
    set num [linum "end - 1c"]
    if {$num < $::linum} {
        .f.linum configure -state normal
        .f.linum delete "$num.end" end
        set ::linum $num
        .f.linum configure -state disable

	set w [string length $::linum]
	if {$w < $::linum_png_width} {
	    set w $::linum_png_width
	}
	.f.linum configure -width $w
    }
}

# get the line number by given index in some text
proc linum {id} {
    return [expr int([.f.content index $id])]
}

proc ifInWord {id} {
    # -1 = word head
    #  1 = word end
    #  2 = in word
    #  0 = not in word

    if [.f.content compare $id == "$id linestart"] {
	if [regexp {\W} [.f.content get $id]] {
	    return 0
	}
	return -1
    }

    if [.f.content compare $id == "$id lineend"] {
	if [regexp {\W} [.f.content get "$id - 1c"]] {
	    return 0
	}
	return 1
    }
    
    set p [.f.content get "$id -1c"]
    set i [.f.content get $id]
    set s "$p$i"

    if [regexp {\W{2}} $s] {
	return 0
    } elseif [regexp {\w\W} $s] {
	return 1
    } elseif [regexp {\W\w} $s] {
	return -1
    } else {
	return 2
    }
}

proc indexWordHead {id} {
    if [.f.content compare $id == "$id linestart"] {
	return [.f.content index $id]
    } else {
	set i 1
	while {![regexp {\W} [.f.content get "$id - $i c"]]} {
	    if [.f.content compare "$id - $i c" == "$id linestart"] {
		return [.f.content index {insert linestart}]
	    }
	    incr i
	}
	return [.f.content index "$id - $i c + 1c"]
    }
}

proc indexWordEnd {id} {
    if [.f.content compare $id == "$id lineend"] {
	return [.f.content index $id]
    } else {
	set i 0
	while {![regexp {\W} [.f.content get "$id + $i c"]]} {
	    incr i
	    if [.f.content compare "$id + $i c" == "$id lineend"] {
		break
	    }
	}
	return [.f.content index "$id + $i c"]
    }
}


#-------------------------------------------------------#
# TEST

if 1 {
    cd [file dirname $argv0]
    source config.txt

    # open file with start of application
    if [catch {
	set ::current_file [lindex $argv 0]
        .f configure -text $::current_file
	set fid [open $::current_file r]
	.f.content insert 1.0 [read $fid]
	close $fid
	switchHighLightLine
	incrLinum
	.f.content edit modified 0
	set ::old_anchor 1
    }] {
	.f configure -text {new file}
    }
}
