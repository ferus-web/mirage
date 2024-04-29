import ./cell, ../interpreter_type

type
  GCGraph* = ref object
    promotes*: seq[Cell]
    removes*: seq[Cell]

proc `$`*(graph: GCGraph): string {.inline.} =
  var s: string
  s &= "Garbage Collection Graph\nRemoving the following cells:"
  
  for removal in graph.removes:
    s &= $removal

import pretty

proc commit*(graph: GCGraph, interpreter: Interpreter) =
  for removal in graph.removes:
    let idx = removal.index
    interpreter.stack[idx] = MAtom(kind: Null) # we're still using 1 byte, is that fine? :P
