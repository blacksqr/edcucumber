set s [socket -async 127.0.0.1 23818]
fconfigure $s -buffering line

puts $s [lindex $argv 0]
flush $s
catch {close $s}
