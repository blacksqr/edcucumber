 package provide pngObj 0.1

package require img::png

namespace eval ::pngObj {
    variable pic_dir
}

proc ::pngObj::produce {namelist} {
    variable pic_dir

    if [file isdirectory pic] {
	set pic_dir pic
    } elseif [file isdirectory ../pic] {
	set pic_dir ../pic
    } else {
	# puts "No images directory found!"
	exit
    }

    set nms [split $namelist] 
    set name [file join $pic_dir [lindex $nms 0]]
    set nms [lreplace $nms 0 0]
    if [file isfile $name] {
	if [catch {set obj [image create photo -file $name -format png]} err] {
	    # puts $err
	    return
	}
	foreach pad $nms {
	    set nm [file join $pic_dir $pad]
	    if [catch {set p [image create photo -file $nm -format png]} err] {
		# puts $err
		return
	    }
	    $obj copy $p
	}
	return  $obj
    } else { 
	# puts "No png file named $name"
	return
    }
}

package provide pngObj 0.1