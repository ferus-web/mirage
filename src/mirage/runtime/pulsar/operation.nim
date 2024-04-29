import ../shared, ./cell

type
  Operation* = ref object
    index*: uint64

    opcode*: Ops
    rawArgs*: seq[Token] # should be zero'd out once `computeArgs` is called

    arguments*: seq[Cell]
