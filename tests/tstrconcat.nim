import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

# disclaimer: this will quickly consoom all your memory, so beware
# it isn't a bug:tm:

let i = newPulsarInterpreter(
  """
CLAUSE main
  1 LOADS    0 "Hey " 
  2 ADDS     0 0 
  3 CALL     print 0 
  4 JUMP     2 
END main
"""
)

analyze i
run i
