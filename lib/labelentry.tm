package provide LabelEntry 0.1

package require img::png
package require snit
package require tile
set ico [image create photo -format png -file "[pwd]/pic/edit-find.png"]

proc createLabelEntry {} {
    namespace eval ::ttk {
        style theme setting "default" {
            set pad [expr [image width $::ico] + 4]
            style layout LabelEntry {
                Entry.field -children {
                    LabelEntry.icon -side left
                    Entry.padding -children {
                        Entry.textarea
                    }
                }
            }
            style element create LabelEntry.icon image $::ico -sticky "" -padding [list $pad 11 2 11]
        }
    }
}

snit::widgetadaptor LabelEntry {
    delegate option * to hull
    delegate method * to hull
    
    constructor args {
	createLabelEntry
	installhull using ttk::entry -style LabelEntry
	# bindtags $win [linsert [bindtags $win] 1 TLabelEntry]
	$self configurelist $args
    }
}




