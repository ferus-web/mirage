import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADI    0 32  
  2 LOADI    1 0
  3 COPY     0 1
  4 CALL     print 1
  5 LOADI    2 1337
  6 LOADI    3 0
  7 MOVE     2 3
  8 CALL     print 2
  9 CALL     print 3
END main
""")

analyze i
run i
