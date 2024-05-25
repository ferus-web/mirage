## MAtoms are a dynamic-ish type used by all of Mirage to pass around values from the emitter to the interpreter, 
## to the calling Nim code itself.
##
## Copyright (C) 2024 Trayambak Rai

import std/[strutils, tables, hashes, options]
import ./runtime/[shared]
import ./utils

type
  MAtomKind* = enum
    Null = 0
    String = 1
    Integer = 2
    Sequence = 3
    Ident = 4
    UnsignedInt = 5
    Boolean = 6
    Object = 7

  MAtom* = object
    case kind*: MAtomKind
    of String:
      str*: string
    of Ident:
      ident*: string
    of Integer:
      integer*: int
    of Sequence:
      sequence*: seq[MAtom]
      cap*: Option[int]
    of UnsignedInt:
      uinteger*: uint
    of Boolean:
      state*: bool
    of Object:
      fields*: TableRef[string, int]
      values*: seq[MAtom]
    of Null: discard

  MAtomSeq* = distinct seq[MAtom]

proc `=destroy`*(dest: MAtom) =
  case dest.kind
  of String:
    `=destroy`(dest.str)
  of Ident:
    `=destroy`(dest.ident)
  of Sequence:
    for atom in dest.sequence:
      `=destroy`(atom)
  else: discard 

#[
proc `=copy`*(dest: var MAtom, src: MAtom) =
  `=destroy`(dest)
  wasMoved dest

  dest.kind = src.kind
  case src.kind
  of String:
    dest.str = cast[string](alloc(sizeof src.str))
    for i, elem in 0..<dest.str.len:
      dest.str[i] = elem
  of Integer:
    var ival = cast[ptr int](alloc(sizeof int))
    ival[] = src.integer

    dest.integer = ival
  of Sequence:
    dest.sequence = cast[seq[MAtom]](alloc(sizeof src.sequence))

    for i, elem in src.sequence:
      dest.sequence[i] = elem
  of Ref:
    var sval = cast[string](alloc(sizeof str.link))
    
    for i, elem in src.link:
      sval[i] = src.link[i]

    dest.reference = deepCopy(src.reference)
    dest.link = sval
  of Null: discard
]#

proc hash*(atom: MAtom): Hash {.inline.} =
  var h: Hash = 0

  case atom.kind
  of String:
    h = h !& atom.str.hash()
  of Ident:
    h = h !& atom.ident.hash()
  of Integer:
    h = h !& atom.integer
  else: discard

  !$h

proc crush*(atom: MAtom, id: string, quote: bool = true): string {.inline.} =
  case atom.kind
  of String:
    if quote:
      result &= '"' & atom.str & '"'
    else:
      result &= atom.str
  of Integer:
    result &= $atom.integer
  of UnsignedInt:
    result &= $atom.uinteger
  of Ident:
    result &= atom.ident
  of Boolean:
    result &= $atom.state
  of Sequence:
    result &= '[' # sequence guard open

    for i, item in atom.sequence:
      echo i
      result &= item.crush(id & "_mseq_" & $i)

      if i + 1 < atom.sequence.len:
        result &= ", "

    result &= ']' # sequence guard close
  of Null, Object:
    return "NULL"

proc len*(s: MAtomSeq): int {.borrow.}
proc `[]`*(s: MAtomSeq, i: Natural): MAtom {.inline.} =
  if i < s.len and i >= 0:
    s[i]
  else:
    MAtom(kind: Null)

proc getStr*(atom: MAtom): Option[string] {.inline.} =
  if atom.kind == String:
    return some(atom.str)

proc getInt*(atom: MAtom): Option[int] {.inline.} =
  if atom.kind == Integer:
    return some(atom.integer)

proc getBool*(atom: MAtom): Option[bool] {.inline.} =
  if atom.kind == Boolean:
    return some atom.state

proc getIdent*(atom: MAtom): Option[string] {.inline.} =
  if atom.kind == Ident:
    return some atom.ident

proc getUint*(atom: MAtom): Option[uint] {.inline.} =
  if atom.kind == UnsignedInt:
    return some atom.uinteger

proc getSequence*(atom: MAtom): Option[seq[MAtom]] {.inline.} =
  if atom.kind == Sequence:
    return some(atom.sequence)

proc str*(s: string): MAtom {.inline, gcsafe, noSideEffect.} =
  MAtom(
    kind: String,
    str: s
  )

proc integer*(i: int): MAtom {.inline, gcsafe, noSideEffect.} =
  MAtom(
    kind: Integer,
    integer: i
  )

proc uinteger*(u: uint): MAtom {.inline, gcsafe, noSideEffect.} =
  MAtom(
    kind: UnsignedInt,
    uinteger: u
  )

proc boolean*(b: bool): MAtom {.inline, gcsafe, noSideEffect.} =
  MAtom(
    kind: Boolean,
    state: b
  )

proc boolean*(s: string): Option[MAtom] {.inline, gcsafe, noSideEffect.} =
  try:
    return some(
      MAtom(
        kind: Boolean,
        state: parseBool(s)
      )
    )
  except ValueError: discard

proc ident*(i: string): MAtom {.inline, gcsafe, noSideEffect.} =
  MAtom(kind: Ident, ident: i)

proc null*: MAtom {.inline, gcsafe, noSideEffect.} =
  MAtom(kind: Null)

proc sequence*(s: seq[MAtom]): MAtom {.inline.} =
  MAtom(
    kind: Sequence,
    sequence: s
  )

proc obj*: MAtom {.inline.} =
  MAtom(
    kind: Object,
    fields: newTable[string, int](),
    values: @[]
  )

proc toString*(atom: MAtom): MAtom {.inline.} =
  case atom.kind
  of String:
    return atom
  of Ident:
    return str(
      $(&atom.getIdent())
    )
  of Integer:
    return str(
      $(&atom.getInt())
    )
  of Sequence:
    return str(
      $(&atom.getSequence())
    )
  of UnsignedInt:
    return str(
      $(&atom.getUint())
    )
  of Boolean:
    return str(
      $(&atom.getBool())
    )
  of Object:
    var msg = "<object structure>\n"
    
    for field, index in atom.fields:
      msg &= field & ": " & atom.values[index].crush("") & '\n'

    msg &= "<end object structure>"
    return msg.str()
  of Null:
    return str "Null"

proc toInt*(atom: MAtom): MAtom {.inline.} =
  case atom.kind
  of String:
    try:
      return parseInt(atom.str).integer()
    except ValueError:
      return integer 0
  of Ident:
    try:
      return parseInt(atom.ident).integer()
    except ValueError:
      return integer 0
  of Integer, UnsignedInt:
    return atom
  of Sequence:
    return atom.sequence.len.integer()
  of Null:
    return integer 0
  of Boolean:
    return atom.state.int.integer()
  of Object: return integer 0
