import mirage/runtime/tokenizer
import std/unittest
import pretty

let src = """
CLAUSE main
LOADI 0 0
LOADI 1 0
LOADS 1 "This runs forever!"

LOOP_CONDITIONS
EQUATE 0 1
LOOP_BODY
CALL print 1
LOOP_END

END main
"""

var t = newTokenizer(src)

for tok in t.flow():
  print tok
