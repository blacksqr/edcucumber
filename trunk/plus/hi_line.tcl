# set bg_linum   #9ACD32 ;#cce900  ;#ff0000
set bg_content #9ACD32 ;#cce900 

package require img::png
set png_go [pngObj::produce go.png]

proc pngToLinum {l} {
    .f.linum configure -state normal
    .f.linum delete "$l.0" "$l.0 lineend"
    .f.linum insert "$l.0" $l justright
    .f.linum configure -state disable
}

proc linumToPng {l} {
    .f.linum configure -state normal
    .f.linum delete "$l.0" "$l.0 lineend"
    .f.linum image create "$l.0 lineend" -image $::png_go
    set d [expr [string length $::linum] - $::linum_png_width]
    while {$d > 0} {
	.f.linum insert "$l.0" { }
	incr d -1
    }
    .f.linum configure -state disable
}

# .f.linum tag configure hline -background $::bg_linum 
.f.content tag configure hline -background $::bg_content 
.f.content tag lower hline

.f.linum tag remove hline 1.0 end
.f.content tag remove hline 1.0 end

.f.content tag add hline {insert linestart} {insert +1l linestart}
# .f.linum tag add hline "$l.0 linestart" "$l.0 +1l linestart"
linumToPng [expr int([.f.linum index insert])]
set ::old_anchor 1

proc addHi {} {
    foreach e {
	<Alt-b>
	<Alt-f>
	<Alt-<>
	<Alt-greater>
	<Return>
	<Control-y>
	<Control-v>
	<Delete>
	<BackSpace>
	<Control-w>
	<Control-z>
	
	<ButtonPress-1>
	<Up>
	<Down>
	<Prior>
	<Next>
	<Control-p>
	<Control-n>
	<Control-Home>
	<Control-End>
	<Control-h>
	<Control-d>
	<Control-x>
	<Control-k>

	<braceleft>
	<braceright>
    } {
	bind .f.content $e {+ switchHighLightLine}
    }
}

proc switchHighLightLine {} {
    # puts {run to here}
    after idle [list mwHline [linum [.f.content index insert]]]
}

proc mwHline {ol} {
    set l [linum insert]

    .f.content tag remove hline 1.0 end
    
    #---#
    # puts "$ol $l"
    if {$::old_anchor != $l} {
	pngToLinum $ol; linumToPng $l
	set ::old_anchor $l
    }

    # after idle [list .f.linum tag add hline "$l.0 linestart" "$l.0 lineend"]

    #---#

    .f.content tag add hline {insert linestart} {insert +1l linestart}
}

bind .f.content <Any-Key> {+ switchHighLightLine}

addHi