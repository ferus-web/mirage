import std/options

type
  MAtomKind* = enum
    String
    Integer
    Sequence
    Ref
    Null

  MAtom* = ref object
    case kind*: MAtomKind
    of String:
      str*: string
    of Integer:
      integer*: int
    of Sequence:
      sequence*: seq[MAtom]
    of Ref:
      reference*: Option[int]
      link*: string
    of Null: discard

  MAtomSeq* = distinct seq[MAtom]

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
  of Ref:
    if atom.reference.isSome:
      return $atom.reference.unsafeGet()

    return atom.link
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

proc isStrong*(atom: MAtom): bool {.inline.} =
  atom.kind == Ref and atom.reference.isSome

proc isWeak*(atom: MAtom): bool {.inline.} =
  atom.kind == Ref and atom.reference.isNone

proc str*(s: string): MAtom {.inline.} =
  MAtom(
    kind: String,
    str: s
  )

proc strongRef*(idx: int): MAtom {.inline.} =
  MAtom(
    kind: Ref,
    reference: some idx
  )

proc weakRef*(link: string): MAtom {.inline.} =
  MAtom(
    kind: Ref,
    link: link
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
