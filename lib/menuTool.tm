package provide menuTool 0.1

namespace eval ::menuTool {}

proc ::menuTool::init {data} {
    menu .mu -tearoff 0

    foreach menu $data {
	set path  .mu.[lindex $menu 0]
	set label [lindex $menu 1]
	set items [lindex $menu 2]
	menu $path -tearoff 0
	.mu add cascade -menu $path -label $label -underline 0
	foreach item $items {
	    ::menuTool::produce $path $item
	}
    }
} 

proc ::menuTool::produce {path item} {
    if ![llength $item] {
	$path add separator
	return
    }

    foreach {label accel under image comm} $item {}
    
    $path add command -label [format "%-15s" $label] \
    	-command $comm \
	-image [pngObj::produce $image] -compound left
	# -underline $under \

    if {$accel ne {}} {
        $path entryconfigure [format "%-15s" $label] \
	    -accelerat "$accel"
    }

    if {$under ne {}} {
       $path entryconfigure [format "%-15s" $label] \
       	     -underline $under
    }
}