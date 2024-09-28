import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter(
  """
CLAUSE main
  1 LOADI   1 2 
  2 LOADI   2 2 
  3 POWI    1 2
  4 CALL    print 1
END main
"""
)

analyze i
run i
