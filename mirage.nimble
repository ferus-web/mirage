# Package

version       = "0.1.2"
author        = "xTrayambak"
description   = "A nifty bytecode generator and runtime"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"
requires "flatty >= 0.3.4"
requires "zippy >= 0.10.12"

requires "pretty >= 0.1.0"

when not defined(mirageNoJit):
  requires "laser >= 0.0.1"

task explorer, "Compile MIR explorer":
  exec "nim c -d:release -d:danger -o:explorer utils/explorer.nim"
