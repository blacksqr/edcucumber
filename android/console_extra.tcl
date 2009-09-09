proc _main {} {
    ttk::labelframe .ex_con -text console
    ttk::scrollbar .ex_con.sb -command {.ex_con.text yview}
    text .ex_con.text -height 3 -yscrollcommand {.ex_con.sb set}
    
    pack .ex_con -side bottom -fill x
    pack .ex_con.text -side left -expand 1 -fill x
    pack .ex_con.sb -side right -fill y

    .ex_con.text tag configure head_tag -foreground red
    .f.content tag configure leave -background #808080
    
    bind .ex_con.text <Escape> {focus .f.content; .f.content tag remove leave 1.0 end}
    bind .f.content <Escape> {
	focus .ex_con.text
	if [.f.content compare {insert +1c} <= {insert lineend}] {
	    .f.content tag add leave insert {insert + 1c}
	} else {
	    .f.content tag add leave insert {insert lineend}
	}
    }
    
    proc _init_con {} {
        catch {interp delete con}
        interp create con
        con eval {
            rename puts _puts
            proc puts {args} {
                return $args
            }
        }
        interp alias con exit {} quitApp
        
        foreach item {
            {cc <Control-c>}
            {cx <Control-x>}
            {cv <Control-v>}
            {cz <Control-z>}
            {cw <Control-w>}
            {aw <Alt-w>}
            {cy <Control-y>}
            {ca <Control-a>}
            {ce <Control-e>}
            {ab <Alt-b>}
            {af <Alt-f>}
            {a< <Alt-<>}
            {a> <Alt-greater>}
            {am <Alt-m>}
            {cl <Control-l>}
            {al <Alt-l>}
            {a/ <Alt-/>}
        } {
            set name [lindex $item 0]
            set command [evtGenerator [lindex $item 1]]
            eval "
            proc $name {} {
                focus .f.content
                $command
                .f.content tag remove leave 1.0 end
                if \[.f.content compare insert != {insert lineend}\] {
                    .f.content tag add leave insert {insert +1c}
                } elseif \[.f.content compare insert != {insert linestart}\] {
                    .f.content tag add leave {insert -1c} insert
                }
                focus .ex_con.text
            }
            "
            interp alias con $name {} $name
        }
        
        proc setSearchWord {w} {set ::searchWord $w}
        interp alias con s {} setSearchWord

        proc _moveToPrevLine {{n 1}} {while {$n > 0} {eval [evtGenerator <Up>];incr n -1}}
        proc _moveToNextLine {{n 1}} {while {$n > 0} {eval [evtGenerator <Down>];incr n -1}}
        proc _moveToPrevChar {{n 1}} {while {$n > 0} {eval [evtGenerator <Left>];incr n -1}}
        proc _moveToNextChar {{n 1}} {while {$n > 0} {eval [evtGenerator <Right>];incr n -1}}
        foreach p {moveToPrevLine moveToNextLine moveToPrevChar moveToNextChar} {
            eval "
            proc $p {{n 1}} {
                focus .f.content
                _$p \$n
                .f.content tag remove leave 1.0 end
                if \[.f.content compare insert != {insert lineend}\] {
                    .f.content tag add leave insert {insert +1c}
                } elseif \[.f.content compare insert != {insert linestart}\] {
                    .f.content tag add leave {insert -1c} insert
                }
                focus .ex_con.text
            }
"
        }
        interp alias con i {} moveToPrevLine
        interp alias con j {} moveToPrevChar
        interp alias con k {} moveToNextLine
        interp alias con l {} moveToNextChar
    }
    _init_con

    set ::head "tclsh%"
    set ::com_buffer     {}
    set ::com_result     {}
    set ::com_err        {}
    set ::com_contin     {miss}
    set ::com_history    {}
    set ::com_history_id {}
    set ::com_region_readonly 1.6

    .ex_con.text insert end $::head
    .ex_con.text tag add head_tag {insert linestart} {insert lineend}

    init_region_readonly
    bind .ex_con.text <Return> {_con_return .ex_con.text}
    bind .ex_con.text <Control-Up> {_prev_history .ex_con.text}
}

proc _con_return {t} {
    set ::com_history_id -1

    if {[expr int([$t index {insert}])] < [expr int([$t index {end -1c}])]} {
	$t mark set insert {end -1c}
    } else {
	$t mark set insert {insert lineend}
	$t insert end "\n"
	set h [$t search -backward {%} end]
	
	set ::com_buffer [string trim [$t get "$h +1c" "insert lineend"]]
	
        if {$::com_buffer == {}} {
            $t insert end "$::head"
            $t tag add head_tag {insert linestart} {insert lineend}
        } elseif {$::com_buffer == {init}} {
            _init_con
            $t insert end "#-------new-------#\n"
            $t insert end "$::head"
            $t tag add head_tag {insert linestart} {insert lineend}
        } else { 
	    if [_verify_con_buffer] {
		if {$::com_result ne {}} {
		    $t insert end $::com_result
		    $t insert end "\n"
		}
		$t insert end $::head
		$t tag add head_tag {insert linestart} {insert lineend}
		lappend ::com_history $::com_buffer
	    } else {
		if [string first $::com_contin $::com_err] {
		    $t insert end "${::com_err}\n${::head}"
		    $t tag add head_tag {insert linestart} {insert lineend}
		}
	    }
	}
    }

    $t see insert
    set ::com_region_readonly [$t index insert]
    return -code break
}

proc init_region_readonly {} {
    rename .ex_con.text ex_con
    proc .ex_con.text {args} {
	switch [lindex $args 0] {
	    "insert" {
		if [ex_con compare insert >= $::com_region_readonly] { 
		    uplevel 1 ex_con $args
		}
	    }
	    "delete" {
		if [ex_con compare insert > $::com_region_readonly] { 
		    uplevel 1 ex_con $args
		}
	    }
	    "default" {
		uplevel 1 ex_con $args
	    }
	}
    }
}

proc _verify_con_buffer {} {
    return [expr ![catch {set ::com_result [interp eval con $::com_buffer]} ::com_err]]
}

proc _prev_history {t} {
    set prev_com {}

    if {$::com_history_id < 0} {
	set ::com_history_id [expr [llength $::com_history] -1]
	if {$::com_history_id >= 0} {
	    set prev_com [lindex $::com_history $::com_history_id]
	}
    } else {
	set prev_com [lindex $::com_history $::com_history_id]
    }
    incr ::com_history_id -1
    
    $t mark set insert end
    set last_line [$t get {insert linestart} {insert lineend}]
    if {[string first $::head $last_line]  == 0} {
	$t delete "[$t search -backward {%} end] +1c" end
    } else {
	$t delete {insert linestart} {insert lineend}
    }
    
    $t insert "end -1c" $prev_com

    return -code break
}

#-------------------------------#

if 1 {
    _main
}