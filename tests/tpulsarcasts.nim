import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADI    0 32  
  2 CASTS    0 0 
  3 CALL     print 0 
  4 CASTI    0 0 
  5 ADDI     0 0 
  6 CALL     print 0 
  7 RETURN   NULL
END main
""")

analyze i
run i
