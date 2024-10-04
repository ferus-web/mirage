# Package

version       = "1.0.3"
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

task explorer, "Compile MIR explorer":
  exec "nim c -d:release -d:danger -o:explorer utils/explorer.nim"

task fmt, "Format the code":
  exec "nph src/"
  exec "nph tests/"

task docs, "Generate documents":
  exec "nim doc --project --index:on src/mirage.nim"
