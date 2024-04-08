# Package

version       = "0.1.0"
author        = "xTrayambak"
description   = "A nifty bytecode generator and interpreter"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.2"

when not defined(release):
  requires "pretty >= 0.1.0"
