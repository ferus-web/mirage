## MIR to C transpiler
import std/[options]
import mirage/runtime/[shared, tokenizer]
import mirage/runtime/pulsar/[bytecodeopsetconv, operation]
import mirage/utils

type
  ClauseRollback* = object
    clause*: int = int.low
    opIndex*: uint = 1

  Clause* = object
    name*: string
    operations*: seq[Operation]

    rollback*: ClauseRollback

  MIRC* = object
    tokenizer*: Tokenizer
    clauses*: seq[Clause]
    currClause*: int

func getClause*(
  mirc: MIRC, id: Option[int] = none int
): Option[Clause] =
  let id =
    if *id:
      &id
    else:
      mirc.currClause

  if id <= mirc.clauses.len - 1 and id > -1:
    some(mirc.clauses[id])
  else:
    none(Clause)

proc analyze*(mirc: var MIRC) =
  var cTok = mirc.tokenizer.deepCopy()
  while not mirc.tokenizer.isEof:
    let
      clause = mirc.getClause()
      tok = cTok.maybeNext()

    if *tok and (&tok).kind == tkClause:
      mirc.clauses.add(
        Clause(name: (&tok).clause, operations: @[], rollback: ClauseRollback())
      )
      mirc.currClause = mirc.clauses.len - 1
      mirc.tokenizer.pos = cTok.pos
      continue

    let op = nextOperation mirc.tokenizer

    if *clause and *op:
      mirc.clauses[mirc.currClause].operations.add(&op)
      cTok.pos = mirc.tokenizer.pos
      continue

    if *tok and (&tok).kind == tkEnd and *clause:
      mirc.tokenizer.pos = cTok.pos
      continue

proc transpile*(mirc: var MIRC): string =
  discard

proc newMIRC*(source: string): MIRC {.inline.} =
  MIRC(
    tokenizer: newTokenizer(source)
  )
