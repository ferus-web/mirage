import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter(
  """
CLAUSE main
  1 LOADF   1 2.0 
  2 LOADF   2 2.0
  3 POWF    1 2
  4 CALL    print 1
END main
"""
)

analyze i
run i
