import std/[options, strutils]
import ../[shared, tokenizer], operation
import ../../utils
import pretty

proc nextOperation*(dtok: var Tokenizer): Option[Operation] {.inline.} =
  discard dtok.consumeWhitespace()

  var op = Operation()
  let opIdx = dtok.nextExcludingWhitespace()
  
  op.index = opIdx.integer.uint64

  let opCode = dtok.nextExcludingWhitespace()

  op.opcode = toOp(opCode.op)

  while not dtok.isEof():
    let arg = dtok.next()

    if arg.kind in [tkQuotedString, tkInteger, tkIdent]:
      op.rawArgs.add(arg)
      continue

    break

  some op
