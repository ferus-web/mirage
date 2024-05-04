import std/[hashes, options]
import utils

type
  MAtomKind* = enum
    Null = 0
    String = 1
    Integer = 2
    Sequence = 3

  MAtom* = object
    case kind*: MAtomKind
    of String:
      str*: string
    of Integer:
      integer*: int
    of Sequence:
      sequence*: seq[MAtom]
      cap*: Option[int]
    of Null: discard

  MAtomSeq* = distinct seq[MAtom]

proc `=destroy`*(dest: MAtom) =
  case dest.kind
  of String:
    `=destroy`(dest.str)
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
  of Sequence:
    result &= '$' # sequence guard open

    for i, item in atom.sequence:
      result &= item.crush(id & "_mseq_" & $i)

    result &= '$' # sequence guard close
  of Null:
    return "Null"

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

proc getSequence*(atom: MAtom): Option[seq[MAtom]] {.inline.} =
  if atom.kind == Sequence:
    return some(atom.sequence)

proc str*(s: string): MAtom {.inline.} =
  MAtom(
    kind: String,
    str: s
  )

proc integer*(i: int): MAtom {.inline.} =
  MAtom(
    kind: Integer,
    integer: i
  )

proc sequence*(s: seq[MAtom]): MAtom {.inline.} =
  MAtom(
    kind: Sequence,
    sequence: s
  )

proc toString*(atom: MAtom): MAtom {.inline.} =
  case atom.kind
  of String:
    return atom
  of Integer:
    return str(
      $(&atom.getInt())
    )
  of Sequence:
    return str(
      $(&atom.getSequence())
    )
  of Null:
    return str "Null"
