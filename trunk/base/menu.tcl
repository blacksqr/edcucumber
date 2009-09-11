package require menuTool

#----------------------------#

proc evtGenerator {evt} {
    return "event generate .f.content $evt"
}
event add <<Popup-Menu>> <Button-2> <Button-3>
bind .f.content <<Popup-Menu>> {tk_popup .popupmenu %X %Y}
menu .popupmenu -tearoff 0

set popup_items [list \
                     [list Copy  C-c 0 {} [evtGenerator <Control-c>]] \
                     [list Cut   C-x 1 {} [evtGenerator <Control-x>]] \
                     [list Paste C-v 0 {} [evtGenerator <Control-v>]] \
                     [list Undo  C-z 0 {} [evtGenerator <Control-z>]] \
                     [list Redo  A-z 0 {} [evtGenerator <Alt-z>]] \
                     [list ] \
                     [list {Local Cut}   C-w {} {} [evtGenerator <Control-w>]] \
                     [list {Local Copy}  A-w {} {} [evtGenerator <Alt-w>]] \
                     [list {Local Paste} C-y {} {} [evtGenerator <Control-y>]] \
                     [list ] \
                     [list {Line Head} C-a {} {} [evtGenerator <Control-a>]] \
                     [list {Line End}  C-e {} {} [evtGenerator <Control-e>]] \
                     [list {Word Prev} A-b {} {} [evtGenerator <Alt-b>]] \
                     [list {Word Next} A-f {} {} [evtGenerator <Alt-f>]] \
                     [list {Doc Head} {A-<} {} {} [evtGenerator <Alt-<>]] \
                     [list {Doc End}  "A->" {} {} [evtGenerator <Alt-greater>]] \
                     [list {Content head} A-m {} {} [evtGenerator <Alt-m>]] \
                     [list ] \
                     [list {Search forwards}  C-l 0 {} [evtGenerator <Control-l>]] \
                     [list {Search backwards} A-l 0 {} [evtGenerator <Alt-l>]] \
                     [list ] \
                     [list {Auto Complete} "A-/" 0 {} [evtGenerator <Alt-/>]] \
                    ]

foreach item $popup_items {
    menuTool::produce .popupmenu $item
}

#----------------------------#

proc menuData {} {
    return "{file File {
        {New    C-n  0 {} createNewDoc}
        {Open   C-o  0 {} openDoc}
        {Save   C-s  0 {} saveDoc}
        {SaveAs {} 1 {} saveAsDoc}
        {}
        {Quit   C-q  0 {} quitApp}
    }} 
    {operation Operation {[concat $::popup_items {{Replace {} 0 {} replaceWord} {} {Shell {} 0 {} shell}}]}}"
}

bind . <Control-n> createNewDoc
bind . <Control-o> openDoc
bind . <Control-s> saveDoc
bind . <Control-q> quitApp

menuTool::init [menuData]
. configure -menu .mu
wm protocol . WM_DELETE_WINDOW quitApp
set type {}

set current_file {}
set types {
    {{TCL Scripts}      {.tcl}        }
    {{Text Files}       {.txt}        }
    {{All Files}        *             }
}
array set arr_types {}
foreach i $types {
    array set arr_types [list [lindex $i 0] [lindex $i 1]]
}

proc createNewDoc {} {
    if [.f.content edit modified] {
	confirm	{Save current documnet?} [list if "\[saveDoc\]" "{_newDoc; destroy .cf}"] {_newDoc; destroy .cf}
    } else {
	_newDoc
    }
}

proc _newDoc {} {
    if {$::current_file eq {shell}} {
        proc runCmd {} {}
    }
    
    .f configure -text {new file}
    .f.content delete 1.0 end
    set ::current_file {}
    
    switchHighLightLine
    decrLinum
    incrLinum
    .f.content edit modified 0
    set ::old_anchor 1
}

proc openDoc {} {
    if [.f.content edit modified] {
	confirm	{Save current documnet?} [list if "\[saveDoc\]" "{_openDoc; destroy .cf}"] {destroy .cf; _openDoc}
    } else {
	_openDoc
    }
}

