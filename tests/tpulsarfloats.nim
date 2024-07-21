import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADF 0 1.5
  2 CALL  print 0
END main
""")

analyze i
run i
