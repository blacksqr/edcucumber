bind .f.content <Control-r> runScript

proc runScript {} {
    catch {interp delete foo}
    interp create foo
    set err [interp eval foo [.f.content get 1.0 end]]
    if {$err ne {}} {
	.sf.lb configure -text $err
    }
    interp delete foo
}