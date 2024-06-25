# Package

version       = "0.1.4"
author        = "xTrayambak"
description   = "A nifty bytecode generator and runtime"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"
requires "flatty >= 0.3.4"
requires "zippy >= 0.10.12"
requires "nimsimd >= 1.2.9"
requires "pretty >= 0.1.0"
requires "crunchy >= 0.1.11"
requires "kashae >= 0.1.5"
requires "sorta >= 0.2.0"
requires "Laser >= 0.0.1"

task explorer, "Compile MIR explorer":
  exec "nim c -d:release -d:danger -o:explorer utils/explorer.nim"
