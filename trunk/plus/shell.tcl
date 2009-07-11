if 0 {
    package require Tk
    
    frame .f
    text .f.content
    
    pack .f
    pack .f.content
    
    bind .f.content <Return> _runCmd
    
    set prompt "[pwd]>"
    .f.content insert end $prompt
}

proc shell {} {
    if [.f.content edit modified] {
        confirm {Save current document?} [list if "\[saveDoc]" "_shell; destroy .cf"] {_shell; destroy .cf}
    } else {
        _shell
    }
}

proc _shell {} {
    .f.content delete 1.0 end
    decrLinum
    incrLinum
    
    set ::current_file shell
    .f configure -text shell
    
    set ::old_anchor 1
    proc runCmd {} {
        _runCmd
        
        .f.content mark set insert end
        .f.content see insert
        
        switchHighLightLine
        decrLinum
        incrLinum
        
        .f.content edit modified 0
        
        return -code break
    }
    
    bind .f.content <Return> {+ runCmd }
    set ::prompt "[pwd]>"
    .f.content insert end $::prompt
}

proc _runCmd {} {
    set start [string trim [.f.content search {>} {insert linestart} {insert lineend}]]
    if {$start eq {}} { return }
    
    set cmd [.f.content get "$start +1c" {insert lineend}]
    
    if [regexp {^cd .*} $cmd] {
        if [catch {cd [string range $cmd 3 [string length $cmd]]}] {
            .f.content insert end "\n$::prompt"
            return
        } else {
            set ::prompt "[pwd]>"
        }
    }
    
    if [catch {set fd [open "|$cmd"]}] {
        .f.content insert end "\n$::prompt"
    } else {
        fileevent $fd readable [list readFd $fd]
        fconfigure $fd -blocking 0 -buffering line
    }
    
    return
}

proc readFd {fd} {
    if [eof $fd] {
        close $fd
        .f.content insert end "\n$::prompt"
        
        .f.content mark set insert end
        .f.content see insert
        
        switchHighLightLine
        decrLinum
        incrLinum
    } else {
        .f.content insert end "\n[string trim [gets $fd]]"
    }
}

#----------------------------------------------#

# shell

proc runCmd {} {}

bind .f.content <Return> {+ runCmd}