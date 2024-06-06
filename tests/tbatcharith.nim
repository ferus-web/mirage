import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADI 1 4 
  2 LOADI 2 8 
  3 LOADI 3 24 
  4 LOADI 4 38 
  5 LOADI 5 23 
  6 LOADI 6 11 
  7 THREEMULT 7 1 2 3 4 5 6 
  8 CALL print 7  
END main
""")

analyze i
run i
