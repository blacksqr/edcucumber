set android_path {}
set android_projects {}
set android_packages {}
set png_android_accept [pngObj::produce accept.png]
set png_android_invalid [pngObj::produce blank.png]

proc showDialog {dlg} {
    set x [expr [winfo rootx .] + [winfo reqwidth .]/2 - [winfo reqwidth $dlg]/2]
    set y [expr [winfo rooty .] + [winfo reqheight .]/2 - [winfo reqheight $dlg]/2]
    wm geometry $dlg +$x+$y
    wm deiconify .android
    
    tkwait visibility $dlg
    grab $dlg
    wm attributes $dlg -toolwindow 1
}

proc createNewActivity {} {
    toplevel .android
    wm withdraw .android
    
    ttk::labelframe .android.fr1 -text info
    ttk::label .android.fr1.lb0 -text Project
    ttk::label .android.fr1.lb1 -text Packages
    ttk::label .android.fr1.lb2 -text Activity
    ttk::combobox .android.fr1.et0 -values $::android_projects -postcommand _updateAndroidPackages
    ttk::combobox .android.fr1.et1 -values $::android_packages -postcommand {
	if {[.android.fr1.et1 get] != {}} {
	    .android.fr1.lbp1 configure -image $::png_android_accept
	    .android.fr1.et2 configure -state normal
	} else {
	    .android.fr1.lbp1 configure -image $::png_android_invalid
	    .android.fr1.et2 configure -state disable -text {}
	}
    } -state disable
    ttk::entry .android.fr1.et2 -state disable
    ttk::label .android.fr1.lbp0 -image $::png_android_invalid
    ttk::label .android.fr1.lbp1 -image $::png_android_invalid
    ttk::label .android.fr1.lbp2 -image $::png_android_invalid
    
    frame .android.fr2
    ttk::button .android.fr2.bt1 -text OK -command _createNewActivity
    ttk::button .android.fr2.bt2 -text Cancel -command [list _clearEntry {.android.fr1.et1 .android.fr1.et2}]
    
    pack .android.fr1 -pady {2 1}
    pack .android.fr2 -pady {1 2}
    
    grid columnconfigure .android.fr1 1 -weight 1
    grid .android.fr1.lb0 .android.fr1.et0 .android.fr1.lbp0 -sticky news -pady {1 1}
    grid .android.fr1.lb1 .android.fr1.et1 .android.fr1.lbp1 -sticky news -pady {1 1}
    grid .android.fr1.lb2 .android.fr1.et2 .android.fr1.lbp2 -sticky news -pady {1 2}
    
    grid .android.fr2.bt1 .android.fr2.bt2
    
    showDialog .android
    focus .android.fr1.et1

    if {$::android_path eq {}} {
	.android.fr1.et0 configure -state disable
    } else {
	if {[string last "/" $::android_path] < [expr [string length $::android_path] - 1]} {
	    set ::android_path "${::android_path}/"
	}
	set ::android_projects [glob "${::android_projects}src/*"]
    }
}

proc addMenu {menu} {
    set path  .mu.[lindex $menu 0]
    set label [lindex $menu 1]
    set items [lindex $menu 2]
    menu $path -tearoff 0
    .mu add cascade -menu $path -label $label -underline 0
    foreach item $items {
	::menuTool::produce $path $item
    }
}

proc _updateAndroidPackages {} {
    set path [.android.fr1.et0 get]
    if {$path != {}} {
	set ::android_packages {}
	_getPackages "${::android_path}$path"
	.android.fr1.lbp0 configure -image $::png_android_accept 
	.android.fr1.et1 configure -state normal
    } else {
	set ::android_packages {}
	.android.fr1.lbp0 configure -image $::png_android_invalid
	.android.fr1.et1 configure -state disable

	.android.fr1.lbp1 configure -image $::png_android_invalid
	.android.fr1.et2 configure -state disable -text {}
    }
}

proc _getPackages {root} {
    set children [glob "${root}/*"]
    set root_package {}
    foreach c $children {
	if {file isfile $c} {
	    set root_package $root
	} else {
	    _getPackages "${root}/$c"
	}
    }
    if {$root == $root_package} {
	set pj [.android.fr1.et1 get]
	regsub -all {/} [string trim $root "$::{android_path}${pj}/src/"] {\.} root_package
	lappend $::android_packages  $root_package
    }
}

proc _createNewActivity {} {
    set package [.android.fr1.et1 get]
    regsub -all {\.} $package {/} nPackage
    set activity [.android.fr1.et2 get]
    if {$activity != {}} {
	set fid [open "${::android_path}${nPackage}/${activity}" w]
	puts $fid "// Created By Cucumber
package $package;

import android.app.Activity;
import android.os.Bundle;
import android.widget.*;

public class $activity extends Activity {
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
	TextView tv = new TextView(this);
	setContentView(tv);
    }
}
"
	close $fid

set activity_xml [string tolower $activity]
set fid [open "${::android_path}$pj/res/layout/${activity_xml}.xml" w]
puts $fid "
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:orientation="vertical"
    android:layout_width="fill_parent"
    android:layout_height="fill_parent"
    >

</LinearLayout>
"
close $fid
    }
}

proc _clearEntry {entry_list} {
    destroy .android
}

addMenu {android Android {{Activity {} 1 {} createNewActivity}}}