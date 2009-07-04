bind .f.content <Control-r> runScript

proc runScript {} {
    catch {interp delete foo}
    interp create foo
    
    interp eval foo {
        rename puts _puts
        proc puts {args} {
            _puts $args
            return $args
        }
    }
    
    set err [interp eval foo [.f.content get 1.0 end]]
    if {$err ne {}} {
	.sf.lb configure -text "result : $err"
    }
}






