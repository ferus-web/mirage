import std/[strutils, options]
import ./base, ../../atom, ../interpreter_type

type DivisionByZeroError* = object of RuntimeError
  p*, q*: MAtom

proc newDivisionByZeroError*(
  interpreter: Interpreter,
  p, q: MAtom
) {.inline.} =
  guard(p.kind == Integer and q.kind == Integer, "Division by zero error will be illogical if the atoms involved aren't integers!")
  guard(q.getInt().unsafeGet() == 0, "Division by zero error will be illogical if the denominator is not zero!")

  interpreter.error(
    DivisionByZeroError(
      message: "Attempt to divide $1 by 0" % [$p.getInt().unsafeGet()],
      p: p,
      q: q
    )
  )
