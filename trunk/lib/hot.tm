package provide hot 0.1

namespace eval ::hot {
    variable port 23818
    variable sock
    variable packs

    array set packs {}
}

proc ::hot::init {args} {
    variable packs
    
    set l [llength $args]
    incr l -1
    if {[expr $l % 2] && $l > 0} {
        incr l -1
        set i 0
        while {$i <= $l} {
	    set hdl [lindex $args $i]
	    set fil [lindex $args [expr $i+1]]
            array set packs [list $hdl $fil]
	    uplevel #0 [list source $fil]
	    incr i
        }
    }

    variable sock 
    variable port
    
    set sock [socket -server ::hot::accept $port]
    fconfigure $sock -buffering line
}

proc ::hot::accept {ns a p} {
    fileevent $ns readable [list ::hot::update $ns]
}

proc ::hot::update {ns} {
    variable packs

    while {![catch {gets $ns line}]} {
        set line [string trim $line]
        if {$line ne {}} {break}
    }

    puts $line
    if {$line ne {}} {
        uplevel #0 [list source $packs($line)]
    }
    catch {close $ns}
}

package provide hot 0.1