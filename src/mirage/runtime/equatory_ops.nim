import std/[options]
import interpreter_type, shared, tokenizer
import std/sugar
import pretty

proc solve*(op: EquatoryOperation, interpreter: Interpreter): bool {.inline.} =
  var atoms: seq[MAtom]

  for idx in op.indexes:
    let x = interpreter.get(idx)

    if x.isSome:
      echo "found: " & $idx
      atoms.add(x.unsafeGet())
    else:
      guard(false, "Equation operation cannot occur as stack index does not exist: " & $idx)

  if atoms.len < 1:
    # FIXME: we should just crash instead of doing this because it's silly
    return false

  var 
    accumulator = false
    prev = atoms[0]

  for atom in atoms[1 .. ^1]:
    if atom != prev:
      break

    accumulator = true
    prev = atom
  
  case op.kind
  of ekEquate:
    accumulator
  of ekNotEquate:
    not accumulator

proc equationFromToken*(token: Token, tokenizer: Tokenizer): EquatoryOperation {.inline.} =
  guard(token.kind == tkIdent, "Can't make equatory operation without ident")
  let kind = 
    if token.ident == "nequate":
      ekNotEquate
    else:
      ekEquate
  
  let indexes = collect:
    for tok in tokenizer.flow():
      if tok.kind == tkWhitespace: break
      if tok.kind == tkInteger: tok.integer
  
  EquatoryOperation(
    kind: kind,
    indexes: indexes
  )

proc satisfied*(equations: seq[EquatoryOperation], interpreter: Interpreter): bool {.inline.} =
  for eq in equations:
    if not eq.solve(interpreter):
      return false
  
  true
