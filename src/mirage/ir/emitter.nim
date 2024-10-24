## Bytecode emitter module.
## This module takes in an IR generator state, and generates MIR accordingly.
##
## Copyright (C) 2024 Trayambak Rai

import ./shared, ../runtime/shared, ../atom
import ../utils
import ../version

proc emitOperation*(gen: IRGenerator, op: IROperation): string {.inline.} =
  let opName = opToString(op.opCode)
  result &= opName & ' '

  for i, arg in op.arguments:
    if arg.kind != String:
      result &= arg.crush() & ' '
    else:
      let content = &arg.getStr()
      if content.contains('"'):
        result &= '\'' & content & '\'' & ' '
      elif content.contains('\''):
        result &= '"' & content & '"' & ' '
      else:
        result &= arg.crush() & ' '

proc emitModule*(gen: IRGenerator, module: CodeModule): string {.inline.} =
  when not defined(release):
    var final =
      "\n\n# Clause/CodeModule \"" & module.name & "\"\n" & "# Operations: " &
      $module.operations.len & "\n"
  else:
    var final = "\n"

  final &= "CLAUSE " & module.name & '\n'

  for i, op in module.operations:
    final &= '\t' & $(i + 1) & ' ' & emitOperation(gen, op)

    if i + 1 < module.operations.len:
      final &= '\n'

  final &= "\nEND " & module.name

  final

proc emitIR*(gen: IRGenerator): string {.inline.} =
  when not defined(release):
    var final =
      "# IR code generated by Mirage v" & MirageVersionString & "; compiled against nim@" &
      NimVersion & '\n' &
      "# Mirage is a bytecode generation and interpretation library under the Ferus project.\n" &
      "# For more information, visit https://github.com/ferus-web/mirage\n" &
      "# (C) 2024 Trayambak Rai and Ferus Authors"
  else:
    var final: string

  for module in gen.modules:
    final &= emitModule(gen, module)

  final
