import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADL 0 
  2 SCAPL 0 34 
  3 LOADI 1 0 
  4 LOADI 2 33 
  5 LOADS 3 "Ended. This shouldn't be possible!" 
  6 GTI 1 2 
  7 JUMP 9 
  8 CALL print 3 
  9 ADDL 0 1 
  10 INC 1
  11 JUMP 6
END main
""")

analyze i
run i
