import std/[options, strutils]
import mirage/atom

type
  ExceptionTrace* = ref object
    prev*, next*: Option[ExceptionTrace]
    clause*, line*: int
    exception*: RuntimeException

  RuntimeException* = ref object of RootObj
    operation*: int
    clause*: string
    message*: string

  WrongType* = ref object of RuntimeException

proc wrongType*(
  operation: int, clause: string,
  expected, got: MAtomKind
): WrongType {.inline, noSideEffect, gcsafe.} =
  WrongType(
    operation: operation,
    clause: clause,
    message: "Expected $1; got $2 instead." % [$expected, $got]
  )