proc _openDoc {} {
    if {$::current_file eq {shell}} {
        proc runCmd {} {}
    }
    if {$::current_file != {}} {
        set filename [tk_getOpenFile -filetypes $::types -initialdir [file dirname $::current_file]]
    } else {
        set filename [tk_getOpenFile -filetypes $::types]
    }
    if {$filename eq {}} {
	return
    }
    .f configure -text $filename
    set ::current_file $filename

    set fid [open $filename r]
    .f.content delete 1.0 end
    decrLinum
    .f.content insert 1.0 [read $fid]
    close $fid
    switchHighLightLine
    incrLinum

    .f.content edit modified 0
    set ::old_anchor 1
    .f.content mark set insert 1.0
}

proc saveDoc {} {
    if ![.f.content edit modified] {
	return 0
    }
    
    if {$::current_file eq {}} { ;#  || $::current_file eq {shell}
        set filename {}
	set filename [tk_getSaveFile -filetypes $::types -typevariable ::type]
	if {$filename eq {}} {
	    return 0
	}
        if {($::type != {*}) &&![regexp "\.$::arr_types($::type)$" $filename]} {
            set filename "${filename}.$::arr_types($::type)"
        }
	set ::current_file $filename
        .f configure -text $filename
    } else {
	set filename $::current_file
    }
    
    set fid [open $filename w]
    puts -nonewline $fid [.f.content get 1.0 "end -1c"]
    close $fid

    .f.content edit modified 0
    
    .sf.lb configure -text "Saving Done at : [clock format [clock seconds] -format {%H:%M:%S}]"
    
    return 1
}

proc saveAsDoc {} {
    if {$::current_file != {}} {
        set filename [tk_getSaveFile -filetypes $::types -typevariable ::type -initialdir [file dirname $::current_file]]
    } else {
        set filename [tk_getSaveFile -filetypes $::types -typevariable ::type]
    }
    if {$filename eq {}} {
	return
    }
    if {($::type != {*}) && ![regexp "\.$::arr_types($::type)$" $filename]} {
        set filename "${filename}.$::arr_types($::type)"
    }
    set fid [open "$filename" w]
    puts -nonewline $fid [.f.content get 1.0 "end -1c"]
    close $fid
    
    if {$::current_file eq {}} {
        set ::current_file $filename
        .f configure -text $filename
    }
}

proc quitApp {} {
    if [.f.content edit modified] {
        confirm {Save current documnet?} [list if "\[saveDoc\]" {writeLog; exit}] {exit}
    } else {
        writeLog
        exit
    }
}

proc replaceWord {} {
    
}

#------------------------------------------------#

proc confirm {text yes_command no_command} {
    toplevel .cf
    ttk::label .cf.lb -text $text -image [pngObj::produce emblem-important.png] \
	-compound left -justify center
    ttk::button .cf.yes -text Yes -command $yes_command
    ttk::button .cf.no  -text No  -command $no_command
    bind .cf.yes <Return> $yes_command
    bind .cf.no  <Return> $no_command
    pack .cf.lb
    pack .cf.yes .cf.no -side left

    focus .cf.yes
    wm title .cf {Are you sure?}

    set x [expr [winfo rootx .] + [winfo reqwidth .]/2 - [winfo reqwidth .cf]/2]
    set y [expr [winfo rooty .] + [winfo reqheight .]/2 - [winfo reqheight .cf]/2]
    wm geometry .cf +$x+$y

    tkwait visibility .cf
    grab .cf
    wm attributes .cf -toolwindow 1
}

proc writeLog {} {
    set fid [open config.txt r]
    set tmp [open tmp w]
    if ![eof $fid] {
	set line [gets $fid]
        if [regexp {current_file} $line] {
            puts -nonewline $tmp "set current_file {$::current_file}"
        } else {
            puts -nonewline $tmp $line
        }
    }
    while {![eof $fid]} {
	puts -nonewline $tmp "\n"
        set line [gets $fid]
        if [regexp {current_file} $line] {
            puts -nonewline $tmp "set current_file {$::current_file}"
        } else {
            puts -nonewline $tmp $line
        }
    }
    close $fid
    close $tmp
    
    file delete config.txt
    file rename tmp config.txt
}