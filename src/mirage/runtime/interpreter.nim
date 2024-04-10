import std/[options, sequtils, sugar]
import tokenizer, shared, interpreter_type, builtins
import errors/prelude
import pretty

proc call*(interpreter: Interpreter, token: Token)

proc arithmeticOpGetArgs(interpreter: Interpreter, nums: var seq[MAtom], pos: var int) {.inline.} =
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

    arithmeticOpGetArgs(interpreter, nums, pos)

    for i, num in nums:
      # guard(num.kind == Integer, "Can't add non-ints for now") # TODO: replace with interpreter based errors
      if num.kind != Integer:
        interpreter.newTypeError(
          "Argument " & $i,
          Integer, num.kind
        )

      accumulator += num
        .getInt()
        .unsafeGet()

    interpreter.grow(pos)
    interpreter.stack[pos] = integer accumulator
  of Mult:
    var
      nums: seq[MAtom]
      accumulator = 1
      pos: int

    arithmeticOpGetArgs(interpreter, nums, pos)

    for num in nums:
      guard(num.kind == Integer, "Can't multiply non-ints for now") # TODO: replace with interpreter based errors
      accumulator *= num
        .getInt()
        .unsafeGet()

    interpreter.grow(pos)
    interpreter.stack[pos] = integer accumulator
  of Sub:
    var
      nums: seq[MAtom]
      accumulator, pos: int
      loop: int

    arithmeticOpGetArgs(interpreter, nums, pos)
    
    while loop < nums.len - 1:
      let 
        left = nums[loop]
        right = if loop + 1 < nums.len: nums[loop + 1] else: integer 0

      guard(left.kind == Integer, "Can't subtract non-ints for now") # TODO: replace with interpreter based errors
      guard(right.kind == Integer, "Can't subtract non-ints for now")

      accumulator +=
        left.getInt().unsafeGet() - right.getInt().unsafeGet()

      inc loop
    
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
    builtins.print(interpreter, args)

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
