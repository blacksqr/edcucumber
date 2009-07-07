set extra_files [list ]
set extra_pos end

proc initExtraFiles {} {
    text .extra
    foreach f $::extra_files {
        set fd [open $f r]
        .extra insert end [read $fd]
    }
}

proc getNextExtraWord {} {
    set ::extra_pos [.extra search -backward $::auto_base $::extra_pos 1.0]
    if {$::extra_pos ne {}} {
	lappend ::auto_list [.extra get $::extra_pos "$::extra_pos wordend"]
    }
}

proc ifExtraFinished {} {
    return [expr {$::extra_pos eq {}}]
}