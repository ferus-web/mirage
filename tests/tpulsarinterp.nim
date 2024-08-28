import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter(
  """
CLAUSE main
  1 LOADI   1 32  # control integer
  2 DEC     1
  3 CALL    print 1
END main
"""
)

analyze i
run i
