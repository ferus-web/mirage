import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter(
  """
CLAUSE main
  1 LOADS 0 "Hello world"
  2 LOADS 1 "Second string"
  3 LOADI 2 0
  3 SWAP  0 1
  4 CALL  print 0
  5 CALL  print 1
END main
"""
)

analyze i
run i
