package require menuTool

proc menuData {} {
    return {
	{file File {
	    {New    n  0 {} createNewDoc}
	    {Save   s  0 {} saveDoc}
	    {SaveAs {} 1 {} saveAsDoc}
	    {}
	    {Quit   q  0 {} quitApp}
	}}
    }
}

menuTool::init [menuData]
. configure -menu .mu

proc createNewDoc {} {}
proc saveDoc {} {}
proc saveAsDoc {} {}
proc quitApp {} {exit}