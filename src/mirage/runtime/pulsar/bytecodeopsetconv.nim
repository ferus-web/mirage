import std/[options]
import ../[shared, tokenizer], operation
import ../../utils
import pretty

proc nextOperation*(tokenizer: var Tokenizer): Option[Operation] {.inline.} =
  var 
    op = Operation()
    dtok = deepCopy(tokenizer)

  let opIdx = dtok.maybeNextExcludingWhitespace()
  
  if not *opIdx or (&opIdx).kind != tkInteger:
    return
  
  op.index = (&opIdx).integer.uint64

  let opIdent = dtok.maybeNextExcludingWhitespace()

  if not *opIdent or (&opIdent).kind != tkOperation:
    return

  try:
    op.opcode = toOp(
      (&opIdent).op
    )
  except ValueError:
    return

  while not dtok.isEof():
    let arg = dtok.maybeNextExcludingWhitespace()

    if not *arg:
      return some op
    
    if (&arg).kind notin [tkQuotedString, tkInteger]:
      return some op

    op.rawArgs.add(&arg)
  
  tokenizer = dtok

  some op
