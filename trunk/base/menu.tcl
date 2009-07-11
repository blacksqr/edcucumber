package require menuTool

proc menuData {} {
    return {
	{file File {
	    {New    n  0 {} createNewDoc}
	    {Open   o  0 {} openDoc}
	    {Save   s  0 {} saveDoc}
	    {SaveAs {} 1 {} saveAsDoc}
	    {}
	    {Quit   q  0 {} quitApp}
	}}
        {operation Operation {
            {Replace {} 0 {} replaceWord}
            {}
            {Shell {} 0 {} shell}
        }}
    }
}

menuTool::init [menuData]
. configure -menu .mu
wm protocol . WM_DELETE_WINDOW quitApp

set current_file {}
set types {
    {{TCL Scripts}      {.tcl}        }
    {{Text Files}       {.txt}        }
    {{All Files}        *             }
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
    
    set filename [tk_getOpenFile -filetypes $::types]
    if {$filename eq {}} {
	return
    }
    .f configure -text $filename
    set ::current_file $filename

    set fid [open $filename r]
    .f.content delete 1.0 end    
    .f.content insert 1.0 [read $fid]
    close $fid
    switchHighLightLine
    decrLinum
    incrLinum

    .f.content edit modified 0
    set ::old_anchor 1
}

proc saveDoc {} {
    if ![.f.content edit modified] {
	return 0
    }
    
    if {$::current_file eq {} || $::current_file eq {shell}} {
        set filename {}
	set filename [tk_getSaveFile -filetypes $::types]
	if {$filename eq {}} {
	    return 0
	}
	set ::current_file $filename
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
    set filename [tk_getSaveFile -filetypes $::types]
    if {$filename eq {}} {
	return
    }
    set fid [open $filename w]
    puts -nonewline $fid [.f.content get 1.0 "end -1c"]
    close $fid
}

proc quitApp {} {
    if [.f.content edit modified] {
        confirm {Save current documnet?} [list if "\[saveDoc\]" "{exit}"] {exit}
    } else {
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
    wm title .cf {Are you sur?}

    set x [expr [winfo rootx .] + [winfo reqwidth .]/2 - [winfo reqwidth .cf]/2]
    set y [expr [winfo rooty .] + [winfo reqheight .]/2 - [winfo reqheight .cf]/2]
    wm geometry .cf +$x+$y

    tkwait visibility .cf
    grab .cf
}