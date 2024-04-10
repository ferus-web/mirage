# Package

version       = "0.1.0"
author        = "xTrayambak"
description   = "A nifty bytecode generator and runtime"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.2"

when not defined(release):
  requires "pretty >= 0.1.0"

when not defined(mirageNoJit):
  requires "laser >= 0.0.1"
