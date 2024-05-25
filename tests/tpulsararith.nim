import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADI   1 0 
  2 LOADI   2 3 
  3 GTI     1 2  
  4 JUMP    6 
  5 JUMP    9 
  6 LOADS   3 "0 > 3" 
  7 CALL    print 3 
  8 RETURN  NULL 
  9 LOADS   3 "0 < 3" 
  10 CALL   print 3 
  11 RETURN NULL 
END main
""")

analyze i
run i
