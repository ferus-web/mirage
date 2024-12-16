import std/[tables, options]
import mirage/atom
import mirage/compiler/mir2c

var cc = newMIRC(
  """
CLAUSE main
  1 LOADS   1 "Hello MIRC!"
  2 CALL    print 1
END main
"""
)

analyze cc
let code = transpile cc
echo code
