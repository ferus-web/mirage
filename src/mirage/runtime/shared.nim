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
    Call = "CALL"

    ## Load an integer onto the stack
    ## Arguments:
    ## `idx`: Integer - stack index
    ## `value`: Integer - int value
    LoadInt = "LOADI"

    ## Load a string onto the stack
    ## Arguments:
    ## `idx`: Integer - stack index
    ## `value`: string - str value
    LoadStr = "LOADS"

    ## Jump to an operation in the current clause
    ## Arguments:
    ## `idx`: Integer - operation ID
    Jump = "JUMP"

    Add = "ADD"
    Mult = "MULT"
    Div = "DIV"
    Sub = "SUB"

    ## Executes the line after this instruction if the condition is true, otherwise the line after that line.
    ## Wherever the line is, execution continues from there on.
    ## Arguments:
    ## `...`: Integer - indexes on the stack
    Equate = "EQU"

    ## Do not execute any more lines after this, signifying an end to a clause.
    ## Arguments:
    ## value: Integer - a return value, can be Null
    Return = "RETURN"

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
  else:
    raise newException(ValueError, "Invalid operation: " & op)

const
  KNOWN_OPS* = [
    "CALL", "LOADI", "LOADS",
    "ADD", "SUB", "MULT", "DIV", "JUMP", "EQU", "RETURN"
  ]
