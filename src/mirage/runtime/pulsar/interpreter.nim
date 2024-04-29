import std/[options]
import ../../utils
import ../[shared, tokenizer]
import ./[operation, bytecodeopsetconv]
import pretty

type
  Clause* = ref object
    name*: string
    operations*: seq[Operation]

  PulsarInterpreter* = ref object
    tokenizer: Tokenizer
    
    currClause: int = -1
    clauses: seq[Clause]

proc getClause*(interpreter: PulsarInterpreter): Option[Clause] {.inline.} =
  if interpreter.currClause <= interpreter.clauses.len-1 and 
    interpreter.currClause > -1:
    some(interpreter.clauses[interpreter.currClause])
  else:
    none Clause

proc analyze*(interpreter: PulsarInterpreter) {.inline.} =
  var cTok = interpreter.tokenizer.deepCopy()
  while not interpreter.tokenizer.isEof:
    let 
      clause = interpreter.getClause()
      tok = cTok.maybeNext()

    if *tok and (&tok).kind == tkClause and 
      not *clause:
      inc interpreter.currClause
      interpreter.clauses.add(
        Clause(
          name: (&tok).clause,
          operations: @[]
        )
      )
      interpreter.tokenizer.pos = cTok.pos
      continue
 
    let op = nextOperation interpreter.tokenizer

    if *clause and *op:
      interpreter.clauses[interpreter.currClause].operations.add(&op)
      cTok.pos = interpreter.tokenizer.pos
      continue

    if *tok and (&tok).kind == tkEnd and
      *clause:
      interpreter.currClause = -1
      interpreter.tokenizer.pos = cTok.pos
      continue

proc newPulsarInterpreter*(source: string): PulsarInterpreter {.inline.} =
  PulsarInterpreter(
    tokenizer: newTokenizer(source),
    clauses: @[]
  )
