import std/[tables, options]
import mirage/atom
import mirage/runtime/prelude
import mirage/utils

let i = newPulsarInterpreter("""
CLAUSE otherclause
  1 CALL throw_a_dumb_error 
  2 LOADS 0 "other clause moment" 
  3 CALL print 0
END otherclause

CLAUSE main
  1 LOADS 0 "Hello there! This is the main clause, no crashes!"
  2 CALL print 0
  3 CALL otherclause
END main
""")
i.registerBuiltin(
  "throw_a_dumb_error",
  proc(op: Operation) =
    i.throw(wrongType(String, Integer))
)

analyze i
run i

echo &i.generateTraceback()
