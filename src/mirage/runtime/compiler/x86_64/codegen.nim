## 64-bit x86 compiler that can compile a clause into ASM using Laser
##
## Copyright (C) 2024 Trayambak Rai

import std/[strutils, tables, options, logging]
import ../../../[atom, utils]
import ../../shared, ../../pulsar/operation
import ../[assembling, types, jit]
import pretty, laser/photon_jit

type
  CompilationFailed* = object of Defect
  StorePlace* = enum
    spRegister = 0x0
    spStack = 0x1

  LocationVerificationError* = object of Defect
  
  Location* = object
    register*: RegX86_64
    case place*: StorePlace = spRegister
    of spStack:
      places*: uint  ## How many pops until we get this value?
    else: discard

  Compiler* = ref object
    stack: Table[uint, RegX86_64]
    assembler*: Assembler[X86_64]

proc isAt*(compiler: Compiler, pos: uint, reg: RegX86_64) {.inline.} =
  compiler.stack[pos] = reg

proc occupied*(compiler: Compiler, reg: RegX86_64): tuple[occupied: bool, idx: Option[uint]] {.inline.} =
  for idx, entreg in compiler.stack:
    if entreg == reg:
      return (occupied: true, idx: some(idx))

  (occupied: false, idx: none(uint))

proc storeStack*(compiler: Compiler, reg: static RegX86_64) =
  compiler.assembler.push(reg)

proc moveStr*(compiler: Compiler, position: uint, str: var string) =
  compiler.assembler.mov(rdi, addr str)
  compiler.isAt(position, rdi)

proc compile*(compiler: Compiler, clause: Clause): JitFunction =
  gen_x86_64(assembler = a, clean_registers = true):
    compiler.assembler = a

    for op in clause.operations:
      case op.opcode
      of LoadStr:
        let position = &op.arguments[0].getUint()
        var strcp = &op.arguments[1].getStr()
        compiler.moveStr(position, strcp) # load `strcp` onto rdi
      of LoadInt:
        let position = &op.arguments[0].getUint()
        var intcp = &op.arguments[0].getInt()
      else:
        discard

    a.ret()

proc newCompiler*: Compiler {.inline.} =
  Compiler()
