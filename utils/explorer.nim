## MIR bytecode explorer utility
## Copyright (C) 2024 Trayambak Rai
import std/[os, options]
import mirage/ir/caching, mirage/utils

{.push checks: off.}
proc main {.inline.} =
  if paramCount() < 1:
    quit "Usage: explorer [name of program]"

  if (let data = paramStr(1).retrieve(); *data):
    echo &data
  else:
    quit "Cannot retrieve MIR file for program: " & paramStr(1)
{.pop.}

when isMainModule:
  main()
