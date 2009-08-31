proc .t {args} {
    switch [lindex $args 0] {
        "insert" {}
        "delete" {}
        "default" { return [eval .internal.t $args] }
      }
}