type
  Reg* = enum
    RAX = 0
    RCX = 1
    RDX = 2
    RBX = 3
    RSP = 4
    RBP = 5
    RSI = 6
    RDI = 7
    R8 = 8
    R9 = 9
    R10 = 10
    R11 = 11
    R12 = 12
    R13 = 13
    R14 = 14
    R15 = 15
    XMM0 = 16
    XMM1 = 17
    XMM2 = 18
    XMM3 = 19
    XMM4 = 20
    XMM5 = 21
    XMM6 = 22
    XMM7 = 23
    XMM8 = 24
    XMM9 = 25
    XMM10 = 26
    XMM11 = 27
    XMM12 = 28
    XMM13 = 29
    XMM14 = 30
    XMM15 = 31

  OperandKind* = enum
    Rst, FRst, Imm, Mem64BaseAndOffset

  Operand* = ref object
    kind*: OperandKind
    reg*: Reg
    offsetOrImmediate*: uint64

  Condition* = enum
    Overflow = 0x0
    UnsignedLessThan = 0x2
    UnsignedGreaterThanOrEqualTo = 0x3
    EqualTo = 0x4
    NotEqualTo = 0x5
    UnsignedLessThanOrEqualTo = 0x6
    UnsignedGreaterThan = 0x7
    ParityEven = 0xA
    ParityOdd = 0xB
    SignedLessThan = 0xC
    SignedGreaterThanOrEqualTo = 0xD
    SignedLessThanOrEqualTo = 0xE
    SignedGreaterThan = 0xF
  
  Patchable* = enum
    paYes
    paNo

  Assembler* = ref object
    output*: seq[byte]

proc register*(reg: Reg): Operand {.inline.} =
  Operand(
    reg: reg,
    kind: Rst
  )

proc floatRegister*(reg: Reg): Operand {.inline.} =
  Operand(
    reg: reg,
    kind: FRst
  )

proc imm*(val: uint64): Operand {.inline.} =
  Operand(
    kind: Imm,
    offsetOrImmediate: val
  )

proc mem64BaseAndOffset*(base: Reg, offset: uint64): Operand {.inline.} =
  Operand(
    kind: Mem64BaseAndOffset,
    reg: base,
    offsetOrImmediate: offset
  )

proc isRegisterOrMemory*(op: Operand): bool {.inline.} =
  op.kind == Rst or op.kind == Mem64BaseAndOffset

proc fitsInU8*(op: Operand): bool {.inline.} =
  op.kind == Imm and op.offsetOrImmediate <= uint8.high.uint64

proc fitsInU32*(op: Operand): bool {.inline.} =
  op.kind == Imm and op.offsetOrImmediate <= uint32.high.uint64

proc fitsInI8*(op: Operand): bool {.inline.} =
  op.kind == Imm and op.offsetOrImmediate <= int8.high.uint64

proc fitsInI32*(op: Operand): bool {.inline.} =
  op.kind == Imm and op.offsetOrImmediate <= int32.high.uint64


