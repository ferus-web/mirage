## Thank you araq, very cool.
import std/[options]
import clause, ../atom, tokenizer, errors/base, gc/cell

type
  RuntimeHalt* = object of Defect
  Interpreter* = ref object
    tokenizer*: Tokenizer
    clauses*: seq[Clause]
    clause*: Clause
    stack*: seq[MAtom]
    errors*: seq[RuntimeError]

    loopConditions*: Option[seq[EquatoryOperation]]
    insideLoop*: bool

  EquationKind* = enum
    ekEquate = 0
    ekNotEquate = 1

  EquatoryOperation* = ref object
    kind*: EquationKind
    indexes*: seq[int32]

  Arena* = ref object
    interpreter*: Interpreter
    cells*: seq[Cell]

{.push hint[XCannotRaiseY]: off, checks: off.}
proc guard*(cond: bool, msg: string) {.raises: [RuntimeHalt], inline.} =
  if not cond:
    raise newException(
      RuntimeHalt,
      "Mirage interpreter encountered a HALT: " & $msg
    )
{.pop.}

proc error*(interpreter: Interpreter, error: RuntimeError) {.inline.} =
  interpreter.errors.add(error)

proc getOwnerClause*(interpreter: Interpreter, idx: int): Option[Clause] {.inline.} =
  for clause in interpreter.clauses:
    if idx in clause.stackClosure:
      return some clause

proc load*(interpreter: Interpreter, source: string) {.inline.} =
  interpreter.tokenizer = newTokenizer(source)

proc get*(interpreter: Interpreter, idx: int): Option[MAtom] {.inline.} =
  if idx < interpreter.stack.len and idx >= 0:
    return interpreter.stack[idx].some()

{.push checks: off.}
proc resolveRef*(interpreter: Interpreter, idx: int): MAtom {.inline.} =
  guard(idx < interpreter.stack.len and idx >= 0, "Attempt to get atom outside of stack")
  let atom = interpreter.stack[idx]

  proc findNonRef(begin: MAtom): MAtom =
    if begin.kind == Ref:
      guard(begin.reference.isSome, "Weak references can't be resolved yet")
      return interpreter
        .resolveRef(
          begin
            .reference
            .unsafeGet()
        )
    
    return begin

  findNonRef(atom)
{.pop.}

proc grow*(interpreter: Interpreter, idx: int) {.inline.} =
  let final = idx + 1

  # guard(final > interpreter.stack.len, "Attempt to shrink stack using `grow()`")
  interpreter.stack.setLen(final)

export clause, atom
