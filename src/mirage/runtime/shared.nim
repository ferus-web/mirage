import ../atom

type
  TokenKind* = enum
    tkComment
    tkOperation
    tkQuotedString
    tkInteger
    tkDouble
    tkWhitespace
    tkClause
    tkIdent
    tkEnd

  Token* = ref object
    case kind*: TokenKind
    of tkComment:
      comment*: string
    of tkQuotedString:
      str*: string
    of tkInteger:
      integer*: int32
      iHasSign*: bool
    of tkOperation:
      op*: string
    of tkDouble:
      double*: float32
      dHasSign*: bool
    of tkWhitespace:
      whitespace*: string
    of tkClause:
      clause*: string
    of tkIdent:
      ident*: string
    of tkEnd:
      endClause*: string
  
  Ops* = enum
    ## Call a function.
    ## Arguments:
    ## `name`: Ident -  name of the function or builtin
    ## `...`: Integers - stack indexes as arguments
    Call = 0x00

    ## Load an integer onto the stack
    ## Arguments:
    ## `idx`: Integer - stack index
    ## `value`: Integer - int value
    LoadInt = 0x01

    ## Load a string onto the stack
    ## Arguments:
    ## `idx`: Integer - stack index
    ## `value`: string - str value
    LoadStr = 0x02

    ## Jump to an operation in the current clause
    ## Arguments:
    ## `idx`: Integer - operation ID
    Jump = 0x03
    
    Add = 0x04
    Mult = 0x05
    Div = 0x06
    Sub = 0x07

    ## Executes the line after this instruction if the condition is true, otherwise the line after that line.
    ## Wherever the line is, execution continues from there on.
    ## Arguments:
    ## `...`: Integer - indexes on the stack
    Equate = 0x08

    ## Do not execute any more lines after this, signifying an end to a clause.
    ## Arguments:
    ## value: Integer - a return value, can be NULL
    Return = 0x09

    ## Add to a pre-existing cell on the stack, granted that it is an integer as well.
    ## Arguments:
    ## value: Integer - the index on the stack to add the value to
    ## adder: Integer - the index on the stack from which the integer is read and added to the value
    AddInt = 0x10

    ## Add to a pre-existing cell on the stack, granted that it is a string as well.
    ## Arguments:
    ## value: Integer - the index on the stack to add the value to
    ## adder: Integer - the index on the stack from which the string is read and appended to the end of the value
    AddStr = 0x11

    ## Subtract from a pre-existing cell on the stack, granted that it is an integer as well.
    ## Arguments:
    ## value: Integer - the index on the stack to subtract from
    ## subber: Integer - the index on the stack from which the subtraction value is read and subtracted from `value`
    SubInt = 0x12

    ## Load a list
    ## Arguments:
    ## `idx`: the index on which the list is loaded
    LoadList = 0x13

    ## Add an atom to a list
    ## Arguments:
    ## `idx`: the index on which the list is located
    ## `value`: Integer/String/List - any accepted atom
    AddList = 0x14

    ## Set a cap/limit on how many items can be added to a list.
    ## If the list already has more items than the new cap, they are removed from the list
    ## and cleaned up* by the garbage collector.
    ## Arguments:
    ## `idx`: Integer - the index on which the list is located
    ## `cap`: Integer - the new list cap
    SetCapList = 0x15

    ## Get the last element of a list and remove it from the list.
    ## If the list is empty, a `Null` atom will be provided
    PopList = 0x16

    ## Get the first element of a list and remove it from the list.
    ## If the list is empty, a `Null` atom will be provided
    PopListPrefix = 0x17

    ## Cast a value on the stack to an integer and store it in another location.
    CastInt = 0x18

    ## Cast a value on the stack to a string and store it in another location.
    CastStr = 0x19

proc toOp*(op: string): Ops {.inline, raises: [ValueError].} =
  case op
  of "CALL":
    Call
  of "LOADI":
    LoadInt
  of "LOADS":
    LoadStr
  of "ADD":
    Add
  of "SUB":
    Sub
  of "MULT":
    Mult
  of "DIV":
    Div
  of "JUMP":
    Jump
  of "RETURN":
    Return
  of "EQU":
    Equate
  of "ADDI":
    AddInt
  of "ADDS":
    AddStr
  of "SUBI":
    SubInt
  of "LOADL":
    LoadList
  of "POPL":
    PopList
  of "POPLPFX":
    PopListPrefix
  of "CASTINT":
    CastInt
  of "CASTSTR":
    CastStr
  else:
    raise newException(ValueError, "Invalid operation: " & op)

const
  KNOWN_OPS* = [
    "CALL", "LOADI", "LOADS", "ADDI", "ADDS",
    "ADD", "SUB", "MULT", "DIV", "JUMP", "EQU", "RETURN",
    "SUBI"
  ]
