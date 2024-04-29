import ../../atom

type
  EmptyCellError* = object of Defect
  Cell* = object
    data: pointer
    id: uint       # id on stack
    empty: bool = true

    refcount: uint
    generation: uint
    refs*: seq[uint] # references to other cells on the stack

proc `!`*(cell: Cell): bool {.inline.} =
  cell.empty

proc addRef*(refered, referer: var Cell) {.inline.} =
  referer.refs.add(refered.id)
  inc refered.refcount

proc deref*(refered, referer: var Cell) {.inline.} =
  dec refered.refcount
  referer.refs.del(referer.refs.find(refered.id))

proc survivedSweep*(cell: var Cell) {.inline.} =
  if cell.generation == 3'u8:
    return

  inc cell.generation

proc get*(cell: Cell): MAtom {.inline.} =
  if !cell:
    raise newException(
      EmptyCellError,
      "Attempt to get data from empty cell."
    )

  cast[MAtom](cell.data)

proc newCell*(atom: MAtom): Cell {.inline.} =
  Cell(
    data: cast[pointer](atom),
    empty: false
  )

export atom
