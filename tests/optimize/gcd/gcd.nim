import std/[tables, options]
import mirage/atom
import mirage/runtime/pulsar/interpreter

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADI 1 0
  2 LOADI 2 32
  3 LOADI 3 48
  4 EQU   2 3
  5 JUMP  13
  6 GTI   2 3
  7 JUMP 9
  8 JUMP 11
  9 SUBI 2 3
  10 JUMP 4
  11 SUBI 3 2
  12 JUMP 4
  13 CALL print 2
END main
""")

analyze i
run i # execution is really fast, analysis is slow.
