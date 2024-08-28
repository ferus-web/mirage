import std/options
import mirage/atom
import mirage/runtime/pulsar/interpreter
import mirage/runtime/exceptions

let i = newPulsarInterpreter(
  """
CLAUSE other
  1 LOADI   1 0  # control integer
  2 LOADS   2 "lol"
  3 ADDI 1 2 
END other

CLAUSE main
  1 LOADS 0 "billions must generate stack traces"
  2 CALL print 0
  3 CALL other
END main
"""
)
analyze i

run i

echo i.generateTraceback().get()
