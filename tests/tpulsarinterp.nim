import mirage/runtime/pulsar/interpreter
import pretty

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADS       0 "Hello world"
  2 LOADI       1 32
  3 EQU         0 32
  4 JUMP        6
  5 JUMP        7
  6 CALL print  0
  7 RETURN      NULL
  8 LOADS       2 "This should never happen"
  9 CALL print  2
  10 RETURN      NULL
END main
""")

analyze i

print i
