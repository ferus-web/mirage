import std/[options, sequtils, sugar]
import tokenizer, shared, clause, ../atom
import pretty

type
  RuntimeHalt* = object of Defect
  Interpreter* = ref object
    tokenizer*: Tokenizer
    clauses*: seq[Clause]
    clause*: Clause
    stack*: seq[MAtom]

{.push hint[XCannotRaiseY]: off, checks: off.}
proc guard*(cond: bool, msg: string) {.raises: [RuntimeHalt], inline.} =
  if not cond:
    raise newException(
      RuntimeHalt,
      "Mirage interpreter encountered a HALT: " & $msg
    )
{.pop.}

proc getOwnerClause*(interpreter: Interpreter, idx: int): Option[Clause] {.inline.} =
  for clause in interpreter.clauses:
    if idx in clause.stackClosure:
      return some clause

proc load*(interpreter: Interpreter, source: string) {.inline.} =
  interpreter.tokenizer = newTokenizer(source)

proc call*(interpreter: Interpreter, token: Token)

{.push checks: off.}
proc resolveRef*(interpreter: Interpreter, idx: int): MAtom {.inline.} =
  guard(idx < interpreter.stack.len and idx >= 0, "Attempt to get atom outside of stack")
  let atom = interpreter.stack[idx]

  proc findInt(begin: MAtom): MAtom =
    if begin.kind == Ref:
      print begin
      guard(begin.reference.isSome, "Weak references can't be resolved yet")
      return interpreter
        .resolveRef(
          begin
            .reference
            .unsafeGet()
        )
    
    if begin.kind == Integer:
      return begin

    guard(false, "findInt() failed; no integer atom could be found recursively.")

  findInt(atom)
{.pop.}

proc grow*(interpreter: Interpreter, idx: int) {.inline.} =
  let final = idx + 1

  guard(final > interpreter.stack.len, "Attempt to shrink stack using `grow()`")
  interpreter.stack.setLen(final)

proc execute*(interpreter: Interpreter, token: Token) =
  guard(token.kind == tkOperation, "execute() got non-operation token!")
  
  case toOp(token.op)
  of LoadInt:
    let
      pos = interpreter.tokenizer.maybeNext()
      value = interpreter.tokenizer.maybeNext()

    guard(pos.isSome and value.isSome, "LOADI expects two arguments (stack_position, value)")
    guard(pos.unsafeGet().kind == tkInteger, "LOADI expects integer token for `stack_position`, got " & $value.unsafeGet().kind)
    guard(value.unsafeGet().kind == tkInteger, "LOADI expects integer token for `value`, got " & $value.unsafeGet().kind)

    let atom = integer value.unsafeGet().integer
    interpreter.stack.setLen(pos.unsafeGet().integer + 1'i32)

    interpreter.stack[pos.unsafeGet().integer] = atom
  of LoadStr:
    let
      pos = interpreter.tokenizer.maybeNext()
      value = interpreter.tokenizer.maybeNext()

    guard(pos.isSome and value.isSome, "LOADS expects two arguments (stack_position, value)")
    guard(pos.unsafeGet().kind == tkInteger, "LOADS expects integer token for `stack_position`, got " & $value.unsafeGet().kind)
    guard(value.unsafeGet().kind == tkQuotedString, "LOADS expects string token for `value`, got " & $value.unsafeGet().kind)

    let atom = str value.unsafeGet().str
    interpreter.grow(pos.unsafeGet().integer)
    interpreter.stack[pos.unsafeGet().integer] = atom
  of LoadRef:
    let
      pos = interpreter.tokenizer.maybeNext()
      value = interpreter.tokenizer.maybeNext()

    guard(pos.isSome and value.isSome, "LOADR expects two arguments (stack_position, value)")
    guard(pos.unsafeGet().kind == tkInteger, "LOADR expects integer token for `stack_position`, got " & $value.unsafeGet().kind)
    guard(
      value.unsafeGet().kind in [tkIdent, tkInteger], 
      "LOADR expects integer index or weak ident reference for `value`, got " & $value.unsafeGet().kind
    )

    var atom: MAtom
    case value.unsafeGet().kind:
      of tkIdent:
        atom = weakRef value.unsafeGet().ident
      of tkInteger:
        atom = strongRef value.unsafeGet().integer
      else: discard
    
    interpreter.grow(pos.unsafeGet().integer)
    interpreter.stack[pos.unsafeGet().integer] = atom
  of Call:
    interpreter.call(token)
  of Add:
    var 
      nums: seq[MAtom]
      accumulator: int
      pos: int

    for tok in interpreter.tokenizer.flow():
      var next: Option[Token]

      if not interpreter.tokenizer.isEof():
        let cTokenizer = deepCopy(interpreter.tokenizer)
        next = cTokenizer.maybeNext()

      if tok.kind == tkInteger and 
        next.isSome and
        next.unsafeGet().kind == tkInteger:
        nums.add(
          interpreter.resolveRef(tok.integer)
        )
      else:
        pos = tok.integer
        break
    
    for num in nums:
      guard(num.kind == Integer, "Can't add non-ints for now") # TODO: replace with interpreter based errors
      
      accumulator += num
        .getInt()
        .unsafeGet()

    interpreter.grow(pos)
    interpreter.stack[pos] = integer accumulator
  else: discard

proc enter*(interpreter: Interpreter, token: Token) {.inline.} =
  interpreter.clause = Clause(
    name: token.clause
  )

  interpreter.clauses.add(interpreter.clause)

proc call*(interpreter: Interpreter, token: Token) =
  let fn = interpreter.tokenizer.maybeNext()
  var args: seq[MAtom]

  for aTok in interpreter.tokenizer.flow(includeWhitespace = true):
    if aTok.kind == tkInteger:
      args.add(interpreter.stack[aTok.integer])
    else:
      if aTok.kind == tkWhitespace and '\n' in aTok.whitespace:
        break

      continue

  guard(fn.isSome, "CALL expected ident for function name; got EOF instead.")
  guard(fn.unsafeGet().kind == tkIdent, "CALL expected ident for function name; got " & $fn.unsafeGet().kind)

  case fn.unsafeGet().ident
  of "print":
    for arg in args:
      arg
        .crush("", false)
        .echo()

proc exit*(interpreter: Interpreter, token: Token) {.inline.} =
  guard(interpreter.clause.name == token.endClause, "Interpreter current clause name and token's clause name are different!")
  interpreter.clause.reset()

proc run*(interpreter: Interpreter) =
  for token in interpreter.tokenizer.flow():
    case token.kind
    of tkOperation:
      interpreter.execute(token)
    of tkClause:
      interpreter.enter(token)
    of tkEnd:
      interpreter.exit(token)
    else: discard

  print interpreter

proc newInterpreter*(source: string): Interpreter {.inline.} =
  Interpreter(
    tokenizer: newTokenizer(source)
  )
