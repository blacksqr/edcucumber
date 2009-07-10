bind .f.content <Control-j> jumpToSearch

bind .toolframe.srh <Control-l> searchNextword
bind .toolframe.srh <Alt-l> searchPrevWord

bind .f.content <Control-l> searchNextword
bind .f.content <Alt-l> searchPrevWord

set ico_back [pngObj::produce back.png]
set ico_forw [pngObj::produce forward.png]

set if_search_reg 0

ttk::checkbutton .toolframe.chk -variable if_search_reg -text regexp
ttk::button .toolframe.btn_back -image $ico_back -command searchPrevWord -style Toolbutton
ttk::button .toolframe.btn_fowr -image $ico_forw -command searchNextword -style Toolbutton

pack .toolframe.chk .toolframe.btn_back .toolframe.btn_fowr -side left -padx {5 0}

proc jumpToSearch {} {
    focus .toolframe.srh
}

proc searchNextword {} {
    if $::if_search_reg {
        set mod {-regexp}
    } else {
        set mod {-exact}
    }
    
    set sw [string trim $::searchWord]
    if {$sw ne {}} {
        set old [.f.content index insert]
        set insert_now [.f.content search $mod $sw insert]
        if {$insert_now eq {}} {
            focus .f.content
            return
        }
        .f.content mark set insert $insert_now
        if [.f.content compare $old == insert] {
            .f.content mark set insert [.f.content search $mod $sw "insert +1c"]
        }
    }
    catch {switchHighLightLine}
    focus .f.content
    .f.content see insert
}

proc searchPrevWord {} {
    if $::if_search_reg {
        set mod {-regexp}
    } else {
        set mod {-exact}
    }
    
    set sw [string trim $::searchWord]
    if {$sw ne {}} {
        set insert_now [.f.content search -backward $mod $sw insert]
        if {$insert_now eq {}} {
            focus .f.content
            return
        }
        .f.content mark set insert $insert_now
    }
    catch {switchHighLightLine}
    focus .f.content
    f.content see insert
}
