bind .f.content <Control-j> jumpToSearch

bind .toolframe.srh <Control-l> searchNextword
bind .toolframe.srh <Alt-l> searchPrevWord

bind .f.content <Control-l> searchNextword
bind .f.content <Alt-l> searchPrevWord

set ico_back [pngObj::produce back.png]
set ico_forw [pngObj::produce forward.png]

ttk::button .toolframe.btn_back -image $ico_back -command searchPrevWord
ttk::button .toolframe.btn_fowr -image $ico_forw -command searchNextword

pack .toolframe.btn_back .toolframe.btn_fowr -side left -padx {5 0}

proc jumpToSearch {} {
    focus .toolframe.srh
}

proc searchNextword {} {
    set sw [string trim $::searchWord]
    if {$sw ne {}} {
        set old [.f.content index insert]
        .f.content mark set insert [.f.content search -exact $sw insert]
        if [.f.content compare $old == insert] {
            .f.content mark set insert [.f.content search -exact $sw "insert +1c"]
        }
    }
    catch {switchHighLightLine}
    focus .f.content
}

proc searchPrevWord {} {
    set sw [string trim $::searchWord]
    if {$sw ne {}} {
        .f.content mark set insert [.f.content search -backward -exact $sw insert]
    }
    catch {switchHighLightLine}
    focus .f.content
}

