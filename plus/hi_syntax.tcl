#-----------------------------------------------------------#
if 0 {
    package require Tk
    
    frame .f
    text .f.content
    
    pack .f .f.content
}

#-----------------------------------------------------------#

.f.content tag configure C1 -foreground #0000FF ;# blue   : commands
.f.content tag configure C2 -foreground #FF0000 ;# red    : library variable
.f.content tag configure C3 -foreground #EE9A00 ;# orange : keyword

.f.content tag configure Num -foreground #FF0000 ;# red : number 
.f.content tag configure Com -foreground #FF0000 ;# red : comment
.f.content tag configure Var -foreground #B23AEE ;# purple : variable
.f.content tag configure Quo -foreground #FF34B3 ;#

# .f.content tag configure C4 -foreground #2F4F4F ;# dark blue
# .f.content tag configure C5 -foreground #00BFFF ;# blue

array set syntax {}

foreach n {0 1 2 3 4 5 6 7 8 9} {
    array set syntax "$n Num"
}

# set f [open plus/tcl-tk.uew r]
set f [open plus/tcl-tk.uew r]
while {![eof $f]} {
    gets $f line
    set line [string trim $line]
    if [regexp {\/(C[0-9]).*} $line match t] {
	set tag $t
	continue
    }
    foreach w $line {
	array set syntax "$w $tag"
    }
}
close $f

set quotes [list]

#-----------------------------------------------------------#

rename .f.content fake
proc .f.content {args} { 
    set cmd [translateIndex $args]
    after idle "$cmd"
    uplevel 1 fake $args
}

proc translateIndex {args} { 
    eval "set args $args"
    if {[string first insert $args] == 0} {
	set id  [fake index [lindex $args 1]]
	set lco [string length [lindex $args 2]]
	return "hiContent $id {$id + $lco c}"
    } elseif {[string first delete $args] == 0} {
	set id [fake index [lindex $args 1]]
	return "hiWord $id"
    }
    return none
}

proc none {} {}

#-----------------------------------------------------------#

proc hiContent {first last} {
    # puts "{[fake get 1.0 end]}"
    set first [hiWord $first]
    while {[fake compare $first <= $last]} {
	set first [hiWord $first]
    }
}

proc hiWord {id} {
    # puts [ifInWord $id]
    # if [varContext $id] {return end}
    # if [commentContext $id] {return end}

    if [ifInWord $id] {
	set h [indexWordHead $id]
	set t [indexWordEnd  $id]
	# puts "$id : $h $t"
	hiSyntax $h $t

	set ret "$t +1c"
    } else {
	set ret "$id +1c"
    }

    updateQuoteContext $id
    # quoteContext $id
    varContext $id
    commentContext $id

    return $ret
}

proc hiSyntax {id_1 id_2} {
    set tags [fake tag names]
    foreach tag $tags {
	if {$tag ne {hline}} {
	    fake tag remove $tag $id_1 $id_2
	}
    }

    set word [fake get $id_1 $id_2]
    set tag [whichTag $word]
    # puts "$word : {$tag}"
    
    if {$tag ne {}} {
	fake tag add $tag $id_1 $id_2
    }

    if ![catch {info args switchHighLightLine}] {
	switchHighLightLine
    }
}

proc whichTag {w} {
    if [catch {set tag $::syntax($w)}] {
	return {}
    }
    return $tag
}

proc varContext {id} {
    if [ifInWord $id] {
	set h [indexWordHead $id]
	set t [indexWordEnd  $id]
	if [fake compare $h > "$h linestart"] {
	    if {[fake get "$h -1c"] eq "\$"} {
		fake tag add Var $h $t
		return 1
	    }
	}
    }
    return 0
}

proc commentContext {id} {
    set i [fake search -regexp {\S} "$id linestart" "$id lineend"]
    if {$i ne {}} {
	if {[fake get $i] eq "\#"} {
	    fake tag add Com $i "$id lineend"
	    return 1
	} else {
	    fake tag remove Com $i "$id lineend"
	}
    }

    set i [fake search {;} "$id linestart" $id]
    if {$i ne {}} {
	set ii [fake search -regexp {\#} $i $id]
	if {$ii ne {}} {
	    fake tag add Com $i "$id lineend"
	    return 1
	} else {
	    fake tag remove Com $i "$id lineend"
	}
    }
    
    return 0
}

proc quoteContext {id} {
    if {[fake get 1.0] eq "\""} {
	set rid [list 1.0]
    } else {
	set rid {}
    }

    set qid [fake search -nolinestop -overlap -all -regexp {[^\\]\"} 1.0 end]
    foreach id $qid {
	lappend rid [fake index [fake index "$id + 1c"]]
    }
    

    # puts "rid : {$rid} ([llength $rid])"
    
    if ![set e [llength $rid]] {
	return
    }

    set n [lindex $rid 0]
    # puts "remove1 : 1.0 {$n}"
    fake tag remove Quo 1.0 $n

    set i 1
    while {$i < $e} {
	set oa [fake index "$n +1c"]
	set od $n
	set n [lindex $rid $i]
	if [expr $i % 2] {
	    # puts "run to here, add : {$o} {$n}"
	    # puts "all : {[fake get 1.0 end]}"
	    fake tag add Quo $oa $n
	} else {
	    # puts "remove : {$o} {$n}"
	    fake tag remove Quo $od $n
	}
	incr i
    }

    set oa [fake index "$n + 1c"]
    if [expr $e % 2] {
	# puts "add2 : {$n} end"
	fake tag add Quo $oa end
    } else {
	# puts "remove2 : {$n} end"
	fake tag remove Quo $n end
    }
}

proc updateQuoteContext {id} {
    foreach id $::quotes {
	catch {after cancel [list quoteContext $id]}
    }
    set ::quotes {}
    lappend ::quotes $id
    after 1000 [list quoteContext $id]
}