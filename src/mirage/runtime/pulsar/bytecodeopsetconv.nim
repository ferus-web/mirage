## Converts a stream of MIR tokens into an operation, if possible.
##
## Copyright (C) 2024 Trayambak Rai

import std/[options, tables]
import ../[shared, tokenizer]
import ./operation
import pretty

proc nextOperation*(dtok: var Tokenizer): Option[Operation] {.inline.} =
  var op = Operation()
  let opIdx = dtok.nextExcludingWhitespace()

  if opIdx.kind != tkInteger:
    return
  
  op.index = opIdx.integer.uint64

  let opCode = dtok.nextExcludingWhitespace()
  op.opcode = toOp(opCode.op)

  while not dtok.isEof():
    let arg = dtok.next()

    if arg.kind == tkQuotedString or arg.kind == tkInteger or arg.kind == tkIdent:
      op.rawArgs.add(arg)
      continue

    break
  
  #print op
  some op
