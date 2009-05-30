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
    }
}

menuTool::init [menuData]
. configure -menu .mu

set current_file {}
set types {
    {{Text Files}       {.txt}        }
    {{TCL Scripts}      {.tcl}        }
    {{All Files}        *             }
}

proc createNewDoc {} {
    if [.f.content edit modified] {
	confirm	{Save current documnet?} saveDoc {destroy .cf}
    }
    .f configure -text {new file}
    .f.content delete 1.0 end
    set ::current_file {}
}

proc openDoc {} {
    createNewDoc

    set filename [tk_getOpenFile -filetypes $::types]
    if {$filename eq {}} {
	return
    }
    .f configure -text $filename
    set ::current_file $filename

    set fid [open $filename r]
    .f.content insert 1.0 [read $fid]
    close $fid
}

proc saveDoc {} {
    if ![.f.content edit modified] {
	return 0
    }
    
    if {$::current_file eq {}} {
	set filename [tk_getOpenFile -filetypes $::types]
	if {$filename eq {}} {
	    return 0
	}
    } else {
	set ::current_file $filename
	.f configure -text $filename
    }
    set fid [open $filename w]
    puts $fid [.f.content get 1.0 end]
    close $fid

    .f.content edit modified 0
    return 1
}
proc saveAsDoc {} {
    set filename [tk_getOpenFile -filetypes $::types]
    if {$filename eq {}} {
	return
    }
    set fid [open $filename w]
    puts $fid [.f.content get 1.0 end]
    close $fid
}
proc quitApp {} {
    if [.f.content edit modified] {
	confirm {Save current documnet?} {saveDoc} exit
    } else {
	exit
    }
}

#------------------------------------------------#

proc confirm {text yes_command tail} {
    toplevel .cf
    ttk::label .cf.lb -text $text -image [pngObj::produce emblem-important.png] \
	-compound left -justify center
    ttk::button .cf.yes -text Yes -command [list if "\[$yes_command\]" "eval $tail"]
    ttk::button .cf.no  -text No  -command [list eval $tail]
    bind .cf.yes <Return> [list if "\[$yes_command\]" "eval $tail"]
    bind .cf.no  <Return> [list eval $tail]
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