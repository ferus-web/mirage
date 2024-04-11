import std/strutils
import ./base, ../[clause, interpreter_type]

type ClosureError* = object of RuntimeError
  index*: int
  accessAttempt*: Clause
  owner*: Clause

proc newClosureError*(interpreter: Interpreter, index: int, accessAttempt, owner: Clause) {.inline.} =
  interpreter.error(
    ClosureError(
      index: index,
      owner: owner,
      accessAttempt: accessAttempt,
      message: "Clause $1 attempted to access stack index $2, which is inside $3's closure." % [accessAttempt.name, $index, owner.name]
    )
  )
