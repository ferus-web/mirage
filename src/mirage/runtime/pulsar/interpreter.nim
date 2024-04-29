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
  var cTok = deepCopy(interpreter.tokenizer)
  while not interpreter.tokenizer.isEof:
    var clause = interpreter.getClause()
    let tok = cTok.maybeNext()

    if interpreter.tokenizer.pos == 15 and *tok:
      print &tok

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

    if *tok and (&tok).kind == tkEnd and
      *clause:
      interpreter.currClause = -1
      continue
    
    let op = nextOperation interpreter.tokenizer
    
    if *op: 
      let x = &op

      if x.index == 1:
        print *clause

      print x

    if *clause and *op: 
      interpreter.clauses[interpreter.currClause].operations.add(&op)
      interpreter.tokenizer.pos = cTok.pos
      print interpreter.tokenizer

proc newPulsarInterpreter*(source: string): PulsarInterpreter {.inline.} =
  PulsarInterpreter(
    tokenizer: newTokenizer(source),
    clauses: @[]
  )
