import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter(
  """
CLAUSE main
  1 LOADO     0
  2 CFIELD    0 0 "value" 
  3 CFIELD    0 1 "intvalue"
  4 FWFIELD   0 0 "Hello World"
  5 FWFIELD   0 1 1337
  6 CASTS     0 1
  7 CALL      print 1
  8 WFIELD    0 "value" "This was changed, it was previously greeting the world." 
  9 WFIELD    0 "intvalue" 1984
  10 CASTS    0 0
  11 CALL     print 0
END main
"""
)

analyze i
run i
