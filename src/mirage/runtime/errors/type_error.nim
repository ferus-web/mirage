import std/strutils
import ./base, ../../atom, ../interpreter_type

type TypeError* = object of RuntimeError
  expected*, got*: MAtomKind

proc newTypeError*(
  interpreter: Interpreter,
  valueName: string, 
  expected, 
  got: MAtomKind
) {.inline.} =
  guard(expected != got, "Type error will be illogical if the expected type is equal to the type provided!")
  interpreter.error(
    TypeError(
      message: "Expected $1 for $2, got $3 instead." % [$expected, valueName, $got],
      expected: expected,
      got: got
    )
  )
