import std/options

type
  MAtomKind* = enum
    String
    Integer
    Sequence
    Ref

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

proc crush*(atom: MAtom, id: string): string {.inline.} =
  case atom.kind
  of String:
    result &= '"' & atom.str & '"'
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
