import ../atom, clause

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
    Call = "CALL"
    LoadInt = "LOADI"
    LoadList = "LOADL"
    LoadStr = "LOADS"
    LoadRef = "LOADR"
    Add = "ADD"
    Mult = "MULT"
    Div = "DIV"
    Sub = "SUB"

    LoopConditions = "LOOP_CONDITIONS"
    LoopBody = "LOOP_BODY"
    LoopEnd = "LOOP_END"

proc toOp*(op: string): Ops {.inline, raises: [ValueError].} =
  case op
  of "CALL":
    Call
  of "LOADI":
    LoadInt
  of "LOADS":
    LoadStr
  of "LOADL":
    LoadList
  of "LOADR":
    LoadRef
  of "ADD":
    Add
  of "SUB":
    Sub
  of "MULT":
    Mult
  of "DIV":
    Div
  of "LOOP_CONDITIONS":
    LoopConditions
  of "LOOP_BODY":
    LoopBody
  of "LOOP_END":
    LoopEnd
  else:
    raise newException(ValueError, "Invalid operation: " & op)

const
  KNOWN_OPS* = [
    "CALL", "LOADI", "LOADL", "LOADS", "LOADR",
    "ADD", "SUB", "MULT", "DIV", "LOOP_CONDITIONS", "LOOP_BODY", "LOOP_END"
  ]
