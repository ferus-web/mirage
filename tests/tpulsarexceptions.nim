import std/options
import mirage/atom
import mirage/runtime/pulsar/interpreter
import mirage/runtime/exceptions

let i = newPulsarInterpreter("""
CLAUSE main
  1 LOADI   1 0  # control integer
  2 LOADI   2 1  # increment factor
  3 LOADI   3 32 # limit
  4 SUBI    1 2  # subtract [2] from [1]
  5 CALL    print 1 # call the print builtin on [1]
  6 EQU     1 3     # equate [1] to [3]
  7 RETURN  NULL    # if we've reached [3], halt the execution of the `main` clause. Since there's no rollback data, we'll exit execution.
  8 JUMP    4       # if we haven't, jump to op 4
END main
""")
analyze i

i.throw(
  wrongType(0, "main", Integer, String)
)

run i

echo i
  .generateTraceback()
  .get()
